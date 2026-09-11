import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase/server";

export type OrgChoice = { organization_id: string; name: string; slug: string; timezone: string; currency_code: string; is_active: boolean };
export async function getSessionContext(required = true) {
  const supabase = await createServerSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) { if (required) redirect("/login"); return { supabase, user: null, organizations: [] as OrgChoice[], activeOrganization: null }; }
  const { data, error } = await supabase.rpc("list_my_organizations");
  if (error && required) throw new Error(`Organization context unavailable: ${error.message}`);
  const organizations = (data ?? []) as OrgChoice[];
  const activeOrganization = organizations.find((o) => o.is_active) ?? null;
  return { supabase, user, organizations, activeOrganization };
}
