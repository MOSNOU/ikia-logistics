"use client";
import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
export default function ReviewPage() {
  const params = useParams();
  const router = useRouter();
  const supabase = getSupabase();
  const [rating, setRating] = useState(0);
  const [hover, setHover] = useState(0);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const handleSubmit = async () => {
    if (rating === 0) { setError("لطفاً امتیاز بدید"); return; }
    setLoading(true); setError("");
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً لاگین کنید"); setLoading(false); return; }
    const { data: booking } = await supabase.from("bookings").select("*").eq("id", params.id).single();
    if (!booking) { setError("رزرو پیدا نشد"); setLoading(false); return; }
    const revieweeId = booking.carrier_id === user.id ? booking.cargo_post_id : booking.carrier_id;
    const { data: cargo } = await supabase.from("cargo_posts").select("shipper_id").eq("id", booking.cargo_post_id).single();
    const actualReviewee = user.id === cargo?.shipper_id ? booking.carrier_id : cargo?.shipper_id;
    const { error: e } = await supabase.from("reviews").insert({ booking_id: params.id, reviewer_id: user.id, reviewee_id: actualReviewee, rating, comment: comment || null });
    if (e) { if (e.code === "23505") setError("قبلاً نظر ثبت کردید"); else setError("خطا: " + e.message); }
    else setSuccess(true);
    setLoading(false);
  };
  if (success) return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}><Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link></nav>
      <main style={{maxWidth:"500px",margin:"0 auto",padding:"60px 20px",textAlign:"center"}}>
        <div style={{background:"white",padding:"48px 28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
          <div style={{width:"80px",height:"80px",borderRadius:"50%",background:"linear-gradient(135deg,#ecfdf5,#d1fae5)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 20px",fontSize:"36px"}}>⭐</div>
          <h2 style={{fontSize:"22px",fontWeight:"bold",color:"#059669",marginBottom:"8px"}}>ممنون از نظرت!</h2>
          <p style={{color:"#888",fontSize:"14px",marginBottom:"24px"}}>نظر شما ثبت شد و به بهبود خدمات کمک می‌کنه</p>
          <div style={{display:"flex",gap:"8px",justifyContent:"center"}}>
            <Link href="/shipper" style={{padding:"10px 20px",background:"#3C3B6E",color:"white",borderRadius:"8px",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>داشبورد بارفرست</Link>
            <Link href="/carrier" style={{padding:"10px 20px",background:"#2E75B6",color:"white",borderRadius:"8px",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>داشبورد حمل‌کننده</Link>
          </div>
        </div>
      </main>
    </div>
  );
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <Link href={"/bookings/"+params.id} style={{color:"#3C3B6E",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>→ بازگشت</Link>
      </nav>
      <main style={{maxWidth:"500px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{background:"white",padding:"32px 28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
          <div style={{textAlign:"center",marginBottom:"28px"}}>
            <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"linear-gradient(135deg,#fffbeb,#fef3c7)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 12px",fontSize:"28px"}}>⭐</div>
            <h1 style={{fontSize:"22px",fontWeight:"bold",color:"#3C3B6E"}}>ثبت نظر و امتیاز</h1>
            <p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>تجربه‌ات رو با بقیه به اشتراک بذار</p>
          </div>
          <div style={{textAlign:"center",marginBottom:"28px"}}>
            <p style={{fontSize:"14px",color:"#555",marginBottom:"12px",fontWeight:"bold"}}>امتیاز شما:</p>
            <div style={{display:"flex",justifyContent:"center",gap:"8px"}} dir="ltr">
              {[1,2,3,4,5].map(s=>(
                <button key={s} type="button" onClick={()=>setRating(s)} onMouseEnter={()=>setHover(s)} onMouseLeave={()=>setHover(0)}
                  style={{fontSize:"36px",background:"none",border:"none",cursor:"pointer",transition:"transform 0.15s",transform: (hover||rating)>=s ? "scale(1.2)" : "scale(1)",filter: (hover||rating)>=s ? "none" : "grayscale(1) opacity(0.3)"}}>⭐</button>
              ))}
            </div>
            <p style={{fontSize:"13px",color:"#999",marginTop:"8px"}}>{rating===1?"ضعیف":rating===2?"متوسط":rating===3?"خوب":rating===4?"خیلی خوب":rating===5?"عالی":"انتخاب کنید"}</p>
          </div>
          <div style={{marginBottom:"24px"}}>
            <label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"}}>نظر شما (اختیاری)</label>
            <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="مثلاً: حمل‌کننده خوش‌قول و دقیق بود. بار سالم تحویل شد." style={{width:"100%",padding:"14px 16px",border:"1px solid #e0e0e0",borderRadius:"10px",fontSize:"15px",outline:"none",fontFamily:"inherit",minHeight:"100px",resize:"vertical"}} />
          </div>
          {error && <div style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"16px",fontSize:"14px",border:"1px solid #fecaca"}}>{error}</div>}
          <button onClick={handleSubmit} disabled={loading||rating===0} style={{width:"100%",padding:"16px",background:rating>0?"linear-gradient(135deg,#f59e0b,#fbbf24)":"#e0e0e0",color:rating>0?"white":"#999",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",cursor:rating>0?"pointer":"not-allowed",boxShadow:rating>0?"0 4px 12px rgba(245,158,11,0.3)":"none"}}>{loading?"در حال ثبت...":"⭐ ثبت نظر"}</button>
        </div>
      </main>
    </div>
  );
}
