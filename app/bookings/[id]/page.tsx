"use client";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { Navbar, Footer, Loading } from "@/components/Shared";
export default function BookingDetailPage() {
  const params = useParams();
  const supabase = getSupabase();
  const [booking, setBooking] = useState<any>(null);
  const [cargo, setCargo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [isCarrier, setIsCarrier] = useState(false);
  const [hasReview, setHasReview] = useState(false);
  const [profile, setProfile] = useState<any>(null);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
        setProfile(p);
      }
      const { data: b } = await supabase.from("bookings").select("*").eq("id", params.id).single();
      setBooking(b);
      if (b) {
        setIsCarrier(b.carrier_id === user?.id);
        const { data: c } = await supabase.from("cargo_posts").select("*").eq("id", b.cargo_post_id).single();
        setCargo(c);
        if (user) {
          const { data: r } = await supabase.from("reviews").select("id").eq("booking_id", params.id).eq("reviewer_id", user.id);
          setHasReview((r || []).length > 0);
        }
      }
      setLoading(false);
    }; f();
  }, [params.id]);
  const handleSignOut = async () => { await supabase.auth.signOut(); window.location.href = "/"; };
  const updateStatus = async (s: string) => {
    await supabase.from("bookings").update({status:s}).eq("id",params.id);
    if (s==="in_transit") await supabase.from("cargo_posts").update({status:"in_transit"}).eq("id",booking.cargo_post_id);
    if (s==="delivered") await supabase.from("cargo_posts").update({status:"delivered"}).eq("id",booking.cargo_post_id);
    window.location.reload();
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const steps = [{key:"confirmed",label:"تأیید شده",icon:"✅",desc:"بارفرست درخواست رو تأیید کرد",color:"#3b82f6"},{key:"in_transit",label:"در مسیر",icon:"🚛",desc:"بارگیری انجام شد و در مسیره",color:"#8b5cf6"},{key:"delivered",label:"تحویل شده",icon:"📦",desc:"حمل‌کننده بار رو تحویل داد",color:"#f59e0b"},{key:"completed",label:"تکمیل",icon:"🎉",desc:"بارفرست تحویل رو تأیید کرد",color:"#10b981"}];
  const getIdx = () => { const i = steps.findIndex(s=>s.key===booking?.status); return i >= 0 ? i : -1; };
  if (loading) return <Loading />;
  if (!booking||!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"#999",fontWeight:900}}>رزرو پیدا نشد</div>;
  const ci = getIdx();
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar role={isCarrier?"carrier":"shipper"} name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{maxWidth:"680px",margin:"0 auto",padding:"32px 20px"}}>
        <Link href={isCarrier?"/carrier":"/shipper"} style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"#1e3a5f",fontSize:"13px",fontWeight:900,marginBottom:"20px"}}>→ بازگشت به داشبورد</Link>
        <div className="animate-fade" style={{background:"white",padding:"28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",marginBottom:"20px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"20px",paddingBottom:"16px",borderBottom:"2px solid #f0f4ff"}}>
            <div style={{display:"flex",alignItems:"center",gap:"10px"}}><span style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f"}}>{cargo.origin_city}</span><span style={{color:"#06b6d4",fontSize:"20px",fontWeight:900}}>←</span><span style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f"}}>{cargo.dest_city}</span></div>
          </div>
          <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:"10px"}}>
            <div style={{background:"#ecfeff",padding:"14px",borderRadius:"12px",textAlign:"center"}}><div style={{fontSize:"11px",color:"#0e7490",fontWeight:900}}>نوع بار</div><div style={{fontSize:"14px",fontWeight:900,color:"#1e3a5f",marginTop:"4px"}}>{cargo.cargo_type}</div></div>
            <div style={{background:"#ecfdf5",padding:"14px",borderRadius:"12px",textAlign:"center"}}><div style={{fontSize:"11px",color:"#047857",fontWeight:900}}>تاریخ</div><div style={{fontSize:"14px",fontWeight:900,color:"#1e3a5f",marginTop:"4px"}}>{cargo.pickup_date}</div></div>
            <div style={{background:"linear-gradient(135deg,#ecfeff,#e0f2fe)",padding:"14px",borderRadius:"12px",textAlign:"center",border:"2px solid #06b6d422"}}><div style={{fontSize:"11px",color:"#0e7490",fontWeight:900}}>قیمت</div><div style={{fontSize:"18px",fontWeight:900,color:"#0ea5e9",marginTop:"4px"}}>{formatPrice(booking.proposed_price)}</div></div>
          </div>
        </div>

        <div className="animate-fade-up" style={{background:"white",padding:"32px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",marginBottom:"20px"}}>
          <h2 style={{fontSize:"18px",fontWeight:900,color:"#1e3a5f",marginBottom:"28px",display:"flex",alignItems:"center",gap:"8px"}}><span style={{width:"32px",height:"32px",borderRadius:"8px",background:"#ecfeff",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px"}}>📍</span> وضعیت تحویل</h2>
          <div style={{position:"relative",paddingRight:"28px"}}>
            {steps.map((s,i)=>(
              <div key={s.key} style={{display:"flex",gap:"18px",marginBottom:i<steps.length-1?"32px":"0",position:"relative"}}>
                {i<steps.length-1 && <div style={{position:"absolute",right:"17px",top:"44px",width:"3px",height:"calc(100% - 12px)",background:i<ci?`linear-gradient(to bottom,${steps[i].color},${steps[i+1].color})`:"#e5e7eb",borderRadius:"2px"}} />}
                <div style={{width:"36px",height:"36px",borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px",background:i<=ci?`linear-gradient(135deg,${s.color},${s.color}dd)`:"#f0f0f0",color:i<=ci?"white":"#ccc",flexShrink:0,boxShadow:i<=ci?`0 4px 12px ${s.color}40`:"none",zIndex:1,border:i===ci?"3px solid white":"none",transition:"all 0.3s"}}>{s.icon}</div>
                <div style={{paddingTop:"4px"}}><div style={{fontSize:"15px",fontWeight:900,color:i<=ci?"#1e3a5f":"#ccc"}}>{s.label}</div><div style={{fontSize:"12px",color:i<=ci?"#666":"#ddd",marginTop:"3px",fontWeight:700}}>{s.desc}</div></div>
              </div>
            ))}
          </div>
        </div>

        {isCarrier && booking.status==="confirmed" && (
          <div className="animate-scale" style={{background:"white",padding:"24px",borderRadius:"20px",border:"2px solid #8b5cf622",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",marginBottom:"20px"}}>
            <button onClick={()=>updateStatus("in_transit")} style={{width:"100%",padding:"18px",background:"linear-gradient(135deg,#7c3aed,#8b5cf6)",color:"white",border:"none",borderRadius:"14px",fontSize:"17px",fontWeight:900,fontFamily:"inherit",cursor:"pointer",boxShadow:"0 4px 15px rgba(124,58,237,0.35)"}}>🚛 بارگیری انجام شد — در مسیرم</button>
          </div>
        )}
        {isCarrier && booking.status==="in_transit" && (
          <div className="animate-scale" style={{background:"white",padding:"24px",borderRadius:"20px",border:"2px solid #10b98122",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",marginBottom:"20px"}}>
            <button onClick={()=>updateStatus("delivered")} className="btn-success" style={{width:"100%",padding:"18px",fontSize:"17px",fontFamily:"inherit",borderRadius:"14px",boxShadow:"0 4px 15px rgba(5,150,105,0.35)"}}>📦 تحویل دادم</button>
          </div>
        )}
        {isCarrier && booking.status==="delivered" && (
          <div className="animate-fade" style={{background:"linear-gradient(135deg,#ecfdf5,#d1fae5)",padding:"24px",borderRadius:"20px",textAlign:"center",marginBottom:"20px",border:"2px solid #10b98133"}}>
            <div style={{fontSize:"18px",fontWeight:900,color:"#059669"}}>✅ تحویل ثبت شد — منتظر تأیید بارفرست</div>
          </div>
        )}
        {isCarrier && booking.status==="pending" && (
          <div className="animate-fade" style={{background:"linear-gradient(135deg,#fffbeb,#fef3c7)",padding:"24px",borderRadius:"20px",textAlign:"center",marginBottom:"20px",border:"2px solid #f59e0b33"}}>
            <div style={{color:"#b45309",fontWeight:900,fontSize:"16px"}}>⏳ منتظر تأیید بارفرست...</div>
          </div>
        )}
        {!isCarrier && booking.status==="delivered" && (
          <div className="animate-scale" style={{background:"white",padding:"28px",borderRadius:"20px",border:"3px solid #10b981",boxShadow:"0 4px 20px rgba(16,185,129,0.15)",marginBottom:"20px"}}>
            <h2 style={{fontSize:"18px",fontWeight:900,color:"#059669",marginBottom:"16px",display:"flex",alignItems:"center",gap:"8px"}}>📦 حمل‌کننده تحویل داده!</h2>
            <p style={{color:"#666",fontSize:"14px",fontWeight:700,marginBottom:"16px"}}>اگه بار رو دریافت کردی، تأیید کن</p>
            <button onClick={()=>updateStatus("completed")} className="btn-success" style={{width:"100%",padding:"18px",fontSize:"17px",fontFamily:"inherit",borderRadius:"14px",boxShadow:"0 4px 15px rgba(5,150,105,0.35)"}}>✅ تأیید تحویل — تکمیل شد</button>
          </div>
        )}
        {booking.status==="completed" && (
          <div className="animate-scale" style={{background:"white",padding:"36px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",textAlign:"center"}}>
            <div style={{width:"80px",height:"80px",borderRadius:"50%",background:"linear-gradient(135deg,#ecfdf5,#d1fae5)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"40px"}} className="animate-float">🎉</div>
            <h3 style={{color:"#059669",fontSize:"22px",fontWeight:900,marginBottom:"16px"}}>تحویل تکمیل شد!</h3>
            {hasReview ? (
              <div style={{background:"#ecfdf5",padding:"18px",borderRadius:"14px",color:"#059669",fontWeight:900,fontSize:"15px"}}>✅ نظر شما ثبت شده — ممنون!</div>
            ) : (
              <div>
                <p style={{color:"#666",fontSize:"14px",fontWeight:700,marginBottom:"20px"}}>نظرت درباره این تجربه چیه؟ به بهبود خدمات کمک کن!</p>
                <Link href={"/bookings/"+params.id+"/review"} style={{display:"inline-block",background:"linear-gradient(135deg,#f59e0b,#fbbf24)",color:"white",padding:"16px 36px",borderRadius:"14px",fontWeight:900,fontSize:"16px",boxShadow:"0 4px 15px rgba(245,158,11,0.35)"}}>⭐ ثبت نظر و امتیاز</Link>
              </div>
            )}
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
