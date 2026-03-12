"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading, StatCard, PageHeader } from "@/components/Shared";
export default function AdminDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState<any>(null);
  const [stats, setStats] = useState({users:0,shippers:0,carriers:0,cargos:0,openCargos:0,bookings:0,pending:0,confirmed:0,inTransit:0,delivered:0,completed:0,reviews:0,avgRating:0});
  const [recentCargos, setRecentCargos] = useState<any[]>([]);
  const [recentBookings, setRecentBookings] = useState<any[]>([]);
  const [users, setUsers] = useState<any[]>([]);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: prof } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      if (prof?.role !== "admin") { router.push("/shipper"); return; }
      setProfile(prof);
      const { data: profiles } = await supabase.from("profiles").select("*");
      const { data: cargos } = await supabase.from("cargo_posts").select("*").order("created_at",{ascending:false});
      const { data: bookings } = await supabase.from("bookings").select("*, cargo_posts(origin_city, dest_city)").order("created_at",{ascending:false});
      const { data: reviews } = await supabase.from("reviews").select("rating");
      const p=profiles||[],c=cargos||[],b=bookings||[],r=reviews||[];
      setStats({users:p.length,shippers:p.filter(x=>x.role==="shipper").length,carriers:p.filter(x=>x.role==="carrier").length,cargos:c.length,openCargos:c.filter(x=>x.status==="open").length,bookings:b.length,pending:b.filter(x=>x.status==="pending").length,confirmed:b.filter(x=>x.status==="confirmed").length,inTransit:b.filter(x=>x.status==="in_transit").length,delivered:b.filter(x=>x.status==="delivered").length,completed:b.filter(x=>x.status==="completed").length,reviews:r.length,avgRating:r.length>0?Math.round((r.reduce((a:number,x:any)=>a+x.rating,0)/r.length)*10)/10:0});
      setRecentCargos(c.slice(0,5)); setRecentBookings(b.slice(0,5)); setUsers(p);
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const SL: Record<string,string> = {open:"باز",matched:"تطبیق",in_transit:"در مسیر",delivered:"تحویل",pending:"انتظار",confirmed:"تأیید",completed:"تکمیل",rejected:"رد"};
  const SC: Record<string,string> = {open:"#0ea5e9",matched:"#8b5cf6",in_transit:"#f59e0b",delivered:"#10b981",pending:"#f59e0b",confirmed:"#3b82f6",completed:"#059669",rejected:"#ef4444"};
  if (loading) return <Loading color="#B22234" />;
  return (
    <DashboardLayout role="admin" name={profile?.full_name} onSignOut={handleSignOut}>
      <PageHeader title="📊 داشبورد مدیریت" subtitle="نمای کلی از عملکرد پلتفرم" />
      <div className="stat-grid" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"14px",marginBottom:"24px"}}>
        <StatCard label="کل کاربران" value={stats.users} icon="👥" color="var(--text)" bg="var(--bg3)" delay={0} />
        <StatCard label="بارفرست‌ها" value={stats.shippers} icon="📦" color="var(--accent)" bg="var(--bg3)" delay={100} />
        <StatCard label="حمل‌کنندگان" value={stats.carriers} icon="🚛" color="#8b5cf6" bg="var(--bg3)" delay={200} />
        <StatCard label="کل بارها" value={stats.cargos} icon="📋" color="var(--success)" bg="var(--bg3)" delay={300} />
      </div>
      <div className="stat-grid-5" style={{display:"grid",gridTemplateColumns:"repeat(5,1fr)",gap:"12px",marginBottom:"24px"}}>
        {[{l:"بار باز",v:stats.openCargos,c:"var(--accent)"},{l:"در انتظار",v:stats.pending,c:"var(--warning)"},{l:"تأیید شده",v:stats.confirmed,c:"#3b82f6"},{l:"در مسیر",v:stats.inTransit,c:"#8b5cf6"},{l:"تکمیل",v:stats.completed,c:"var(--success)"}].map((s,i)=>(
          <div key={i} className="card animate-fade" style={{padding:"16px",textAlign:"center",animationDelay:`${i*60}ms`}}>
            <div style={{fontSize:"24px",fontWeight:900,color:s.c}}>{s.v}</div>
            <div style={{fontSize:"11px",color:"var(--text3)",marginTop:"4px",fontWeight:900}}>{s.l}</div>
          </div>
        ))}
      </div>
      <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"24px"}}>
        <div className="card" style={{padding:"24px"}}>
          <div style={{display:"flex",justifyContent:"space-between",marginBottom:"8px"}}><span style={{fontSize:"14px",fontWeight:900,color:"var(--text)"}}>⭐ میانگین امتیاز</span><span style={{fontSize:"12px",color:"var(--text3)",fontWeight:700}}>{stats.reviews} نظر</span></div>
          <div style={{fontSize:"40px",fontWeight:900,color:"var(--warning)"}}>{stats.avgRating>0?stats.avgRating:"—"}</div>
          <div style={{fontSize:"13px",color:"var(--text3)",fontWeight:700}}>از ۵</div>
        </div>
        <div className="card" style={{padding:"24px"}}>
          <div style={{fontSize:"14px",fontWeight:900,color:"var(--text)",marginBottom:"8px"}}>📈 نرخ تکمیل</div>
          <div style={{fontSize:"40px",fontWeight:900,color:"var(--success)"}}>{stats.bookings>0?Math.round(stats.completed/stats.bookings*100):0}٪</div>
          <div style={{fontSize:"13px",color:"var(--text3)",fontWeight:700}}>{stats.completed} از {stats.bookings} رزرو</div>
        </div>
      </div>
      <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"24px"}}>
        <div className="card" style={{overflow:"hidden"}}>
          <div style={{padding:"16px 18px",borderBottom:"1px solid var(--border)"}}><h3 style={{fontSize:"14px",fontWeight:900,color:"var(--text)",margin:0}}>📦 آخرین بارها</h3></div>
          {recentCargos.length===0?<div style={{padding:"32px",textAlign:"center",color:"var(--text3)",fontWeight:700}}>باری نیست</div>:
            <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><tbody>{recentCargos.map(c=><tr key={c.id} style={{borderBottom:"1px solid var(--border)"}}><td style={{padding:"10px 14px",fontWeight:900,color:"var(--text)"}}>{c.origin_city} ← {c.dest_city}</td><td style={{padding:"10px 14px"}}><span className="badge" style={{background:SC[c.status]||"#999",color:"white"}}>{SL[c.status]||c.status}</span></td></tr>)}</tbody></table>}
        </div>
        <div className="card" style={{overflow:"hidden"}}>
          <div style={{padding:"16px 18px",borderBottom:"1px solid var(--border)"}}><h3 style={{fontSize:"14px",fontWeight:900,color:"var(--text)",margin:0}}>🤝 آخرین رزروها</h3></div>
          {recentBookings.length===0?<div style={{padding:"32px",textAlign:"center",color:"var(--text3)",fontWeight:700}}>رزروی نیست</div>:
            <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><tbody>{recentBookings.map(b=><tr key={b.id} style={{borderBottom:"1px solid var(--border)"}}><td style={{padding:"10px 14px",fontWeight:900,color:"var(--text)"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td><td style={{padding:"10px 14px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td></tr>)}</tbody></table>}
        </div>
      </div>
      <div className="card" style={{overflow:"hidden"}}>
        <div style={{padding:"16px 18px",borderBottom:"1px solid var(--border)"}}><h3 style={{fontSize:"14px",fontWeight:900,color:"var(--text)",margin:0}}>👥 کاربران ({users.length})</h3></div>
        <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><thead><tr style={{background:"var(--bg3)"}}><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>نام</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>نقش</th><th style={{padding:"10px 14px",textAlign:"right",color:"var(--text3)",fontWeight:900}}>ایمیل</th></tr></thead>
          <tbody>{users.map(u=><tr key={u.id} style={{borderBottom:"1px solid var(--border)"}}><td style={{padding:"10px 14px",fontWeight:900,color:"var(--text)"}}>{u.full_name||"—"}</td><td style={{padding:"10px 14px"}}><span className="badge" style={{background:u.role==="admin"?"#B22234":u.role==="carrier"?"#06b6d4":"var(--primary)",color:"white"}}>{u.role==="admin"?"ادمین":u.role==="carrier"?"حمل‌کننده":"بارفرست"}</span></td><td style={{padding:"10px 14px",color:"var(--text3)",fontWeight:700}} dir="ltr">{u.phone||"—"}</td></tr>)}</tbody></table>
      </div>
    </DashboardLayout>
  );
}
