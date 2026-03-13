"use client";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading } from "@/components/Shared";
export default function BookingDetailPage() {
  const params = useParams();
  const router = useRouter();
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
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      const { data: b } = await supabase.from("bookings").select("*").eq("id", params.id).single();
      setBooking(b);
      if (b) {
        setIsCarrier(b.carrier_id === user.id);
        const { data: c } = await supabase.from("cargo_posts").select("*").eq("id", b.cargo_post_id).single();
        setCargo(c);
        const { data: r } = await supabase.from("reviews").select("id").eq("booking_id", params.id).eq("reviewer_id", user.id);
        setHasReview((r || []).length > 0);
      }
      setLoading(false);
    }; f();
  }, [params.id]);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const updateStatus = async (s: string) => {
    await supabase.from("bookings").update({status:s}).eq("id",params.id);
    if (s==="in_transit") await supabase.from("cargo_posts").update({status:"in_transit"}).eq("id",booking.cargo_post_id);
    if (s==="delivered") await supabase.from("cargo_posts").update({status:"delivered"}).eq("id",booking.cargo_post_id);
    window.location.reload();
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const steps = [{key:"confirmed",label:"تأیید شده",icon:"✅",desc:"درخواست تأیید شد",color:"#3b82f6"},{key:"in_transit",label:"در مسیر",icon:"🚛",desc:"بارگیری و در مسیر",color:"#8b5cf6"},{key:"delivered",label:"تحویل شده",icon:"📦",desc:"تحویل داده شد",color:"#f59e0b"},{key:"completed",label:"تکمیل",icon:"🎉",desc:"تحویل تأیید شد",color:"#10b981"}];
  const getIdx = () => { const i = steps.findIndex(s=>s.key===booking?.status); return i >= 0 ? i : -1; };
  if (loading) return <Loading />;
  if (!booking||!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"var(--text3)",fontWeight:900}}>رزرو پیدا نشد</div>;
  const ci = getIdx();
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <div style={{maxWidth:"650px"}}>
        <Link href={isCarrier?"/carrier":"/shipper"} style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"var(--accent)",fontSize:"13px",fontWeight:900,marginBottom:"16px"}}>→ بازگشت</Link>
        <div className="card animate-fade" style={{padding:"24px",marginBottom:"18px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"16px",paddingBottom:"14px",borderBottom:"2px solid var(--border)"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px"}}><span style={{fontSize:"22px",fontWeight:900,color:"var(--text)"}}>{cargo.origin_city}</span><span style={{color:"var(--accent)",fontSize:"18px",fontWeight:900}}>←</span><span style={{fontSize:"22px",fontWeight:900,color:"var(--text)"}}>{cargo.dest_city}</span></div>
          </div>
          <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:"10px"}}>
            <div style={{background:"var(--bg3)",padding:"12px",borderRadius:"12px",textAlign:"center"}}><div style={{fontSize:"11px",color:"var(--text3)",fontWeight:900}}>نوع</div><div style={{fontSize:"13px",fontWeight:900,color:"var(--text)",marginTop:"4px"}}>{cargo.cargo_type}</div></div>
            <div style={{background:"var(--bg3)",padding:"12px",borderRadius:"12px",textAlign:"center"}}><div style={{fontSize:"11px",color:"var(--text3)",fontWeight:900}}>تاریخ</div><div style={{fontSize:"13px",fontWeight:900,color:"var(--text)",marginTop:"4px"}}>{cargo.pickup_date}</div></div>
            <div style={{background:"var(--bg3)",padding:"12px",borderRadius:"12px",textAlign:"center",border:"2px solid var(--border)"}}><div style={{fontSize:"11px",color:"var(--accent)",fontWeight:900}}>قیمت</div><div style={{fontSize:"16px",fontWeight:900,color:"var(--accent)",marginTop:"4px"}}>{formatPrice(booking.proposed_price)}</div></div>
          </div>
        </div>

        <div className="card animate-fade-up" style={{padding:"28px",marginBottom:"18px"}}>
          <h2 style={{fontSize:"17px",fontWeight:900,color:"var(--text)",marginBottom:"24px",display:"flex",alignItems:"center",gap:"8px"}}><span style={{fontSize:"18px"}}>📍</span> وضعیت تحویل</h2>
          <div style={{position:"relative",paddingRight:"24px"}}>
            {steps.map((s,i)=>(
              <div key={s.key} style={{display:"flex",gap:"16px",marginBottom:i<steps.length-1?"28px":"0",position:"relative"}}>
                {i<steps.length-1 && <div style={{position:"absolute",right:"15px",top:"40px",width:"3px",height:"calc(100% - 8px)",background:i<ci?`linear-gradient(to bottom,${steps[i].color},${steps[i+1].color})`:"var(--border2)",borderRadius:"2px"}} />}
                <div style={{width:"34px",height:"34px",borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px",background:i<=ci?`linear-gradient(135deg,${s.color},${s.color}dd)`:"var(--bg3)",color:i<=ci?"white":"var(--text3)",flexShrink:0,boxShadow:i<=ci?`0 4px 12px ${s.color}40`:"none",zIndex:1,border:i===ci?"3px solid var(--bg2)":"none"}}>{s.icon}</div>
                <div style={{paddingTop:"4px"}}><div style={{fontSize:"14px",fontWeight:900,color:i<=ci?"var(--text)":"var(--text3)"}}>{s.label}</div><div style={{fontSize:"12px",color:i<=ci?"var(--text2)":"var(--border2)",marginTop:"2px",fontWeight:700}}>{s.desc}</div></div>
              </div>
            ))}
          </div>
        </div>

        {isCarrier && booking.status==="confirmed" && (
          <div className="card animate-scale" style={{padding:"20px",marginBottom:"18px",border:"2px solid #8b5cf6"}}>
            <button onClick={()=>updateStatus("in_transit")} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#7c3aed,#8b5cf6)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:900,fontFamily:"inherit",cursor:"pointer"}}>🚛 بارگیری شد — در مسیرم</button>
          </div>
        )}
        {isCarrier && booking.status==="in_transit" && (
          <div className="card animate-scale" style={{padding:"20px",marginBottom:"18px",border:"2px solid var(--success)"}}>
            <button onClick={()=>updateStatus("delivered")} className="btn-success" style={{width:"100%",padding:"16px",fontSize:"16px",fontFamily:"inherit",borderRadius:"12px"}}>📦 تحویل دادم</button>
          </div>
        )}
        {isCarrier && booking.status==="delivered" && (
          <div className="card animate-fade" style={{padding:"20px",textAlign:"center",marginBottom:"18px",border:"2px solid var(--success)"}}><div style={{fontSize:"16px",fontWeight:900,color:"var(--success)"}}>✅ منتظر تأیید بارفرست...</div></div>
        )}
        {isCarrier && booking.status==="pending" && (
          <div className="card animate-fade" style={{padding:"20px",textAlign:"center",marginBottom:"18px",border:"2px solid var(--warning)"}}><div style={{fontSize:"16px",fontWeight:900,color:"var(--warning)"}}>⏳ منتظر تأیید بارفرست...</div></div>
        )}
        {!isCarrier && booking.status==="delivered" && (
          <div className="card animate-scale" style={{padding:"24px",marginBottom:"18px",border:"3px solid var(--success)"}}>
            <h2 style={{fontSize:"17px",fontWeight:900,color:"var(--success)",marginBottom:"12px"}}>📦 بار تحویل شد!</h2>
            <p style={{color:"var(--text2)",fontSize:"13px",fontWeight:700,marginBottom:"14px"}}>دریافت کردی؟ تأیید کن</p>
            <button onClick={()=>updateStatus("completed")} className="btn-success" style={{width:"100%",padding:"16px",fontSize:"16px",fontFamily:"inherit",borderRadius:"12px"}}>✅ تأیید تحویل</button>
          </div>
        )}
        {booking.status==="completed" && (
          <div className="card animate-scale" style={{padding:"32px",textAlign:"center"}}>
            <div style={{width:"72px",height:"72px",borderRadius:"50%",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"36px"}} className="animate-float">🎉</div>
            <h3 style={{color:"var(--success)",fontSize:"20px",fontWeight:900,marginBottom:"14px"}}>تحویل تکمیل شد!</h3>
            {hasReview ? (
              <div style={{background:"var(--bg3)",padding:"16px",borderRadius:"12px",color:"var(--success)",fontWeight:900}}>✅ نظر ثبت شده</div>
            ) : (
              <div><p style={{color:"var(--text3)",fontSize:"13px",fontWeight:700,marginBottom:"16px"}}>نظرت چیه؟</p><Link href={"/bookings/"+params.id+"/review"} style={{display:"inline-block",background:"linear-gradient(135deg,#f59e0b,#fbbf24)",color:"white",padding:"14px 32px",borderRadius:"12px",fontWeight:900,fontSize:"15px"}}>⭐ ثبت نظر</Link></div>
            )}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
