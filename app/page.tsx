import Link from "next/link";
export default function Home() {
  return (
    <div style={{minHeight:"100vh",textAlign:"center",padding:"80px 20px",fontFamily:"sans-serif",direction:"rtl"}}>
      <h1 style={{fontSize:"48px",color:"#1B3A5C"}}>🚛 iKIA Logistics</h1>
      <p style={{fontSize:"20px",color:"#666",marginTop:"16px"}}>پلتفرم هوشمند لجستیک — مسیر تهران-مشهد</p>
      <div style={{marginTop:"40px",display:"flex",gap:"16px",justifyContent:"center"}}>
        <Link href="/login" style={{background:"#1B3A5C",color:"white",padding:"16px 32px",borderRadius:"12px",fontSize:"18px",textDecoration:"none"}}>📦 بارفرست هستم</Link>
        <Link href="/login" style={{background:"#2E75B6",color:"white",padding:"16px 32px",borderRadius:"12px",fontSize:"18px",textDecoration:"none"}}>🚛 حمل‌کننده هستم</Link>
      </div>
    </div>
  );
}
