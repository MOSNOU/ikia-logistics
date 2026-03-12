"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { LogoNav } from "@/components/Logo";
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
  const statusLabels: Record<string,string> = {pending:"در انتظار",confirmed:"تأیید شده",in_transit:"در مسیر",delivered:"تحویل شده",completed:"تکمیل",rejected:"رد شده"};
  const statusColors: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669",rejected:"#ef4444"};
  const active = bookings.filter(b=>b.status==="confirmed"||b.status==="in_transit");
  const pending = bookings.filter(b=>b.status==="pending");
  const done = bookings.filter(b=>b.status==="delivered"||b.status==="completed");
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",background:"#f4f6f9"}}><div style={{textAlign:"center"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #2E75B6",borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style><p style={{color:"#888",marginTop:"12px"}}>در حال بارگذاری...</p></div></div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"12px",alignItems:"center"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px"}}>
            <div style={{width:"32px",height:"32px",borderRadius:"50%",background:"linear-gradient(135deg,#2E75B6,#60a5fa)",display:"flex",alignItems:"center",justifyContent:"center",color:"white",fontSize:"14px",fontWeight:"bold"}}>{profile?.full_name?.[0] || "؟"}</div>
            <div><div style={{fontSize:"13px",fontWeight:"bold",color:"#333"}}>{profile?.full_name || "حمل‌کننده"}</div><div style={{fontSize:"11px",color:"#999"}}>حمل‌کننده</div></div>
          </div>
          <button onClick={handleSignOut} style={{color:"#ef4444",background:"#fef2f2",border:"1px solid #fecaca",padding:"6px 14px",borderRadius:"8px",fontSize:"12px",fontFamily:"inherit",fontWeight:"bold"}}>خروج</button>
        </div>
      </nav>
      <main style={{maxWidth:"1000px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"28px"}}>
          <div><h1 style={{fontSize:"24px",fontWeight:"bold",color:"#2E75B6",margin:0}}>داشبورد حمل‌کننده</h1><p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>مدیریت رزروها و تحویل‌ها</p></div>
          <Link href="/cargo" style={{display:"flex",alignItems:"center",gap:"6px",background:"linear-gradient(135deg,#2E75B6,#60a5fa)",color:"white",padding:"12px 24px",borderRadius:"10px",textDecoration:"none",fontSize:"14px",fontWeight:"bold",boxShadow:"0 4px 12px rgba(46,117,182,0.3)"}}>
            🔍 جستجوی بار
          </Link>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          {[
            {label:"در انتظار",value:pending.length,icon:"⏳",color:"#f59e0b",bg:"#fffbeb"},
            {label:"فعال",value:active.length,icon:"🚛",color:"#3b82f6",bg:"#eff6ff"},
            {label:"تکمیل شده",value:done.length,icon:"✅",color:"#059669",bg:"#ecfdf5"},
            {label:"کل رزروها",value:bookings.length,icon:"📋",color:"#3C3B6E",bg:"#f0f0ff"},
          ].map((s,i)=>(
            <div key={i} style={{background:"white",padding:"20px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}>
                <span style={{fontSize:"13px",color:"#888",fontWeight:"bold"}}>{s.label}</span>
                <span style={{width:"36px",height:"36px",borderRadius:"10px",background:s.bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{s.icon}</span>
              </div>
              <div style={{fontSize:"28px",fontWeight:"bold",color:s.color}}>{s.value}</div>
            </div>
          ))}
        </div>
        {active.length > 0 && (
          <div style={{marginBottom:"28px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"14px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"#3b82f6",display:"inline-block"}} /><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#1e40af",margin:0}}>رزروهای فعال ({active.length})</h2></div>
            {active.map(b=>(
              <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                <div style={{background:"white",padding:"18px 20px",borderRadius:"12px",border:"2px solid #bfdbfe",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",cursor:"pointer"}}>
                  <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                    <div style={{width:"44px",height:"44px",borderRadius:"12px",background:"linear-gradient(135deg,#eff6ff,#dbeafe)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px"}}>🚛</div>
                    <div><div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div><div style={{fontSize:"12px",color:"#888",marginTop:"3px"}}>{b.cargo_posts?.cargo_type} • {b.cargo_posts?.pickup_date}</div></div>
                  </div>
                  <div style={{textAlign:"left"}}>
                    <span style={{background:statusColors[b.status],color:"white",padding:"5px 14px",borderRadius:"20px",fontSize:"12px",fontWeight:"bold"}}>{statusLabels[b.status]}</span>
                    <div style={{fontSize:"13px",color:"#2E75B6",fontWeight:"bold",marginTop:"4px"}}>{formatPrice(b.proposed_price)}</div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
        <div>
          <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"14px"}}>همه رزروها</h2>
          {bookings.length === 0 ? (
            <div style={{background:"white",borderRadius:"16px",padding:"48px 20px",textAlign:"center",border:"2px dashed #e0e0e0"}}>
              <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"#eff6ff",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"28px"}}>🚛</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#2E75B6",marginBottom:"8px"}}>هنوز رزروی نداری</h3>
              <p style={{color:"#999",fontSize:"14px",marginBottom:"20px"}}>بارهای موجود رو ببین و درخواست حمل بده</p>
              <Link href="/cargo" style={{display:"inline-block",background:"linear-gradient(135deg,#2E75B6,#60a5fa)",color:"white",padding:"12px 28px",borderRadius:"10px",fontWeight:"bold",fontSize:"14px",textDecoration:"none"}}>🔍 جستجوی بار</Link>
            </div>
          ) : (
            <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"14px"}}>
                <thead><tr style={{background:"#f8fafc",borderBottom:"1px solid #eee"}}>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>مسیر</th>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>نوع بار</th>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>قیمت</th>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>وضعیت</th>
                </tr></thead>
                <tbody>{bookings.map(b=>(
                  <tr key={b.id} style={{borderBottom:"1px solid #f5f5f5",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                    <td style={{padding:"12px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                    <td style={{padding:"12px 16px",color:"#555"}}>{b.cargo_posts?.cargo_type}</td>
                    <td style={{padding:"12px 16px",color:"#2E75B6",fontWeight:"bold"}}>{formatPrice(b.proposed_price)}</td>
                    <td style={{padding:"12px 16px"}}><span style={{background:statusColors[b.status]||"#999",color:"white",padding:"3px 12px",borderRadius:"20px",fontSize:"11px",fontWeight:"bold"}}>{statusLabels[b.status]||b.status}</span></td>
                  </tr>
                ))}</tbody>
              </table>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
