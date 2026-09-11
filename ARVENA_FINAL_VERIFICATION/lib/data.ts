import { getSessionContext } from "@/lib/context";
import { entityTables, resources, type ResourceKey } from "@/lib/p0";
export async function listResource(key: ResourceKey, limit=100) {
  const { supabase, activeOrganization } = await getSessionContext();
  if (!activeOrganization) return { rows: [] as Record<string,unknown>[], error: "No active organization" };
  const cfg=resources[key]; const source=cfg.view ?? cfg.table!;
  const { data, error } = await supabase.from(source).select("*").eq("organization_id",activeOrganization.organization_id).limit(limit);
  return { rows:(data ?? []) as Record<string,unknown>[], error:error?.message ?? null };
}
export async function getEntity(key:string,id:string) {
  const { supabase, activeOrganization }=await getSessionContext();
  if(!activeOrganization) return {row:null,error:"No active organization"};
  const table=entityTables[key]; if(!table) return {row:null,error:"Unknown entity"};
  const {data,error}=await supabase.from(table).select("*").eq("organization_id",activeOrganization.organization_id).eq("id",id).maybeSingle();
  return {row:data as Record<string,unknown>|null,error:error?.message ?? null};
}
