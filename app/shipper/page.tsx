"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { LogoNav } from "@/components/Logo";
export default function ShipperDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [cargos, setCargos] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      setUser(user);
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
  const statusLabels: Record<string,string> = {pending:"در انتظار تأیید",confirmed:"تأیید شده",in_transit:"در مسیر",delivered:"تحویل شده — تأیید کن!",completed:"تکمیل شده",rejected:"رد شده"};
  const statusColors: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669",rejected:"#ef4444"};
  const needAction = bookings.filter(b => b.status === "pending" || b.status === "delivered");
  const openCargos = cargos.filter(c => c.status === "open");
  const activeCargos = cargos.filter(c => c.status === "matched" || c.status === "in_transit");
  const doneCargos = cargos.filter(c => c.status === "delivered" || c.status === "cancelled");
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",background:"#f4f6f9"}}><div style={{textAlign:"center"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #3C3B6E",borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style><p style={{color:"#888",marginTop:"12px"}}>در حال بارگذاری...</p></div></div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"12px",alignItems:"center"}}>
          <div style={{display:"flex",alignItems:"center",gap:"8px"}}>
            <div style={{width:"32px",height:"32px",borderRadius:"50%",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",display:"flex",alignItems:"center",justifyContent:"center",color:"white",fontSize:"14px",fontWeight:"bold"}}>{profile?.full_name?.[0] || "؟"}</div>
            <div><div style={{fontSize:"13px",fontWeight:"bold",color:"#333"}}>{profile?.full_name || "بارفرست"}</div><div style={{fontSize:"11px",color:"#999"}}>بارفرست</div></div>
          </div>
          <button onClick={handleSignOut} style={{color:"#ef4444",background:"#fef2f2",border:"1px solid #fecaca",padding:"6px 14px",borderRadius:"8px",fontSize:"12px",fontFamily:"inherit",fontWeight:"bold"}}>خروج</button>
        </div>
      </nav>
      <main style={{maxWidth:"1000px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"28px"}}>
          <div><h1 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>داشبورد بارفرست</h1><p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>مدیریت بارها و رزروها</p></div>
          <Link href="/cargo/new" style={{display:"flex",alignItems:"center",gap:"6px",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",color:"white",padding:"12px 24px",borderRadius:"10px",textDecoration:"none",fontSize:"14px",fontWeight:"bold",boxShadow:"0 4px 12px rgba(60,59,110,0.3)"}}>
            <span style={{fontSize:"18px"}}>+</span> ثبت بار جدید
          </Link>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          {[
            {label:"بارهای باز",value:openCargos.length,icon:"📦",color:"#3b82f6",bg:"#eff6ff"},
            {label:"در حال حمل",value:activeCargos.length,icon:"🚛",color:"#8b5cf6",bg:"#f5f3ff"},
            {label:"تکمیل شده",value:doneCargos.length,icon:"✅",color:"#059669",bg:"#ecfdf5"},
            {label:"نیاز به اقدام",value:needAction.length,icon:"⚡",color:"#f59e0b",bg:needAction.length>0?"#fffbeb":"#f9fafb"},
          ].map((s,i)=>(
            <div key={i} style={{background:"white",padding:"20px",borderRadius:"14px",border: s.value>0 && i===3 ? "2px solid #fbbf24" : "1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}>
                <span style={{fontSize:"13px",color:"#888",fontWeight:"bold"}}>{s.label}</span>
                <span style={{width:"36px",height:"36px",borderRadius:"10px",background:s.bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{s.icon}</span>
              </div>
              <div style={{fontSize:"28px",fontWeight:"bold",color:s.color}}>{s.value}</div>
            </div>
          ))}
        </div>
        {needAction.length > 0 && (
          <div style={{marginBottom:"28px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px",marginBottom:"14px"}}><span style={{width:"8px",height:"8px",borderRadius:"50%",background:"#f59e0b",display:"inline-block"}} /><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#b45309",margin:0}}>نیاز به اقدام شما ({needAction.length})</h2></div>
            {needAction.map(b => (
              <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                <div style={{background:"white",padding:"18px 20px",borderRadius:"12px",border: b.status==="delivered" ? "2px solid #10b981" : "2px solid #fbbf24",marginBottom:"10px",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",transition:"transform 0.15s",cursor:"pointer"}}>
                  <div>
                    <div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</div>
                    <div style={{fontSize:"13px",color:"#888",marginTop:"4px"}}>💰 {formatPrice(b.proposed_price)}</div>
                  </div>
                  <div style={{textAlign:"left"}}>
                    <span style={{background:statusColors[b.status],color:"white",padding:"5px 14px",borderRadius:"20px",fontSize:"12px",fontWeight:"bold",display:"inline-block"}}>{statusLabels[b.status]}</span>
                    {b.status==="delivered" && <div style={{fontSize:"11px",color:"#059669",marginTop:"4px",fontWeight:"bold"}}>کلیک کن و تأیید کن ←</div>}
                    {b.status==="pending" && <div style={{fontSize:"11px",color:"#b45309",marginTop:"4px",fontWeight:"bold"}}>بررسی و تأیید/رد ←</div>}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
        <div style={{marginBottom:"28px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"14px"}}><h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>بارهای من</h2><Link href="/cargo" style={{fontSize:"13px",color:"#2E75B6",textDecoration:"none",fontWeight:"bold"}}>مشاهده همه ←</Link></div>
          {cargos.length === 0 ? (
            <div style={{background:"white",borderRadius:"16px",padding:"48px 20px",textAlign:"center",border:"2px dashed #e0e0e0"}}>
              <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"#eff6ff",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"28px"}}>📦</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>هنوز باری ثبت نکردی</h3>
              <p style={{color:"#999",fontSize:"14px",marginBottom:"20px"}}>اولین بارت رو ثبت کن و حمل‌کننده پیدا کن</p>
              <Link href="/cargo/new" style={{display:"inline-block",background:"linear-gradient(135deg,#3C3B6E,#2E75B6)",color:"white",padding:"12px 28px",borderRadius:"10px",fontWeight:"bold",fontSize:"14px",textDecoration:"none"}}>+ ثبت اولین بار</Link>
            </div>
          ) : (
            <div style={{display:"grid",gap:"10px"}}>{cargos.slice(0,5).map(c => (
              <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
                <div style={{background:"white",padding:"16px 20px",borderRadius:"12px",border:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",boxShadow:"0 1px 4px rgba(0,0,0,0.03)",cursor:"pointer"}}>
                  <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
                    <div style={{width:"40px",height:"40px",borderRadius:"10px",background:c.status==="open"?"#eff6ff":c.status==="matched"?"#f5f3ff":"#ecfdf5",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{c.status==="open"?"📦":"🚛"}</div>
                    <div><div style={{fontWeight:"bold",color:"#3C3B6E",fontSize:"15px"}}>{c.origin_city} ← {c.dest_city}</div><div style={{fontSize:"12px",color:"#999",marginTop:"2px"}}>{c.cargo_type} • {c.pickup_date}</div></div>
                  </div>
                  <div style={{textAlign:"left"}}><div style={{fontWeight:"bold",color:"#2E75B6",fontSize:"14px"}}>{formatPrice(c.price_suggestion)}</div></div>
                </div>
              </Link>
            ))}</div>
          )}
        </div>
        {bookings.length > 0 && (
          <div>
            <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"14px"}}>تاریخچه رزروها</h2>
            <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"14px"}}>
                <thead><tr style={{background:"#f8fafc",borderBottom:"1px solid #eee"}}>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>مسیر</th>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>قیمت</th>
                  <th style={{padding:"12px 16px",textAlign:"right",color:"#888",fontWeight:"bold",fontSize:"12px"}}>وضعیت</th>
                </tr></thead>
                <tbody>{bookings.map(b => (
                  <tr key={b.id} style={{borderBottom:"1px solid #f5f5f5",cursor:"pointer"}} onClick={()=>router.push("/bookings/"+b.id)}>
                    <td style={{padding:"12px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                    <td style={{padding:"12px 16px",color:"#555"}}>{formatPrice(b.proposed_price)}</td>
                    <td style={{padding:"12px 16px"}}><span style={{background:statusColors[b.status]||"#999",color:"white",padding:"3px 12px",borderRadius:"20px",fontSize:"11px",fontWeight:"bold"}}>{statusLabels[b.status]||b.status}</span></td>
                  </tr>
                ))}</tbody>
              </table>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
