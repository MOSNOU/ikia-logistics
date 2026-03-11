"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { useRouter } from "next/navigation";
export default function ShipperDashboard() {
  const supabase = getSupabase();
  const router = useRouter();
  const [cargos, setCargos] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: c } = await supabase.from("cargo_posts").select("*").eq("shipper_id", user.id).order("created_at",{ascending:false});
      setCargos(c || []);
      const cargoIds = (c||[]).map((x:any)=>x.id);
      if (cargoIds.length > 0) {
        const { data: b } = await supabase.from("bookings").select("*, cargo_posts(*)").in("cargo_post_id", cargoIds).order("created_at",{ascending:false});
        setBookings(b || []);
      }
      setLoading(false);
    };
    f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const statusLabels: Record<string,string> = {pending:"در انتظار تأیید",confirmed:"تأیید شده",rejected:"رد شده",in_transit:"در مسیر",delivered:"تحویل شده — تأیید کن!",completed:"تکمیل شده"};
  const statusColors: Record<string,string> = {pending:"#f59e0b",confirmed:"#3b82f6",rejected:"#ef4444",in_transit:"#8b5cf6",delivered:"#10b981",completed:"#059669"};
  const needAction = bookings.filter(b => b.status === "pending" || b.status === "delivered");
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb",color:"#333"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <div style={{display:"flex",gap:"8px",alignItems:"center"}}>
          <span style={{background:"#e8f0fe",padding:"4px 12px",borderRadius:"20px",fontSize:"13px",color:"#1B3A5C"}}>بارفرست</span>
          <button onClick={handleSignOut} style={{color:"#ef4444",background:"none",border:"none",cursor:"pointer",fontSize:"14px"}}>خروج</button>
        </div>
      </nav>
      <main style={{maxWidth:"800px",margin:"0 auto",padding:"32px 16px"}}>
        <h1 style={{fontSize:"28px",color:"#1B3A5C",marginBottom:"24px"}}>سلام بارفرست 👋</h1>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(180px,1fr))",gap:"16px",marginBottom:"32px"}}>
          <Link href="/cargo/new" style={{textDecoration:"none"}}>
            <div style={{background:"#1B3A5C",color:"white",padding:"20px",borderRadius:"16px"}}>
              <div style={{fontSize:"28px",marginBottom:"8px"}}>📦</div>
              <h3 style={{fontSize:"16px",fontWeight:"bold"}}>ثبت بار جدید</h3>
            </div>
          </Link>
          <Link href="/cargo" style={{textDecoration:"none",color:"inherit"}}>
            <div style={{background:"white",padding:"20px",borderRadius:"16px",border:"1px solid #eee"}}>
              <div style={{fontSize:"28px",marginBottom:"8px"}}>📋</div>
              <h3 style={{fontSize:"16px",fontWeight:"bold"}}>بارهای من</h3>
              <div style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C"}}>{cargos.length}</div>
            </div>
          </Link>
          <div style={{background: needAction.length > 0 ? "#fef3c7" : "white",padding:"20px",borderRadius:"16px",border: needAction.length > 0 ? "2px solid #f59e0b" : "1px solid #eee"}}>
            <div style={{fontSize:"28px",marginBottom:"8px"}}>⚡</div>
            <h3 style={{fontSize:"16px",fontWeight:"bold"}}>نیاز به اقدام</h3>
            <div style={{fontSize:"24px",fontWeight:"bold",color:"#f59e0b"}}>{needAction.length}</div>
          </div>
        </div>

        {needAction.length > 0 && (
          <div style={{marginBottom:"32px"}}>
            <h2 style={{fontSize:"20px",color:"#f59e0b",marginBottom:"16px"}}>⚡ نیاز به اقدام شما</h2>
            <div style={{display:"flex",flexDirection:"column",gap:"12px"}}>
              {needAction.map(b => (
                <Link href={"/bookings/"+b.id} key={b.id} style={{textDecoration:"none",color:"inherit"}}>
                  <div style={{background:"white",padding:"16px",borderRadius:"12px",border: b.status==="delivered" ? "2px solid #10b981" : "1px solid #eee"}}>
                    <div style={{display:"flex",justifyContent:"space-between",marginBottom:"8px"}}>
                      <span style={{fontWeight:"bold",color:"#1B3A5C"}}>{b.cargo_posts?.origin_city} ← {b.cargo_posts?.dest_city}</span>
                      <span style={{background:statusColors[b.status],color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"13px"}}>{statusLabels[b.status]}</span>
                    </div>
                    <div style={{fontSize:"14px",color:"#666"}}>قیمت: {formatPrice(b.proposed_price)}</div>
                    {b.status === "delivered" && <div style={{marginTop:"8px",color:"#10b981",fontWeight:"bold",fontSize:"14px"}}>📦 حمل‌کننده تحویل داده — کلیک کن و تأیید کن!</div>}
                    {b.status === "pending" && <div style={{marginTop:"8px",color:"#f59e0b",fontWeight:"bold",fontSize:"14px"}}>🤝 درخواست جدید — کلیک کن و تأیید/رد کن!</div>}
                  </div>
                </Link>
              ))}
            </div>
          </div>
        )}

        <h2 style={{fontSize:"20px",color:"#1B3A5C",marginBottom:"16px"}}>همه رزروها</h2>
        {loading ? <div style={{textAlign:"center",padding:"40px",color:"#999"}}>در حال بارگذاری...</div> : bookings.length === 0 ? (
          <div style={{textAlign:"center",padding:"40px",background:"white",borderRadius:"16px",border:"2px dashed #ddd"}}>
            <div style={{fontSize:"48px",marginBottom:"12px"}}>📭</div>
            <p style={{color:"#999"}}>هنوز رزروی ندارید</p>
          </div>
        ) : (
          <div style={{display:"flex",flexDirection:"column",gap:"12px"}}>
            {bookings.map(b => (
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
