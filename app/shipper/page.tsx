"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/Sidebar";
import { Footer, Loading, EmptyState, StatCard, PageHeader } from "@/components/Shared";
export default function ShipperDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [cargos, setCargos] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      const { data: c } = await supabase.from("cargo_posts").select("*").eq("shipper_id", user.id).order("created_at",{ascending:false});
      setCargos(c || []);
      const ids = (c||[]).map((x:any)=>x.id);
      if (ids.length > 0) {
        const { data: b } = await supabase.from("bookings").select("*, cargo_posts(*)").in("cargo_post_id", ids).order("created_at",{ascending:false});
        setBookings(b || []);
      }
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const SL: Record<string,string> = {pending:"در انتظار",confirmed:"تأیید شده",in_transit:"در مسیر",delivered:"تحویل — تأیید کن!",completed:"تکمیل",rejected:"رد شده"};
  const SC: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669",rejected:"#ef4444"};
  const needAction = bookings.filter(b => b.status === "pending" || b.status === "delivered");
  const openCargos = cargos.filter(c => c.status === "open");
  const activeCargos = cargos.filter(c => c.status === "matched" || c.status === "in_transit");
  if (loading) return <Loading />;
  return (
    <DashboardLayout role="shipper" name={profile?.full_name} onSignOut={handleSignOut}>
      <PageHeader title="داشبورد بارفرست" subtitle="مدیریت بارها و رزروها" action={<Link href="/cargo/new" className="btn-primary" style={{display:"flex",alignItems:"center",gap:"6px",padding:"12px 24px",fontSize:"14px"}}><span style={{fontSize:"18px"}}>+</span> ثبت بار</Link>} />
      <div className="stat-grid" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"14px",marginBottom:"24px"}}>
        <StatCard label="بارهای باز" value={openCargos.length} icon="📦" color="var(--accent)" bg="var(--bg3)" delay={0} />
        <StatCard label="در حال حمل" value={activeCargos.length} icon="🚛" color="#8b5cf6" bg="var(--bg3)" delay={100} />
        <StatCard label="تکمیل شده" value={cargos.filter(c=>c.status==="delivered").length} icon="✅" color="var(--success)" bg="var(--bg3)" delay={200} />
        <StatCard label="نیاز به اقدام" value={needAction.length} icon="⚡" color="var(--warning)" bg={needAction.length>0?"#fffbeb":"var(--bg3)"} delay={300} />
      </div>
      {needAction.length > 0 && (
        <div style={{marginBottom:"24px"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"12px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"var(--warning)",animation:"pulse 2s infinite"}} /><h2 style={{fontSize:"16px",fontWeight:900,color:"var(--warning)",margin:0}}>نیاز به اقدام ({needAction.length})</h2></div>
          {needAction.map((b,i) => (
            <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
              <div className="card" style={{padding:"16px 18px",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",border:b.status==="delivered"?"2px solid var(--success)":"2px solid var(--warning)",cursor:"pointer"}}>
                <div><div style={{fontWeight:900,color:"var(--text)",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div><div style={{fontSize:"13px",color:"var(--text3)",marginTop:"4px"}}>{formatPrice(b.proposed_price)}</div></div>
                <span className="badge" style={{background:SC[b.status],color:"white"}}>{SL[b.status]}</span>
              </div>
            </Link>
          ))}
        </div>
      )}
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}><h2 style={{fontSize:"16px",fontWeight:900,color:"var(--text)",margin:0}}>بارهای من</h2><Link href="/cargo" style={{fontSize:"13px",color:"var(--accent)",fontWeight:900}}>مشاهده همه ←</Link></div>
      {cargos.length === 0 ? <EmptyState icon="📦" title="هنوز باری نداری" description="اولین بارت رو ثبت کن" actionText="+ ثبت بار" actionHref="/cargo/new" /> : (
        <div style={{display:"grid",gap:"10px"}}>{cargos.slice(0,5).map((c,i) => (
          <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
            <div className="card" style={{padding:"16px 18px",display:"flex",justifyContent:"space-between",alignItems:"center",cursor:"pointer"}}>
              <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                <div style={{width:"40px",height:"40px",borderRadius:"10px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{c.status==="open"?"📦":"🚛"}</div>
                <div><div style={{fontWeight:900,color:"var(--text)",fontSize:"15px"}}>{c.origin_city} ← {c.dest_city}</div><div style={{fontSize:"12px",color:"var(--text3)",marginTop:"2px"}}>{c.cargo_type} • {c.pickup_date}</div></div>
              </div>
              <div style={{fontWeight:900,color:"var(--accent)",fontSize:"14px"}}>{formatPrice(c.price_suggestion)}</div>
            </div>
          </Link>
        ))}</div>
      )}
      {bookings.length > 0 && (
        <div style={{marginTop:"24px"}}>
          <h2 style={{fontSize:"16px",fontWeight:900,color:"var(--text)",marginBottom:"12px"}}>تاریخچه رزروها</h2>
          <div className="card" style={{overflow:"hidden"}}>
            <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}>
              <thead><tr style={{background:"var(--bg3)"}}><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>مسیر</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>قیمت</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>وضعیت</th></tr></thead>
              <tbody>{bookings.map(b => (
                <tr key={b.id} style={{borderBottom:"1px solid var(--border)",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                  <td style={{padding:"10px 14px",fontWeight:900,color:"var(--text)"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                  <td style={{padding:"10px 14px",color:"var(--text2)"}}>{formatPrice(b.proposed_price)}</td>
                  <td style={{padding:"10px 14px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}
