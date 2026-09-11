export type ResourceKey = "customers"|"team"|"leads"|"quotes"|"jobs"|"visits"|"invoices"|"payments"|"followups"|"assets"|"recurring"|"imports"|"exports"|"notifications";
export const resources: Record<ResourceKey,{title:string;view?:string;table?:string;newHref?:string;detailBase?:string;columns:string[]}> = {
 customers:{title:"Customers",view:"customer_list_v",newHref:"/customers/new",detailBase:"/customers",columns:["name","type","normalized_phone","source","assigned_sales","updated_at"]},
 team:{title:"Team",view:"team_list_v",newHref:"/team/invite",detailBase:"/team",columns:["display_name","email","role","status"]},
 leads:{title:"Leads",view:"lead_list_v",newHref:"/leads/new",detailBase:"/leads",columns:["customer","phone","service","status","temperature","sales","source","next_follow_up_at","updated_at"]},
 quotes:{title:"Quotes",view:"quote_list_v",newHref:"/quotes/new",detailBase:"/quotes",columns:["quote_number","customer","total_minor","currency_code","status","expires_at","sales"]},
 jobs:{title:"Jobs",view:"job_list_v",newHref:"/jobs/new",detailBase:"/jobs",columns:["job_number","customer","service","status","next_visit","assigned_team","priority","updated_at"]},
 visits:{title:"Visits",view:"visit_list_v",detailBase:"/visits",columns:["job_number","customer","service","status","scheduled_start","assigned_team"]},
 invoices:{title:"Invoices",view:"invoice_list_v",newHref:"/invoices/new",detailBase:"/invoices",columns:["invoice_number","customer","total_minor","paid_minor","outstanding_minor","currency_code","due_at","status"]},
 payments:{title:"Payments",view:"payment_list_v",newHref:"/payments/new",columns:["invoice_number","customer","amount_minor","currency_code","method","paid_at","status"]},
 followups:{title:"Follow-ups",view:"followup_list_v",columns:["customer","reason","due_at","assignee","status"]},
 assets:{title:"Assets",view:"asset_list_v",newHref:"/assets/new",detailBase:"/assets",columns:["name","asset_type","customer","brand","model","serial_number","status"]},
 recurring:{title:"Recurring",view:"recurring_list_v",newHref:"/recurring/new",detailBase:"/recurring",columns:["customer","recurrence_type","interval_value","local_time","timezone","next_occurrence_at","active","failures"]},
 imports:{title:"Import history",table:"import_jobs",newHref:"/data/import",detailBase:"/data/import",columns:["kind","status","valid_count","duplicate_count","error_count","committed_count","created_at"]},
 exports:{title:"Export history",table:"export_jobs",newHref:"/data/export",detailBase:"/data/export",columns:["dataset","state","expires_at","created_at"]},
 notifications:{title:"Notifications",table:"notifications",columns:["title","body","read_at","created_at"]},
};

export const entityTables: Record<string,string> = {
 customers:"customers", team:"organization_members", leads:"leads", quotes:"quotes", jobs:"jobs", visits:"visits", invoices:"invoices", assets:"assets", recurring:"recurring_rules", imports:"import_jobs", exports:"export_jobs"
};

export const commands = new Set([
 "create_customer","create_lead","create_followup","create_quote","update_quote_draft","issue_quote","update_quote_status","convert_quote_to_job",
 "create_job","update_job_fields","confirm_job","schedule_visit","visit_action","complete_job","job_action",
 "create_invoice","update_invoice_draft","issue_invoice","record_payment","reverse_payment","void_invoice",
 "create_asset","update_asset_fields","create_recurring_rule","update_recurring_rule","skip_recurring_occurrence","deactivate_recurring_rule",
 "invite_member","update_member","create_media","finalize_media","fail_media","retry_media","respond_checklist","create_note",
 "create_import_job","attach_import_source","update_import_mapping","stage_import_rows","set_import_duplicate_decision","commit_import_job",
 "create_export_job","refresh_export_expiry","register_export_result","fail_export_job","process_client_actions","upsert_notification_preference"
]);
