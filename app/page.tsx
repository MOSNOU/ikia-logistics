"use client";
import Link from "next/link";
import { LogoSphere, LogoText, LogoNav } from "@/components/Logo";
import { Footer } from "@/components/Shared";
export default function Home() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav className="nav-responsive animate-slide-down" style={{padding:"14px 24px",background:"rgba(255,255,255,0.95)",backdropFilter:"blur(10px)",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow:"0 1px 3px rgba(0,0,0,0.05)"}}>
        <Link href="/" style={{textDecoration:"none"}}><LogoNav /></Link>
        <div style={{display:"flex",gap:"10px"}}>
          <Link href="/login" style={{padding:"10px 20px",borderRadius:"10px",fontSize:"14px",fontWeight:900,color:"#3C3B6E",border:"2px solid #3C3B6E"}}>ورود</Link>
          <Link href="/login" className="btn-primary" style={{padding:"10px 20px",fontSize:"14px"}}>ثبت‌نام رایگان</Link>
        </div>
      </nav>
      <section style={{background:"linear-gradient(160deg,#0f172a 0%,#1e3a5f 35%,#1a5276 60%,#1b4f72 100%)",color:"white",padding:"70px 24px 90px",textAlign:"center",position:"relative",overflow:"hidden"}}>
        <div style={{position:"absolute",top:0,left:0,right:0,bottom:0,background:"radial-gradient(ellipse at 50% 30%, rgba(6,182,212,0.15) 0%, transparent 60%), radial-gradient(ellipse at 20% 80%, rgba(245,158,11,0.08) 0%, transparent 50%), radial-gradient(ellipse at 80% 70%, rgba(16,185,129,0.08) 0%, transparent 50%)",pointerEvents:"none"}} />
        <div className="animate-fade-up" style={{position:"relative",zIndex:1}}>
          <div style={{marginBottom:"24px"}} className="animate-float"><LogoSphere size={220} /></div>
          <div style={{marginBottom:"28px"}}><LogoText size="large" onDark={true} /></div>
          <p style={{fontSize:"22px",fontWeight:900,marginBottom:"10px",textShadow:"0 2px 10px rgba(0,0,0,0.3)"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
          <p style={{fontSize:"16px",fontWeight:700,opacity:0.8,marginBottom:"44px"}}>مسیر تهران ↔ مشهد | کاهش هزینه تا ۳۰٪ | حذف خالی‌برگشت</p>
          <div className="flex-wrap-mobile" style={{display:"flex",gap:"16px",justifyContent:"center"}}>
            <Link href="/login" style={{background:"white",color:"#1e3a5f",padding:"18px 44px",borderRadius:"14px",fontSize:"17px",fontWeight:900,boxShadow:"0 4px 25px rgba(0,0,0,0.25)",transition:"transform 0.2s"}}>📦 بار دارم، حمل‌کننده می‌خوام</Link>
            <Link href="/login" style={{background:"rgba(255,255,255,0.12)",backdropFilter:"blur(10px)",color:"white",padding:"18px 44px",borderRadius:"14px",fontSize:"17px",fontWeight:900,border:"2px solid rgba(255,255,255,0.3)",transition:"transform 0.2s"}}>🚛 ناوگان دارم، بار می‌خوام</Link>
          </div>
        </div>
      </section>
      <section className="padding-responsive" style={{padding:"70px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 className="animate-fade text-responsive" style={{textAlign:"center",fontSize:"30px",color:"#1e3a5f",marginBottom:"44px",fontWeight:900}}>چرا <span style={{color:"#B22234"}}>i</span><span style={{color:"#3C3B6E"}}>KIA</span>؟</h2>
        <div className="grid-responsive" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"24px"}}>
          {[{icon:"💰",title:"کاهش هزینه حمل",desc:"دسترسی مستقیم به بازار رقابتی بدون واسطه. قیمت‌های شفاف و منصفانه.",color:"#f59e0b",bg:"#fffbeb",delay:0},{icon:"🔄",title:"حذف خالی‌برگشت",desc:"حمل‌کنندگان بار برگشت پیدا می‌کنن. بهره‌وری ناوگان بالا می‌ره.",color:"#06b6d4",bg:"#ecfeff",delay:100},{icon:"⚡",title:"سرعت و شفافیت",desc:"ثبت بار در ۲ دقیقه. پیگیری لحظه‌ای وضعیت. تسویه سریع.",color:"#10b981",bg:"#ecfdf5",delay:200}].map((f,i)=>(
            <div key={i} className="card-hover animate-fade-up" style={{background:"white",padding:"32px 24px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 12px rgba(0,0,0,0.06)",animationDelay:`${f.delay}ms`}}>
              <div style={{width:"60px",height:"60px",borderRadius:"16px",background:f.bg,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"28px",border:`2px solid ${f.color}22`}}>{f.icon}</div>
              <h3 style={{fontSize:"18px",fontWeight:900,color:"#1e3a5f",marginBottom:"10px"}}>{f.title}</h3>
              <p style={{color:"#555",fontSize:"14px",lineHeight:"2",fontWeight:500}}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>
      <section style={{background:"linear-gradient(135deg,#0f172a,#1e3a5f)",color:"white",padding:"52px 24px"}}>
        <div className="grid-responsive" style={{maxWidth:"800px",margin:"0 auto",display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"24px",textAlign:"center"}}>
          {[{n:"۹۰۰+",l:"کیلومتر مسیر",icon:"🛤️"},{n:"۳۰٪",l:"کاهش هزینه",icon:"💰"},{n:"۴۰٪",l:"کاهش خالی‌برگشت",icon:"🔄"},{n:"۲۴h",l:"تسویه سریع",icon:"⚡"}].map((s,i)=>(
            <div key={i} className="animate-fade" style={{animationDelay:`${i*100}ms`}}>
              <div style={{fontSize:"24px",marginBottom:"8px"}}>{s.icon}</div>
              <div style={{fontSize:"34px",fontWeight:900}}>{s.n}</div>
              <div style={{fontSize:"14px",opacity:0.7,marginTop:"4px",fontWeight:700}}>{s.l}</div>
            </div>
          ))}
        </div>
      </section>
      <section style={{padding:"80px 24px",background:"white"}}>
        <div style={{maxWidth:"800px",margin:"0 auto"}}>
          <h2 className="text-responsive" style={{textAlign:"center",fontSize:"30px",color:"#1e3a5f",marginBottom:"44px",fontWeight:900}}>چطور کار می‌کنه؟</h2>
          <div className="grid-responsive-1" style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:"32px"}}>
            {[{step:"۱",title:"ثبت بار",desc:"مشخصات بارت رو وارد کن: مبدأ، مقصد، نوع و وزن",icon:"📝",color:"#0ea5e9"},{step:"۲",title:"دریافت پیشنهاد",desc:"حمل‌کنندگان درخواست می‌دن و قیمت پیشنهاد می‌دن",icon:"🤝",color:"#f59e0b"},{step:"۳",title:"تحویل مطمئن",desc:"پیگیری لحظه‌ای و تأیید تحویل در مقصد",icon:"✅",color:"#10b981"}].map((s,i)=>(
              <div key={i} className="animate-fade-up" style={{textAlign:"center",animationDelay:`${i*150}ms`}}>
                <div style={{width:"68px",height:"68px",borderRadius:"50%",background:`linear-gradient(135deg,${s.color}20,${s.color}10)`,border:`2px solid ${s.color}40`,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"30px",boxShadow:`0 4px 15px ${s.color}20`}}>{s.icon}</div>
                <div style={{fontSize:"13px",color:s.color,fontWeight:900,marginBottom:"6px"}}>مرحله {s.step}</div>
                <h3 style={{fontSize:"17px",fontWeight:900,color:"#1e3a5f",marginBottom:"8px"}}>{s.title}</h3>
                <p style={{color:"#666",fontSize:"14px",lineHeight:"1.9",fontWeight:500}}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
      <section style={{padding:"64px 24px",textAlign:"center",background:"linear-gradient(135deg,#ecfeff,#eff6ff,#ecfdf5)"}}>
        <div className="animate-fade-up">
          <h2 style={{fontSize:"26px",color:"#1e3a5f",marginBottom:"14px",fontWeight:900}}>آماده‌ای شروع کنی؟</h2>
          <p style={{color:"#555",marginBottom:"28px",fontWeight:700,fontSize:"15px"}}>ثبت‌نام رایگان — بدون نیاز به قرارداد</p>
          <Link href="/login" className="btn-primary" style={{display:"inline-block",padding:"18px 52px",fontSize:"18px"}}>شروع کن — رایگان</Link>
        </div>
      </section>
      <Footer />
    </div>
  );
}
