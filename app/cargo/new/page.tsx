"use client";
export const dynamic = "force-dynamic";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
export default function NewCargoPage() {
  const router = useRouter();
  const supabase = getSupabase();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({ origin_city:"تهران", dest_city:"مشهد", cargo_type:"general", cargo_description:"", weight_tons:"", vehicle_type_needed:"truck_large", pickup_date:"", price_suggestion:"" });
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setError("");
    if (!form.pickup_date) { setError("تاریخ بارگیری رو وارد کن"); return; }
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً اول لاگین کنید"); setLoading(false); return; }
    const { error: dbError } = await supabase.from("cargo_posts").insert({ shipper_id: user.id, origin_city: form.origin_city, dest_city: form.dest_city, cargo_type: form.cargo_type, cargo_description: form.cargo_description || null, weight_tons: form.weight_tons ? parseFloat(form.weight_tons) : null, vehicle_type_needed: form.vehicle_type_needed, pickup_date: form.pickup_date, price_suggestion: form.price_suggestion ? parseInt(form.price_suggestion) * 10 : null, status: "open" });
    if (dbError) setError("خطا: " + dbError.message); else router.push("/cargo");
    setLoading(false);
  };
  const S = {width:"100%",padding:"12px",border:"1px solid #ddd",borderRadius:"8px",fontSize:"15px"};
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between"}}><Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link><Link href="/shipper" style={{color:"#1B3A5C",textDecoration:"none"}}>← بازگشت</Link></nav>
      <main style={{maxWidth:"600px",margin:"0 auto",padding:"32px 16px"}}>
        <h1 style={{fontSize:"24px",color:"#1B3A5C",marginBottom:"24px"}}>📦 ثبت بار جدید</h1>
        <form onSubmit={handleSubmit} style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"16px"}}>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>شهر مبدأ</label><select value={form.origin_city} onChange={e=>setForm({...form,origin_city:e.target.value})} style={S}><option>تهران</option><option>مشهد</option><option>اصفهان</option><option>سمنان</option></select></div>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>شهر مقصد</label><select value={form.dest_city} onChange={e=>setForm({...form,dest_city:e.target.value})} style={S}><option>مشهد</option><option>تهران</option><option>اصفهان</option><option>سمنان</option></select></div>
          </div>
          <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>نوع بار</label><select value={form.cargo_type} onChange={e=>setForm({...form,cargo_type:e.target.value})} style={S}><option value="general">بار عمومی</option><option value="construction">مصالح ساختمانی</option><option value="food">مواد غذایی</option><option value="industrial">کالای صنعتی</option></select></div>
          <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>توضیحات</label><textarea value={form.cargo_description} onChange={e=>setForm({...form,cargo_description:e.target.value})} placeholder="مثلاً: ۵۰ پالت سیمان" style={{...S,minHeight:"80px"}} /></div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"16px"}}>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>وزن (تن)</label><input type="number" value={form.weight_tons} onChange={e=>setForm({...form,weight_tons:e.target.value})} placeholder="۲۰" style={S} /></div>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>نوع خودرو</label><select value={form.vehicle_type_needed} onChange={e=>setForm({...form,vehicle_type_needed:e.target.value})} style={S}><option value="truck_small">کامیونت</option><option value="truck_large">کامیون</option><option value="trailer">تریلر</option><option value="refrigerated">یخچال‌دار</option></select></div>
          </div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"16px"}}>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>تاریخ بارگیری *</label><input type="date" value={form.pickup_date} onChange={e=>setForm({...form,pickup_date:e.target.value})} style={S} /></div>
            <div><label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>قیمت (تومان)</label><input type="number" value={form.price_suggestion} onChange={e=>setForm({...form,price_suggestion:e.target.value})} placeholder="۱۵۰۰۰۰۰۰" style={{...S,direction:"ltr"}} /></div>
          </div>
          {error && <div style={{background:"#fee",color:"#c00",padding:"10px",borderRadius:"8px",marginBottom:"16px",fontSize:"14px"}}>{error}</div>}
          <button type="submit" disabled={loading} style={{width:"100%",padding:"14px",background:"#1B3A5C",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer"}}>{loading ? "در حال ثبت..." : "✅ ثبت بار"}</button>
        </form>
      </main>
    </div>
  );
}
