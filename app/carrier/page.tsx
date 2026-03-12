"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading, EmptyState, StatCard, PageHeader } from "@/components/Shared";
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
  const done = bookings.filter(b=>b.status==="delivered"||b.status==="completed");
  if (loading) return <Loading color="#0ea5e9" />;
  return (
    <DashboardLayout role="carrier" name={profile?.full_name} onSignOut={handleSignOut}>
      <PageHeader title="داشبورد حمل‌کننده" subtitle="مدیریت رزروها و تحویل‌ها" action={<Link href="/cargo" className="btn-primary" style={{padding:"12px 24px",fontSize:"14px",background:"linear-gradient(135deg,#0ea5e9,#06b6d4)"}}>🔍 جستجوی بار</Link>} />
      <div className="stat-grid" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"14px",marginBottom:"24px"}}>
        <StatCard label="در انتظار" value={bookings.filter(b=>b.status==="pending").length} icon="⏳" color="var(--warning)" bg="var(--bg3)" delay={0} />
        <StatCard label="فعال" value={active.length} icon="🚛" color="var(--accent)" bg="var(--bg3)" delay={100} />
        <StatCard label="تکمیل شده" value={done.length} icon="✅" color="var(--success)" bg="var(--bg3)" delay={200} />
        <StatCard label="کل رزروها" value={bookings.length} icon="📋" color="var(--text)" bg="var(--bg3)" delay={300} />
      </div>
      {active.length > 0 && (
        <div style={{marginBottom:"24px"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"12px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"var(--accent)",animation:"pulse 2s infinite"}} /><h2 style={{fontSize:"16px",fontWeight:900,color:"var(--accent)",margin:0}}>رزروهای فعال ({active.length})</h2></div>
          {active.map(b=>(
            <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
              <div className="card" style={{padding:"16px 18px",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",border:"2px solid var(--accent)",cursor:"pointer"}}>
                <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                  <div style={{width:"42px",height:"42px",borderRadius:"12px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"20px"}}>🚛</div>
                  <div><div style={{fontWeight:900,color:"var(--text)",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div><div style={{fontSize:"12px",color:"var(--text3)",marginTop:"3px"}}>{b.cargo_posts?.cargo_type} • {b.cargo_posts?.pickup_date}</div></div>
                </div>
                <div style={{textAlign:"left"}}><span className="badge" style={{background:SC[b.status],color:"white"}}>{SL[b.status]}</span><div style={{fontSize:"13px",color:"var(--accent)",fontWeight:900,marginTop:"4px"}}>{formatPrice(b.proposed_price)}</div></div>
              </div>
            </Link>
          ))}
        </div>
      )}
      <h2 style={{fontSize:"16px",fontWeight:900,color:"var(--text)",marginBottom:"12px"}}>همه رزروها</h2>
      {bookings.length === 0 ? <EmptyState icon="🚛" title="هنوز رزروی نداری" description="بارهای موجود رو ببین" actionText="🔍 جستجوی بار" actionHref="/cargo" /> : (
        <div className="card" style={{overflow:"hidden"}}>
          <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}>
            <thead><tr style={{background:"var(--bg3)"}}><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>مسیر</th><th className="hide-mobile" style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>نوع</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>قیمت</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>وضعیت</th></tr></thead>
            <tbody>{bookings.map(b=>(
              <tr key={b.id} style={{borderBottom:"1px solid var(--border)",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                <td style={{padding:"10px 14px",fontWeight:900,color:"var(--text)"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                <td className="hide-mobile" style={{padding:"10px 14px",color:"var(--text2)"}}>{b.cargo_posts?.cargo_type}</td>
                <td style={{padding:"10px 14px",color:"var(--accent)",fontWeight:900}}>{formatPrice(b.proposed_price)}</td>
                <td style={{padding:"10px 14px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </DashboardLayout>
  );
}
