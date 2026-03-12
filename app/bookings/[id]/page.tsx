"use client";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
export default function BookingDetailPage() {
  const params = useParams();
  const supabase = getSupabase();
  const [booking, setBooking] = useState<any>(null);
  const [cargo, setCargo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [isCarrier, setIsCarrier] = useState(false);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      const { data: b } = await supabase.from("bookings").select("*").eq("id", params.id).single();
      setBooking(b);
      if (b) {
        setIsCarrier(b.carrier_id === user?.id);
        const { data: c } = await supabase.from("cargo_posts").select("*").eq("id", b.cargo_post_id).single();
        setCargo(c);
      }
      setLoading(false);
    }; f();
  }, [params.id]);
  const updateStatus = async (s: string) => {
    await supabase.from("bookings").update({status:s}).eq("id",params.id);
    if (s==="in_transit") await supabase.from("cargo_posts").update({status:"in_transit"}).eq("id",booking.cargo_post_id);
    if (s==="delivered") await supabase.from("cargo_posts").update({status:"delivered"}).eq("id",booking.cargo_post_id);
    window.location.reload();
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const steps = [{key:"confirmed",label:"تأیید شده",icon:"✅",desc:"بارفرست درخواست رو تأیید کرد"},{key:"in_transit",label:"در مسیر",icon:"🚛",desc:"بارگیری انجام شد و در مسیره"},{key:"delivered",label:"تحویل شده",icon:"📦",desc:"حمل‌کننده بار رو تحویل داد"},{key:"completed",label:"تکمیل",icon:"🎉",desc:"بارفرست تحویل رو تأیید کرد"}];
  const getIdx = () => { const i = steps.findIndex(s=>s.key===booking?.status); return i >= 0 ? i : -1; };
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #3C3B6E",borderRadius:"50%",animation:"spin 1s linear infinite"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style></div>;
  if (!booking||!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"#999"}}>رزرو پیدا نشد</div>;
  const ci = getIdx();
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <Link href={isCarrier?"/carrier":"/shipper"} style={{color:"#3C3B6E",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>→ بازگشت</Link>
      </nav>
      <main style={{maxWidth:"650px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)",marginBottom:"20px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"16px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px"}}><span style={{fontSize:"22px",fontWeight:"bold",color:"#3C3B6E"}}>{cargo.origin_city}</span><span style={{color:"#2E75B6"}}>←</span><span style={{fontSize:"22px",fontWeight:"bold",color:"#3C3B6E"}}>{cargo.dest_city}</span></div>
          </div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:"10px"}}>
            <div style={{background:"#f8fafc",padding:"12px",borderRadius:"10px",textAlign:"center"}}><div style={{fontSize:"11px",color:"#999"}}>نوع بار</div><div style={{fontSize:"14px",fontWeight:"bold",marginTop:"2px"}}>{cargo.cargo_type}</div></div>
            <div style={{background:"#f8fafc",padding:"12px",borderRadius:"10px",textAlign:"center"}}><div style={{fontSize:"11px",color:"#999"}}>تاریخ</div><div style={{fontSize:"14px",fontWeight:"bold",marginTop:"2px"}}>{cargo.pickup_date}</div></div>
            <div style={{background:"linear-gradient(135deg,#eff6ff,#dbeafe)",padding:"12px",borderRadius:"10px",textAlign:"center"}}><div style={{fontSize:"11px",color:"#3C3B6E"}}>قیمت</div><div style={{fontSize:"16px",fontWeight:"bold",color:"#2E75B6",marginTop:"2px"}}>{formatPrice(booking.proposed_price)}</div></div>
          </div>
        </div>
        <div style={{background:"white",padding:"28px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)",marginBottom:"20px"}}>
          <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"24px"}}>📍 وضعیت تحویل</h2>
          <div style={{position:"relative",paddingRight:"24px"}}>
            {steps.map((s,i)=>(
              <div key={s.key} style={{display:"flex",gap:"16px",marginBottom:i<steps.length-1?"28px":"0",position:"relative"}}>
                {i<steps.length-1 && <div style={{position:"absolute",right:"15px",top:"40px",width:"2px",height:"calc(100% - 12px)",background:i<ci?"#10b981":"#e0e0e0"}} />}
                <div style={{width:"32px",height:"32px",borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px",background:i<=ci?"linear-gradient(135deg,#059669,#10b981)":"#f0f0f0",color:i<=ci?"white":"#ccc",flexShrink:0,boxShadow:i<=ci?"0 2px 8px rgba(5,150,105,0.3)":"none",zIndex:1}}>{s.icon}</div>
                <div><div style={{fontSize:"14px",fontWeight:"bold",color:i<=ci?"#333":"#ccc"}}>{s.label}</div><div style={{fontSize:"12px",color:i<=ci?"#888":"#ddd",marginTop:"2px"}}>{s.desc}</div></div>
              </div>
            ))}
          </div>
        </div>
        {isCarrier && (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            {booking.status==="confirmed" && <button onClick={()=>updateStatus("in_transit")} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#7c3aed,#8b5cf6)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer",boxShadow:"0 4px 12px rgba(124,58,237,0.3)"}}>🚛 بارگیری انجام شد — در مسیرم</button>}
            {booking.status==="in_transit" && <button onClick={()=>updateStatus("delivered")} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#059669,#10b981)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer",boxShadow:"0 4px 12px rgba(5,150,105,0.3)"}}>📦 تحویل دادم</button>}
            {booking.status==="delivered" && <div style={{textAlign:"center",padding:"16px",color:"#059669",fontSize:"16px",fontWeight:"bold",background:"#ecfdf5",borderRadius:"12px"}}>✅ تحویل ثبت شد — منتظر تأیید بارفرست</div>}
            {booking.status==="pending" && <div style={{textAlign:"center",padding:"16px",color:"#f59e0b",background:"#fffbeb",borderRadius:"12px"}}>⏳ منتظر تأیید بارفرست...</div>}
          </div>
        )}
        {!isCarrier && booking.status==="delivered" && (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"2px solid #10b981",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <h2 style={{fontSize:"17px",fontWeight:"bold",color:"#059669",marginBottom:"16px"}}>📦 حمل‌کننده تحویل داده</h2>
            <button onClick={()=>updateStatus("completed")} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#059669,#10b981)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer",boxShadow:"0 4px 12px rgba(5,150,105,0.3)"}}>✅ تأیید تحویل — تکمیل شد</button>
          </div>
        )}
        {!isCarrier && booking.status==="completed" && (
          <div style={{background:"#ecfdf5",padding:"24px",borderRadius:"16px",textAlign:"center"}}><div style={{fontSize:"48px",marginBottom:"8px"}}>🎉</div><h3 style={{color:"#059669",fontSize:"18px"}}>تکمیل شد!</h3></div>
        )}
      </main>
    </div>
  );
}
