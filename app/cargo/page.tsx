"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading, EmptyState, PageHeader } from "@/components/Shared";
const CL: Record<string,string> = {general:"بار عمومی",construction:"مصالح ساختمانی",food:"مواد غذایی",agricultural:"کشاورزی",industrial:"صنعتی",fragile:"شکستنی",refrigerated:"یخچالی",machinery:"ماشین‌آلات"};
const VL: Record<string,string> = {truck_small:"کامیونت",truck_large:"کامیون",trailer:"تریلر",refrigerated:"یخچال‌دار",flatbed:"کفی",container:"کانتینر"};
export default function CargoListPage() {
  const supabase = getSupabase();
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [cargos, setCargos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState({origin:"",dest:"",type:""});
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      fetchCargos();
    }; f();
  }, []);
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
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  if (!profile) return <Loading />;
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <PageHeader title="🔍 بارهای موجود" subtitle="بارهای باز برای حمل" action={<Link href="/cargo/new" className="btn-primary" style={{padding:"10px 20px",fontSize:"13px"}}>+ ثبت بار</Link>} />
      <div className="card flex-wrap-mobile" style={{display:"flex",gap:"10px",padding:"16px 18px",marginBottom:"20px",alignItems:"end"}}>
        <div><label style={{display:"block",fontSize:"11px",color:"var(--text3)",marginBottom:"4px",fontWeight:900}}>مبدأ</label><select value={filter.origin} onChange={e=>setFilter({...filter,origin:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="تهران">تهران</option><option value="مشهد">مشهد</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
        <div><label style={{display:"block",fontSize:"11px",color:"var(--text3)",marginBottom:"4px",fontWeight:900}}>مقصد</label><select value={filter.dest} onChange={e=>setFilter({...filter,dest:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="مشهد">مشهد</option><option value="تهران">تهران</option><option value="اصفهان">اصفهان</option><option value="سمنان">سمنان</option></select></div>
        <div><label style={{display:"block",fontSize:"11px",color:"var(--text3)",marginBottom:"4px",fontWeight:900}}>نوع</label><select value={filter.type} onChange={e=>setFilter({...filter,type:e.target.value})} className="input-field" style={{padding:"10px 14px",fontSize:"14px"}}><option value="">همه</option><option value="general">عمومی</option><option value="construction">مصالح</option><option value="food">غذایی</option></select></div>
        <button onClick={fetchCargos} className="btn-primary" style={{padding:"10px 24px",fontSize:"14px"}}>جستجو</button>
      </div>
      <div style={{fontSize:"13px",color:"var(--text3)",fontWeight:700,marginBottom:"12px"}}>{cargos.length} بار موجود</div>
      {loading ? <Loading /> : cargos.length===0 ? <EmptyState icon="📭" title="باری نیست" description="اولین بار رو ثبت کن" actionText="+ ثبت بار" actionHref="/cargo/new" /> : (
        <div style={{display:"grid",gap:"10px"}}>{cargos.map((c,i)=>(
          <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
            <div className="card" style={{padding:"18px 20px",display:"flex",justifyContent:"space-between",alignItems:"center",cursor:"pointer"}}>
              <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                <div style={{width:"44px",height:"44px",borderRadius:"12px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px"}}>📦</div>
                <div><div style={{display:"flex",alignItems:"center",gap:"6px",marginBottom:"4px"}}><span style={{fontSize:"16px",fontWeight:900,color:"var(--text)"}}>{c.origin_city}</span><span style={{color:"var(--accent)",fontWeight:900}}>←</span><span style={{fontSize:"16px",fontWeight:900,color:"var(--text)"}}>{c.dest_city}</span></div><div style={{display:"flex",gap:"12px",fontSize:"12px",color:"var(--text3)",fontWeight:700}}><span>🚛 {VL[c.vehicle_type_needed]||c.vehicle_type_needed}</span>{c.weight_tons&&<span>⚖️ {c.weight_tons} تن</span>}<span>📅 {c.pickup_date}</span></div></div>
              </div>
              <div style={{textAlign:"left"}}><div style={{fontSize:"16px",fontWeight:900,color:"var(--accent)"}}>{formatPrice(c.price_suggestion)}</div><span className="badge" style={{background:"var(--bg3)",color:"var(--text)",marginTop:"4px"}}>{CL[c.cargo_type]||c.cargo_type}</span></div>
            </div>
          </Link>
        ))}</div>
      )}
    </DashboardLayout>
  );
}
