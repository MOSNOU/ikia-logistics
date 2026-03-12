"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { Navbar, Footer, Loading, EmptyState } from "@/components/Shared";
const CL: Record<string,string> = {general:"بار عمومی",construction:"مصالح ساختمانی",food:"مواد غذایی",agricultural:"کشاورزی",industrial:"صنعتی",fragile:"شکستنی",refrigerated:"یخچالی",machinery:"ماشین‌آلات"};
const VL: Record<string,string> = {truck_small:"کامیونت",truck_large:"کامیون",trailer:"تریلر",refrigerated:"یخچال‌دار",flatbed:"کفی",container:"کانتینر"};
export default function CargoListPage() {
  const supabase = getSupabase();
  const [cargos, setCargos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState({origin:"",dest:"",type:""});
  useEffect(() => { fetchCargos(); }, []);
  const fetchCargos = async () => {
    setLoading(true);
    let q = supabase.from("cargo_posts").select("*").eq("status","open").order("created_at",{ascending:false});
    if (filter.origin) q = q.eq("origin_city", filter.origin);
    if (filter.dest) q = q.eq("dest_city", filter.dest);
    if (filter.type) q = q.eq("cargo_type", filter.type);
    const { data } = await q;
    setCargos(data || []);
    setLoading(false);
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar />
      <main style={{maxWidth:"950px",margin:"0 auto",padding:"32px 20px"}}>
        <div className="animate-fade" style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"24px",flexWrap:"wrap",gap:"12px"}}>
          <div><h1 style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f",margin:0}}>🔍 بارهای موجود</h1><p style={{color:"#666",fontSize:"13px",marginTop:"4px",fontWeight:700}}>بارهای باز برای حمل در مسیر تهران-مشهد</p></div>
          <div style={{display:"flex",gap:"8px"}}>
            <Link href="/shipper" style={{padding:"10px 18px",borderRadius:"10px",fontSize:"13px",fontWeight:900,color:"#1e3a5f",border:"2px solid #e0e0e0",background:"white"}}>داشبورد</Link>
            <Link href="/cargo/new" style={{padding:"10px 18px",borderRadius:"10px",fontSize:"13px",fontWeight:900,color:"white",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",boxShadow:"0 2px 8px rgba(15,23,42,0.2)"}}>+ ثبت بار</Link>
          </div>
        </div>
        <div className="animate-fade flex-wrap-mobile" style={{display:"flex",gap:"10px",marginBottom:"24px",background:"white",padding:"18px 20px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.04)",alignItems:"end"}}>
          <div><label style={{display:"block",fontSize:"11px",color:"#888",marginBottom:"4px",fontWeight:900}}>مبدأ</label><select value={filter.origin} onChange={e=>setFilter({...filter,origin:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="تهران">تهران</option><option value="مشهد">مشهد</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
          <div><label style={{display:"block",fontSize:"11px",color:"#888",marginBottom:"4px",fontWeight:900}}>مقصد</label><select value={filter.dest} onChange={e=>setFilter({...filter,dest:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="مشهد">مشهد</option><option value="تهران">تهران</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
          <div><label style={{display:"block",fontSize:"11px",color:"#888",marginBottom:"4px",fontWeight:900}}>نوع</label><select value={filter.type} onChange={e=>setFilter({...filter,type:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="general">عمومی</option><option value="construction">مصالح</option><option value="food">غذایی</option><option value="industrial">صنعتی</option></select></div>
          <button onClick={fetchCargos} style={{padding:"10px 28px",background:"linear-gradient(135deg,#06b6d4,#0ea5e9)",color:"white",border:"none",borderRadius:"10px",fontSize:"14px",fontWeight:900,fontFamily:"inherit",cursor:"pointer",boxShadow:"0 2px 8px rgba(6,182,212,0.3)"}}>جستجو</button>
        </div>
        <div className="animate-fade" style={{marginBottom:"12px",fontSize:"13px",color:"#888",fontWeight:700}}>{cargos.length} بار موجود</div>
        {loading ? <Loading /> : cargos.length===0 ? <EmptyState icon="📭" title="باری ثبت نشده" description="اولین بار رو ثبت کن!" actionText="📦 ثبت بار" actionHref="/cargo/new" /> : (
          <div style={{display:"grid",gap:"12px"}}>{cargos.map((c,i)=>(
            <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
              <div className="card-hover animate-fade" style={{background:"white",padding:"22px 24px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.04)",display:"flex",justifyContent:"space-between",alignItems:"center",animationDelay:`${i*60}ms`}}>
                <div style={{display:"flex",alignItems:"center",gap:"14px"}}>
                  <div style={{width:"50px",height:"50px",borderRadius:"14px",background:"linear-gradient(135deg,#ecfeff,#cffafe)",border:"2px solid #06b6d422",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"24px"}}>📦</div>
                  <div>
                    <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"6px"}}><span style={{fontSize:"17px",fontWeight:900,color:"#1e3a5f"}}>{c.origin_city}</span><span style={{color:"#06b6d4",fontWeight:900}}>←</span><span style={{fontSize:"17px",fontWeight:900,color:"#1e3a5f"}}>{c.dest_city}</span></div>
                    <div style={{display:"flex",gap:"14px",fontSize:"12px",color:"#888",fontWeight:700}}><span>🚛 {VL[c.vehicle_type_needed]||c.vehicle_type_needed}</span>{c.weight_tons&&<span>⚖️ {c.weight_tons} تن</span>}<span>📅 {c.pickup_date}</span></div>
                  </div>
                </div>
                <div style={{textAlign:"left"}}>
                  <div style={{fontSize:"17px",fontWeight:900,color:"#0ea5e9"}}>{formatPrice(c.price_suggestion)}</div>
                  <span className="badge" style={{background:"#f0f4ff",color:"#1e3a5f",marginTop:"6px",fontWeight:900}}>{CL[c.cargo_type]||c.cargo_type}</span>
                </div>
              </div>
            </Link>
          ))}</div>
        )}
      </main>
      <Footer />
    </div>
  );
}
