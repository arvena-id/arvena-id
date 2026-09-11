"use client";
import { useState } from "react";
type Field={name:string;label:string;type?:string;required?:boolean;placeholder?:string};
export function CommandForm({command,fields,defaults={},onSuccess}:{command:string;fields:Field[];defaults?:Record<string,string|number|boolean|null>;onSuccess?:string}){
 const [busy,setBusy]=useState(false); const [message,setMessage]=useState<string|null>(null);
 async function submit(form:FormData){setBusy(true);setMessage(null);const args:Record<string,unknown>={};for(const f of fields){const v=form.get(f.name);args[f.name]=v===""?null:v;} args.p_key=crypto.randomUUID(); const r=await fetch(`/api/command/${command}`,{method:"POST",headers:{"content-type":"application/json"},body:JSON.stringify(args)});const j=await r.json();setBusy(false);if(!r.ok){setMessage(j.error??"Command failed");return;}setMessage("Tersimpan.");if(onSuccess) location.assign(onSuccess);}
 return <form className="panel stack" action={submit}>{fields.map(f=><label className="field" key={f.name}><span className="label">{f.label}</span><input className="input" name={f.name} type={f.type??"text"} required={f.required} defaultValue={defaults[f.name]==null?"":String(defaults[f.name])} placeholder={f.placeholder}/></label>)}{message&&<div className="notice">{message}</div>}<button className="btn btn-primary" disabled={busy}>{busy?"Menyimpan…":"Simpan"}</button></form>
}
