"use client";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
const CL: Record<string,string> = {general:"بار عمومی",construction:"مصالح ساختمانی",food:"مواد غذایی",agricultural:"کشاورزی",industrial:"صنعتی",fragile:"شکستنی",refrigerated:"یخچالی",machinery:"ماشین‌آلات"};
const VL: Record<string,string> = {truck_small:"کامیونت",truck_large:"کامیون",trailer:"تریلر",refrigerated:"یخچال‌دار",flatbed:"کفی",container:"کانتینر"};
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
    const { error: e } = await supabase.from("bookings").insert({cargo_post_id:params.id,carrier_id:user.id,proposed_price:bookingPrice?parseInt(bookingPrice)*10:null,carrier_message:bookingMsg||null,status:"pending"});
    if (e) setError("خطا: "+e.message); else setSuccess(true);
    setSubmitting(false);
  };
  const handleAccept = async (bid: string) => { await supabase.from("bookings").update({status:"confirmed"}).eq("id",bid); await supabase.from("cargo_posts").update({status:"matched"}).eq("id",params.id); window.location.reload(); };
  const handleReject = async (bid: string) => { await supabase.from("bookings").update({status:"rejected"}).eq("id",bid); window.location.reload(); };
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  const SL: Record<string,string> = {pending:"در انتظار",confirmed:"تأیید شده",rejected:"رد شده"};
  const SC: Record<string,string> = {pending:"#f59e0b",confirmed:"#10b981",rejected:"#ef4444"};
  const S: React.CSSProperties = {width:"100%",padding:"14px 16px",border:"1px solid #e0e0e0",borderRadius:"10px",fontSize:"15px",outline:"none",fontFamily:"inherit",background:"white"};
  if (loading) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif"}}><div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:"4px solid #3C3B6E",borderRadius:"50%",animation:"spin 1s linear infinite"}} /><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style></div>;
  if (!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"#999"}}>بار پیدا نشد</div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <Link href="/cargo" style={{color:"#3C3B6E",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>→ بازگشت به لیست</Link>
      </nav>
      <main style={{maxWidth:"700px",margin:"0 auto",padding:"32px 20px"}}>
        <div style={{background:"white",padding:"28px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)",marginBottom:"20px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"20px",paddingBottom:"16px",borderBottom:"1px solid #f0f0f0"}}>
            <div style={{display:"flex",alignItems:"center",gap:"8px"}}><span style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E"}}>{cargo.origin_city}</span><span style={{color:"#2E75B6",fontSize:"20px"}}>←</span><span style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E"}}>{cargo.dest_city}</span></div>
            <span style={{background:"#e8f0fe",color:"#3C3B6E",padding:"6px 16px",borderRadius:"20px",fontSize:"13px",fontWeight:"bold"}}>{CL[cargo.cargo_type]||cargo.cargo_type}</span>
          </div>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"12px",marginBottom:"20px"}}>
            {[{l:"نوع خودرو",v:VL[cargo.vehicle_type_needed]||cargo.vehicle_type_needed,i:"🚛"},{l:"وزن",v:cargo.weight_tons?cargo.weight_tons+" تن":"نامشخص",i:"⚖️"},{l:"تاریخ بارگیری",v:cargo.pickup_date,i:"📅"},{l:"وضعیت",v:cargo.status==="open"?"باز":"در حال حمل",i:"📊"}].map((x,i)=>(
              <div key={i} style={{background:"#f8fafc",padding:"14px",borderRadius:"10px",display:"flex",alignItems:"center",gap:"10px"}}>
                <span style={{fontSize:"20px"}}>{x.i}</span>
                <div><div style={{fontSize:"11px",color:"#999"}}>{x.l}</div><div style={{fontSize:"14px",fontWeight:"bold",color:"#333"}}>{x.v}</div></div>
              </div>
            ))}
          </div>
          {cargo.cargo_description && <div style={{background:"#f8fafc",padding:"14px",borderRadius:"10px",marginBottom:"20px"}}><div style={{fontSize:"11px",color:"#999",marginBottom:"4px"}}>توضیحات</div><div style={{fontSize:"14px",color:"#333"}}>{cargo.cargo_description}</div></div>}
          <div style={{background:"linear-gradient(135deg,#eff6ff,#dbeafe)",padding:"20px",borderRadius:"12px",textAlign:"center"}}><div style={{fontSize:"13px",color:"#3C3B6E",marginBottom:"4px"}}>قیمت پیشنهادی</div><div style={{fontSize:"28px",fontWeight:"bold",color:"#2E75B6"}}>{formatPrice(cargo.price_suggestion)}</div></div>
        </div>
        {isOwner ? (
          <div style={{background:"white",padding:"28px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <h2 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"16px",display:"flex",alignItems:"center",gap:"8px"}}>🤝 درخواست‌های حمل <span style={{background:"#e8f0fe",color:"#3C3B6E",padding:"2px 10px",borderRadius:"20px",fontSize:"13px"}}>{bookings.length}</span></h2>
            {bookings.length === 0 ? <div style={{textAlign:"center",padding:"32px",color:"#999"}}><div style={{fontSize:"32px",marginBottom:"8px"}}>⏳</div><p>هنوز کسی درخواست نداده. صبر کن!</p></div> :
              bookings.map(b => (
                <div key={b.id} style={{border:"1px solid #eee",borderRadius:"12px",padding:"18px",marginBottom:"12px",background:"#f8fafc"}}>
                  <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"10px"}}>
                    <span style={{fontWeight:"bold",color:"#3C3B6E"}}>💰 {formatPrice(b.proposed_price)}</span>
                    <span style={{background:SC[b.status]||"#999",color:"white",padding:"4px 14px",borderRadius:"20px",fontSize:"12px",fontWeight:"bold"}}>{SL[b.status]||b.status}</span>
                  </div>
                  {b.carrier_message && <p style={{color:"#666",fontSize:"14px",marginBottom:"12px",background:"white",padding:"10px",borderRadius:"8px"}}>💬 {b.carrier_message}</p>}
                  {b.status === "pending" && (
                    <div style={{display:"flex",gap:"8px"}}>
                      <button onClick={()=>handleAccept(b.id)} style={{flex:1,padding:"12px",background:"linear-gradient(135deg,#059669,#10b981)",color:"white",border:"none",borderRadius:"10px",fontSize:"14px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer"}}>✅ تأیید</button>
                      <button onClick={()=>handleReject(b.id)} style={{flex:1,padding:"12px",background:"#fef2f2",color:"#ef4444",border:"1px solid #fecaca",borderRadius:"10px",fontSize:"14px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer"}}>❌ رد</button>
                    </div>
                  )}
                </div>
              ))
            }
          </div>
        ) : (
          <div style={{background:"white",padding:"28px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <h2 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"20px"}}>🚛 درخواست حمل این بار</h2>
            {success ? (
              <div style={{textAlign:"center",padding:"32px"}}>
                <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"#ecfdf5",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"28px"}}>✅</div>
                <h3 style={{color:"#059669",fontSize:"18px",marginBottom:"8px"}}>درخواست شما ثبت شد!</h3>
                <p style={{color:"#888",fontSize:"14px"}}>بارفرست بررسی می‌کنه و بهت خبر می‌ده</p>
                <Link href="/cargo" style={{display:"inline-block",marginTop:"16px",padding:"10px 24px",background:"#3C3B6E",color:"white",borderRadius:"8px",textDecoration:"none",fontWeight:"bold",fontSize:"14px"}}>بازگشت به لیست</Link>
              </div>
            ) : (
              <>
                <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"}}>قیمت پیشنهادی شما (تومان)</label><input type="number" value={bookingPrice} onChange={e=>setBookingPrice(e.target.value)} placeholder="مثلاً ۱۲,۰۰۰,۰۰۰" dir="ltr" style={S} /></div>
                <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:"bold",color:"#555"}}>پیام به بارفرست</label><textarea value={bookingMsg} onChange={e=>setBookingMsg(e.target.value)} placeholder="مثلاً: ناوگان آماده‌ست، فردا بارگیری می‌کنم" style={{...S,minHeight:"90px"}} /></div>
                {error && <div style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"16px",fontSize:"14px",border:"1px solid #fecaca"}}>{error}</div>}
                <button onClick={handleBook} disabled={submitting} style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#059669,#10b981)",color:"white",border:"none",borderRadius:"12px",fontSize:"16px",fontWeight:"bold",fontFamily:"inherit",cursor:"pointer",boxShadow:"0 4px 12px rgba(5,150,105,0.3)"}}>{submitting?"در حال ثبت...":"🤝 ارسال درخواست حمل"}</button>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
