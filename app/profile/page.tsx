"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading } from "@/components/Shared";
export default function ProfilePage() {
  const supabase = getSupabase();
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({full_name:"",phone:"",company_name:""});
  const [stats, setStats] = useState({cargos:0,bookings:0,reviews:0,avgRating:0});
  useEffect(() => {
    const f = async () => {
      const { data: { user: u } } = await supabase.auth.getUser();
      if (!u) { router.push("/login"); return; }
      setUser(u);
      const { data: p } = await supabase.from("profiles").select("*").eq("id", u.id).single();
      setProfile(p);
      if (p) setForm({full_name:p.full_name||"",phone:p.phone||"",company_name:p.company_name||""});
      if (p?.role==="carrier") {
        const { count } = await supabase.from("bookings").select("*",{count:"exact",head:true}).eq("carrier_id",u.id);
        const { data: rv } = await supabase.from("reviews").select("rating").eq("reviewee_id",u.id);
        const r = rv||[];
        setStats({cargos:0,bookings:count||0,reviews:r.length,avgRating:r.length>0?Math.round((r.reduce((a:number,x:any)=>a+x.rating,0)/r.length)*10)/10:0});
      }
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const handleSave = async () => {
    setError(""); setSuccess(false); setSaving(true);
    if (!form.full_name.trim()) { setError("نام رو وارد کن"); setSaving(false); return; }
    const { error: e } = await supabase.from("profiles").update({full_name:form.full_name,phone:form.phone,company_name:form.company_name}).eq("id",user.id);
    if (e) setError("خطا: "+e.message); else { setSuccess(true); setTimeout(()=>setSuccess(false),3000); }
    setSaving(false);
  };
  const roleLabels: Record<string,string> = {admin:"ادمین",shipper:"بارفرست",carrier:"حمل‌کننده"};
  if (loading) return <Loading />;
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <div style={{maxWidth:"650px"}}>
        <div className="card animate-fade" style={{padding:"28px",marginBottom:"20px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",position:"relative",overflow:"hidden"}}>
          <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 30% 50%, rgba(6,182,212,0.15) 0%, transparent 60%)",pointerEvents:"none"}} />
          <div style={{position:"relative",zIndex:1,display:"flex",alignItems:"center",gap:"18px",flexWrap:"wrap"}}>
            <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"linear-gradient(135deg,var(--accent),#2E75B6)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"26px",fontWeight:900,border:"3px solid rgba(255,255,255,0.3)"}}>{form.full_name?.[0]||"؟"}</div>
            <div><h1 style={{fontSize:"20px",fontWeight:900,marginBottom:"4px"}}>{form.full_name||"کاربر"}</h1><div style={{display:"flex",gap:"8px",alignItems:"center",flexWrap:"wrap"}}><span className="badge" style={{background:"rgba(255,255,255,0.15)"}}>{roleLabels[profile?.role]||"کاربر"}</span><span style={{opacity:0.7,fontSize:"13px"}} dir="ltr">{user?.email}</span></div></div>
          </div>
        </div>
        <div className="card animate-fade-up" style={{padding:"28px",marginBottom:"20px"}}>
          <h2 style={{fontSize:"17px",fontWeight:900,color:"var(--text)",marginBottom:"20px",display:"flex",alignItems:"center",gap:"8px"}}><span style={{width:"28px",height:"28px",borderRadius:"8px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"14px"}}>✏️</span> ویرایش اطلاعات</h2>
          <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>نام *</label><input type="text" value={form.full_name} onChange={e=>setForm({...form,full_name:e.target.value})} className="input-field" /></div>
          <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>تلفن</label><input type="tel" dir="ltr" value={form.phone} onChange={e=>setForm({...form,phone:e.target.value})} placeholder="09123456789" className="input-field" /></div>
          <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>نام شرکت</label><input type="text" value={form.company_name} onChange={e=>setForm({...form,company_name:e.target.value})} className="input-field" /></div>
          {error && <div style={{background:"var(--bg3)",color:"var(--danger)",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700}}>⚠️ {error}</div>}
          {success && <div style={{background:"var(--bg3)",color:"var(--success)",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700}}>✅ ذخیره شد!</div>}
          <button onClick={handleSave} disabled={saving} className="btn-primary" style={{width:"100%",padding:"14px",fontSize:"15px"}}>{saving?"در حال ذخیره...":"💾 ذخیره تغییرات"}</button>
        </div>
        <div className="card animate-fade" style={{padding:"20px"}}>
          <h2 style={{fontSize:"16px",fontWeight:900,color:"var(--text)",marginBottom:"14px"}}>⚙️ تنظیمات</h2>
          <div style={{display:"flex",justifyContent:"space-between",padding:"12px 0",borderBottom:"1px solid var(--border)"}}><div><div style={{fontSize:"14px",fontWeight:900,color:"var(--text)"}}>ایمیل</div><div style={{fontSize:"12px",color:"var(--text3)"}} dir="ltr">{user?.email}</div></div><span className="badge" style={{background:"var(--bg3)",color:"var(--success)"}}>تأیید شده</span></div>
          <div style={{display:"flex",justifyContent:"space-between",padding:"12px 0"}}><div><div style={{fontSize:"14px",fontWeight:900,color:"var(--text)"}}>عضویت</div><div style={{fontSize:"12px",color:"var(--text3)"}}>{new Date(user?.created_at).toLocaleDateString("fa-IR")}</div></div></div>
        </div>
      </div>
    </DashboardLayout>
  );
}
