import Link from "next/link";
export default function Home() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"Vazirmatn,sans-serif",direction:"rtl",color:"#333"}}>
      <nav style={{padding:"16px 24px",background:"white",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50}}>
        <div style={{display:"flex",alignItems:"center",gap:"8px"}}><span style={{fontSize:"28px"}}>🚛</span><span style={{fontSize:"22px",fontWeight:"bold",color:"#1B3A5C"}}>iKIA Logistics</span></div>
        <Link href="/login" style={{background:"#1B3A5C",color:"white",padding:"10px 24px",borderRadius:"10px",textDecoration:"none",fontSize:"14px",fontWeight:"bold"}}>ورود به پلتفرم</Link>
      </nav>
      <section style={{background:"linear-gradient(135deg,#1B3A5C 0%,#2E75B6 100%)",color:"white",padding:"80px 24px",textAlign:"center"}}>
        <h1 style={{fontSize:"42px",fontWeight:"bold",marginBottom:"16px",lineHeight:"1.4"}}>پلتفرم هوشمند حمل‌ونقل بار</h1>
        <p style={{fontSize:"20px",opacity:0.9,marginBottom:"8px"}}>اتصال مستقیم بارفرست‌ها و حمل‌کنندگان</p>
        <p style={{fontSize:"16px",opacity:0.7,marginBottom:"40px"}}>مسیر تهران ↔ مشهد | کاهش هزینه تا ۳۰٪ | حذف خالی‌برگشت</p>
        <div style={{display:"flex",gap:"16px",justifyContent:"center",flexWrap:"wrap"}}>
          <Link href="/login" style={{background:"white",color:"#1B3A5C",padding:"16px 40px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold",boxShadow:"0 4px 15px rgba(0,0,0,0.2)"}}>📦 بار دارم، حمل‌کننده می‌خوام</Link>
          <Link href="/login" style={{background:"rgba(255,255,255,0.15)",color:"white",padding:"16px 40px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold",border:"2px solid rgba(255,255,255,0.3)"}}>🚛 ناوگان دارم، بار می‌خوام</Link>
        </div>
      </section>
      <section style={{padding:"60px 24px",maxWidth:"900px",margin:"0 auto"}}>
        <h2 style={{textAlign:"center",fontSize:"28px",color:"#1B3A5C",marginBottom:"40px"}}>چرا iKIA؟</h2>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(250px,1fr))",gap:"24px"}}>
          <div style={{background:"white",padding:"32px 24px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <div style={{fontSize:"40px",marginBottom:"12px"}}>💰</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"8px"}}>کاهش هزینه حمل</h3>
            <p style={{color:"#666",fontSize:"14px",lineHeight:"1.8"}}>دسترسی مستقیم به بازار رقابتی بدون واسطه. قیمت‌های شفاف و منصفانه.</p>
          </div>
          <div style={{background:"white",padding:"32px 24px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <div style={{fontSize:"40px",marginBottom:"12px"}}>🔄</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"8px"}}>حذف خالی‌برگشت</h3>
            <p style={{color:"#666",fontSize:"14px",lineHeight:"1.8"}}>حمل‌کنندگان بار برگشت پیدا می‌کنن. بهره‌وری ناوگان بالا می‌ره.</p>
          </div>
          <div style={{background:"white",padding:"32px 24px",borderRadius:"16px",border:"1px solid #eee",textAlign:"center",boxShadow:"0 2px 10px rgba(0,0,0,0.05)"}}>
            <div style={{fontSize:"40px",marginBottom:"12px"}}>⚡</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C",marginBottom:"8px"}}>سرعت و شفافیت</h3>
            <p style={{color:"#666",fontSize:"14px",lineHeight:"1.8"}}>ثبت بار در ۲ دقیقه. پیگیری لحظه‌ای وضعیت. تسویه سریع.</p>
          </div>
        </div>
      </section>
      <section style={{background:"#1B3A5C",color:"white",padding:"40px 24px"}}>
        <div style={{maxWidth:"800px",margin:"0 auto",display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:"24px",textAlign:"center"}}>
          <div><div style={{fontSize:"32px",fontWeight:"bold"}}>۹۰۰+</div><div style={{fontSize:"13px",opacity:0.7,marginTop:"4px"}}>کیلومتر مسیر</div></div>
          <div><div style={{fontSize:"32px",fontWeight:"bold"}}>۳۰٪</div><div style={{fontSize:"13px",opacity:0.7,marginTop:"4px"}}>کاهش هزینه</div></div>
          <div><div style={{fontSize:"32px",fontWeight:"bold"}}>۴۰٪</div><div style={{fontSize:"13px",opacity:0.7,marginTop:"4px"}}>کاهش خالی‌برگشت</div></div>
          <div><div style={{fontSize:"32px",fontWeight:"bold"}}>۲۴h</div><div style={{fontSize:"13px",opacity:0.7,marginTop:"4px"}}>تسویه سریع</div></div>
        </div>
      </section>
      <section style={{padding:"60px 24px",textAlign:"center",background:"#f0f5ff"}}>
        <h2 style={{fontSize:"24px",color:"#1B3A5C",marginBottom:"12px"}}>آماده‌ای شروع کنی؟</h2>
        <p style={{color:"#666",marginBottom:"24px"}}>ثبت‌نام رایگان — بدون نیاز به قرارداد</p>
        <Link href="/login" style={{display:"inline-block",background:"#1B3A5C",color:"white",padding:"16px 48px",borderRadius:"12px",textDecoration:"none",fontSize:"17px",fontWeight:"bold"}}>شروع کن — رایگان</Link>
      </section>
      <footer style={{background:"#111",color:"#999",padding:"24px",textAlign:"center",fontSize:"13px"}}>
        <p>© ۱۴۰۴ iKIA Logistics — پلتفرم هوشمند لجستیک ایران</p>
        <p style={{marginTop:"4px"}}>مسیر تهران ↔ مشهد | نسخه بتا</p>
      </footer>
    </div>
  );
}
