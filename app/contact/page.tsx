"use client";
import { useState } from "react";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";
import { Footer } from "@/components/Shared";
export default function ContactPage() {
  const [form, setForm] = useState({ name: "", email: "", phone: "", subject: "", message: "" });
  const [sent, setSent] = useState(false);
  const handleSubmit = (e: React.FormEvent) => { e.preventDefault(); setSent(true); };
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav className="nav-responsive animate-slide-down" style={{padding:"14px 24px",background:"rgba(255,255,255,0.95)",backdropFilter:"blur(10px)",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"8px"}}>
          <Link href="/about" style={{padding:"10px 18px",borderRadius:"10px",fontSize:"13px",fontWeight:900,color:"#1e3a5f",border:"2px solid #e0e0e0"}}>درباره ما</Link>
          <Link href="/login" className="btn-primary" style={{padding:"10px 18px",fontSize:"13px"}}>ورود</Link>
        </div>
      </nav>

      <section style={{background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",color:"white",padding:"48px 24px",textAlign:"center",position:"relative"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 30%, rgba(6,182,212,0.15) 0%, transparent 60%)",pointerEvents:"none"}} />
        <div className="animate-fade-up" style={{position:"relative",zIndex:1}}>
          <h1 style={{fontSize:"30px",fontWeight:900,marginBottom:"10px"}}>📞 تماس با ما</h1>
          <p style={{fontSize:"15px",fontWeight:700,opacity:0.8}}>سوال، پیشنهاد یا همکاری — ما آماده شنیدن هستیم</p>
        </div>
      </section>

      <section className="section-padding" style={{padding:"48px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"24px"}}>
          <div className="animate-fade">
            <h2 style={{fontSize:"20px",fontWeight:900,color:"#1e3a5f",marginBottom:"24px"}}>راه‌های ارتباطی</h2>
            {[
              {icon:"📞",title:"تلفن",value:"۰۲۱-۱۲۳۴۵۶۷۸",desc:"شنبه تا پنجشنبه، ۹ صبح تا ۶ عصر",bg:"#ecfeff",color:"#0ea5e9"},
              {icon:"📧",title:"ایمیل",value:"info@ikia-logistics.ir",desc:"پاسخ در کمتر از ۲۴ ساعت",bg:"#f0f4ff",color:"#3b82f6"},
              {icon:"📍",title:"آدرس",value:"تهران، خیابان ولیعصر",desc:"دفتر مرکزی iKIA Logistics",bg:"#ecfdf5",color:"#10b981"},
              {icon:"💬",title:"پشتیبانی آنلاین",value:"از داخل پلتفرم",desc:"۲۴ ساعته، ۷ روز هفته",bg:"#fffbeb",color:"#f59e0b"},
            ].map((c,i)=>(
              <div key={i} className="card-hover animate-fade" style={{background:"white",padding:"20px",borderRadius:"14px",border:"1px solid #eee",marginBottom:"12px",display:"flex",gap:"14px",alignItems:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",animationDelay:`${i*80}ms`}}>
                <div style={{width:"48px",height:"48px",borderRadius:"12px",background:c.bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px",flexShrink:0}}>{c.icon}</div>
                <div>
                  <div style={{fontSize:"14px",fontWeight:900,color:"#1e3a5f"}}>{c.title}</div>
                  <div style={{fontSize:"14px",fontWeight:700,color:c.color}} dir="ltr">{c.value}</div>
                  <div style={{fontSize:"12px",color:"#999",fontWeight:700}}>{c.desc}</div>
                </div>
              </div>
            ))}
          </div>

          <div className="animate-fade-up">
            <h2 style={{fontSize:"20px",fontWeight:900,color:"#1e3a5f",marginBottom:"24px"}}>فرم تماس</h2>
            {sent ? (
              <div className="animate-scale" style={{background:"white",padding:"48px 24px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",textAlign:"center"}}>
                <div style={{width:"72px",height:"72px",borderRadius:"50%",background:"#ecfdf5",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"32px"}} className="animate-float">✅</div>
                <h3 style={{color:"#059669",fontSize:"20px",fontWeight:900,marginBottom:"8px"}}>پیام شما ارسال شد!</h3>
                <p style={{color:"#888",fontSize:"14px",fontWeight:700}}>در اسرع وقت با شما تماس می‌گیریم</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} style={{background:"white",padding:"28px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)"}}>
                <div className="form-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"14px",marginBottom:"14px"}}>
                  <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>نام *</label><input type="text" value={form.name} onChange={e=>setForm({...form,name:e.target.value})} placeholder="نام شما" className="input-field" required /></div>
                  <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>ایمیل *</label><input type="email" dir="ltr" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} placeholder="name@example.com" className="input-field" required /></div>
                </div>
                <div className="form-grid" style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:"14px",marginBottom:"14px"}}>
                  <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>تلفن</label><input type="tel" dir="ltr" value={form.phone} onChange={e=>setForm({...form,phone:e.target.value})} placeholder="09123456789" className="input-field" /></div>
                  <div><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>موضوع *</label><select value={form.subject} onChange={e=>setForm({...form,subject:e.target.value})} className="input-field" required>
                    <option value="">انتخاب کنید</option>
                    <option value="general">سوال عمومی</option>
                    <option value="support">پشتیبانی فنی</option>
                    <option value="partnership">پیشنهاد همکاری</option>
                    <option value="investment">سرمایه‌گذاری</option>
                    <option value="feedback">بازخورد و پیشنهاد</option>
                  </select></div>
                </div>
                <div style={{marginBottom:"20px"}}><label style={{display:"block",marginBottom:"6px",fontSize:"13px",fontWeight:900,color:"#444"}}>پیام شما *</label><textarea value={form.message} onChange={e=>setForm({...form,message:e.target.value})} placeholder="پیام خود را بنویسید..." className="input-field" style={{minHeight:"120px",resize:"vertical"}} required /></div>
                <button type="submit" style={{width:"100%",padding:"16px",background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",border:"none",borderRadius:"14px",fontSize:"16px",fontWeight:900,fontFamily:"inherit",boxShadow:"0 4px 15px rgba(15,23,42,0.3)",cursor:"pointer"}}>📨 ارسال پیام</button>
              </form>
            )}
          </div>
        </div>
      </section>

      <section style={{padding:"40px 24px",background:"white"}}>
        <div style={{maxWidth:"900px",margin:"0 auto"}}>
          <h2 style={{textAlign:"center",fontSize:"20px",fontWeight:900,color:"#1e3a5f",marginBottom:"24px"}}>سوالات متداول</h2>
          {[
            {q:"ثبت‌نام رایگان هست؟",a:"بله! ثبت‌نام و استفاده از پلتفرم کاملاً رایگان هست."},
            {q:"چطور بار ثبت کنم؟",a:"بعد از ثبت‌نام، از داشبورد بارفرست دکمه «ثبت بار جدید» رو بزنید و اطلاعات بار رو وارد کنید."},
            {q:"چطور حمل‌کننده پیدا کنم؟",a:"بعد از ثبت بار، حمل‌کنندگان درخواست می‌دن و شما بهترین پیشنهاد رو انتخاب می‌کنید."},
            {q:"آیا تسویه حساب انجام می‌شه؟",a:"در نسخه فعلی (بتا)، تسویه بین طرفین مستقیم انجام می‌شه. سیستم پرداخت آنلاین به زودی اضافه می‌شه."},
          ].map((faq,i)=>(
            <div key={i} className="animate-fade" style={{background:"#f8fafc",padding:"18px 20px",borderRadius:"12px",marginBottom:"10px",animationDelay:`${i*60}ms`}}>
              <div style={{fontSize:"14px",fontWeight:900,color:"#1e3a5f",marginBottom:"6px"}}>❓ {faq.q}</div>
              <div style={{fontSize:"13px",color:"#555",fontWeight:700,lineHeight:"1.8"}}>{faq.a}</div>
            </div>
          ))}
        </div>
      </section>
      <Footer />
    </div>
  );
}
