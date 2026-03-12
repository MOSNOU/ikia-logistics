"use client";
import Link from "next/link";
import { LogoSphere, LogoText, LogoNav } from "@/components/Logo";
import { Footer } from "@/components/Shared";
export default function AboutPage() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav className="nav-responsive animate-slide-down" style={{padding:"14px 24px",background:"rgba(255,255,255,0.95)",backdropFilter:"blur(10px)",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"8px"}}>
          <Link href="/contact" style={{padding:"10px 18px",borderRadius:"10px",fontSize:"13px",fontWeight:900,color:"#1e3a5f",border:"2px solid #e0e0e0"}}>تماس با ما</Link>
          <Link href="/login" className="btn-primary" style={{padding:"10px 18px",fontSize:"13px"}}>ورود</Link>
        </div>
      </nav>

      <section style={{background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",color:"white",padding:"60px 24px",textAlign:"center",position:"relative",overflow:"hidden"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 30%, rgba(6,182,212,0.15) 0%, transparent 60%)",pointerEvents:"none"}} />
        <div className="animate-fade-up" style={{position:"relative",zIndex:1}}>
          <LogoSphere size={120} />
          <h1 style={{fontSize:"32px",fontWeight:900,marginTop:"20px",marginBottom:"10px"}}>درباره <span style={{color:"#B22234"}}>i</span>KIA Logistics</h1>
          <p style={{fontSize:"16px",fontWeight:700,opacity:0.8,maxWidth:"600px",margin:"0 auto"}}>ما یک پلتفرم هوشمند لجستیک هستیم که بارفرست‌ها و حمل‌کنندگان رو در مسیر تهران-مشهد به هم وصل می‌کنیم</p>
        </div>
      </section>

      <section className="section-padding" style={{padding:"60px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="text-responsive" style={{textAlign:"center",fontSize:"26px",color:"#1e3a5f",marginBottom:"40px",fontWeight:900}}>داستان ما</h2>
        <div className="animate-fade" style={{background:"white",padding:"32px",borderRadius:"20px",border:"1px solid #eee",boxShadow:"0 4px 20px rgba(0,0,0,0.06)",lineHeight:"2.2",fontSize:"15px",color:"#444",fontWeight:500}}>
          <p style={{marginBottom:"16px"}}>صنعت حمل‌ونقل جاده‌ای ایران با چالش‌های بزرگی مواجهه: <strong style={{color:"#1e3a5f",fontWeight:900}}>هزینه‌های بالای واسطه‌گری، خالی‌برگشت کامیون‌ها، و عدم شفافیت</strong> در قیمت‌گذاری و ردیابی بار.</p>
          <p style={{marginBottom:"16px"}}><strong style={{color:"#B22234",fontWeight:900}}>iKIA Logistics</strong> با هدف حل این مشکلات پایه‌گذاری شد. ما معتقدیم فناوری می‌تونه حمل‌ونقل بار رو <strong style={{color:"#0ea5e9",fontWeight:900}}>ساده‌تر، ارزان‌تر و شفاف‌تر</strong> کنه.</p>
          <p>پلتفرم ما با تمرکز بر مسیر پرتردد <strong style={{color:"#1e3a5f",fontWeight:900}}>تهران ↔ مشهد</strong> (بیش از ۹۰۰ کیلومتر) شروع به کار کرده و هدف ما پوشش تمام مسیرهای اصلی ایران هست.</p>
        </div>
      </section>

      <section className="section-padding" style={{padding:"40px 24px 60px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="text-responsive" style={{textAlign:"center",fontSize:"26px",color:"#1e3a5f",marginBottom:"40px",fontWeight:900}}>مزایای ما</h2>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(2,1fr)",gap:"20px"}}>
          {[
            {icon:"💰",title:"حذف واسطه",desc:"ارتباط مستقیم بارفرست و حمل‌کننده بدون دلال و واسطه",color:"#f59e0b",bg:"#fffbeb"},
            {icon:"🔄",title:"کاهش خالی‌برگشت",desc:"حمل‌کنندگان می‌تونن بار برگشت پیدا کنن و درآمد بیشتری داشته باشن",color:"#06b6d4",bg:"#ecfeff"},
            {icon:"📍",title:"شفافیت کامل",desc:"پیگیری لحظه‌ای وضعیت بار، قیمت‌گذاری شفاف و سیستم امتیازدهی",color:"#10b981",bg:"#ecfdf5"},
            {icon:"⚡",title:"سرعت بالا",desc:"ثبت بار در ۲ دقیقه، دریافت پیشنهاد فوری و تسویه ۲۴ ساعته",color:"#8b5cf6",bg:"#f5f3ff"},
            {icon:"🛡️",title:"امنیت و اعتماد",desc:"سیستم امتیازدهی و نظرات برای ایجاد اعتماد بین طرفین",color:"#3b82f6",bg:"#eff6ff"},
            {icon:"📱",title:"دسترسی آسان",desc:"استفاده از پلتفرم با موبایل و دسکتاپ — هر جا و هر زمان",color:"#ec4899",bg:"#fdf2f8"},
          ].map((f,i)=>(
            <div key={i} className="card-hover animate-fade-up" style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee",boxShadow:"0 2px 10px rgba(0,0,0,0.05)",display:"flex",gap:"16px",alignItems:"flex-start",animationDelay:`${i*80}ms`}}>
              <div style={{width:"48px",height:"48px",borderRadius:"12px",background:f.bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"24px",flexShrink:0,border:`2px solid ${f.color}22`}}>{f.icon}</div>
              <div><h3 style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f",marginBottom:"6px"}}>{f.title}</h3><p style={{color:"#666",fontSize:"13px",lineHeight:"1.8",fontWeight:500}}>{f.desc}</p></div>
            </div>
          ))}
        </div>
      </section>

      <section style={{background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",padding:"52px 24px",textAlign:"center"}}>
        <h2 style={{fontSize:"24px",fontWeight:900,marginBottom:"32px"}}>چشم‌انداز ما</h2>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"24px",maxWidth:"800px",margin:"0 auto"}}>
          {[
            {year:"۱۴۰۴",title:"مسیر تهران-مشهد",desc:"راه‌اندازی MVP و جذب اولین کاربران",icon:"🚀"},
            {year:"۱۴۰۵",title:"مسیرهای اصلی ایران",desc:"گسترش به ۱۰ مسیر پرتردد کشور",icon:"🗺️"},
            {year:"۱۴۰۶",title:"پلتفرم ملی لجستیک",desc:"پوشش کامل حمل‌ونقل جاده‌ای ایران",icon:"🇮🇷"},
          ].map((s,i)=>(
            <div key={i} className="animate-fade" style={{background:"rgba(255,255,255,0.08)",backdropFilter:"blur(10px)",padding:"24px",borderRadius:"16px",border:"1px solid rgba(255,255,255,0.12)",animationDelay:`${i*150}ms`}}>
              <div style={{fontSize:"28px",marginBottom:"10px"}}>{s.icon}</div>
              <div style={{fontSize:"13px",color:"#06b6d4",fontWeight:900,marginBottom:"4px"}}>{s.year}</div>
              <h3 style={{fontSize:"16px",fontWeight:900,marginBottom:"6px"}}>{s.title}</h3>
              <p style={{fontSize:"13px",opacity:0.7,fontWeight:700}}>{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section-padding" style={{padding:"60px 24px",textAlign:"center",background:"linear-gradient(135deg,#ecfeff,#eff6ff,#ecfdf5)"}}>
        <h2 style={{fontSize:"24px",color:"#1e3a5f",marginBottom:"12px",fontWeight:900}}>آماده‌ای با ما همراه بشی؟</h2>
        <p style={{color:"#555",marginBottom:"24px",fontWeight:700,fontSize:"14px"}}>همین الان ثبت‌نام کن و شروع کن</p>
        <div style={{display:"flex",gap:"12px",justifyContent:"center",flexWrap:"wrap"}}>
          <Link href="/login" className="btn-primary" style={{display:"inline-block",padding:"16px 40px",fontSize:"16px"}}>شروع کن — رایگان</Link>
          <Link href="/contact" style={{display:"inline-block",padding:"16px 40px",fontSize:"16px",background:"white",color:"#1e3a5f",borderRadius:"10px",fontWeight:900,border:"2px solid #1e3a5f"}}>تماس با ما</Link>
        </div>
      </section>
      <Footer />
    </div>
  );
}
