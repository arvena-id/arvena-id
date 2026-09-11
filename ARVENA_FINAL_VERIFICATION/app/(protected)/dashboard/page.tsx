import Link from "next/link";
import { getSessionContext } from "@/lib/context";
const count=(rows:unknown[]|null)=>rows?.length??0;
export default async function Page(){
 const {supabase,activeOrganization}=await getSessionContext();
 const org=activeOrganization?.organization_id;
 if(!org)return <main className="page"><div className="error-state">Pilih organization aktif untuk membuka Dashboard.</div></main>;
 const now=new Date().toISOString();
 const [fu,jobs,visits,conflicts,inv,rec,team]=await Promise.all([
  supabase.from("follow_ups").select("id",{count:"exact"}).eq("organization_id",org).eq("status","PENDING").lt("due_at",now),
  supabase.from("jobs").select("id",{count:"exact"}).eq("organization_id",org).in("status",["CONFIRMED","SCHEDULED","IN_PROGRESS"]).is("archived_at",null),
  supabase.from("visits").select("id,status,scheduled_start,scheduled_end").eq("organization_id",org).not("status","in",'(COMPLETED,CANCELLED,NO_SHOW)').lte("scheduled_end",now),
  supabase.from("active_schedule_conflicts_v").select("visit_id").eq("organization_id",org),
  supabase.from("invoices").select("id,total_minor,paid_minor,outstanding_minor,currency_code,status,due_at").eq("organization_id",org).gt("outstanding_minor",0),
  supabase.from("recurring_occurrences").select("id").eq("organization_id",org).eq("status","PENDING").lte("resolved_occurrence_at",new Date(Date.now()+7*86400000).toISOString()),
  supabase.from("organization_members").select("id,status").eq("organization_id",org).eq("status","ACTIVE")
 ]);
 const overdueInvoices=(inv.data??[]).filter(i=>i.due_at&&new Date(i.due_at)<new Date());
 const money=(inv.data??[]).reduce<Record<string,{outstanding:number;overdue:number}>>((a,i)=>{const k=i.currency_code;a[k]??={outstanding:0,overdue:0};a[k].outstanding+=Number(i.outstanding_minor??0);if(i.due_at&&new Date(i.due_at)<new Date())a[k].overdue+=Number(i.outstanding_minor??0);return a;},{});
 const attention=[
  ["Follow-up overdue",fu.count??0,"/follow-ups?tab=overdue"],["Unassigned / active Jobs",jobs.count??0,"/jobs?unassigned=1"],["Schedule conflicts",count(conflicts.data),"/calendar?conflicts=1"],["Late Visits",count(visits.data),"/calendar?late=1"],["Invoices overdue",overdueInvoices.length,"/invoices?overdue=1"],["Recurring due",count(rec.data),"/recurring?due=1"]
 ] as const;
 return <main className="page"><div className="page-head"><div><h1>Dashboard</h1><p>Apa yang perlu perhatian sekarang?</p></div></div><section className="stack"><h2>Perlu Perhatian</h2><div className="grid-3">{attention.map(([label,n,href])=><Link className="card" href={href} key={label}><div className="kpi">{n}</div><strong>{label}</strong><p className="muted">Buka record terkait</p></Link>)}</div><h2>Today&apos;s Operations</h2><div className="grid-3"><div className="card"><div className="kpi">{jobs.count??0}</div><span>Jobs aktif</span></div><div className="card"><div className="kpi">{team.count??0}</div><span>Team aktif</span></div><div className="card"><div className="kpi">{count(visits.data)}</div><span>Late/open Visits</span></div></div><h2>Money Snapshot</h2><div className="grid-3">{Object.entries(money).map(([cur,v])=><div className="card" key={cur}><strong>{cur}</strong><p>Outstanding: {v.outstanding}</p><p>Overdue: {v.overdue}</p></div>)}</div><h2>Business Health Center</h2><div className="panel"><p>{(fu.count??0)>0?`${fu.count} follow-up terlambat perlu ditindak.`:"Tidak ada follow-up overdue saat ini."}</p>{overdueInvoices.length>0&&<p>{overdueInvoices.length} invoice overdue perlu ditinjau.</p>}<Link className="btn" href="/reports">View Records</Link></div></section></main>
}
