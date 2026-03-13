"use client";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";
import { DashboardLayout } from "@/components/Sidebar";
import { Loading } from "@/components/Shared";
import { RouteMap } from "@/components/Map";
const CL: Record<string,string> = {general:"بار عمومی",construction:"مصالح ساختمانی",food:"مواد غذایی",agricultural:"کشاورزی",industrial:"صنعتی",fragile:"شکستنی",refrigerated:"یخچالی",machinery:"ماشین‌آلات"};
const VL: Record<string,string> = {truck_small:"کامیونت",truck_large:"کامیون",trailer:"تریلر",refrigerated:"یخچال‌دار",flatbed:"کفی",container:"کانتینر"};
export default function CargoDetailPage() {
  const params = useParams();
  const router = useRouter();
  const supabase = getSupabase();
  const [cargo, setCargo] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
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
      if (!user) { router.push("/login"); return; }
      const { data: p } = await supabase.from("profiles").select("*").eq("id", user.id).single();
      setProfile(p);
      const { data } = await supabase.from("cargo_posts").select("*").eq("id", params.id).single();
      setCargo(data);
      if (data && user) setIsOwner(data.shipper_id === user.id);
      const { data: bks } = await supabase.from("bookings").select("*").eq("cargo_post_id", params.id);
      setBookings(bks || []);
      setLoading(false);
    }; load();
  }, [params.id]);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const handleBook = async () => {
    setError(""); setSubmitting(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setError("لطفاً لاگین کنید"); setSubmitting(false); return; }
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
  if (!cargo) return <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",color:"var(--text3)",fontWeight:900}}>بار پیدا نشد</div>;
  return (
    <DashboardLayout role={profile?.role||"shipper"} name={profile?.full_name} onSignOut={handleSignOut}>
      <div style={{maxWidth:"700px"}}>
        <Link href="/cargo" style={{display:"inline-flex",alignItems:"center",gap:"6px",color:"var(--accent)",fontSize:"13px",fontWeight:900,marginBottom:"16px"}}>→ بازگشت به لیست</Link>
        <div className="card animate-fade" style={{padding:"24px",marginBottom:"18px"}}>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"18px",paddingBottom:"14px",borderBottom:"2px solid var(--border)",flexWrap:"wrap",gap:"8px"}}>
            <div style={{display:"flex",alignItems:"center",gap:"10px"}}><span style={{fontSize:"22px",fontWeight:900,color:"var(--text)"}}>{cargo.origin_city}</span><span style={{color:"var(--accent)",fontSize:"20px",fontWeight:900}}>←</span><span style={{fontSize:"22px",fontWeight:900,color:"var(--text)"}}>{cargo.dest_city}</span></div>
            <span className="badge" style={{background:"var(--bg3)",color:"var(--text)"}}>{CL[cargo.cargo_type]||cargo.cargo_type}</span>
          </div>
          <div style={{marginBottom:"18px"}}><RouteMap origin={cargo.origin_city} destination={cargo.dest_city} height="260px" /></div>
          <div className="detail-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"10px",marginBottom:"18px"}}>
            {[{l:"نوع خودرو",v:VL[cargo.vehicle_type_needed]||cargo.vehicle_type_needed,i:"🚛"},{l:"وزن",v:cargo.weight_tons?cargo.weight_tons+" تن":"نامشخص",i:"⚖️"},{l:"تاریخ بارگیری",v:cargo.pickup_date,i:"📅"},{l:"وضعیت",v:cargo.status==="open"?"باز":"در حال حمل",i:"📊"}].map((x,i)=>(
              <div key={i} style={{background:"var(--bg3)",padding:"12px",borderRadius:"12px",display:"flex",alignItems:"center",gap:"10px"}}>
                <span style={{fontSize:"18px"}}>{x.i}</span>
                <div><div style={{fontSize:"11px",color:"var(--text3)",fontWeight:900}}>{x.l}</div><div style={{fontSize:"14px",fontWeight:900,color:"var(--text)"}}>{x.v}</div></div>
              </div>
            ))}
          </div>
          {cargo.cargo_description && <div style={{background:"var(--bg3)",padding:"14px",borderRadius:"12px",marginBottom:"18px"}}><div style={{fontSize:"11px",color:"var(--text3)",fontWeight:900,marginBottom:"4px"}}>توضیحات</div><div style={{fontSize:"14px",color:"var(--text2)",fontWeight:700,lineHeight:"1.8"}}>{cargo.cargo_description}</div></div>}
          <div style={{background:"var(--bg3)",padding:"20px",borderRadius:"14px",textAlign:"center",border:"2px solid var(--border)"}}><div style={{fontSize:"12px",color:"var(--accent)",fontWeight:900,marginBottom:"4px"}}>قیمت پیشنهادی</div><div style={{fontSize:"28px",fontWeight:900,color:"var(--accent)"}}>{formatPrice(cargo.price_suggestion)}</div></div>
        </div>
        {isOwner ? (
          <div className="card animate-fade-up" style={{padding:"24px"}}>
            <h2 style={{fontSize:"17px",fontWeight:900,color:"var(--text)",marginBottom:"16px",display:"flex",alignItems:"center",gap:"8px"}}>🤝 درخواست‌ها <span className="badge" style={{background:"var(--bg3)",color:"var(--text)"}}>{bookings.length}</span></h2>
            {bookings.length === 0 ? <div style={{textAlign:"center",padding:"32px",color:"var(--text3)"}}><div style={{fontSize:"32px",marginBottom:"8px"}}>⏳</div><p style={{fontWeight:700}}>هنوز درخواستی نیست</p></div> :
              bookings.map(b => (
                <div key={b.id} className="animate-fade" style={{border:"2px solid var(--border)",borderRadius:"14px",padding:"18px",marginBottom:"10px",background:"var(--bg3)"}}>
                  <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"10px",flexWrap:"wrap",gap:"8px"}}>
                    <span style={{fontWeight:900,color:"var(--text)",fontSize:"15px"}}>💰 {formatPrice(b.proposed_price)}</span>
                    <span className="badge" style={{background:SC[b.status]||"#999",color:"white"}}>{SL[b.status]||b.status}</span>
                  </div>
                  {b.carrier_message && <p style={{color:"var(--text2)",fontSize:"13px",fontWeight:700,marginBottom:"12px",background:"var(--bg2)",padding:"10px",borderRadius:"10px",lineHeight:"1.8"}}>💬 {b.carrier_message}</p>}
                  {b.status === "pending" && (
                    <div style={{display:"flex",gap:"10px"}}>
                      <button onClick={()=>handleAccept(b.id)} className="btn-success" style={{flex:1,padding:"12px",fontSize:"14px",fontFamily:"inherit",borderRadius:"10px"}}>✅ تأیید</button>
                      <button onClick={()=>handleReject(b.id)} style={{flex:1,padding:"12px",background:"var(--bg2)",color:"var(--danger)",border:"2px solid var(--danger)",borderRadius:"10px",fontSize:"14px",fontWeight:900,fontFamily:"inherit",cursor:"pointer"}}>❌ رد</button>
                    </div>
                  )}
                </div>
              ))
            }
          </div>
        ) : (
          <div className="card animate-fade-up" style={{padding:"24px"}}>
            <h2 style={{fontSize:"17px",fontWeight:900,color:"var(--text)",marginBottom:"20px"}}>🚛 درخواست حمل</h2>
            {success ? (
              <div style={{textAlign:"center",padding:"32px"}} className="animate-scale">
                <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"28px"}}>✅</div>
                <h3 style={{color:"var(--success)",fontSize:"17px",fontWeight:900,marginBottom:"8px"}}>درخواست ثبت شد!</h3>
                <p style={{color:"var(--text3)",fontSize:"13px",fontWeight:700}}>بارفرست بررسی می‌کنه</p>
                <Link href="/cargo" className="btn-primary" style={{display:"inline-block",marginTop:"14px",padding:"10px 24px",fontSize:"14px"}}>بازگشت</Link>
              </div>
            ) : (
              <>
                <div style={{marginBottom:"16px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>قیمت پیشنهادی (تومان)</label><input type="number" value={bookingPrice} onChange={e=>setBookingPrice(e.target.value)} placeholder="۱۲۰۰۰۰۰۰" dir="ltr" className="input-field" /></div>
                <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"var(--text2)"}}>پیام</label><textarea value={bookingMsg} onChange={e=>setBookingMsg(e.target.value)} placeholder="مثلاً: ناوگان آماده‌ست" className="input-field" style={{minHeight:"80px"}} /></div>
                {error && <div style={{background:"var(--bg3)",color:"var(--danger)",padding:"12px",borderRadius:"10px",marginBottom:"14px",fontSize:"14px",fontWeight:700}}>{error}</div>}
                <button onClick={handleBook} disabled={submitting} className="btn-success" style={{width:"100%",padding:"16px",fontSize:"16px",fontFamily:"inherit",borderRadius:"12px"}}>{submitting?"در حال ثبت...":"🤝 ارسال درخواست"}</button>
              </>
            )}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
