"use client";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { Navbar, Footer, Loading } from "@/components/Shared";
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
  const [isOwner, setIsOwner] = useState(false);
  useEffect(() => {
    const load = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      const { data } = await supabase.from("cargo_posts").select("*").eq("id", params.id).single();
      setCargo(data);
      if (data && user) setIsOwner(data.shipper_id === user.id);
      const { data: bks } = await supabase.from("bookings").select("*").eq("cargo_post_id", params.id);
      setBookings(bks || []);
      setLoading(false);
    }; load();
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
  if (loading) return <Loading />;
  if (!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"#999",fontWeight:900}}>بار پیدا نشد</div>;
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"#f4f6f9",color:"#333"}}>
      <Navbar />
      <main style={{maxWidth:"720px",margin:"0 auto",padding:"32px 20px"}}>
        <Link href="/cargo" style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"#1e3a5f",fontSize:"13px",fontWeight:900,marginBottom:"20px"}}>→ بازگشت به لیست</Link>
        <div className="animate-fade" style={{background:"white",padding:"28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",marginBottom:"20px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"24px",paddingBottom:"18px",borderBottom:"2px solid #f0f4ff"}}>
            <div style={{display:"flex",alignItems:"center",gap:"10px"}}><span style={{fontSize:"26px",fontWeight:900,color:"#1e3a5f"}}>{cargo.origin_city}</span><span style={{color:"#06b6d4",fontSize:"22px",fontWeight:900}}>←</span><span style={{fontSize:"26px",fontWeight:900,color:"#1e3a5f"}}>{cargo.dest_city}</span></div>
            <span className="badge" style={{background:"#f0f4ff",color:"#1e3a5f",fontSize:"13px",fontWeight:900,padding:"6px 16px"}}>{CL[cargo.cargo_type]||cargo.cargo_type}</span>
          </div>
          <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"12px",marginBottom:"20px"}}>
            {[{l:"نوع خودرو",v:VL[cargo.vehicle_type_needed]||cargo.vehicle_type_needed,i:"🚛",bg:"#ecfeff"},{l:"وزن",v:cargo.weight_tons?cargo.weight_tons+" تن":"نامشخص",i:"⚖️",bg:"#fffbeb"},{l:"تاریخ بارگیری",v:cargo.pickup_date,i:"📅",bg:"#ecfdf5"},{l:"وضعیت",v:cargo.status==="open"?"باز":"در حال حمل",i:"📊",bg:"#f0f4ff"}].map((x,i)=>(
              <div key={i} style={{background:x.bg,padding:"16px",borderRadius:"12px",display:"flex",alignItems:"center",gap:"12px"}}>
                <span style={{fontSize:"22px"}}>{x.i}</span>
                <div><div style={{fontSize:"11px",color:"#888",fontWeight:900}}>{x.l}</div><div style={{fontSize:"15px",fontWeight:900,color:"#1e3a5f"}}>{x.v}</div></div>
              </div>
            ))}
          </div>
          {cargo.cargo_description && <div style={{background:"#f8fafc",padding:"16px",borderRadius:"12px",marginBottom:"20px"}}><div style={{fontSize:"11px",color:"#888",fontWeight:900,marginBottom:"4px"}}>توضیحات</div><div style={{fontSize:"14px",color:"#333",fontWeight:700,lineHeight:"1.8"}}>{cargo.cargo_description}</div></div>}
          <div style={{background:"linear-gradient(135deg,#ecfeff,#e0f2fe)",padding:"24px",borderRadius:"14px",textAlign:"center",border:"2px solid #06b6d422"}}><div style={{fontSize:"13px",color:"#0e7490",fontWeight:900,marginBottom:"4px"}}>قیمت پیشنهادی</div><div style={{fontSize:"32px",fontWeight:900,color:"#0ea5e9"}}>{formatPrice(cargo.price_suggestion)}</div></div>
        </div>
        {isOwner ? (
          <div className="animate-fade-up" style={{background:"white",padding:"28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
            <h2 style={{fontSize:"18px",fontWeight:900,color:"#1e3a5f",marginBottom:"18px",display:"flex",alignItems:"center",gap:"8px"}}>🤝 درخواست‌های حمل <span className="badge" style={{background:"#f0f4ff",color:"#1e3a5f"}}>{bookings.length}</span></h2>
            {bookings.length === 0 ? <div style={{textAlign:"center",padding:"36px",color:"#999"}}><div style={{fontSize:"36px",marginBottom:"8px"}}>⏳</div><p style={{fontWeight:700}}>هنوز کسی درخواست نداده. صبر کن!</p></div> :
              bookings.map(b => (
                <div key={b.id} className="animate-fade" style={{border:"2px solid #eee",borderRadius:"14px",padding:"20px",marginBottom:"12px",background:"#f8fafc"}}>
                  <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}>
                    <span style={{fontWeight:900,color:"#1e3a5f",fontSize:"16px"}}>💰 {formatPrice(b.proposed_price)}</span>
                    <span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span>
                  </div>
                  {b.carrier_message && <p style={{color:"#555",fontSize:"14px",fontWeight:700,marginBottom:"14px",background:"white",padding:"12px",borderRadius:"10px",lineHeight:"1.8"}}>💬 {b.carrier_message}</p>}
                  {b.status === "pending" && (
                    <div style={{display:"flex",gap:"10px"}}>
                      <button onClick={()=>handleAccept(b.id)} className="btn-success" style={{flex:1,padding:"14px",fontSize:"14px",fontFamily:"inherit",borderRadius:"12px"}}>✅ تأیید</button>
                      <button onClick={()=>handleReject(b.id)} style={{flex:1,padding:"14px",background:"#fef2f2",color:"#ef4444",border:"2px solid #fecaca",borderRadius:"12px",fontSize:"14px",fontWeight:900,fontFamily:"inherit",cursor:"pointer"}}>❌ رد</button>
                    </div>
                  )}
                </div>
              ))
            }
          </div>
        ) : (
          <div className="animate-fade-up" style={{background:"white",padding:"28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
            <h2 style={{fontSize:"18px",fontWeight:900,color:"#1e3a5f",marginBottom:"22px"}}>🚛 درخواست حمل این بار</h2>
            {success ? (
              <div style={{textAlign:"center",padding:"36px"}} className="animate-scale">
                <div style={{width:"72px",height:"72px",borderRadius:"50%",background:"#ecfdf5",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"32px"}}>✅</div>
                <h3 style={{color:"#059669",fontSize:"18px",fontWeight:900,marginBottom:"8px"}}>درخواست شما ثبت شد!</h3>
                <p style={{color:"#888",fontSize:"14px",fontWeight:700}}>بارفرست بررسی می‌کنه و بهت خبر می‌ده</p>
                <Link href="/cargo" style={{display:"inline-block",marginTop:"16px",padding:"12px 28px",background:"#1e3a5f",color:"white",borderRadius:"10px",fontWeight:900,fontSize:"14px"}}>بازگشت به لیست</Link>
              </div>
            ) : (
              <>
                <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>قیمت پیشنهادی شما (تومان)</label><input type="number" value={bookingPrice} onChange={e=>setBookingPrice(e.target.value)} placeholder="مثلاً ۱۲,۰۰۰,۰۰۰" dir="ltr" className="input-field" /></div>
                <div style={{marginBottom:"22px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>پیام به بارفرست</label><textarea value={bookingMsg} onChange={e=>setBookingMsg(e.target.value)} placeholder="مثلاً: ناوگان آماده‌ست، فردا بارگیری می‌کنم" className="input-field" style={{minHeight:"90px"}} /></div>
                {error && <div className="animate-scale" style={{background:"#fef2f2",color:"#dc2626",padding:"12px",borderRadius:"10px",marginBottom:"16px",fontSize:"14px",fontWeight:700,border:"1px solid #fecaca"}}>{error}</div>}
                <button onClick={handleBook} disabled={submitting} className="btn-success" style={{width:"100%",padding:"18px",fontSize:"17px",fontFamily:"inherit",borderRadius:"14px",boxShadow:"0 4px 15px rgba(5,150,105,0.3)"}}>{submitting?"در حال ثبت...":"🤝 ارسال درخواست حمل"}</button>
              </>
            )}
          </div>
        )}
      </main>
      <Footer />
    </div>
  );
}
