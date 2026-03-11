"use client";
export const dynamic = "force-dynamic";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";
import Link from "next/link";
export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const router = useRouter();
  const supabase = createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password });
      if (authError) { setError("ایمیل یا رمز عبور اشتباه است"); setLoading(false); return; }
      const { data: profile } = await supabase.from("profiles").select("role").eq("id", data.user.id).single();
      if (profile?.role === "carrier") { router.push("/carrier"); }
      else { router.push("/shipper"); }
    } catch { setError("خطای اتصال"); }
    finally { setLoading(false); }
  };
  return (
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",direction:"rtl",fontFamily:"sans-serif",padding:"20px",background:"#f9fafb",color:"#333"}}>
      <div style={{background:"white",borderRadius:"16px",padding:"40px",maxWidth:"400px",width:"100%",boxShadow:"0 4px 20px rgba(0,0,0,0.1)"}}>
        <div style={{textAlign:"center",marginBottom:"24px"}}>
          <Link href="/" style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
          <p style={{color:"#666",marginTop:"8px"}}>ورود به پلتفرم</p>
        </div>
        <form onSubmit={handleLogin}>
          <div style={{marginBottom:"16px"}}>
            <label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>ایمیل</label>
            <input type="email" dir="ltr" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="shipper@test.com" style={{width:"100%",padding:"12px",border:"1px solid #ddd",borderRadius:"8px",fontSize:"16px"}} autoFocus />
          </div>
          <div style={{marginBottom:"16px"}}>
            <label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>رمز عبور</label>
            <input type="password" dir="ltr" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Test1234!" style={{width:"100%",padding:"12px",border:"1px solid #ddd",borderRadius:"8px",fontSize:"16px"}} />
          </div>
          {error && <div style={{background:"#fee",color:"#c00",padding:"10px",borderRadius:"8px",marginBottom:"16px",fontSize:"14px"}}>{error}</div>}
          <button type="submit" disabled={loading} style={{width:"100%",padding:"14px",background:"#1B3A5C",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer"}}>{loading ? "در حال ورود..." : "ورود"}</button>
        </form>
        <div style={{marginTop:"20px",padding:"16px",background:"#f9fafb",borderRadius:"8px",fontSize:"13px",color:"#666"}}>
          <p style={{fontWeight:"bold",marginBottom:"8px"}}>اکانت‌های تست:</p>
          <p>📦 بارفرست: <code>shipper@test.com</code></p>
          <p>🚛 حمل‌کننده: <code>carrier@test.com</code></p>
          <p>رمز هر دو: <code>Test1234!</code></p>
        </div>
      </div>
    </div>
  );
}
