"use client";
import { FormEvent, useState } from "react";
import { createBrowserSupabase } from "@/lib/supabase/client";
import { Brand } from "@/components/brand";
export function AuthForm({mode}:{mode:"login"|"signup"|"forgot"|"reset"}){
 const [error,setError]=useState<string|null>(null);const [busy,setBusy]=useState(false);
 async function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();setBusy(true);setError(null);const form=new FormData(e.currentTarget);const email=String(form.get("email")??"");const password=String(form.get("password")??"");const supabase=createBrowserSupabase();
  if(mode==="login"){const {error}=await supabase.auth.signInWithPassword({email,password});if(error){setError("Email atau password tidak valid.");setBusy(false);return;}location.assign("/dashboard");return;}
  if(mode==="signup"){const {error}=await supabase.auth.signUp({email,password,options:{data:{display_name:String(form.get("name")??"")},emailRedirectTo:`${location.origin}/onboarding`}});if(error){setError("Pendaftaran belum berhasil. Periksa data lalu coba lagi.");setBusy(false);return;}location.assign("/onboarding");return;}
  if(mode==="forgot"){const {error}=await supabase.auth.resetPasswordForEmail(email,{redirectTo:`${location.origin}/reset-password`});if(error){setError("Permintaan belum dapat diproses. Coba lagi.");}else{setError("Jika email dapat digunakan untuk pemulihan, instruksi akan dikirim.");}setBusy(false);return;}
  const {error}=await supabase.auth.updateUser({password});if(error){setError("Password belum berhasil diubah.");setBusy(false);return;}location.assign("/dashboard");
 }
 const title={login:"Masuk ke ARVENA",signup:"Buat akun ARVENA",forgot:"Lupa password",reset:"Atur password baru"}[mode];
 return <div className="auth-shell"><div className="auth-card"><Brand/><h1>{title}</h1><p>Gunakan akun Anda untuk mengakses organization yang diizinkan.</p><form className="stack" onSubmit={submit}>{mode==="signup"&&<label className="field"><span className="label">Nama</span><input className="input" name="name" required/></label>}{mode!=="reset"&&<label className="field"><span className="label">Email</span><input className="input" type="email" name="email" autoComplete="email" required/></label>}{mode!=="forgot"&&<label className="field"><span className="label">Password</span><input className="input" type="password" name="password" minLength={8} autoComplete={mode==="login"?"current-password":"new-password"} required/></label>}{error&&<div className="notice">{error}</div>}<button className="btn btn-primary" disabled={busy}>{busy?"Memproses…":"Lanjut"}</button></form>{mode==="login"&&<p><a href="/forgot-password">Lupa password?</a> · <a href="/signup">Daftar</a></p>}{mode==="signup"&&<p><a href="/login">Sudah punya akun?</a></p>}</div></div>
}
