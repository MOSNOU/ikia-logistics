"use client";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading } from "@/components/Shared";
export default function NewCargoPage() {
  const router = useRouter();
  const supabase = getSupabase();
  const [profile, setProfile] = useState<any>(null);
  const [pageLoading, setPageLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({origin_city:"تهران",dest_city:"مشهد",cargo_type:"general",cargo_description:"",weight_tons:"",vehicle_type_needed:"truck_large",pickup_date:"",price_suggestion:""});
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p); setPageLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setError("");
    if (!form.pickup_date) { setError("تاریخ بارگیری رو وارد کن"); return; }
    setSubmitting(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً لاگین کنید"); setSubmitting(false); return; }
    const { error: dbError } = await supabase.from("cargo_posts").insert({shipper_id:user.id,origin_city:form.origin_city,dest_city:form.dest_city,cargo_type:form.cargo_type,cargo_description:form.cargo_description||null,weight_tons:form.weight_tons?parseFloat(form.weight_tons):null,vehicle_type_needed:form.vehicle_type_needed,pickup_date:form.pickup_date,price_suggestion:form.price_suggestion?parseInt(form.price_suggestion)*10:null,status:"open"});
    if (dbError) setError("خطا: "+dbError.message); else router.push("/cargo");
    setSubmitting(false);
  };
  if (pageLoading) return <Loading />;
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <div style={{maxWidth:"650px"}}>
        <Link href="/shipper" style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"var(--accent)",fontSize:"13px",fontWeight:900,marginBottom:"16px"}}>→ بازگشت</Link>
        <h1 style={{fontSize:"22px",fontWeight:900,color:"var(--text)",marginBottom:"6px",display:"flex",alignItems:"center",gap:"10px"}}><span style={{width:"40px",height:"40px",borderRadius:"12px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"20px"}}>📦</span> ثبت بار جدید</h1>
        <p style={{color:"var(--text3)",fontSize:"13px",marginBottom:"24px",fontWeight:700}}>اطلاعات بار رو وارد کن</p>
        <form onSubmit={handleSubmit} className="card" style={{padding:"28px"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"20px",paddingBottom:"14px",borderBottom:"2px solid var(--border)"}}><span>📍</span><span style={{fontWeight:900,color:"var(--text)"}}>مسیر حمل</span></div>
          <div className="form-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"14px",marginBottom:"24px"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>شهر مبدأ</label><select value={form.origin_city} onChange={e=>setForm({...form,origin_city:e.target.value})} className="input-field"><option>تهران</option><option>مشهد</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>شهر مقصد</label><select value={form.dest_city} onChange={e=>setForm({...form,dest_city:e.target.value})} className="input-field"><option>مشهد</option><option>تهران</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"20px",paddingBottom:"14px",borderBottom:"2px solid var(--border)"}}><span>📋</span><span style={{fontWeight:900,color:"var(--text)"}}>مشخصات بار</span></div>
          <div className="form-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"14px",marginBottom:"16px"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>نوع بار</label><select value={form.cargo_type} onChange={e=>setForm({...form,cargo_type:e.target.value})} className="input-field"><option value="general">بار عمومی</option><option value="construction">مصالح ساختمانی</option><option value="food">مواد غذایی</option><option value="agricultural">کشاورزی</option><option value="industrial">صنعتی</option><option value="fragile">شکستنی</option><option value="refrigerated">یخچالی</option><option value="machinery">ماشین‌آلات</option></select></div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>نوع خودرو</label><select value={form.vehicle_type_needed} onChange={e=>setForm({...form,vehicle_type_needed:e.target.value})} className="input-field"><option value="truck_small">کامیونت</option><option value="truck_large">کامیون</option><option value="trailer">تریلر</option><option value="refrigerated">یخچال‌دار</option><option value="flatbed">کفی</option><option value="container">کانتینر</option></select></div>
          </div>
          <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>توضیحات</label><textarea value={form.cargo_description} onChange={e=>setForm({...form,cargo_description:e.target.value})} placeholder="مثلاً: ۵۰ پالت سیمان" className="input-field" style={{minHeight:"80px"}} /></div>
          <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>وزن (تن)</label><input type="number" value={form.weight_tons} onChange={e=>setForm({...form,weight_tons:e.target.value})} placeholder="۲۰" className="input-field" /></div>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"20px",paddingBottom:"14px",borderBottom:"2px solid var(--border)"}}><span>💰</span><span style={{fontWeight:900,color:"var(--text)"}}>زمان و قیمت</span></div>
          <div className="form-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"14px",marginBottom:"24px"}}>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>تاریخ بارگیری *</label><input type="date" value={form.pickup_date} onChange={e=>setForm({...form,pickup_date:e.target.value})} className="input-field" /></div>
            <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>قیمت (تومان)</label><input type="number" value={form.price_suggestion} onChange={e=>setForm({...form,price_suggestion:e.target.value})} placeholder="۱۵۰۰۰۰۰۰" dir="ltr" className="input-field" /></div>
          </div>
          {error && <div className="animate-scale" style={{background:"var(--bg3)",color:"var(--danger)",padding:"12px",borderRadius:"10px",marginBottom:"16px",fontSize:"14px",fontWeight:700}}> ⚠️ {error}</div>}
          <button type="submit" disabled={submitting} className="btn-primary" style={{width:"100%",padding:"16px",fontSize:"16px"}}>{submitting?"در حال ثبت...":"✅ ثبت بار"}</button>
        </form>
      </div>
    </DashboardLayout>
  );
}
