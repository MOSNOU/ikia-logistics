"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { createBrowserClient } from "@supabase/ssr";
import Link from "next/link";
import { useRouter } from "next/navigation";
export default function CarrierDashboard() {
  const supabase = createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
  const router = useRouter();
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data } = await supabase.from("bookings").select("*, cargo_posts(*)").eq("carrier_id", user.id).order("created_at",{ascending:false});
      setBookings(data || []);
      setLoading(false);
    };
    f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const statusLabels: Record<string,string> = {pending:"در انتظار",confirmed:"تأیید شده",rejected:"رد شده",in_transit:"در مسیر",delivered:"تحویل شده",completed:"تکمیل"};
  const statusColors: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",rejected:"#ef4444",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669"};
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb",color:"#333"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <div style={{display:"flex",gap:"8px",alignItems:"center"}}>
          <span style={{background:"#e0f2fe",padding:"4px 12px",borderRadius:"20px",fontSize:"13px",color:"#2E75B6"}}>حمل‌کننده</span>
          <button onClick={handleSignOut} style={{color:"#ef4444",background:"none",border:"none",cursor:"pointer",fontSize:"14px"}}>خروج</button>
        </div>
      </nav>
      <main style={{maxWidth:"800px",margin:"0 auto",padding:"32px 16px"}}>
        <h1 style={{fontSize:"28px",color:"#1B3A5C",marginBottom:"24px"}}>سلام حمل‌کننده 👋</h1>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(200px,1fr))",gap:"16px",marginBottom:"32px"}}>
          <Link href="/cargo" style={{textDecoration:"none"}}>
            <div style={{background:"#2E75B6",color:"white",padding:"24px",borderRadius:"16px"}}>
              <div style={{fontSize:"32px",marginBottom:"8px"}}>🔍</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold"}}>جستجوی بار</h3>
              <p style={{fontSize:"14px",opacity:0.8}}>بارهای موجود رو ببین</p>
            </div>
          </Link>
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>📋</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>رزروهای من</h3>
            <div style={{fontSize:"28px",fontWeight:"bold",color:"#2E75B6"}}>{bookings.length}</div>
          </div>
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>✅</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>تحویل شده</h3>
            <div style={{fontSize:"28px",fontWeight:"bold",color:"#10b981"}}>{bookings.filter(b=>b.status==="delivered"||b.status==="completed").length}</div>
          </div>
        </div>
        <h2 style={{fontSize:"20px",color:"#1B3A5C",marginBottom:"16px"}}>رزروهای من</h2>
        {loading ? <div style={{textAlign:"center",padding:"40px",color:"#999"}}>در حال بارگذاری...</div> : bookings.length === 0 ? (
          <div style={{textAlign:"center",padding:"40px",background:"white",borderRadius:"16px",border:"2px dashed #ddd"}}>
            <div style={{fontSize:"48px",marginBottom:"12px"}}>🚛</div>
            <p style={{color:"#999"}}>هنوز رزروی نداری</p>
            <Link href="/cargo" style={{display:"inline-block",marginTop:"12px",padding:"10px 20px",background:"#2E75B6",color:"white",borderRadius:"8px",textDecoration:"none"}}>جستجوی بار</Link>
          </div>
        ) : (
          <div style={{display:"flex",flexDirection:"column",gap:"12px"}}>
            {bookings.map(b=>(
              <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                <div style={{background:"white",padding:"16px",borderRadius:"12px",border:"1px solid #eee"}}>
                  <div style={{display:"flex",justifyContent:"space-between",marginBottom:"8px"}}>
                    <span style={{fontWeight:"bold",color:"#1B3A5C"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</span>
                    <span style={{background:statusColors[b.status]||"#999",color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"13px"}}>{statusLabels[b.status]||b.status}</span>
                  </div>
                  <div style={{fontSize:"14px",color:"#666"}}>{b.cargo_posts?.cargo_type} | {formatPrice(b.proposed_price)}</div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
