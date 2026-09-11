import { NextResponse } from "next/server";
import { commands } from "@/lib/p0";
import { createServerSupabase } from "@/lib/supabase/server";
import { parsePhoneNumberFromString } from "libphonenumber-js";
export async function POST(request:Request,{params}:{params:Promise<{command:string}>}){
 const {command}=await params;if(!commands.has(command))return NextResponse.json({error:"Unsupported P0 command"},{status:404});
 const supabase=await createServerSupabase();const {data:{user}}=await supabase.auth.getUser();if(!user)return NextResponse.json({error:"Authentication required"},{status:401});
 const {data:org,error:orgError}=await supabase.rpc("active_organization_id");if(orgError||!org)return NextResponse.json({error:"Active organization required"},{status:403});
 const body=(await request.json()) as Record<string,unknown>;delete body.p_org;body.p_org=org;
 const numericKeys=new Set(["p_expected_version","p_amount","p_estimated","p_document_discount","p_interval","p_size","p_rate_ppm"]);
 const jsonKeys=new Set(["p_items","p_template","p_address","p_filter","p_mapping","p_value","p_rows"]);
 for(const [key,value] of Object.entries(body)){
   if(value===""){body[key]=null;continue;}
   if(numericKeys.has(key)&&typeof value==="string") body[key]=Number(value);
   if(jsonKeys.has(key)&&typeof value==="string"){try{body[key]=JSON.parse(value)}catch{return NextResponse.json({error:`${key} harus JSON valid`},{status:400});}}
   if(key==="p_override"&&typeof value==="string") body[key]=value==="true";
   if(key==="p_assign_members"&&typeof value==="string") body[key]=value.split(",").map(v=>v.trim()).filter(Boolean);
 }
 if(command==="create_customer"&&typeof body.p_raw_phone==="string"&&!body.p_normalized_phone){const country=typeof body.country_code==="string"?body.country_code:undefined;const parsed=parsePhoneNumberFromString(body.p_raw_phone,country as never);body.p_normalized_phone=parsed?.isValid()?parsed.number:null;delete body.country_code;}
 const {data,error}=await supabase.rpc(command,body);if(error)return NextResponse.json({error:error.message,code:error.code},{status:error.message.includes("permission")?403:409});return NextResponse.json({data});
}
