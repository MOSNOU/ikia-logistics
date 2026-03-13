"use client";
import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { DashboardLayout } from "@/components/Sidebar";
export default function ReviewPage() {
  const params = useParams();
  const router = useRouter();
  const supabase = getSupabase();
  const [profile, setProfile] = useState<any>(null);
  const [rating, setRating] = useState(0);
  const [hover, setHover] = useState(0);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [pageLoading, setPageLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  useEffect(() => {
    const f = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p); setPageLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const ratingLabels = ["","ضعیف","متوسط","خوب","خیلی خوب","عالی"];
  const ratingColors = ["","#ef4444","#f59e0b","#06b6d4","#3b82f6","#10b981"];
  const handleSubmit = async () => {
    if (rating === 0) { setError("امتیاز بدید"); return; }
    setLoading(true); setError("");
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لاگین کنید"); setLoading(false); return; }
    const { data: booking } = await supabase.from("bookings").select("*").eq("id", params.id).single();
    if (!booking) { setError("رزرو پیدا نشد"); setLoading(false); return; }
    const { data: cargo } = await supabase.from("cargo_posts").select("shipper_id").eq("id", booking.cargo_post_id).single();
    const reviewee = user.id === cargo?.shipper_id ? booking.carrier_id : cargo?.shipper_id;
    const { error: e } = await supabase.from("reviews").insert({booking_id:params.id,reviewer_id:user.id,reviewee_id:reviewee,rating,comment:comment||null});
    if (e) { if (e.code==="23505") setError("قبلاً ثبت شده"); else setError("خطا: "+e.message); }
    else setSuccess(true);
    setLoading(false);
  };
  if (pageLoading) return null;
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <div style={{maxWidth:"500px"}}>
        <Link href={"/bookings/"+params.id} style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"var(--accent)",fontSize:"13px",fontWeight:900,marginBottom:"16px"}}>→ بازگشت</Link>
        {success ? (
          <div className="card animate-scale" style={{padding:"48px 24px",textAlign:"center"}}>
            <div style={{width:"72px",height:"72px",borderRadius:"50%",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"36px"}} className="animate-float">⭐</div>
            <h2 style={{fontSize:"22px",fontWeight:900,color:"var(--success)",marginBottom:"10px"}}>ممنون از نظرت!</h2>
            <p style={{color:"var(--text3)",fontSize:"14px",fontWeight:700,marginBottom:"24px"}}>نظر شما ثبت شد</p>
            <div style={{display:"flex",gap:"10px",justifyContent:"center"}}>
              <Link href="/shipper" className="btn-primary" style={{padding:"10px 20px",fontSize:"14px"}}>داشبورد بارفرست</Link>
              <Link href="/carrier" style={{padding:"10px 20px",fontSize:"14px",background:"var(--bg3)",color:"var(--accent)",borderRadius:"12px",fontWeight:900}}>داشبورد حمل‌کننده</Link>
            </div>
          </div>
        ) : (
          <div className="card animate-fade" style={{padding:"32px"}}>
            <div style={{textAlign:"center",marginBottom:"28px"}}>
              <div style={{width:"60px",height:"60px",borderRadius:"50%",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 12px",fontSize:"28px"}}>⭐</div>
              <h1 style={{fontSize:"22px",fontWeight:900,color:"var(--text)"}}>ثبت نظر</h1>
              <p style={{color:"var(--text3)",fontSize:"13px",marginTop:"4px",fontWeight:700}}>تجربه‌ات رو به اشتراک بذار</p>
            </div>
            <div style={{textAlign:"center",marginBottom:"28px"}}>
              <p style={{fontSize:"14px",color:"var(--text2)",marginBottom:"12px",fontWeight:900}}>امتیاز:</p>
              <div style={{display:"flex",justifyContent:"center",gap:"8px"}} dir="ltr">
                {[1,2,3,4,5].map(s=>(
                  <button key={s} type="button" onClick={()=>setRating(s)} onMouseEnter={()=>setHover(s)} onMouseLeave={()=>setHover(0)}
                    style={{fontSize:"36px",background:"none",border:"none",cursor:"pointer",transition:"transform 0.2s",transform:(hover||rating)>=s?"scale(1.25)":"scale(1)",filter:(hover||rating)>=s?"none":"grayscale(1) opacity(0.25)"}}>⭐</button>
                ))}
              </div>
              {(hover||rating)>0 && <p className="animate-fade" style={{fontSize:"14px",fontWeight:900,color:ratingColors[hover||rating],marginTop:"8px"}}>{ratingLabels[hover||rating]}</p>}
            </div>
            <div style={{marginBottom:"24px"}}>
              <label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>نظر (اختیاری)</label>
              <textarea value={comment} onChange={e=>setComment(e.target.value)} placeholder="مثلاً: حمل‌کننده خوش‌قول بود" className="input-field" style={{minHeight:"100px"}} />
            </div>
            {error && <div style={{background:"var(--bg3)",color:"var(--danger)",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700}}>{error}</div>}
            <button onClick={handleSubmit} disabled={loading||rating===0} style={{width:"100%",padding:"16px",background:rating>0?"linear-gradient(135deg,#f59e0b,#fbbf24)":"var(--bg3)",color:rating>0?"white":"var(--text3)",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:900,fontFamily:"inherit",cursor:rating>0?"pointer":"not-allowed"}}>{loading?"در حال ثبت...":"⭐ ثبت نظر"}</button>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
