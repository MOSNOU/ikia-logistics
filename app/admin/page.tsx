"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
export default function AdminDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({users:0,shippers:0,carriers:0,cargos:0,openCargos:0,bookings:0,pending:0,confirmed:0,inTransit:0,delivered:0,completed:0,reviews:0,avgRating:0});
  const [recentCargos, setRecentCargos] = useState<any[]>([]);
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const [users, setUsers] = useState<any[]>([]);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: prof } = await supabase.from("profiles").select("role").eq("id", user.id).single();
      if (prof?.role !== "admin") { router.push("/shipper"); return; }
      const { data: profiles } = await supabase.from("profiles").select("*");
      const { data: cargos } = await supabase.from("cargo_posts").select("*").order("created_at",{ascending:false});
      const { data: bookings } = await supabase.from("bookings").select("*, cargo_posts(origin_city, dest_city)").order("created_at",{ascending:false});
      const { data: reviews } = await supabase.from("reviews").select("rating");
      const p = profiles || [];
      const c = cargos || [];
      const b = bookings || [];
      const r = reviews || [];
      setStats({
        users: p.length,
        shippers: p.filter(x=>x.role==="shipper").length,
        carriers: p.filter(x=>x.role==="carrier").length,
        cargos: c.length,
        openCargos: c.filter(x=>x.status==="open").length,
        bookings: b.length,
        pending: b.filter(x=>x.status==="pending").length,
        confirmed: b.filter(x=>x.status==="confirmed").length,
        inTransit: b.filter(x=>x.status==="in_transit").length,
        delivered: b.filter(x=>x.status==="delivered").length,
        completed: b.filter(x=>x.status==="completed").length,
        reviews: r.length,
        avgRating: r.length > 0 ? Math.round((r.reduce((a:number,x:any)=>a+x.rating,0)/r.length)*10)/10 : 0,
      });
      setRecentCargos(c.slice(0,5));
      setRecentBookings(b.slice(0,5));
      setUsers(p);
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const formatPrice = (p:number|null) => { if(!p) return "—"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const SL: Record<string,string> = {open:"باز",matched:"تطبیق",in_transit:"در مسیر",delivered:"تحویل",cancelled:"لغو",pending:"انتظار",confirmed:"تأیید",completed:"تکمیل",rejected:"رد"};
  const SC: Record<string,string> = {open:"#3b82f6",matched:"#8b5cf6",in_transit:"#f59e0b",delivered:"#10b981",cancelled:"#ef4444",pending:"#f59e0b",confirmed:"#3b82f6",completed:"#059669",rejected:"#ef4444"};
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",background:"#f4f6f9"}}><div style={{textAlign:"center"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #B22234",borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style><p style={{color:"#888",marginTop:"12px"}}>در حال بارگذاری...</p></div></div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"linear-gradient(135deg,#1a1a2e,#16213e)",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 2px 10px rgba(0,0,0,0.2)"}}>
        <div style={{display:"flex",alignItems:"center",gap:"12px"}}><LogoNav onDark={true} /><span style={{background:"#B22234",color:"white",padding:"3px 10px",borderRadius:"20px",fontSize:"11px",fontWeight:"bold"}}>ادمین</span></div>
        <button onClick={handleSignOut} style={{color:"#fca5a5",background:"rgba(255,255,255,0.1)",border:"1px solid rgba(255,255,255,0.2)",padding:"6px 14px",borderRadius:"8px",fontSize:"12px",fontFamily:"inherit"}}>خروج</button>
      </nav>
      <main style={{maxWidth:"1100px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{marginBottom:"28px"}}><h1 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>📊 داشبورد مدیریت</h1><p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>نمای کلی از عملکرد پلتفرم iKIA Logistics</p></div>

        <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          {[
            {label:"کل کاربران",value:stats.users,icon:"👥",color:"#3C3B6E",bg:"#f0f0ff"},
            {label:"بارفرست‌ها",value:stats.shippers,icon:"📦",color:"#3b82f6",bg:"#eff6ff"},
            {label:"حمل‌کنندگان",value:stats.carriers,icon:"🚛",color:"#8b5cf6",bg:"#f5f3ff"},
            {label:"کل بارها",value:stats.cargos,icon:"📋",color:"#059669",bg:"#ecfdf5"},
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

        <div style={{display:"grid",gridTemplateColumns:"repeat(5,1fr)",gap:"12px",marginBottom:"28px"}}>
          {[
            {label:"بار باز",value:stats.openCargos,color:"#3b82f6"},
            {label:"در انتظار",value:stats.pending,color:"#f59e0b"},
            {label:"تأیید شده",value:stats.confirmed,color:"#3b82f6"},
            {label:"در مسیر",value:stats.inTransit,color:"#8b5cf6"},
            {label:"تکمیل شده",value:stats.completed,color:"#059669"},
          ].map((s,i)=>(
            <div key={i} style={{background:"white",padding:"16px",borderRadius:"12px",border:"1px solid #eee",textAlign:"center"}}>
              <div style={{fontSize:"24px",fontWeight:"bold",color:s.color}}>{s.value}</div>
              <div style={{fontSize:"12px",color:"#888",marginTop:"4px"}}>{s.label}</div>
            </div>
          ))}
        </div>

        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"28px"}}>
          <div style={{background:"white",padding:"24px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
            <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"8px"}}>
              <span style={{fontSize:"14px",fontWeight:"bold",color:"#3C3B6E"}}>⭐ میانگین امتیاز</span>
              <span style={{fontSize:"12px",color:"#888"}}>{stats.reviews} نظر</span>
            </div>
            <div style={{fontSize:"40px",fontWeight:"bold",color:"#f59e0b"}}>{stats.avgRating > 0 ? stats.avgRating : "—"}</div>
            <div style={{fontSize:"13px",color:"#888",marginTop:"4px"}}>از ۵</div>
          </div>
          <div style={{background:"white",padding:"24px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
            <div style={{fontSize:"14px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>📈 نرخ تکمیل</div>
            <div style={{fontSize:"40px",fontWeight:"bold",color:"#059669"}}>{stats.bookings > 0 ? Math.round(stats.completed/stats.bookings*100) : 0}٪</div>
            <div style={{fontSize:"13px",color:"#888",marginTop:"4px"}}>{stats.completed} از {stats.bookings} رزرو</div>
          </div>
        </div>

        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"28px"}}>
          <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
            <div style={{padding:"16px 20px",borderBottom:"1px solid #f0f0f0",display:"flex",justifyContent:"space-between",alignItems:"center"}}><h3 style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>📦 آخرین بارها</h3></div>
            {recentCargos.length === 0 ? <div style={{padding:"32px",textAlign:"center",color:"#ccc"}}>باری ثبت نشده</div> :
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}>
                <thead><tr style={{background:"#f8fafc"}}><th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>مسیر</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>وضعیت</th></tr></thead>
                <tbody>{recentCargos.map(c=>(
                  <tr key={c.id} style={{borderBottom:"1px solid #f5f5f5"}}>
                    <td style={{padding:"10px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{c.origin_city} ← {c.dest_city}</td>
                    <td style={{padding:"10px 16px"}}><span style={{background:SC[c.status]||"#999",color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"11px"}}>{SL[c.status]||c.status}</span></td>
                  </tr>
                ))}</tbody>
              </table>
            }
          </div>
          <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
            <div style={{padding:"16px 20px",borderBottom:"1px solid #f0f0f0"}}><h3 style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>🤝 آخرین رزروها</h3></div>
            {recentBookings.length === 0 ? <div style={{padding:"32px",textAlign:"center",color:"#ccc"}}>رزروی نیست</div> :
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}>
                <thead><tr style={{background:"#f8fafc"}}><th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>مسیر</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>وضعیت</th></tr></thead>
                <tbody>{recentBookings.map(b=>(
                  <tr key={b.id} style={{borderBottom:"1px solid #f5f5f5"}}>
                    <td style={{padding:"10px 16px",fontWeight:"bold",color:"#3C3B6E"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td>
                    <td style={{padding:"10px 16px"}}><span style={{background:SC[b.status]||"#999",color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"11px"}}>{SL[b.status]||b.status}</span></td>
                  </tr>
                ))}</tbody>
              </table>
            }
          </div>
        </div>

        <div style={{background:"white",borderRadius:"14px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 8px rgba(0,0,0,0.04)"}}>
          <div style={{padding:"16px 20px",borderBottom:"1px solid #f0f0f0"}}><h3 style={{fontSize:"15px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>👥 کاربران ({users.length})</h3></div>
          <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}>
            <thead><tr style={{background:"#f8fafc"}}>
              <th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>نام</th>
              <th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>نقش</th>
              <th style={{padding:"10px 16px",textAlign:"right",color:"#888"}}>تلفن/ایمیل</th>
            </tr></thead>
            <tbody>{users.map(u=>(
              <tr key={u.id} style={{borderBottom:"1px solid #f5f5f5"}}>
                <td style={{padding:"10px 16px",fontWeight:"bold",color:"#333"}}>{u.full_name || "—"}</td>
                <td style={{padding:"10px 16px"}}><span style={{background:u.role==="admin"?"#B22234":u.role==="carrier"?"#2E75B6":"#3C3B6E",color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"11px"}}>{u.role==="admin"?"ادمین":u.role==="carrier"?"حمل‌کننده":"بارفرست"}</span></td>
                <td style={{padding:"10px 16px",color:"#888"}} dir="ltr">{u.phone || "—"}</td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
