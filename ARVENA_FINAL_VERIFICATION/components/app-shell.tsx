import Link from "next/link";
import { Brand } from "@/components/brand";
import { getSessionContext } from "@/lib/context";
const nav=[['Home','/dashboard'],['Leads','/leads'],['Quotes','/quotes'],['Follow-ups','/follow-ups'],['Jobs','/jobs'],['Calendar','/calendar'],['Customers','/customers'],['Assets','/assets'],['Invoices','/invoices'],['Payments','/payments'],['Team','/team'],['Reports','/reports'],['Settings','/settings']];
export async function AppShell({children}:{children:React.ReactNode}){
 const {user,activeOrganization,organizations}=await getSessionContext();
 return <div className="app-shell"><aside className="sidebar"><Brand/><div className="org-pill"><strong>{activeOrganization?.name??"Organization belum dipilih"}</strong><br/><span className="muted">{organizations.length} membership</span></div><nav className="nav-section">{nav.map(([label,href])=><Link className="nav-link" key={href} href={href}>{label}</Link>)}</nav><div className="sidebar-footer muted">{user?.email}</div></aside><div className="main"><header className="topbar"><span>{activeOrganization?.name??"ARVENA"}</span><Link href="/settings">Profile & Settings</Link></header>{children}<nav className="mobile-bottom">{[['Home','/dashboard'],['Jobs','/jobs'],['Customers','/customers'],['Calendar','/calendar'],['More','/settings']].map(([l,h])=><Link className="mobile-nav-link" key={h} href={h}>{l}</Link>)}</nav></div></div>
}
