"use client";
import Link from "next/link";
import { LogoSphere, LogoText, LogoNav } from "@/components/Logo";
import { Footer } from "@/components/Shared";
export default function AboutPage() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"var(--text2)",background:"var(--bg)"}}>
      <nav className="nav-responsive animate-slide-down" style={{padding:"14px 24px",background:"var(--bg2)",borderBottom:"1px solid var(--border)",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px var(--shadow)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"8px"}}>
          <Link href="/contact" className="btn-outline" style={{padding:"10px 18px",fontSize:"13px"}}>تماس با ما</Link>
          <Link href="/login" className="btn-primary" style={{padding:"10px 18px",fontSize:"13px"}}>ورود</Link>
        </div>
      </nav>

      <section style={{background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",color:"white",padding:"60px 24px",textAlign:"center",position:"relative",overflow:"hidden"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 30%, rgba(6,182,212,0.15) 0%, transparent 60%)",pointerEvents:"none"}} />
        <div className="animate-fade-up" style={{position:"relative",zIndex:1}}>
          <LogoSphere size={120} />
          <h1 style={{fontSize:"30px",fontWeight:900,marginTop:"20px",marginBottom:"10px"}}>درباره <span style={{color:"#B22234"}}>i</span>KIA Logistics</h1>
          <p style={{fontSize:"15px",fontWeight:700,opacity:0.8,maxWidth:"600px",margin:"0 auto"}}>پلتفرم هوشمند لجستیک — ارتباط بارفرست‌ها و حمل‌کنندگان در مسیر تهران-مشهد</p>
        </div>
      </section>

      <section className="section-padding" style={{padding:"60px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="text-responsive" style={{textAlign:"center",fontSize:"26px",color:"var(--text)",marginBottom:"36px",fontWeight:900}}>داستان ما</h2>
        <div className="card animate-fade" style={{padding:"28px",lineHeight:"2.2",fontSize:"15px",color:"var(--text2)"}}>
          <p style={{marginBottom:"16px"}}>صنعت حمل‌ونقل جاده‌ای ایران با چالش‌های بزرگی مواجهه: <strong style={{color:"var(--text)",fontWeight:900}}>هزینه‌های بالای واسطه‌گری، خالی‌برگشت کامیون‌ها، و عدم شفافیت</strong> در قیمت‌گذاری.</p>
          <p style={{marginBottom:"16px"}}><strong style={{color:"#B22234",fontWeight:900}}>iKIA Logistics</strong> با هدف حل این مشکلات پایه‌گذاری شد. فناوری می‌تونه حمل‌ونقل بار رو <strong style={{color:"var(--accent)",fontWeight:900}}>ساده‌تر، ارزان‌تر و شفاف‌تر</strong> کنه.</p>
          <p>تمرکز ما روی مسیر پرتردد <strong style={{color:"var(--text)",fontWeight:900}}>تهران ↔ مشهد</strong> (بیش از ۹۰۰ کیلومتر) هست و هدف ما پوشش تمام مسیرهای اصلی ایرانه.</p>
        </div>
      </section>

      <section className="section-padding" style={{padding:"40px 24px 60px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="text-responsive" style={{textAlign:"center",fontSize:"26px",color:"var(--text)",marginBottom:"36px",fontWeight:900}}>مزایای ما</h2>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(2,1fr)",gap:"16px"}}>
          {[
            {icon:"💰",title:"حذف واسطه",desc:"ارتباط مستقیم بارفرست و حمل‌کننده بدون دلال"},
            {icon:"🔄",title:"کاهش خالی‌برگشت",desc:"حمل‌کنندگان بار برگشت پیدا می‌کنن و درآمد بیشتری دارن"},
            {icon:"📍",title:"شفافیت کامل",desc:"پیگیری لحظه‌ای وضعیت بار و قیمت‌گذاری شفاف"},
            {icon:"⚡",title:"سرعت بالا",desc:"ثبت بار در ۲ دقیقه، پیشنهاد فوری و تسویه ۲۴ ساعته"},
            {icon:"🛡️",title:"امنیت و اعتماد",desc:"سیستم امتیازدهی و نظرات برای اعتماد بین طرفین"},
            {icon:"📱",title:"دسترسی آسان",desc:"استفاده با موبایل و دسکتاپ — هر جا و هر زمان"},
          ].map((f,i)=>(
            <div key={i} className="card animate-fade-up" style={{padding:"22px",display:"flex",gap:"14px",alignItems:"flex-start",animationDelay:`${i*80}ms`}}>
              <div style={{width:"44px",height:"44px",borderRadius:"12px",background:"var(--bg3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:"22px",flexShrink:0}}>{f.icon}</div>
              <div><h3 style={{fontSize:"15px",fontWeight:900,color:"var(--text)",marginBottom:"6px"}}>{f.title}</h3><p style={{color:"var(--text3)",fontSize:"13px",lineHeight:"1.8",fontWeight:500}}>{f.desc}</p></div>
            </div>
          ))}
        </div>
      </section>

      <section style={{background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",padding:"52px 24px",textAlign:"center"}}>
        <h2 style={{fontSize:"24px",fontWeight:900,marginBottom:"32px"}}>چشم‌انداز ما</h2>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"20px",maxWidth:"800px",margin:"0 auto"}}>
          {[
            {year:"۱۴۰۴",title:"مسیر تهران-مشهد",desc:"راه‌اندازی MVP و جذب اولین کاربران",icon:"🚀"},
            {year:"۱۴۰۵",title:"مسیرهای اصلی ایران",desc:"گسترش به ۱۰ مسیر پرتردد",icon:"🗺️"},
            {year:"۱۴۰۶",title:"پلتفرم ملی لجستیک",desc:"پوشش کامل حمل‌ونقل جاده‌ای",icon:"🇮🇷"},
          ].map((s,i)=>(
            <div key={i} className="animate-fade glass" style={{padding:"24px",borderRadius:"16px",animationDelay:`${i*150}ms`}}>
              <div style={{fontSize:"28px",marginBottom:"10px"}}>{s.icon}</div>
              <div style={{fontSize:"13px",color:"#22d3ee",fontWeight:900,marginBottom:"4px"}}>{s.year}</div>
              <h3 style={{fontSize:"16px",fontWeight:900,marginBottom:"6px"}}>{s.title}</h3>
              <p style={{fontSize:"13px",opacity:0.7,fontWeight:700}}>{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="section-padding" style={{padding:"60px 24px",textAlign:"center",background:"var(--bg3)"}}>
        <h2 style={{fontSize:"24px",color:"var(--text)",marginBottom:"12px",fontWeight:900}}>آماده‌ای با ما همراه بشی؟</h2>
        <p style={{color:"var(--text3)",marginBottom:"24px",fontWeight:700,fontSize:"14px"}}>همین الان ثبت‌نام کن و شروع کن</p>
        <div style={{display:"flex",gap:"12px",justifyContent:"center",flexWrap:"wrap"}}>
          <Link href="/login" className="btn-primary" style={{display:"inline-block",padding:"16px 40px",fontSize:"16px"}}>شروع کن — رایگان</Link>
          <Link href="/contact" className="btn-outline" style={{display:"inline-block",padding:"16px 40px",fontSize:"16px"}}>تماس با ما</Link>
        </div>
      </section>
      <Footer />
    </div>
  );
}
