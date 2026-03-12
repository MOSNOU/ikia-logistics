"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Navbar, Footer, Loading, EmptyState, StatCard, PageHeader } from "@/components/Shared";
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
  const SL: Record<string,string> = {pending:"در انتظار تأیید",confirmed:"تأیید شده",in_transit:"در مسیر",delivered:"تحویل شده — تأیید کن!",completed:"تکمیل شده",rejected:"رد شده"};
  const SC: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669",rejected:"#ef4444"};
  const needAction = bookings.filter(b => b.status === "pending" || b.status === "delivered");
  const openCargos = cargos.filter(c => c.status === "open");
  const activeCargos = cargos.filter(c => c.status === "matched" || c.status === "in_transit");
  const doneCargos = cargos.filter(c => c.status === "delivered" || c.status === "cancelled");
  if (loading) return <Loading />;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar role="shipper" name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{maxWidth:"1000px",margin:"0 auto",padding:"32px 20px"}}>
        <PageHeader title="داشبورد بارفرست" subtitle="مدیریت بارها و رزروها" action={<Link href="/cargo/new" className="btn-primary" style={{display:"flex",alignItems:"center",gap:"6px",padding:"12px 24px",fontSize:"14px"}}><span style={{fontSize:"18px"}}>+</span> ثبت بار جدید</Link>} />
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          <StatCard label="بارهای باز" value={openCargos.length} icon="📦" color="#3b82f6" bg="#eff6ff" delay={0} />
          <StatCard label="در حال حمل" value={activeCargos.length} icon="🚛" color="#8b5cf6" bg="#f5f3ff" delay={100} />
          <StatCard label="تکمیل شده" value={doneCargos.length} icon="✅" color="#059669" bg="#ecfdf5" delay={200} />
          <StatCard label="نیاز به اقدام" value={needAction.length} icon="⚡" color="#f59e0b" bg={needAction.length>0?"#fffbeb":"#f9fafb"} delay={300} />
        </div>
        {needAction.length > 0 && (
          <div className="animate-fade" style={{marginBottom:"28px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"14px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"#f59e0b",display:"inline-block",animation:"pulse 2s infinite"}} /><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#b45309",margin:0}}>نیاز به اقدام شما ({needAction.length})</h2></div>
            {needAction.map((b,i) => (
              <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                <div className="card-hover animate-fade" style={{background:"white",padding:"18px 20px",borderRadius:"14px",border: b.status==="delivered" ? "2px solid #10b981" : "2px solid #fbbf24",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",animationDelay:`${i*80}ms`}}>
                  <div><div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div><div style={{fontSize:"13px",color:"#888",marginTop:"4px"}}>💰 {formatPrice(b.proposed_price)}</div></div>
                  <div style={{textAlign:"left"}}><span className="badge" style={{background:SC[b.status],color:"white"}}>{SL[b.status]}</span></div>
                </div>
              </Link>
            ))}
          </div>
        )}
        <div style={{marginBottom:"28px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"14px"}}><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>بارهای من</h2><Link href="/cargo" style={{fontSize:"13px",color:"#2E75B6",fontWeight:"bold"}}>مشاهده همه ←</Link></div>
          {cargos.length === 0 ? <EmptyState icon="📦" title="هنوز باری ثبت نکردی" description="اولین بارت رو ثبت کن و حمل‌کننده پیدا کن" actionText="+ ثبت اولین بار" actionHref="/cargo/new" /> : (
            <div style={{display:"grid",gap:"10px"}}>{cargos.slice(0,5).map((c,i) => (
              <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
                <div className="card-hover animate-fade" style={{background:"white",padding:"16px 20px",borderRadius:"12px",border:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 1px 4px rgba(0,0,0,0.03)",animationDelay:`${i*60}ms`}}>
                  <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                    <div style={{width:"40px",height:"40px",borderRadius:"10px",background:c.status==="open"?"#eff6ff":"#f5f3ff",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{c.status==="open"?"📦":"🚛"}</div>
                    <div><div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{c.origin_city} ← {c.dest_city}</div><div style={{fontSize:"12px",color:"#999",marginTop:"2px"}}>{c.cargo_type} • {c.pickup_date}</div></div>
                  </div>
                  <div style={{fontWeight:"bold",color:"#2E75B6",fontSize:"14px"}}>{formatPrice(c.price_suggestion)}</div>
                </div>
              </Link>
            ))}</div>
          )}
        </div>
        {bookings.length > 0 && (
          <div className="animate-fade">
            <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"14px"}}>تاریخچه رزروها</h2>
            <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"14px"}}>
                <thead><tr style={{background:"#f8fafc",borderBottom:"1px solid #eee"}}><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>مسیر</th><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>قیمت</th><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>وضعیت</th></tr></thead>
                <tbody>{bookings.map(b => (
                  <tr key={b.id} style={{borderBottom:"1px solid #f5f5f5",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                    <td style={{padding:"12px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                    <td style={{padding:"12px 16px",color:"#555"}}>{formatPrice(b.proposed_price)}</td>
                    <td style={{padding:"12px 16px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td>
                  </tr>
                ))}</tbody>
              </table>
            </div>
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
