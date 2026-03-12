"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoSphere, LogoText } from "@/components/Logo";
export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const router = useRouter();
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault(); setError(""); setLoading(true);
    try {
      const supabase = getSupabase();
      const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });
      if (authError) { setError("ایمیل یا رمز عبور اشتباه است"); setLoading(false); return; }
      const { data: profile } = await supabase.from("profiles").select("role").eq("id", data.user.id).single();
      if (profile?.role === "admin") router.push("/admin"); else if (profile?.role === "carrier") router.push("/carrier"); else router.push("/shipper");
    } catch { setError("خطای اتصال"); } finally { setLoading(false); }
  };
  const S = {width:"100%",padding:"14px 16px",border:"1px solid #e0e0e0",borderRadius:"10px",fontSize:"15px",outline:"none",transition:"border 0.2s"};
  return (
    <div style={{minHeight:"100vh",display:"flex",fontFamily:"Vazirmatn,sans-serif",direction:"rtl"}}>
      <div style={{flex:1,background:"linear-gradient(135deg,#0c1929 0%,#1B3A5C 40%,#2E75B6 100%)",display:"flex",flexDirection:"column",justifyContent:"center",alignItems:"center",padding:"40px",color:"white"}}>
        <Link href="/" style={{textDecoration:"none",color:"white",display:"flex",flexDirection:"column",alignItems:"center",gap:"16px"}}>
          <LogoSphere size={160} />
          <LogoText size="medium" onDark={true} />
          <p style={{opacity:0.7,fontSize:"14px",marginTop:"8px"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
        </Link>
      </div>
      <div style={{flex:1,display:"flex",alignItems:"center",justifyContent:"center",padding:"40px",background:"#f9fafb"}}>
        <div style={{maxWidth:"400px",width:"100%"}}>
          <h2 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>ورود به حساب</h2>
          <p style={{color:"#888",marginBottom:"32px",fontSize:"14px"}}>ایمیل و رمز عبور خود را وارد کنید</p>
          <form onSubmit={handleLogin}>
            <div style={{marginBottom:"20px"}}>
              <label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"}}>ایمیل</label>
              <input type="email" dir="ltr" value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@company.com" style={{...S}} autoFocus onFocus={e=>(e.target.style.border="1px solid #2E75B6")} onBlur={e=>(e.target.style.border="1px solid #e0e0e0")} />
            </div>
            <div style={{marginBottom:"20px"}}>
              <label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"}}>رمز عبور</label>
              <input type="password" dir="ltr" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" style={{...S}} onFocus={e=>(e.target.style.border="1px solid #2E75B6")} onBlur={e=>(e.target.style.border="1px solid #e0e0e0")} />
            </div>
            {error && <div style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"20px",fontSize:"14px",border:"1px solid #fecaca"}}>{error}</div>}
            <button type="submit" disabled={loading} style={{width:"100%",padding:"14px",background:"#3C3B6E",color:"white",border:"none",borderRadius:"10px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit"}}>{loading?"در حال ورود...":"ورود به حساب"}</button>
          </form>
          <div style={{marginTop:"32px",padding:"20px",background:"white",borderRadius:"12px",border:"1px solid #eee",fontSize:"13px",color:"#888"}}>
            <p style={{fontWeight:"bold",color:"#555",marginBottom:"10px",fontSize:"14px"}}>🔑 اکانت‌های تست:</p>
            <div style={{display:"flex",justifyContent:"space-between",padding:"8px 0",borderBottom:"1px solid #f5f5f5"}}><span>📦 بارفرست</span><code style={{background:"#f5f5f5",padding:"2px 8px",borderRadius:"4px",fontSize:"12px"}} dir="ltr">shipper@test.com</code></div>
            <div style={{display:"flex",justifyContent:"space-between",padding:"8px 0",borderBottom:"1px solid #f5f5f5"}}><span>🚛 حمل‌کننده</span><code style={{background:"#f5f5f5",padding:"2px 8px",borderRadius:"4px",fontSize:"12px"}} dir="ltr">carrier@test.com</code></div>
            <div style={{display:"flex",justifyContent:"space-between",padding:"8px 0"}}><span>🔒 رمز هر دو</span><code style={{background:"#f5f5f5",padding:"2px 8px",borderRadius:"4px",fontSize:"12px"}} dir="ltr">Test1234!</code></div>
          </div>
        </div>
      </div>
    </div>
  );
}
