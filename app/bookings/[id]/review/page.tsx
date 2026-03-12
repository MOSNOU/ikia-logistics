"use client";
import { useState } from "react";
import { useParams } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { Navbar, Footer } from "@/components/Shared";
export default function ReviewPage() {
  const params = useParams();
  const supabase = getSupabase();
  const [rating, setRating] = useState(0);
  const [hover, setHover] = useState(0);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const ratingLabels = ["","ضعیف","متوسط","خوب","خیلی خوب","عالی"];
  const ratingColors = ["","#ef4444","#f59e0b","#06b6d4","#3b82f6","#10b981"];
  const handleSubmit = async () => {
    if (rating === 0) { setError("لطفاً امتیاز بدید"); return; }
    setLoading(true); setError("");
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً لاگین کنید"); setLoading(false); return; }
    const { data: booking } = await supabase.from("bookings").select("*").eq("id", params.id).single();
    if (!booking) { setError("رزرو پیدا نشد"); setLoading(false); return; }
    const { data: cargo } = await supabase.from("cargo_posts").select("shipper_id").eq("id", booking.cargo_post_id).single();
    const actualReviewee = user.id === cargo?.shipper_id ? booking.carrier_id : cargo?.shipper_id;
    const { error: e } = await supabase.from("reviews").insert({ booking_id: params.id, reviewer_id: user.id, reviewee_id: actualReviewee, rating, comment: comment || null });
    if (e) { if (e.code === "23505") setError("قبلاً نظر ثبت کردید"); else setError("خطا: " + e.message); }
    else setSuccess(true);
    setLoading(false);
  };
  if (success) return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar />
      <main style={{maxWidth:"520px",margin:"0 auto",padding:"60px 20px",textAlign:"center"}}>
        <div className="animate-scale" style={{background:"white",padding:"52px 32px",borderRadius:"24px",border:"1px solid #eee",boxShadow:"0 4px 25px rgba(0,0,0,0.06)"}}>
          <div style={{width:"88px",height:"88px",borderRadius:"50%",background:"linear-gradient(135deg,#ecfdf5,#d1fae5)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 20px",fontSize:"40px"}} className="animate-float">⭐</div>
          <h2 style={{fontSize:"24px",fontWeight:900,color:"#059669",marginBottom:"10px"}}>ممنون از نظرت!</h2>
          <p style={{color:"#666",fontSize:"15px",fontWeight:700,marginBottom:"28px"}}>نظر شما ثبت شد و به بهبود خدمات کمک می‌کنه</p>
          <div style={{display:"flex",gap:"10px",justifyContent:"center"}}>
            <Link href="/shipper" style={{padding:"12px 24px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",borderRadius:"12px",fontWeight:900,fontSize:"14px"}}>داشبورد بارفرست</Link>
            <Link href="/carrier" style={{padding:"12px 24px",background:"linear-gradient(135deg,#06b6d4,#0ea5e9)",color:"white",borderRadius:"12px",fontWeight:900,fontSize:"14px"}}>داشبورد حمل‌کننده</Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar />
      <main style={{maxWidth:"520px",margin:"0 auto",padding:"32px 20px"}}>
        <Link href={"/bookings/"+params.id} style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"#1e3a5f",fontSize:"13px",fontWeight:900,marginBottom:"20px"}}>→ بازگشت</Link>
        <div className="animate-fade" style={{background:"white",padding:"36px 32px",borderRadius:"24px",border:"1px solid #eee",boxShadow:"0 4px 25px rgba(0,0,0,0.06)"}}>
          <div style={{textAlign:"center",marginBottom:"32px"}}>
            <div style={{width:"68px",height:"68px",borderRadius:"50%",background:"linear-gradient(135deg,#fffbeb,#fef3c7)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"32px",border:"3px solid #f59e0b33"}}>⭐</div>
            <h1 style={{fontSize:"24px",fontWeight:900,color:"#1e3a5f"}}>ثبت نظر و امتیاز</h1>
            <p style={{color:"#888",fontSize:"14px",marginTop:"6px",fontWeight:700}}>تجربه‌ات رو با بقیه به اشتراک بذار</p>
          </div>
          <div style={{textAlign:"center",marginBottom:"32px"}}>
            <p style={{fontSize:"14px",color:"#444",marginBottom:"14px",fontWeight:900}}>امتیاز شما:</p>
            <div style={{display:"flex",justifyContent:"center",gap:"10px"}} dir="ltr">
              {[1,2,3,4,5].map(s=>(
                <button key={s} type="button" onClick={()=>setRating(s)} onMouseEnter={()=>setHover(s)} onMouseLeave={()=>setHover(0)}
                  style={{fontSize:"40px",background:"none",border:"none",cursor:"pointer",transition:"transform 0.2s",transform: (hover||rating)>=s ? "scale(1.25)" : "scale(1)",filter: (hover||rating)>=s ? "none" : "grayscale(1) opacity(0.25)"}}>⭐</button>
              ))}
            </div>
            {(hover||rating) > 0 && <p className="animate-fade" style={{fontSize:"15px",fontWeight:900,color:ratingColors[hover||rating],marginTop:"10px"}}>{ratingLabels[hover||rating]}</p>}
          </div>
          <div style={{marginBottom:"28px"}}>
            <label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>نظر شما (اختیاری)</label>
            <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="مثلاً: حمل‌کننده خوش‌قول و دقیق بود. بار سالم تحویل شد." className="input-field" style={{minHeight:"110px",resize:"vertical"}} />
          </div>
          {error && <div className="animate-scale" style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"16px",fontSize:"14px",fontWeight:700,border:"1px solid #fecaca"}}>{error}</div>}
          <button onClick={handleSubmit} disabled={loading||rating===0} style={{width:"100%",padding:"18px",background:rating>0?"linear-gradient(135deg,#f59e0b,#fbbf24)":"#e5e7eb",color:rating>0?"white":"#999",border:"none",borderRadius:"14px",fontSize:"17px",fontWeight:900,fontFamily:"inherit",cursor:rating>0?"pointer":"not-allowed",boxShadow:rating>0?"0 4px 15px rgba(245,158,11,0.35)":"none",transition:"all 0.3s"}}>{loading?"در حال ثبت...":"⭐ ثبت نظر"}</button>
        </div>
      </main>
      <Footer />
    </div>
  );
}
