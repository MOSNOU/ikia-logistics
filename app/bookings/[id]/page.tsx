"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
export default function BookingDetailPage() {
  const params = useParams();
  const supabase = getSupabase();
  const [booking, setBooking] = useState<any>(null);
  const [cargo, setCargo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState("");
  const [isCarrier, setIsCarrier] = useState(false);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) setUserId(user.id);
      const { data: b } = await supabase.from("bookings").select("*").eq("id", params.id).single();
      setBooking(b);
      if (b) {
        setIsCarrier(b.carrier_id === user?.id);
        const { data: c } = await supabase.from("cargo_posts").select("*").eq("id", b.cargo_post_id).single();
        setCargo(c);
      }
      setLoading(false);
    };
    f();
  }, [params.id]);
  const updateStatus = async (newStatus: string) => {
    await supabase.from("bookings").update({ status: newStatus }).eq("id", params.id);
    if (newStatus === "in_transit") await supabase.from("cargo_posts").update({ status: "in_transit" }).eq("id", booking.cargo_post_id);
    if (newStatus === "delivered") await supabase.from("cargo_posts").update({ status: "delivered" }).eq("id", booking.cargo_post_id);
    window.location.reload();
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const steps = [
    { key:"confirmed", label:"تأیید شده", icon:"✅" },
    { key:"in_transit", label:"در مسیر", icon:"🚛" },
    { key:"delivered", label:"تحویل شده", icon:"📦" },
    { key:"completed", label:"تکمیل", icon:"🎉" },
  ];
  const getStepIndex = () => { const idx = steps.findIndex(s=>s.key===booking?.status); return idx >= 0 ? idx : -1; };
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"sans-serif"}}>در حال بارگذاری...</div>;
  if (!booking || !cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"sans-serif"}}>رزرو پیدا نشد</div>;
  const currentStep = getStepIndex();
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb",color:"#333"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <Link href={isCarrier?"/carrier":"/shipper"} style={{color:"#1B3A5C",textDecoration:"none"}}>← بازگشت</Link>
      </nav>
      <main style={{maxWidth:"600px",margin:"0 auto",padding:"32px 16px"}}>
        <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",marginBottom:"16px"}}>
          <div style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>{cargo.origin_city} ← {cargo.dest_city}</div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"12px",marginBottom:"16px"}}>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>نوع بار</div><div style={{fontWeight:"bold"}}>{cargo.cargo_type}</div></div>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>قیمت توافقی</div><div style={{fontWeight:"bold",color:"#2E75B6"}}>{formatPrice(booking.proposed_price)}</div></div>
          </div>
        </div>
        <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",marginBottom:"16px"}}>
          <h2 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"20px"}}>📍 وضعیت تحویل</h2>
          <div style={{display:"flex",flexDirection:"column",gap:"0"}}>
            {steps.map((s,i) => (
              <div key={s.key} style={{display:"flex",alignItems:"center",gap:"12px",padding:"12px 0"}}>
                <div style={{width:"40px",height:"40px",borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"20px",background: i<=currentStep ? "#10b981" : "#e5e7eb",color: i<=currentStep ? "white" : "#999"}}>{s.icon}</div>
                <div>
                  <div style={{fontWeight:"bold",color: i<=currentStep ? "#333" : "#999"}}>{s.label}</div>
                </div>
                {i < steps.length-1 && <div style={{position:"absolute" as any,right:"36px",height:"20px",width:"2px",background:"#e5e7eb"}} />}
              </div>
            ))}
          </div>
        </div>
        {isCarrier && (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <h2 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>🚛 آپدیت وضعیت</h2>
            {booking.status === "confirmed" && (
              <button onClick={()=>updateStatus("in_transit")} style={{width:"100%",padding:"14px",background:"#8b5cf6",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer",marginBottom:"8px"}}>🚛 بارگیری انجام شد — در مسیرم</button>
            )}
            {booking.status === "in_transit" && (
              <button onClick={()=>updateStatus("delivered")} style={{width:"100%",padding:"14px",background:"#10b981",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer"}}>📦 تحویل دادم</button>
            )}
            {booking.status === "delivered" && (
              <div style={{textAlign:"center",padding:"16px",color:"#10b981",fontSize:"18px",fontWeight:"bold"}}>✅ تحویل ثبت شد — منتظر تأیید بارفرست</div>
            )}
            {booking.status === "pending" && (
              <div style={{textAlign:"center",padding:"16px",color:"#f59e0b"}}>⏳ منتظر تأیید بارفرست...</div>
            )}
          </div>
        )}
        {!isCarrier && booking.status === "delivered" && (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <h2 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>تأیید تحویل</h2>
            <button onClick={()=>updateStatus("completed")} style={{width:"100%",padding:"14px",background:"#059669",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer"}}>✅ تحویل گرفتم — تکمیل شد</button>
          </div>
        )}
      </main>
    </div>
  );
}
