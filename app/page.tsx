"use client";
import Link from "next/link";
import { LogoSphere, LogoText, LogoNav } from "@/components/Logo";
import { Footer } from "@/components/Shared";
export default function Home() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav className="nav-responsive animate-slide-down" style={{padding:"14px 24px",background:"rgba(255,255,255,0.95)",backdropFilter:"blur(10px)",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"8px"}}>
          <Link href="/login" className="hide-mobile" style={{padding:"10px 18px",borderRadius:"10px",fontSize:"14px",fontWeight:900,color:"#3C3B6E",border:"2px solid #3C3B6E"}}>ورود</Link>
          <Link href="/login" className="btn-primary" style={{padding:"10px 18px",fontSize:"13px"}}>ورود / ثبت‌نام</Link>
        </div>
      </nav>
      <section className="section-padding" style={{background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",color:"white",padding:"60px 24px 80px",textAlign:"center",position:"relative",overflow:"hidden"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 30%, rgba(6,182,212,0.15) 0%, transparent 60%), radial-gradient(ellipse at 20% 80%, rgba(245,158,11,0.08) 0%, transparent 50%)",pointerEvents:"none"}} />
        <div className="animate-fade-up" style={{position:"relative",zIndex:1}}>
          <div style={{marginBottom:"20px"}} className="animate-float"><LogoSphere size={180} /></div>
          <div style={{marginBottom:"24px"}}><LogoText size="large" onDark={true} /></div>
          <p className="hero-title" style={{fontSize:"22px",fontWeight:900,marginBottom:"10px",textShadow:"0 2px 10px rgba(0,0,0,0.3)"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
          <p className="hero-subtitle" style={{fontSize:"15px",fontWeight:700,opacity:0.8,marginBottom:"40px"}}>مسیر تهران ↔ مشهد | کاهش هزینه تا ۳۰٪ | حذف خالی‌برگشت</p>
          <div className="hero-buttons" style={{display:"flex",gap:"16px",justifyContent:"center"}}>
            <Link href="/login" style={{background:"white",color:"#1e3a5f",padding:"18px 36px",borderRadius:"14px",fontSize:"16px",fontWeight:900,boxShadow:"0 4px 25px rgba(0,0,0,0.25)"}}>📦 بار دارم، حمل‌کننده می‌خوام</Link>
            <Link href="/login" className="glass" style={{color:"white",padding:"18px 36px",borderRadius:"14px",fontSize:"16px",fontWeight:900}}>🚛 ناوگان دارم، بار می‌خوام</Link>
          </div>
        </div>
      </section>
      <section className="section-padding" style={{padding:"60px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="animate-fade text-responsive" style={{textAlign:"center",fontSize:"28px",color:"#1e3a5f",marginBottom:"40px",fontWeight:900}}>چرا <span style={{color:"#B22234"}}>i</span><span style={{color:"#3C3B6E"}}>KIA</span>؟</h2>
        <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"20px"}}>
          {[{icon:"💰",title:"کاهش هزینه حمل",desc:"دسترسی مستقیم به بازار رقابتی بدون واسطه.",color:"#f59e0b",bg:"#fffbeb"},{icon:"🔄",title:"حذف خالی‌برگشت",desc:"حمل‌کنندگان بار برگشت پیدا می‌کنن.",color:"#06b6d4",bg:"#ecfeff"},{icon:"⚡",title:"سرعت و شفافیت",desc:"ثبت بار در ۲ دقیقه. پیگیری لحظه‌ای.",color:"#10b981",bg:"#ecfdf5"}].map((f,i)=>(
            <div key={i} className="card-hover animate-fade-up" style={{background:"white",padding:"28px 20px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 12px rgba(0,0,0,0.06)",animationDelay:`${i*100}ms`}}>
              <div style={{width:"52px",height:"52px",borderRadius:"14px",background:f.bg,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"26px",border:`2px solid ${f.color}22`}}>{f.icon}</div>
              <h3 style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f",marginBottom:"8px"}}>{f.title}</h3>
              <p style={{color:"#555",fontSize:"13px",lineHeight:"1.9",fontWeight:500}}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>
      <section className="section-padding" style={{background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",padding:"48px 24px"}}>
        <div className="stat-grid" style={{maxWidth:"700px",margin:"0 auto",display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"20px",textAlign:"center"}}>
          {[{n:"۹۰۰+",l:"کیلومتر مسیر"},{n:"۳۰٪",l:"کاهش هزینه"},{n:"۴۰٪",l:"کاهش خالی‌برگشت"},{n:"۲۴h",l:"تسویه سریع"}].map((s,i)=>(
            <div key={i}><div style={{fontSize:"28px",fontWeight:900}}>{s.n}</div><div style={{fontSize:"12px",opacity:0.7,marginTop:"4px",fontWeight:700}}>{s.l}</div></div>
          ))}
        </div>
      </section>
      <section className="section-padding" style={{padding:"60px 24px",background:"white"}}>
        <div style={{maxWidth:"700px",margin:"0 auto"}}>
          <h2 className="text-responsive" style={{textAlign:"center",fontSize:"28px",color:"#1e3a5f",marginBottom:"40px",fontWeight:900}}>چطور کار می‌کنه؟</h2>
          <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"28px"}}>
            {[{step:"۱",title:"ثبت بار",desc:"مشخصات بارت رو وارد کن",icon:"📝",color:"#0ea5e9"},{step:"۲",title:"دریافت پیشنهاد",desc:"حمل‌کنندگان قیمت پیشنهاد می‌دن",icon:"🤝",color:"#f59e0b"},{step:"۳",title:"تحویل مطمئن",desc:"پیگیری لحظه‌ای و تأیید تحویل",icon:"✅",color:"#10b981"}].map((s,i)=>(
              <div key={i} style={{textAlign:"center"}}>
                <div style={{width:"60px",height:"60px",borderRadius:"50%",background:`${s.color}15`,border:`2px solid ${s.color}30`,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"26px"}}>{s.icon}</div>
                <div style={{fontSize:"12px",color:s.color,fontWeight:900,marginBottom:"4px"}}>مرحله {s.step}</div>
                <h3 style={{fontSize:"16px",fontWeight:900,color:"#1e3a5f",marginBottom:"6px"}}>{s.title}</h3>
                <p style={{color:"#666",fontSize:"13px",lineHeight:"1.8",fontWeight:500}}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
      <section className="section-padding" style={{padding:"56px 24px",textAlign:"center",background:"linear-gradient(135deg,#ecfeff,#eff6ff,#ecfdf5)"}}>
        <h2 style={{fontSize:"22px",color:"#1e3a5f",marginBottom:"12px",fontWeight:900}}>آماده‌ای شروع کنی؟</h2>
        <p style={{color:"#555",marginBottom:"24px",fontWeight:700,fontSize:"14px"}}>ثبت‌نام رایگان — بدون نیاز به قرارداد</p>
        <Link href="/login" className="btn-primary" style={{display:"inline-block",padding:"16px 44px",fontSize:"16px"}}>شروع کن — رایگان</Link>
      </section>
      <Footer />
    </div>
  );
}
