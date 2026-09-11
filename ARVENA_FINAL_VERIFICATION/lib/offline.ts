export type OfflineResult = "APPLIED" | "DUPLICATE" | "RETRYABLE" | "CONFLICT" | "REJECTED";

export type OfflineAction = {
  client_action_id: string;
  sequence: number;
  entity_type: string;
  entity_id: string;
  action: string;
  expected_version?: number | null;
  payload_version: number;
  payload?: Record<string, unknown>;
  dependencies: string[];
  local_occurred_at: string;
};

type QueueState = {
  deviceId: string;
  nextSequence: number;
  actions: OfflineAction[];
  history: Array<{ client_action_id: string; result: OfflineResult; at: string }>;
};

const STORAGE_KEY = "arvena.offline.queue.v1";

function randomId(){
  if(typeof crypto!=="undefined"&&"randomUUID" in crypto) return crypto.randomUUID();
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function emptyState(): QueueState {
  return { deviceId: randomId(), nextSequence: 1, actions: [], history: [] };
}

function readState(): QueueState {
  if(typeof window==="undefined") return emptyState();
  const raw=window.localStorage.getItem(STORAGE_KEY);
  if(!raw){const state=emptyState();writeState(state);return state;}
  try{
    const parsed=JSON.parse(raw) as QueueState;
    if(!parsed.deviceId||!Number.isInteger(parsed.nextSequence)||!Array.isArray(parsed.actions)) throw new Error("invalid queue state");
    return {...parsed,history:Array.isArray(parsed.history)?parsed.history:[]};
  }catch{
    const state=emptyState();writeState(state);return state;
  }
}

function writeState(state: QueueState){
  if(typeof window!=="undefined") window.localStorage.setItem(STORAGE_KEY,JSON.stringify(state));
}

export function enqueueOfflineAction(input: Omit<OfflineAction,"client_action_id"|"sequence"|"payload_version"|"local_occurred_at"|"dependencies"> & {dependencies?:string[]}){
  const state=readState();
  const queued: OfflineAction={
    client_action_id:randomId(),
    sequence:state.nextSequence,
    entity_type:input.entity_type.toUpperCase(),
    entity_id:input.entity_id,
    action:input.action.toUpperCase(),
    expected_version:input.expected_version??null,
    payload_version:1,
    payload:input.payload??{},
    dependencies:input.dependencies??[],
    local_occurred_at:new Date().toISOString()
  };
  state.nextSequence+=1;
  state.actions.push(queued);
  writeState(state);
  return queued;
}

export function getOfflineQueue(){
  const state=readState();
  return {deviceId:state.deviceId,actions:[...state.actions],history:[...state.history]};
}

export async function flushOfflineQueue(){
  const state=readState();
  if(state.actions.length===0) return {processed:0,pending:0};
  const response=await fetch("/api/command/process_client_actions",{
    method:"POST",
    headers:{"content-type":"application/json"},
    body:JSON.stringify({p_device_id:state.deviceId,p_actions:state.actions})
  });
  const body=await response.json() as {data?:Array<{client_action_id:string;result:OfflineResult}>;error?:string};
  if(!response.ok) throw new Error(body.error??"Offline sync failed");
  const results=body.data??[];
  const terminal=new Set<OfflineResult>(["APPLIED","DUPLICATE","CONFLICT","REJECTED"]);
  const resultById=new Map(results.map(r=>[r.client_action_id,r.result]));
  const remaining:OfflineAction[]=[];
  for(const queued of state.actions){
    const result=resultById.get(queued.client_action_id);
    if(!result||result==="RETRYABLE"){
      remaining.push(queued);
      continue;
    }
    if(terminal.has(result)) state.history.push({client_action_id:queued.client_action_id,result,at:new Date().toISOString()});
  }
  state.actions=remaining;
  state.history=state.history.slice(-200);
  writeState(state);
  return {processed:results.length,pending:remaining.length};
}

export function clearOfflineQueue(){
  if(typeof window!=="undefined") window.localStorage.removeItem(STORAGE_KEY);
}
