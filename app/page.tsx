"use client";
import Link from "next/link";
import { LogoHero, LogoNav } from "@/components/Logo";
export default function Home() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav style={{padding:"12px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50}}>
        <LogoNav onDark={false} />
        <Link href="/login" style={{background:"#3C3B6E",color:"white",padding:"10px 24px",borderRadius:"10px",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>ورود به پلتفرم</Link>
      </nav>
      <section style={{background:"linear-gradient(135deg,#0c1929 0%,#1B3A5C 40%,#2E75B6 100%)",color:"white",padding:"60px 24px 80px",textAlign:"center"}}>
        <LogoHero onDark={true} />
        <p style={{fontSize:"20px",opacity:0.9,marginTop:"24px",marginBottom:"8px"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
        <p style={{fontSize:"15px",opacity:0.6,marginBottom:"40px"}}>مسیر تهران ↔ مشهد | کاهش هزینه تا ۳۰٪ | حذف خالی‌برگشت</p>
        <div style={{display:"flex",gap:"16px",justifyContent:"center",flexWrap:"wrap"}}>
          <Link href="/login" style={{background:"white",color:"#3C3B6E",padding:"16px 40px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold",boxShadow:"0 4px 20px rgba(0,0,0,0.3)"}}>📦 بار دارم، حمل‌کننده می‌خوام</Link>
          <Link href="/login" style={{background:"rgba(255,255,255,0.12)",color:"white",padding:"16px 40px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold",border:"2px solid rgba(255,255,255,0.25)"}}>🚛 ناوگان دارم، بار می‌خوام</Link>
        </div>
      </section>
      <section style={{padding:"60px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 style={{textAlign:"center",fontSize:"28px",color:"#3C3B6E",marginBottom:"40px"}}>چرا iKIA؟</h2>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(250px,1fr))",gap:"24px"}}>
          {[{icon:"💰",title:"کاهش هزینه حمل",desc:"دسترسی مستقیم به بازار رقابتی بدون واسطه. قیمت‌های شفاف و منصفانه."},{icon:"🔄",title:"حذف خالی‌برگشت",desc:"حمل‌کنندگان بار برگشت پیدا می‌کنن. بهره‌وری ناوگان بالا می‌ره."},{icon:"⚡",title:"سرعت و شفافیت",desc:"ثبت بار در ۲ دقیقه. پیگیری لحظه‌ای وضعیت. تسویه سریع."}].map((f,i)=>(
            <div key={i} style={{background:"white",padding:"32px 24px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
              <div style={{fontSize:"40px",marginBottom:"12px"}}>{f.icon}</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>{f.title}</h3>
              <p style={{color:"#666",fontSize:"14px",lineHeight:"1.8"}}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>
      <section style={{background:"#3C3B6E",color:"white",padding:"40px 24px"}}>
        <div style={{maxWidth:"800px",margin:"0 auto",display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"24px",textAlign:"center"}}>
          {[{n:"۹۰۰+",l:"کیلومتر مسیر"},{n:"۳۰٪",l:"کاهش هزینه"},{n:"۴۰٪",l:"کاهش خالی‌برگشت"},{n:"۲۴h",l:"تسویه سریع"}].map((s,i)=>(
            <div key={i}><div style={{fontSize:"32px",fontWeight:"bold"}}>{s.n}</div><div style={{fontSize:"13px",opacity:0.7,marginTop:"4px"}}>{s.l}</div></div>
          ))}
        </div>
      </section>
      <section style={{padding:"60px 24px",textAlign:"center",background:"#f0f4ff"}}>
        <h2 style={{fontSize:"24px",color:"#3C3B6E",marginBottom:"12px"}}>آماده‌ای شروع کنی؟</h2>
        <p style={{color:"#666",marginBottom:"24px"}}>ثبت‌نام رایگان — بدون نیاز به قرارداد</p>
        <Link href="/login" style={{display:"inline-block",background:"#3C3B6E",color:"white",padding:"16px 48px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold"}}>شروع کن — رایگان</Link>
      </section>
      <footer style={{background:"#111",color:"#999",padding:"24px",textAlign:"center",fontSize:"13px"}}>
        <p>© ۱۴۰۴ iKIA Logistics — پلتفرم هوشمند لجستیک ایران</p>
      </footer>
    </div>
  );
}
