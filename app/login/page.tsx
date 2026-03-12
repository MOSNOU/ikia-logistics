"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoSphere, LogoText, LogoNav } from "@/components/Logo";
export default function LoginPage() {
  const [mode, setMode] = useState<"login"|"signup">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [role, setRole] = useState("shipper");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
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
  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault(); setError(""); setSuccess(""); setLoading(true);
    if (!fullName.trim()) { setError("نام و نام خانوادگی رو وارد کن"); setLoading(false); return; }
    if (password.length < 6) { setError("رمز عبور باید حداقل ۶ کاراکتر باشد"); setLoading(false); return; }
    try {
      const supabase = getSupabase();
      const { data, error: authError } = await supabase.auth.signUp({ email, password });
      if (authError) { setError("خطا در ثبت‌نام: " + authError.message); setLoading(false); return; }
      if (data.user) {
        await supabase.from("profiles").upsert({ id: data.user.id, phone: email, role, full_name: fullName });
        setSuccess("ثبت‌نام موفق! الان می‌تونی وارد بشی");
        setMode("login");
      }
    } catch { setError("خطای اتصال"); } finally { setLoading(false); }
  };
  return (
    <div className="login-split" style={{minHeight:"100vh",display:"flex",fontFamily:"Vazirmatn,sans-serif",direction:"rtl"}}>
      <div className="login-left" style={{flex:1,background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",display:"flex",flexDirection:"column",justifyContent:"center",alignItems:"center",padding:"40px",color:"white",position:"relative",overflow:"hidden"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 40%, rgba(6,182,212,0.15) 0%, transparent 60%)",pointerEvents:"none"}} />
        <Link href="/" style={{textDecoration:"none",color:"white",display:"flex",flexDirection:"column",alignItems:"center",gap:"20px",position:"relative",zIndex:1}} className="animate-fade-up">
          <div className="animate-float"><LogoSphere size={180} /></div>
          <LogoText size="medium" onDark={true} />
          <p style={{fontWeight:900,fontSize:"16px",marginTop:"8px"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
          <div style={{display:"flex",gap:"16px",marginTop:"20px"}}>
            {[{n:"۹۰۰+",l:"کیلومتر"},{n:"۳۰٪",l:"صرفه‌جویی"},{n:"۲۴h",l:"تسویه"}].map((s,i)=>(
              <div key={i} style={{textAlign:"center",background:"rgba(255,255,255,0.08)",backdropFilter:"blur(10px)",padding:"10px 14px",borderRadius:"10px",border:"1px solid rgba(255,255,255,0.12)"}}>
                <div style={{fontSize:"18px",fontWeight:900}}>{s.n}</div>
                <div style={{fontSize:"10px",opacity:0.7,fontWeight:700}}>{s.l}</div>
              </div>
            ))}
          </div>
        </Link>
      </div>
      <div className="login-right" style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",padding:"32px",background:"#f4f6f9",minHeight:"100vh"}}>
        <div className="show-mobile" style={{display:"none",marginBottom:"24px",textAlign:"center"}}>
          <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        </div>
        <div className="animate-fade" style={{maxWidth:"420px",width:"100%"}}>
          <div className="login-tabs" style={{display:"flex",gap:"0",marginBottom:"24px",background:"#e5e7eb",borderRadius:"14px",padding:"4px"}}>
            <button onClick={()=>{setMode("login");setError("");setSuccess("")}} style={{flex:1,padding:"12px",borderRadius:"12px",fontSize:"15px",fontWeight:900,border:"none",background:mode==="login"?"white":"transparent",color:mode==="login"?"#1e3a5f":"#999",boxShadow:mode==="login"?"0 2px 10px rgba(0,0,0,0.08)":"none",transition:"all 0.2s"}}>ورود</button>
            <button onClick={()=>{setMode("signup");setError("");setSuccess("")}} style={{flex:1,padding:"12px",borderRadius:"12px",fontSize:"15px",fontWeight:900,border:"none",background:mode==="signup"?"white":"transparent",color:mode==="signup"?"#1e3a5f":"#999",boxShadow:mode==="signup"?"0 2px 10px rgba(0,0,0,0.08)":"none",transition:"all 0.2s"}}>ثبت‌نام</button>
          </div>
          {mode === "login" ? (
            <>
              <h2 style={{fontSize:"22px",fontWeight:900,color:"#1e3a5f",marginBottom:"6px"}}>ورود به حساب</h2>
              <p style={{color:"#666",marginBottom:"24px",fontSize:"14px",fontWeight:700}}>ایمیل و رمز عبور خود را وارد کنید</p>
              <form onSubmit={handleLogin}>
                <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>ایمیل</label><input type="email" dir="ltr" value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@company.com" className="input-field" autoFocus /></div>
                <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>رمز عبور</label><input type="password" dir="ltr" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" className="input-field" /></div>
                {error && <div className="animate-scale" style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700,border:"1px solid #fecaca"}}><span>⚠️ </span>{error}</div>}
                {success && <div className="animate-scale" style={{background:"#ecfdf5",color:"#059669",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700,border:"1px solid #a7f3d0"}}><span>✅ </span>{success}</div>}
                <button type="submit" disabled={loading} style={{width:"100%",padding:"14px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:900,fontFamily:"inherit",boxShadow:"0 4px 15px rgba(15,23,42,0.3)"}}>{loading?"در حال ورود...":"ورود به حساب"}</button>
              </form>
            </>
          ) : (
            <>
              <h2 style={{fontSize:"22px",fontWeight:900,color:"#1e3a5f",marginBottom:"6px"}}>ثبت‌نام</h2>
              <p style={{color:"#666",marginBottom:"24px",fontSize:"14px",fontWeight:700}}>حساب جدید بسازید</p>
              <form onSubmit={handleSignup}>
                <div style={{marginBottom:"14px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>نام و نام خانوادگی</label><input type="text" value={fullName} onChange={e=>setFullName(e.target.value)} placeholder="مثلاً: علی احمدی" className="input-field" autoFocus /></div>
                <div style={{marginBottom:"14px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>ایمیل</label><input type="email" dir="ltr" value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@company.com" className="input-field" /></div>
                <div style={{marginBottom:"14px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>رمز عبور</label><input type="password" dir="ltr" value={password} onChange={e=>setPassword(e.target.value)} placeholder="حداقل ۶ کاراکتر" className="input-field" /></div>
                <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"8px",fontSize:"13px",fontWeight:900,color:"#444"}}>نقش شما</label>
                  <div className="role-buttons" style={{display:"flex",gap:"10px"}}>
                    <button type="button" onClick={()=>setRole("shipper")} style={{flex:1,padding:"14px 10px",borderRadius:"12px",border:role==="shipper"?"2px solid #1e3a5f":"2px solid #e0e0e0",background:role==="shipper"?"#eff6ff":"white",fontSize:"14px",fontWeight:900,color:role==="shipper"?"#1e3a5f":"#888",cursor:"pointer"}}><div style={{fontSize:"22px",marginBottom:"2px"}}>📦</div>بارفرست</button>
                    <button type="button" onClick={()=>setRole("carrier")} style={{flex:1,padding:"14px 10px",borderRadius:"12px",border:role==="carrier"?"2px solid #0ea5e9":"2px solid #e0e0e0",background:role==="carrier"?"#ecfeff":"white",fontSize:"14px",fontWeight:900,color:role==="carrier"?"#0e7490":"#888",cursor:"pointer"}}><div style={{fontSize:"22px",marginBottom:"2px"}}>🚛</div>حمل‌کننده</button>
                  </div>
                </div>
                {error && <div className="animate-scale" style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700,border:"1px solid #fecaca"}}><span>⚠️ </span>{error}</div>}
                <button type="submit" disabled={loading} style={{width:"100%",padding:"14px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:900,fontFamily:"inherit",boxShadow:"0 4px 15px rgba(15,23,42,0.3)"}}>{loading?"در حال ثبت‌نام...":"ثبت‌نام"}</button>
              </form>
            </>
          )}
          <div style={{marginTop:"20px",padding:"14px",background:"white",borderRadius:"12px",border:"1px solid #eee",fontSize:"11px",color:"#999"}}>
            <p style={{fontWeight:900,color:"#666",marginBottom:"8px",fontSize:"12px"}}>🔑 تست:</p>
            {[{r:"📊",e:"admin@ikia.ir"},{r:"📦",e:"shipper@test.com"},{r:"🚛",e:"carrier@test.com"}].map((a,i)=>(
              <div key={i} style={{display:"flex",justifyContent:"space-between",padding:"5px 0",fontWeight:700}}><span>{a.r}</span><code dir="ltr" style={{background:"#f0f4ff",padding:"1px 6px",borderRadius:"4px",fontSize:"10px",color:"#1e3a5f",fontWeight:900}}>{a.e}</code></div>
            ))}
            <div style={{textAlign:"center",fontSize:"10px",color:"#ccc",marginTop:"4px"}}>رمز: Test1234!</div>
          </div>
        </div>
      </div>
    </div>
  );
}
