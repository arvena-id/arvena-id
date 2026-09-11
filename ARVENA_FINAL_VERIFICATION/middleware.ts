import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
const publicPaths=["/login","/signup","/forgot-password","/reset-password"];
export async function middleware(request:NextRequest){
 let response=NextResponse.next({request});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 if(!url||!key) return response;
 const supabase=createServerClient(url,key,{cookies:{getAll(){return request.cookies.getAll()},setAll(cookies){cookies.forEach(({name,value})=>request.cookies.set(name,value));response=NextResponse.next({request});cookies.forEach(({name,value,options})=>response.cookies.set(name,value,options));}}});
 const {data:{user}}=await supabase.auth.getUser(); const isPublic=publicPaths.some(p=>request.nextUrl.pathname.startsWith(p));
 if(!user&&!isPublic&&!request.nextUrl.pathname.startsWith("/api")){const u=request.nextUrl.clone();u.pathname="/login";u.searchParams.set("next",request.nextUrl.pathname);return NextResponse.redirect(u)}
 if(user&&isPublic){const u=request.nextUrl.clone();u.pathname="/dashboard";u.search="";return NextResponse.redirect(u)}
 return response;
}
export const config={matcher:["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"]};
