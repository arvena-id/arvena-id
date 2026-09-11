import Link from "next/link";
import { listResource } from "@/lib/data";
import { resources, type ResourceKey } from "@/lib/p0";
import { EmptyState, ErrorState } from "@/components/states";
const fmt=(v:unknown)=>v==null?"—":typeof v==="object"?JSON.stringify(v):String(v);
export async function ResourceList({resource}:{resource:ResourceKey}){
 const cfg=resources[resource]; const {rows,error}=await listResource(resource);
 return <main className="page"><div className="page-head"><div><h1>{cfg.title}</h1><p>Data nyata dari organization aktif. Akses tetap ditentukan oleh RLS dan permission server.</p></div>{cfg.newHref&&<Link className="btn btn-primary" href={cfg.newHref}>Tambah</Link>}</div>
 {error?<ErrorState message={error}/>:rows.length===0?<EmptyState action={cfg.newHref?<Link className="btn btn-primary" href={cfg.newHref}>Tambah {cfg.title}</Link>:undefined}/>:<><div className="desktop-table table-wrap"><table><thead><tr>{cfg.columns.map(c=><th key={c}>{c.replaceAll("_"," ")}</th>)}{cfg.detailBase&&<th>Aksi</th>}</tr></thead><tbody>{rows.map((r,i)=><tr key={String(r.id??i)}>{cfg.columns.map(c=><td key={c}>{fmt(r[c])}</td>)}{cfg.detailBase&&<td><Link className="btn btn-ghost" href={`${cfg.detailBase}/${r.id}`}>Detail</Link></td>}</tr>)}</tbody></table></div><div className="mobile-cards">{rows.map((r,i)=><article className="card" key={String(r.id??i)}>{cfg.columns.slice(0,5).map(c=><div key={c}><strong>{c.replaceAll("_"," ")}:</strong> {fmt(r[c])}</div>)}{cfg.detailBase&&<Link className="btn" href={`${cfg.detailBase}/${r.id}`}>Detail</Link>}</article>)}</div></>}
 </main>
}
