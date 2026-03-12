"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { Navbar, Footer, Loading } from "@/components/Shared";
export default function NewCargoPage() {
  const router = useRouter();
  const supabase = getSupabase();
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({origin_city:"تهران",dest_city:"مشهد",cargo_type:"general",cargo_description:"",weight_tons:"",vehicle_type_needed:"truck_large",pickup_date:"",price_suggestion:""});
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setError("");
    if (!form.pickup_date) { setError("تاریخ بارگیری رو وارد کن"); return; }
    setSubmitting(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً اول لاگین کنید"); setSubmitting(false); return; }
    const { error: dbError } = await supabase.from("cargo_posts").insert({shipper_id:user.id,origin_city:form.origin_city,dest_city:form.dest_city,cargo_type:form.cargo_type,cargo_description:form.cargo_description||null,weight_tons:form.weight_tons?parseFloat(form.weight_tons):null,vehicle_type_needed:form.vehicle_type_needed,pickup_date:form.pickup_date,price_suggestion:form.price_suggestion?parseInt(form.price_suggestion)*10:null,status:"open"});
    if (dbError) setError("خطا: "+dbError.message); else router.push("/cargo");
    setSubmitting(false);
  };
  if (loading) return <Loading />;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar role="shipper" name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{maxWidth:"680px",margin:"0 auto",padding:"32px 20px"}}>
        <div className="animate-fade" style={{marginBottom:"28px"}}>
          <Link href="/shipper" style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"#1e3a5f",fontSize:"13px",fontWeight:900,marginBottom:"16px"}}>→ بازگشت به داشبورد</Link>
          <h1 style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f",margin:0,display:"flex",alignItems:"center",gap:"10px"}}>
            <span style={{width:"44px",height:"44px",borderRadius:"12px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"20px",color:"white"}}>📦</span>
            ثبت بار جدید
          </h1>
          <p style={{color:"#666",fontSize:"13px",marginTop:"6px",fontWeight:700}}>اطلاعات بار رو وارد کن تا حمل‌کنندگان ببینن</p>
        </div>
        <form onSubmit={handleSubmit} className="animate-fade-up" style={{background:"white",padding:"32px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
          <div style={{display:"flex",alignItems:"center",gap:"10px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"2px solid #f0f4ff"}}><span style={{width:"32px",height:"32px",borderRadius:"8px",background:"#ecfeff",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px"}}>📍</span><span style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f"}}>مسیر حمل</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr auto 1fr",gap:"12px",marginBottom:"28px",alignItems:"end"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>شهر مبدأ</label><select value={form.origin_city} onChange={e=>setForm({...form,origin_city:e.target.value})} className="input-field"><option>تهران</option><option>مشهد</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
            <div style={{fontSize:"28px",color:"#06b6d4",paddingBottom:"14px",fontWeight:900}}>←</div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>شهر مقصد</label><select value={form.dest_city} onChange={e=>setForm({...form,dest_city:e.target.value})} className="input-field"><option>مشهد</option><option>تهران</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:"10px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"2px solid #f0f4ff"}}><span style={{width:"32px",height:"32px",borderRadius:"8px",background:"#fffbeb",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px"}}>📋</span><span style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f"}}>مشخصات بار</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"20px"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>نوع بار</label><select value={form.cargo_type} onChange={e=>setForm({...form,cargo_type:e.target.value})} className="input-field"><option value="general">بار عمومی</option><option value="construction">مصالح ساختمانی</option><option value="food">مواد غذایی</option><option value="agricultural">کشاورزی</option><option value="industrial">کالای صنعتی</option><option value="fragile">شکستنی</option><option value="refrigerated">یخچالی</option><option value="machinery">ماشین‌آلات</option></select></div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>نوع خودرو</label><select value={form.vehicle_type_needed} onChange={e=>setForm({...form,vehicle_type_needed:e.target.value})} className="input-field"><option value="truck_small">کامیونت</option><option value="truck_large">کامیون</option><option value="trailer">تریلر</option><option value="refrigerated">یخچال‌دار</option><option value="flatbed">کفی</option><option value="container">کانتینر</option></select></div>
          </div>
          <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>توضیحات بار</label><textarea value={form.cargo_description} onChange={e=>setForm({...form,cargo_description:e.target.value})} placeholder="مثلاً: ۵۰ پالت سیمان بسته‌بندی شده — نیاز به محافظت از رطوبت" className="input-field" style={{minHeight:"90px",resize:"vertical"}} /></div>
          <div style={{marginBottom:"24px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>وزن (تن)</label><input type="number" value={form.weight_tons} onChange={e=>setForm({...form,weight_tons:e.target.value})} placeholder="مثلاً ۲۰" className="input-field" /></div>
          <div style={{display:"flex",alignItems:"center",gap:"10px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"2px solid #f0f4ff"}}><span style={{width:"32px",height:"32px",borderRadius:"8px",background:"#ecfdf5",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px"}}>💰</span><span style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f"}}>زمان و قیمت</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"28px"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>تاریخ بارگیری *</label><input type="date" value={form.pickup_date} onChange={e=>setForm({...form,pickup_date:e.target.value})} className="input-field" /></div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>قیمت پیشنهادی (تومان)</label><input type="number" value={form.price_suggestion} onChange={e=>setForm({...form,price_suggestion:e.target.value})} placeholder="مثلاً ۱۵,۰۰۰,۰۰۰" dir="ltr" className="input-field" /></div>
          </div>
          {error && <div className="animate-scale" style={{background:"#fef2f2",color:"#dc2626",padding:"14px 16px",borderRadius:"12px",marginBottom:"20px",fontSize:"14px",fontWeight:700,border:"1px solid #fecaca",display:"flex",alignItems:"center",gap:"8px"}}><span>⚠️</span>{error}</div>}
          <button type="submit" disabled={submitting} style={{width:"100%",padding:"18px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",border:"none",borderRadius:"14px",fontSize:"17px",fontWeight:900,fontFamily:"inherit",boxShadow:"0 4px 15px rgba(15,23,42,0.3)",cursor:"pointer"}}>{submitting?"در حال ثبت...":"✅ ثبت بار"}</button>
        </form>
      </main>
      <Footer />
    </div>
  );
}
