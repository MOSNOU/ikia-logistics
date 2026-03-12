"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
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
  const S: React.CSSProperties = {padding:"10px 14px",border:"1px solid #e0e0e0",borderRadius:"8px",fontSize:"14px",background:"white",outline:"none",fontFamily:"inherit"};
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"8px"}}><Link href="/shipper" style={{padding:"8px 16px",borderRadius:"8px",fontSize:"13px",color:"#3C3B6E",border:"1px solid #e0e0e0",background:"white",textDecoration:"none",fontWeight:"bold"}}>داشبورد</Link><Link href="/cargo/new" style={{padding:"8px 16px",borderRadius:"8px",fontSize:"13px",color:"white",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",textDecoration:"none",fontWeight:"bold"}}>+ ثبت بار</Link></div>
      </nav>
      <main style={{maxWidth:"900px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{marginBottom:"24px"}}><h1 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>🔍 بارهای موجود</h1><p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>بارهای باز برای حمل در مسیر تهران-مشهد</p></div>
        <div style={{display:"flex",gap:"10px",marginBottom:"24px",flexWrap:"wrap",background:"white",padding:"16px 20px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",alignItems:"end"}}>
          <div><label style={{display:"block",fontSize:"11px",color:"#999",marginBottom:"4px",fontWeight:"bold"}}>مبدأ</label><select value={filter.origin} onChange={e=>setFilter({...filter,origin:e.target.value})} style={S}><option value="">همه</option><option value="تهران">تهران</option><option value="مشهد">مشهد</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
          <div><label style={{display:"block",fontSize:"11px",color:"#999",marginBottom:"4px",fontWeight:"bold"}}>مقصد</label><select value={filter.dest} onChange={e=>setFilter({...filter,dest:e.target.value})} style={S}><option value="">همه</option><option value="مشهد">مشهد</option><option value="تهران">تهران</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
          <div><label style={{display:"block",fontSize:"11px",color:"#999",marginBottom:"4px",fontWeight:"bold"}}>نوع</label><select value={filter.type} onChange={e=>setFilter({...filter,type:e.target.value})} style={S}><option value="">همه</option><option value="general">عمومی</option><option value="construction">مصالح</option><option value="food">غذایی</option><option value="industrial">صنعتی</option></select></div>
          <button onClick={fetchCargos} style={{padding:"10px 24px",background:"linear-gradient(135deg,#2E75B6,#60a5fa)",color:"white",border:"none",borderRadius:"8px",fontSize:"14px",fontFamily:"inherit",fontWeight:"bold",cursor:"pointer",boxShadow:"0 2px 8px rgba(46,117,182,0.3)"}}>جستجو</button>
        </div>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"16px"}}><span style={{fontSize:"13px",color:"#999"}}>{cargos.length} بار موجود</span></div>
        {loading ? <div style={{textAlign:"center",padding:"60px"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #3C3B6E",borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style></div> : cargos.length===0 ? (
          <div style={{background:"white",borderRadius:"16px",padding:"60px 20px",textAlign:"center",border:"2px dashed #e0e0e0"}}>
            <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"#eff6ff",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"28px"}}>📭</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>باری ثبت نشده</h3>
            <p style={{color:"#999",fontSize:"14px",marginBottom:"20px"}}>اولین بار رو ثبت کن!</p>
            <Link href="/cargo/new" style={{display:"inline-block",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",color:"white",padding:"12px 28px",borderRadius:"10px",fontWeight:"bold",textDecoration:"none"}}>📦 ثبت بار</Link>
          </div>
        ) : (
          <div style={{display:"grid",gap:"12px"}}>{cargos.map(c=>(
            <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
              <div style={{background:"white",padding:"20px 24px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",display:"flex",justifyContent:"space-between",alignItems:"center",cursor:"pointer",transition:"box-shadow 0.2s"}}>
                <div style={{display:"flex",alignItems:"center",gap:"14px"}}>
                  <div style={{width:"48px",height:"48px",borderRadius:"12px",background:"linear-gradient(135deg,#eff6ff,#dbeafe)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px"}}>📦</div>
                  <div>
                    <div style={{display:"flex",alignItems:"center",gap:"6px",marginBottom:"4px"}}><span style={{fontSize:"16px",fontWeight:"bold",color:"#3C3B6E"}}>{c.origin_city}</span><span style={{color:"#2E75B6",fontSize:"14px"}}>←</span><span style={{fontSize:"16px",fontWeight:"bold",color:"#3C3B6E"}}>{c.dest_city}</span></div>
                    <div style={{display:"flex",gap:"12px",fontSize:"12px",color:"#999"}}><span>🚛 {VL[c.vehicle_type_needed]||c.vehicle_type_needed}</span>{c.weight_tons&&<span>⚖️ {c.weight_tons} تن</span>}<span>📅 {c.pickup_date}</span></div>
                  </div>
                </div>
                <div style={{textAlign:"left"}}>
                  <div style={{fontSize:"16px",fontWeight:"bold",color:"#2E75B6"}}>{formatPrice(c.price_suggestion)}</div>
                  <span style={{background:"#e8f0fe",color:"#3C3B6E",padding:"3px 12px",borderRadius:"20px",fontSize:"11px",fontWeight:"bold",marginTop:"4px",display:"inline-block"}}>{CL[c.cargo_type]||c.cargo_type}</span>
                </div>
              </div>
            </Link>
          ))}</div>
        )}
      </main>
    </div>
  );
}
