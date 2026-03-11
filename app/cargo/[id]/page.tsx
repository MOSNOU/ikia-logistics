"use client";
export const dynamic = "force-dynamic";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
export default function CargoDetailPage() {
  const params = useParams();
  const router = useRouter();
  const supabase = getSupabase();
  const [cargo, setCargo] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [bookingPrice, setBookingPrice] = useState("");
  const [bookingMsg, setBookingMsg] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [bookings, setBookings] = useState<any[]>([]);
  const [userId, setUserId] = useState("");
  const [isOwner, setIsOwner] = useState(false);
  useEffect(() => {
    const load = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) setUserId(user.id);
      const { data } = await supabase.from("cargo_posts").select("*").eq("id", params.id).single();
      setCargo(data);
      if (data && user) setIsOwner(data.shipper_id === user.id);
      const { data: bks } = await supabase.from("bookings").select("*").eq("cargo_post_id", params.id);
      setBookings(bks || []);
      setLoading(false);
    };
    load();
  }, [params.id]);
  const handleBook = async () => {
    setError(""); setSubmitting(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً اول لاگین کنید"); setSubmitting(false); return; }
    const { error: e } = await supabase.from("bookings").insert({ cargo_post_id: params.id, carrier_id: user.id, proposed_price: bookingPrice ? parseInt(bookingPrice)*10 : null, carrier_message: bookingMsg || null, status: "pending" });
    if (e) setError("خطا: " + e.message); else setSuccess(true);
    setSubmitting(false);
  };
  const handleAccept = async (bookingId: string) => {
    await supabase.from("bookings").update({ status: "confirmed" }).eq("id", bookingId);
    await supabase.from("cargo_posts").update({ status: "matched" }).eq("id", params.id);
    router.refresh();
    window.location.reload();
  };
  const handleReject = async (bookingId: string) => {
    await supabase.from("bookings").update({ status: "rejected" }).eq("id", bookingId);
    window.location.reload();
  };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const statusLabels: Record<string,string> = { pending:"در انتظار",confirmed:"تأیید شده",rejected:"رد شده" };
  const statusColors: Record<string,string> = { pending:"#f59e0b",confirmed:"#10b981",rejected:"#ef4444" };
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"sans-serif"}}>در حال بارگذاری...</div>;
  if (!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"sans-serif"}}>بار پیدا نشد</div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between"}}><Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link><Link href="/cargo" style={{color:"#1B3A5C",textDecoration:"none"}}>← بازگشت</Link></nav>
      <main style={{maxWidth:"600px",margin:"0 auto",padding:"32px 16px"}}>
        <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",marginBottom:"16px"}}>
          <div style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>{cargo.origin_city} ← {cargo.dest_city}</div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"12px",marginBottom:"16px"}}>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>نوع بار</div><div style={{fontWeight:"bold"}}>{cargo.cargo_type}</div></div>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>خودرو</div><div style={{fontWeight:"bold"}}>{cargo.vehicle_type_needed}</div></div>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>وزن</div><div style={{fontWeight:"bold"}}>{cargo.weight_tons ? cargo.weight_tons+" تن" : "—"}</div></div>
            <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px"}}><div style={{fontSize:"12px",color:"#999"}}>تاریخ</div><div style={{fontWeight:"bold"}}>{cargo.pickup_date}</div></div>
          </div>
          {cargo.cargo_description && <div style={{background:"#f9fafb",padding:"12px",borderRadius:"8px",marginBottom:"16px"}}><div style={{fontSize:"12px",color:"#999"}}>توضیحات</div><div>{cargo.cargo_description}</div></div>}
          <div style={{fontSize:"24px",fontWeight:"bold",color:"#2E75B6",textAlign:"center",padding:"16px",background:"#e8f0fe",borderRadius:"12px"}}>{formatPrice(cargo.price_suggestion)}</div>
        </div>

        {isOwner ? (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <h2 style={{fontSize:"20px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>🤝 درخواست‌های حمل ({bookings.length})</h2>
            {bookings.length === 0 ? <p style={{color:"#999",textAlign:"center",padding:"20px"}}>هنوز کسی درخواست نداده</p> :
              bookings.map(b => (
                <div key={b.id} style={{border:"1px solid #eee",borderRadius:"12px",padding:"16px",marginBottom:"12px"}}>
                  <div style={{display:"flex",justifyContent:"space-between",marginBottom:"8px"}}>
                    <span style={{fontWeight:"bold"}}>قیمت پیشنهادی: {formatPrice(b.proposed_price)}</span>
                    <span style={{background:statusColors[b.status]||"#999",color:"white",padding:"2px 10px",borderRadius:"12px",fontSize:"13px"}}>{statusLabels[b.status]||b.status}</span>
                  </div>
                  {b.carrier_message && <p style={{color:"#666",fontSize:"14px",marginBottom:"8px"}}>💬 {b.carrier_message}</p>}
                  {b.status === "pending" && (
                    <div style={{display:"flex",gap:"8px"}}>
                      <button onClick={()=>handleAccept(b.id)} style={{flex:1,padding:"10px",background:"#10b981",color:"white",border:"none",borderRadius:"8px",cursor:"pointer",fontSize:"14px"}}>✅ تأیید</button>
                      <button onClick={()=>handleReject(b.id)} style={{flex:1,padding:"10px",background:"#ef4444",color:"white",border:"none",borderRadius:"8px",cursor:"pointer",fontSize:"14px"}}>❌ رد</button>
                    </div>
                  )}
                </div>
              ))
            }
          </div>
        ) : (
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <h2 style={{fontSize:"20px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"16px"}}>🚛 درخواست حمل این بار</h2>
            {success ? (
              <div style={{textAlign:"center",padding:"20px"}}>
                <div style={{fontSize:"48px",marginBottom:"12px"}}>✅</div>
                <h3 style={{color:"#10b981",fontSize:"18px"}}>درخواست شما ثبت شد!</h3>
                <p style={{color:"#666",fontSize:"14px"}}>بارفرست بررسی می‌کنه و بهت خبر می‌ده</p>
                <Link href="/cargo" style={{display:"inline-block",marginTop:"16px",padding:"10px 20px",background:"#1B3A5C",color:"white",borderRadius:"8px",textDecoration:"none"}}>بازگشت به لیست</Link>
              </div>
            ) : (
              <>
                <div style={{marginBottom:"16px"}}>
                  <label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>قیمت پیشنهادی شما (تومان)</label>
                  <input type="number" value={bookingPrice} onChange={e=>setBookingPrice(e.target.value)} placeholder="مثلاً ۱۲۰۰۰۰۰۰" style={{width:"100%",padding:"12px",border:"1px solid #ddd",borderRadius:"8px",direction:"ltr"}} />
                </div>
                <div style={{marginBottom:"16px"}}>
                  <label style={{display:"block",marginBottom:"4px",fontSize:"14px",fontWeight:"bold"}}>پیام به بارفرست</label>
                  <textarea value={bookingMsg} onChange={e=>setBookingMsg(e.target.value)} placeholder="مثلاً: ناوگان آماده‌ست، فردا می‌تونم بارگیری کنم" style={{width:"100%",padding:"12px",border:"1px solid #ddd",borderRadius:"8px",minHeight:"80px"}} />
                </div>
                {error && <div style={{background:"#fee",color:"#c00",padding:"10px",borderRadius:"8px",marginBottom:"16px",fontSize:"14px"}}>{error}</div>}
                <button onClick={handleBook} disabled={submitting} style={{width:"100%",padding:"14px",background:"#10b981",color:"white",border:"none",borderRadius:"8px",fontSize:"16px",cursor:"pointer"}}>{submitting ? "در حال ثبت..." : "🤝 ارسال درخواست حمل"}</button>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
