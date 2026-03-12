"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { Navbar, Footer, Loading, StatCard } from "@/components/Shared";
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
      const p = profiles||[], c = cargos||[], b = bookings||[], r = reviews||[];
      setStats({users:p.length,shippers:p.filter(x=>x.role==="shipper").length,carriers:p.filter(x=>x.role==="carrier").length,cargos:c.length,openCargos:c.filter(x=>x.status==="open").length,bookings:b.length,pending:b.filter(x=>x.status==="pending").length,confirmed:b.filter(x=>x.status==="confirmed").length,inTransit:b.filter(x=>x.status==="in_transit").length,delivered:b.filter(x=>x.status==="delivered").length,completed:b.filter(x=>x.status==="completed").length,reviews:r.length,avgRating:r.length>0?Math.round((r.reduce((a:number,x:any)=>a+x.rating,0)/r.length)*10)/10:0});
      setRecentCargos(c.slice(0,5)); setRecentBookings(b.slice(0,5)); setUsers(p);
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const SL: Record<string,string> = {open:"باز",matched:"تطبیق",in_transit:"در مسیر",delivered:"تحویل",cancelled:"لغو",pending:"انتظار",confirmed:"تأیید",completed:"تکمیل",rejected:"رد"};
  const SC: Record<string,string> = {open:"#0ea5e9",matched:"#8b5cf6",in_transit:"#f59e0b",delivered:"#10b981",cancelled:"#ef4444",pending:"#f59e0b",confirmed:"#3b82f6",completed:"#059669",rejected:"#ef4444"};
  if (loading) return <Loading color="#B22234" />;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar role="admin" name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{maxWidth:"1100px",margin:"0 auto",padding:"32px 20px"}}>
        <div className="animate-fade" style={{marginBottom:"28px"}}><h1 style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f",margin:0}}>📊 داشبورد مدیریت</h1><p style={{color:"#666",fontSize:"13px",marginTop:"4px",fontWeight:700}}>نمای کلی از عملکرد پلتفرم iKIA Logistics</p></div>
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"16px",marginBottom:"28px"}}>
          <StatCard label="کل کاربران" value={stats.users} icon="👥" color="#1e3a5f" bg="#f0f4ff" delay={0} />
          <StatCard label="بارفرست‌ها" value={stats.shippers} icon="📦" color="#0ea5e9" bg="#ecfeff" delay={100} />
          <StatCard label="حمل‌کنندگان" value={stats.carriers} icon="🚛" color="#8b5cf6" bg="#f5f3ff" delay={200} />
          <StatCard label="کل بارها" value={stats.cargos} icon="📋" color="#10b981" bg="#ecfdf5" delay={300} />
        </div>
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"repeat(5,1fr)",gap:"12px",marginBottom:"28px"}}>
          {[{l:"بار باز",v:stats.openCargos,c:"#0ea5e9"},{l:"در انتظار",v:stats.pending,c:"#f59e0b"},{l:"تأیید شده",v:stats.confirmed,c:"#3b82f6"},{l:"در مسیر",v:stats.inTransit,c:"#8b5cf6"},{l:"تکمیل شده",v:stats.completed,c:"#059669"}].map((s,i)=>(
            <div key={i} className="card-hover animate-fade" style={{background:"white",padding:"18px",borderRadius:"14px",border:"1px solid #eee",textAlign:"center",animationDelay:`${i*60}ms`}}>
              <div style={{fontSize:"26px",fontWeight:900,color:s.c}}>{s.v}</div>
              <div style={{fontSize:"12px",color:"#888",marginTop:"4px",fontWeight:900}}>{s.l}</div>
            </div>
          ))}
        </div>
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"28px"}}>
          <div className="card-hover animate-fade" style={{background:"white",padding:"28px",borderRadius:"18px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.04)"}}>
            <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}><span style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f"}}>⭐ میانگین امتیاز</span><span style={{fontSize:"13px",color:"#888",fontWeight:700}}>{stats.reviews} نظر</span></div>
            <div style={{fontSize:"44px",fontWeight:900,color:"#f59e0b"}}>{stats.avgRating > 0 ? stats.avgRating : "—"}</div>
            <div style={{fontSize:"14px",color:"#888",marginTop:"4px",fontWeight:700}}>از ۵</div>
          </div>
          <div className="card-hover animate-fade" style={{background:"white",padding:"28px",borderRadius:"18px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.04)",animationDelay:"100ms"}}>
            <div style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f",marginBottom:"12px"}}>📈 نرخ تکمیل</div>
            <div style={{fontSize:"44px",fontWeight:900,color:"#10b981"}}>{stats.bookings>0?Math.round(stats.completed/stats.bookings*100):0}٪</div>
            <div style={{fontSize:"14px",color:"#888",marginTop:"4px",fontWeight:700}}>{stats.completed} از {stats.bookings} رزرو</div>
          </div>
        </div>
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"16px",marginBottom:"28px"}}>
          <div className="animate-fade" style={{background:"white",borderRadius:"18px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 10px rgba(0,0,0,0.04)"}}>
            <div style={{padding:"18px 22px",borderBottom:"2px solid #f0f4ff"}}><h3 style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f",margin:0}}>📦 آخرین بارها</h3></div>
            {recentCargos.length===0?<div style={{padding:"36px",textAlign:"center",color:"#ccc",fontWeight:700}}>باری ثبت نشده</div>:
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><thead><tr style={{background:"#f8fafc"}}><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>مسیر</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>وضعیت</th></tr></thead>
                <tbody>{recentCargos.map(c=><tr key={c.id} style={{borderBottom:"1px solid #f5f5f5"}}><td style={{padding:"10px 16px",fontWeight:900,color:"#1e3a5f"}}>{c.origin_city} ← {c.dest_city}</td><td style={{padding:"10px 16px"}}><span className="badge" style={{background:SC[c.status]||"#999",color:"white"}}>{SL[c.status]||c.status}</span></td></tr>)}</tbody></table>}
          </div>
          <div className="animate-fade" style={{background:"white",borderRadius:"18px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 10px rgba(0,0,0,0.04)",animationDelay:"100ms"}}>
            <div style={{padding:"18px 22px",borderBottom:"2px solid #f0f4ff"}}><h3 style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f",margin:0}}>🤝 آخرین رزروها</h3></div>
            {recentBookings.length===0?<div style={{padding:"36px",textAlign:"center",color:"#ccc",fontWeight:700}}>رزروی نیست</div>:
              <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><thead><tr style={{background:"#f8fafc"}}><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>مسیر</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>وضعیت</th></tr></thead>
                <tbody>{recentBookings.map(b=><tr key={b.id} style={{borderBottom:"1px solid #f5f5f5"}}><td style={{padding:"10px 16px",fontWeight:900,color:"#1e3a5f"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</td><td style={{padding:"10px 16px"}}><span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span></td></tr>)}</tbody></table>}
          </div>
        </div>
        <div className="animate-fade" style={{background:"white",borderRadius:"18px",border:"1px solid #eee",overflow:"hidden",boxShadow:"0 2px 10px rgba(0,0,0,0.04)"}}>
          <div style={{padding:"18px 22px",borderBottom:"2px solid #f0f4ff"}}><h3 style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f",margin:0}}>👥 کاربران ({users.length})</h3></div>
          <table style={{width:"100%",borderCollapse:"collapse",fontSize:"13px"}}><thead><tr style={{background:"#f8fafc"}}><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>نام</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>نقش</th><th style={{padding:"10px 16px",textAlign:"right",color:"#888",fontWeight:900}}>تلفن/ایمیل</th></tr></thead>
            <tbody>{users.map(u=><tr key={u.id} style={{borderBottom:"1px solid #f5f5f5"}}><td style={{padding:"10px 16px",fontWeight:900,color:"#1e3a5f"}}>{u.full_name||"—"}</td><td style={{padding:"10px 16px"}}><span className="badge" style={{background:u.role==="admin"?"#B22234":u.role==="carrier"?"#06b6d4":"#1e3a5f",color:"white"}}>{u.role==="admin"?"ادمین":u.role==="carrier"?"حمل‌کننده":"بارفرست"}</span></td><td style={{padding:"10px 16px",color:"#888",fontWeight:700}} dir="ltr">{u.phone||"—"}</td></tr>)}</tbody></table>
        </div>
      </main>
      <Footer />
    </div>
  );
}
