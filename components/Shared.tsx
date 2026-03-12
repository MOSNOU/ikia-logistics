"use client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";

export function Navbar({ role, name, onSignOut }: { role?: string; name?: string; onSignOut?: () => void }) {
  const roleLabels: Record<string,string> = { admin: "ادمین", shipper: "بارفرست", carrier: "حمل‌کننده" };
  const roleColors: Record<string,string> = { admin: "#B22234", shipper: "#3C3B6E", carrier: "#2E75B6" };
  const roleBg: Record<string,string> = { admin: "#fef2f2", shipper: "#f0f0ff", carrier: "#e0f2fe" };
  const isAdmin = role === "admin";
  return (
    <nav className="nav-responsive animate-slide-down" style={{padding:"12px 24px",background: isAdmin ? "linear-gradient(135deg,#1a1a2e,#16213e)" : "white",borderBottom: isAdmin ? "none" : "1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow: isAdmin ? "0 2px 10px rgba(0,0,0,0.2)" : "0 1px 3px rgba(0,0,0,0.05)"}}>
      <Link href="/" style={{textDecoration:"none"}}><LogoNav onDark={isAdmin} /></Link>
      {role && (
        <div style={{display:"flex",gap:"12px",alignItems:"center"}}>
          {name && (
            <div style={{display:"flex",alignItems:"center",gap:"8px"}}>
              <div style={{width:"32px",height:"32px",borderRadius:"50%",background:`linear-gradient(135deg,${roleColors[role]||"#3C3B6E"},${role==="carrier"?"#60a5fa":"#2E75B6"})`,display:"flex",alignItems:"center",justifyContent:"center",color:"white",fontSize:"14px",fontWeight:"bold"}}>{name[0] || "؟"}</div>
              <div className="hide-mobile"><div style={{fontSize:"13px",fontWeight:"bold",color: isAdmin ? "white" : "#333"}}>{name}</div><div style={{fontSize:"11px",color: isAdmin ? "rgba(255,255,255,0.6)" : "#999"}}>{roleLabels[role]}</div></div>
            </div>
          )}
          {!name && <span className="badge" style={{background: isAdmin ? "rgba(178,34,52,0.2)" : roleBg[role],color: isAdmin ? "#fca5a5" : roleColors[role]}}>{roleLabels[role]}</span>}
          {onSignOut && <button onClick={onSignOut} style={{color: isAdmin ? "#fca5a5" : "#ef4444",background: isAdmin ? "rgba(255,255,255,0.1)" : "#fef2f2",border:`1px solid ${isAdmin ? "rgba(255,255,255,0.2)" : "#fecaca"}`,padding:"6px 14px",borderRadius:"8px",fontSize:"12px",fontWeight:"bold"}}>خروج</button>}
        </div>
      )}
    </nav>
  );
}

export function Footer() {
  return (
    <footer style={{background:"#111827",color:"#9ca3af",padding:"40px 24px 24px",marginTop:"40px"}}>
      <div style={{maxWidth:"900px",margin:"0 auto"}}>
        <div className="flex-wrap-mobile" style={{display:"flex",justifyContent:"space-between",marginBottom:"24px",gap:"24px"}}>
          <div>
            <div dir="ltr" style={{fontFamily:"'Orbitron',sans-serif",marginBottom:"8px"}}><span style={{color:"#B22234",fontWeight:900,fontSize:"20px"}}>i</span><span style={{color:"white",fontWeight:900,fontSize:"20px"}}>KIA</span><span style={{color:"#9ca3af",fontWeight:700,fontSize:"20px",marginLeft:"6px"}}>Logistics</span></div>
            <p style={{fontSize:"13px",lineHeight:"1.8"}}>پلتفرم هوشمند حمل‌ونقل بار<br/>مسیر تهران ↔ مشهد</p>
          </div>
          <div>
            <h4 style={{color:"white",fontSize:"14px",fontWeight:"bold",marginBottom:"10px"}}>دسترسی سریع</h4>
            <div style={{display:"flex",flexDirection:"column",gap:"6px",fontSize:"13px"}}>
              <Link href="/cargo" style={{color:"#9ca3af",transition:"color 0.2s"}}>جستجوی بار</Link>
              <Link href="/cargo/new" style={{color:"#9ca3af"}}>ثبت بار</Link>
              <Link href="/login" style={{color:"#9ca3af"}}>ورود به حساب</Link>
            </div>
          </div>
          <div>
            <h4 style={{color:"white",fontSize:"14px",fontWeight:"bold",marginBottom:"10px"}}>تماس با ما</h4>
            <div style={{fontSize:"13px",lineHeight:"2"}}>
              <p>📞 ۰۲۱-۱۲۳۴۵۶۷۸</p>
              <p dir="ltr" style={{textAlign:"right"}}>📧 info@ikia-logistics.ir</p>
            </div>
          </div>
        </div>
        <div style={{borderTop:"1px solid #1f2937",paddingTop:"16px",display:"flex",justifyContent:"space-between",alignItems:"center",fontSize:"12px",flexWrap:"wrap",gap:"8px"}}>
          <p>© ۱۴۰۴ iKIA Logistics — تمامی حقوق محفوظ است</p>
          <p>نسخه بتا ۰.۸</p>
        </div>
      </div>
    </footer>
  );
}

export function Loading({ color = "#3C3B6E" }: { color?: string }) {
  return (
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",background:"#f4f6f9"}}>
      <div style={{textAlign:"center"}} className="animate-fade">
        <div style={{width:"44px",height:"44px",border:"4px solid #e0e0e0",borderTop:`4px solid ${color}`,borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} />
        <p style={{color:"#888",marginTop:"12px",fontSize:"14px"}}>در حال بارگذاری...</p>
      </div>
    </div>
  );
}

export function EmptyState({ icon, title, description, actionText, actionHref }: { icon: string; title: string; description: string; actionText?: string; actionHref?: string }) {
  return (
    <div className="animate-fade" style={{background:"white",borderRadius:"20px",padding:"60px 24px",textAlign:"center",border:"2px dashed #e0e0e0"}}>
      <div style={{width:"72px",height:"72px",borderRadius:"50%",background:"#f0f4ff",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",fontSize:"32px"}} className="animate-float">{icon}</div>
      <h3 style={{fontSize:"18px",fontWeight:"bold",color:"#3C3B6E",marginBottom:"8px"}}>{title}</h3>
      <p style={{color:"#999",fontSize:"14px",marginBottom:"20px"}}>{description}</p>
      {actionText && actionHref && <Link href={actionHref} className="btn-primary" style={{display:"inline-block",padding:"12px 28px",fontSize:"14px"}}>{actionText}</Link>}
    </div>
  );
}

export function StatCard({ label, value, icon, color, bg, delay = 0 }: { label: string; value: number|string; icon: string; color: string; bg: string; delay?: number }) {
  return (
    <div className="card-hover animate-fade" style={{background:"white",padding:"20px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",animationDelay:`${delay}ms`}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"12px"}}>
        <span style={{fontSize:"13px",color:"#888",fontWeight:"bold"}}>{label}</span>
        <span style={{width:"36px",height:"36px",borderRadius:"10px",background:bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"18px"}}>{icon}</span>
      </div>
      <div style={{fontSize:"28px",fontWeight:"bold",color}}>{value}</div>
    </div>
  );
}

export function PageHeader({ title, subtitle, action }: { title: string; subtitle?: string; action?: React.ReactNode }) {
  return (
    <div className="animate-fade" style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"28px",flexWrap:"wrap",gap:"12px"}}>
      <div><h1 style={{fontSize:"24px",fontWeight:"bold",color:"#3C3B6E",margin:0}}>{title}</h1>{subtitle && <p style={{color:"#999",fontSize:"13px",marginTop:"4px"}}>{subtitle}</p>}</div>
      {action}
    </div>
  );
}
