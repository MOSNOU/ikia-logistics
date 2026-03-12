"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
export default function NewCargoPage() {
  const router = useRouter();
  const supabase = getSupabase();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({origin_city:"تهران",dest_city:"مشهد",cargo_type:"general",cargo_description:"",weight_tons:"",vehicle_type_needed:"truck_large",pickup_date:"",price_suggestion:""});
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setError("");
    if (!form.pickup_date) { setError("تاریخ بارگیری رو وارد کن"); return; }
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً اول لاگین کنید"); setLoading(false); return; }
    const { error: dbError } = await supabase.from("cargo_posts").insert({shipper_id:user.id,origin_city:form.origin_city,dest_city:form.dest_city,cargo_type:form.cargo_type,cargo_description:form.cargo_description||null,weight_tons:form.weight_tons?parseFloat(form.weight_tons):null,vehicle_type_needed:form.vehicle_type_needed,pickup_date:form.pickup_date,price_suggestion:form.price_suggestion?parseInt(form.price_suggestion)*10:null,status:"open"});
    if (dbError) setError("خطا: "+dbError.message); else router.push("/cargo");
    setLoading(false);
  };
  const S: React.CSSProperties = {width:"100%",padding:"14px 16px",border:"1px solid #e0e0e0",borderRadius:"10px",fontSize:"15px",outline:"none",fontFamily:"inherit",background:"white",transition:"border 0.2s"};
  const L: React.CSSProperties = {display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"};
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <Link href="/shipper" style={{color:"#3C3B6E",textDecoration:"none",fontSize:"14px",fontWeight:"bold",display:"flex",alignItems:"center",gap:"4px"}}>→ بازگشت به داشبورد</Link>
      </nav>
      <main style={{maxWidth:"650px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{marginBottom:"28px"}}>
          <h1 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",margin:0,display:"flex",alignItems:"center",gap:"8px"}}><span style={{width:"40px",height:"40px",borderRadius:"12px",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"20px",color:"white"}}>📦</span> ثبت بار جدید</h1>
          <p style={{color:"#999",fontSize:"13px",marginTop:"6px"}}>اطلاعات بار رو وارد کن تا حمل‌کنندگان ببینن</p>
        </div>
        <form onSubmit={handleSubmit} style={{background:"white",padding:"28px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"1px solid #f0f0f0"}}><span style={{fontSize:"16px"}}>📍</span><span style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E"}}>مسیر حمل</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr auto 1fr",gap:"12px",marginBottom:"24px",alignItems:"end"}}>
            <div><label style={L}>شهر مبدأ</label><select value={form.origin_city} onChange={e=>setForm({...form,origin_city:e.target.value})} style={S}><option>تهران</option><option>مشهد</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
            <div style={{fontSize:"24px",color:"#2E75B6",paddingBottom:"14px"}}>←</div>
            <div><label style={L}>شهر مقصد</label><select value={form.dest_city} onChange={e=>setForm({...form,dest_city:e.target.value})} style={S}><option>مشهد</option><option>تهران</option><option>اصفهان</option><option>سمنان</option><option>شاهرود</option><option>نیشابور</option></select></div>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"1px solid #f0f0f0"}}><span style={{fontSize:"16px"}}>📋</span><span style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E"}}>مشخصات بار</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"20px"}}>
            <div><label style={L}>نوع بار</label><select value={form.cargo_type} onChange={e=>setForm({...form,cargo_type:e.target.value})} style={S}><option value="general">بار عمومی</option><option value="construction">مصالح ساختمانی</option><option value="food">مواد غذایی</option><option value="agricultural">کشاورزی</option><option value="industrial">کالای صنعتی</option><option value="fragile">شکستنی</option><option value="refrigerated">یخچالی</option><option value="machinery">ماشین‌آلات</option></select></div>
            <div><label style={L}>نوع خودرو</label><select value={form.vehicle_type_needed} onChange={e=>setForm({...form,vehicle_type_needed:e.target.value})} style={S}><option value="truck_small">کامیونت</option><option value="truck_large">کامیون</option><option value="trailer">تریلر</option><option value="refrigerated">یخچال‌دار</option><option value="flatbed">کفی</option><option value="container">کانتینر</option></select></div>
          </div>
          <div style={{marginBottom:"20px"}}><label style={L}>توضیحات بار</label><textarea value={form.cargo_description} onChange={e=>setForm({...form,cargo_description:e.target.value})} placeholder="مثلاً: ۵۰ پالت سیمان بسته‌بندی شده — نیاز به محافظت از رطوبت" style={{...S,minHeight:"90px",resize:"vertical"}} /></div>
          <div style={{marginBottom:"20px"}}><label style={L}>وزن (تن)</label><input type="number" value={form.weight_tons} onChange={e=>setForm({...form,weight_tons:e.target.value})} placeholder="مثلاً ۲۰" style={S} /></div>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"24px",paddingBottom:"16px",borderBottom:"1px solid #f0f0f0"}}><span style={{fontSize:"16px"}}>💰</span><span style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E"}}>زمان و قیمت</span></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"24px"}}>
            <div><label style={L}>تاریخ بارگیری *</label><input type="date" value={form.pickup_date} onChange={e=>setForm({...form,pickup_date:e.target.value})} style={S} /></div>
            <div><label style={L}>قیمت پیشنهادی (تومان)</label><input type="number" value={form.price_suggestion} onChange={e=>setForm({...form,price_suggestion:e.target.value})} placeholder="مثلاً ۱۵,۰۰۰,۰۰۰" dir="ltr" style={S} /></div>
          </div>
          {error && <div style={{background:"#fef2f2",color:"#dc2626",padding:"12px 16px",borderRadius:"10px",marginBottom:"20px",fontSize:"14px",border:"1px solid #fecaca",display:"flex",alignItems:"center",gap:"8px"}}><span>⚠️</span>{error}</div>}
          <button type="submit" disabled={loading} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",boxShadow:"0 4px 12px rgba(60,59,110,0.3)",cursor:"pointer"}}>{loading?"در حال ثبت...":"✅ ثبت بار"}</button>
        </form>
      </main>
    </div>
  );
}
