"use client";
import Link from "next/link";
export default function ShipperDashboard() {
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <span style={{background:"#e8f0fe",padding:"4px 12px",borderRadius:"20px",fontSize:"13px",color:"#1B3A5C"}}>بارفرست</span>
      </nav>
      <main style={{maxWidth:"800px",margin:"0 auto",padding:"32px 16px"}}>
        <h1 style={{fontSize:"28px",color:"#1B3A5C",marginBottom:"32px"}}>سلام بارفرست 👋</h1>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(200px,1fr))",gap:"16px"}}>
          <div style={{background:"#1B3A5C",color:"white",padding:"24px",borderRadius:"16px"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>📦</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>ثبت بار جدید</h3>
            <p style={{fontSize:"14px",opacity:0.8}}>بار خودت رو ثبت کن</p>
          </div>
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>📋</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>بارهای من</h3>
            <div style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C"}}>۰</div>
          </div>
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>🤝</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>رزروها</h3>
            <div style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C"}}>۰</div>
          </div>
        </div>
        <div style={{marginTop:"32px",textAlign:"center",padding:"48px",background:"#f9fafb",borderRadius:"16px",border:"2px dashed #ddd"}}>
          <div style={{fontSize:"48px",marginBottom:"16px"}}>🚀</div>
          <h3 style={{fontSize:"20px",fontWeight:"bold"}}>شروع کن!</h3>
          <p style={{color:"#666"}}>اولین بار خودت رو ثبت کن تا حمل‌کنندگان درخواست بدن</p>
        </div>
      </main>
    </div>
  );
}
