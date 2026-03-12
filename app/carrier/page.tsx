"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Navbar, Footer, Loading, EmptyState, StatCard, PageHeader } from "@/components/Shared";
export default function CarrierDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      const { data } = await supabase.from("bookings").select("*, cargo_posts(*)").eq("carrier_id", user.id).order("created_at",{ascending:false});
      setBookings(data || []);
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const SL: Record<string,string> = {pending:"در انتظار",confirmed:"تأیید شده",in_transit:"در مسیر",delivered:"تحویل شده",completed:"تکمیل",rejected:"رد شده"};
  const SC: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669",rejected:"#ef4444"};
  const active = bookings.filter(b=>b.status==="confirmed"||b.status==="in_transit");
  const pending = bookings.filter(b=>b.status==="pending");
  const done = bookings.filter(b=>b.status==="delivered"||b.status==="completed");
  if (loading) return <Loading color="#2E75B6" />;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar role="carrier" name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{maxWidth:"1000px",margin:"0 auto",padding:"32px 20px"}}>
        <PageHeader title="داشبورد حمل‌کننده" subtitle="مدیریت رزروها و تحویل‌ها" action={<Link href="/cargo" className="btn-primary" style={{display:"flex",alignItems:"center",gap:"6px",padding:"12px 24px",fontSize:"14px",background:"linear-gradient(135deg,#2E75B6,#60a5fa)"}}>🔍 جستجوی بار</Link>} />
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          <StatCard label="در انتظار" value={pending.length} icon="⏳" color="#f59e0b" bg="#fffbeb" delay={0} />
          <StatCard label="فعال" value={active.length} icon="🚛" color="#3b82f6" bg="#eff6ff" delay={100} />
          <StatCard label="تکمیل شده" value={done.length} icon="✅" color="#059669" bg="#ecfdf5" delay={200} />
          <StatCard label="کل رزروها" value={bookings.length} icon="📋" color="#3C3B6E" bg="#f0f0ff" delay={300} />
        </div>
        {active.length > 0 && (
          <div className="animate-fade" style={{marginBottom:"28px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"14px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"#3b82f6",display:"inline-block",animation:"pulse 2s infinite"}} /><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#1e40af",margin:0}}>رزروهای فعال ({active.length})</h2></div>
            {active.map((b,i)=>(
              <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                <div className="card-hover animate-fade" style={{background:"white",padding:"18px 20px",borderRadius:"14px",border:"2px solid #bfdbfe",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",animationDelay:`${i*80}ms`}}>
                  <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                    <div style={{width:"44px",height:"44px",borderRadius:"12px",background:"linear-gradient(135deg,#eff6ff,#dbeafe)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px"}}>🚛</div>
                    <div><div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div><div style={{fontSize:"12px",color:"#888",marginTop:"3px"}}>{b.cargo_posts?.cargo_type} • {b.cargo_posts?.pickup_date}</div></div>
                  </div>
                  <div style={{textAlign:"left"}}><span className="badge" style={{background:SC[b.status],color:"white"}}>{SL[b.status]}</span><div style={{fontSize:"13px",color:"#2E75B6",fontWeight:"bold",marginTop:"4px"}}>{formatPrice(b.proposed_price)}</div></div>
                </div>
              </Link>
            ))}
          </div>
        )}
        <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"14px"}}>همه رزروها</h2>
        {bookings.length === 0 ? <EmptyState icon="🚛" title="هنوز رزروی نداری" description="بارهای موجود رو ببین و درخواست حمل بده" actionText="🔍 جستجوی بار" actionHref="/cargo" /> : (
          <div className="animate-fade" style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
            <table style={{width:"100%",borderCollapse:"collapse",fontSize:"14px"}}>
              <thead><tr style={{background:"#f8fafc"}}><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>مسیر</th><th className="hide-mobile" style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>نوع بار</th><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>قیمت</th><th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>وضعیت</th></tr></thead>
              <tbody>{bookings.map(b=>(
                <tr key={b.id} style={{borderBottom:"1px solid #f5f5f5",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                  <td style={{padding:"12px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                  <td className="hide-mobile" style={{padding:"12px 16px",color:"#555"}}>{b.cargo_posts?.cargo_type}</td>
                  <td style={{padding:"12px 16px",color:"#2E75B6",fontWeight:"bold"}}>{formatPrice(b.proposed_price)}</td>
                  <td style={{padding:"12px 16px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
