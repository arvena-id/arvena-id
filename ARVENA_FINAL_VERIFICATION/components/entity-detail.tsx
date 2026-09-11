import Link from "next/link";
import { getEntity } from "@/lib/data";
import { ErrorState, EmptyState } from "@/components/states";
export async function EntityDetail({entity,id,editHref}:{entity:string;id:string;editHref?:string}){
 const {row,error}=await getEntity(entity,id);
 return <main className="page"><div className="page-head"><div><h1>{entity.slice(0,1).toUpperCase()+entity.slice(1)} detail</h1><p>Record ID {id}</p></div>{editHref&&<Link className="btn" href={editHref}>Edit</Link>}</div>{error?<ErrorState message={error}/>:!row?<EmptyState title="Record tidak ditemukan" message="Record tidak tersedia dalam organization atau scope Anda."/>:<div className="panel"><dl className="grid-2">{Object.entries(row).filter(([,v])=>v!==null).map(([k,v])=><div key={k}><dt className="muted">{k.replaceAll("_"," ")}</dt><dd>{typeof v==="object"?JSON.stringify(v):String(v)}</dd></div>)}</dl></div>}</main>
}
