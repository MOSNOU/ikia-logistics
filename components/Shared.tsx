"use client";
import Link from "next/link";
import { LogoNav } from "@/components/Logo";

export function Navbar({ role, name, onSignOut }: { role?: string; name?: string; onSignOut?: () => void }) {
  const roleLabels: Record<string,string> = { admin: "ادمین", shipper: "بارفرست", carrier: "حمل‌کننده" };
  const roleColors: Record<string,string> = { admin: "#B22234", shipper: "#1e3a5f", carrier: "#0ea5e9" };
  const isAdmin = role === "admin";
  return (
    <nav className="nav-responsive animate-slide-down" style={{padding:"12px 24px",background: isAdmin ? "linear-gradient(135deg,#1a1a2e,#16213e)" : "white",borderBottom: isAdmin ? "none" : "1px solid #eee",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:50,boxShadow: isAdmin ? "0 2px 10px rgba(0,0,0,0.2)" : "0 1px 3px rgba(0,0,0,0.05)"}}>
      <Link href="/" style={{textDecoration:"none"}}><LogoNav onDark={isAdmin} /></Link>
      {role && (
        <div style={{display:"flex",gap:"10px",alignItems:"center"}}>
          {name && (
            <div style={{display:"flex",alignItems:"center",gap:"6px"}}>
              <div style={{width:"30px",height:"30px",borderRadius:"50%",background:`linear-gradient(135deg,${roleColors[role]||"#1e3a5f"},#2E75B6)`,display:"flex",alignItems:"center",justifyContent:"center",color:"white",fontSize:"13px",fontWeight:900}}>{name[0]||"؟"}</div>
              <div className="hide-mobile"><div style={{fontSize:"12px",fontWeight:900,color:isAdmin?"white":"#333"}}>{name}</div><div style={{fontSize:"10px",color:isAdmin?"rgba(255,255,255,0.6)":"#999"}}>{roleLabels[role]}</div></div>
            </div>
          )}
          {!name && role && <span className="badge hide-mobile" style={{background:isAdmin?"rgba(178,34,52,0.2)":"#f0f4ff",color:isAdmin?"#fca5a5":roleColors[role],fontWeight:900}}>{roleLabels[role]}</span>}
          {onSignOut && <button onClick={onSignOut} style={{color:isAdmin?"#fca5a5":"#ef4444",background:isAdmin?"rgba(255,255,255,0.1)":"#fef2f2",border:`1px solid ${isAdmin?"rgba(255,255,255,0.2)":"#fecaca"}`,padding:"5px 12px",borderRadius:"8px",fontSize:"11px",fontWeight:900}}>خروج</button>}
        </div>
      )}
    </nav>
  );
}

export function Footer() {
  return (
    <footer style={{background:"#111827",color:"#9ca3af",padding:"36px 20px 20px",marginTop:"40px"}}>
      <div style={{maxWidth:"800px",margin:"0 auto"}}>
        <div className="footer-grid" style={{display:"flex",justifyContent:"space-between",marginBottom:"20px",gap:"20px"}}>
          <div>
            <div dir="ltr" style={{fontFamily:"Vazirmatn,sans-serif",marginBottom:"6px"}}><span style={{color:"#B22234",fontWeight:900,fontSize:"18px"}}>i</span><span style={{color:"white",fontWeight:900,fontSize:"18px"}}>KIA</span><span style={{color:"#9ca3af",fontWeight:700,fontSize:"18px",marginLeft:"4px"}}>Logistics</span></div>
            <p style={{fontSize:"12px",lineHeight:"1.8"}}>پلتفرم هوشمند حمل‌ونقل بار</p>
          </div>
          <div>
            <h4 style={{color:"white",fontSize:"13px",fontWeight:900,marginBottom:"8px"}}>دسترسی</h4>
            <div style={{display:"flex",flexDirection:"column",gap:"4px",fontSize:"12px"}}>
              <Link href="/cargo">جستجوی بار</Link>
              <Link href="/cargo/new">ثبت بار</Link>
              <Link href="/login">ورود</Link>
            </div>
          </div>
          <div>
            <h4 style={{color:"white",fontSize:"13px",fontWeight:900,marginBottom:"8px"}}>تماس</h4>
            <div style={{fontSize:"12px",lineHeight:"2"}}>
              <p>📞 ۰۲۱-۱۲۳۴۵۶۷۸</p>
              <p dir="ltr" style={{textAlign:"right"}}>📧 info@ikia.ir</p>
            </div>
          </div>
        </div>
        <div style={{borderTop:"1px solid #1f2937",paddingTop:"14px",display:"flex",justifyContent:"space-between",fontSize:"11px",flexWrap:"wrap",gap:"6px"}}>
          <p>© ۱۴۰۴ iKIA Logistics</p>
          <p>نسخه بتا</p>
        </div>
      </div>
    </footer>
  );
}

export function Loading({ color = "#1e3a5f" }: { color?: string }) {
  return (
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"Vazirmatn,sans-serif",background:"#f4f6f9"}}>
      <div style={{textAlign:"center"}} className="animate-fade">
        <div style={{width:"40px",height:"40px",border:"4px solid #e0e0e0",borderTop:`4px solid ${color}`,borderRadius:"50%",animation:"spin 1s linear infinite",margin:"0 auto"}} />
        <p style={{color:"#888",marginTop:"12px",fontSize:"13px",fontWeight:700}}>در حال بارگذاری...</p>
      </div>
    </div>
  );
}

export function EmptyState({ icon, title, description, actionText, actionHref }: { icon: string; title: string; description: string; actionText?: string; actionHref?: string }) {
  return (
    <div className="animate-fade" style={{background:"white",borderRadius:"20px",padding:"48px 20px",textAlign:"center",border:"2px dashed #e0e0e0"}}>
      <div style={{width:"64px",height:"64px",borderRadius:"50%",background:"#f0f4ff",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 14px",fontSize:"28px"}} className="animate-float">{icon}</div>
      <h3 style={{fontSize:"17px",fontWeight:900,color:"#1e3a5f",marginBottom:"8px"}}>{title}</h3>
      <p style={{color:"#888",fontSize:"13px",marginBottom:"18px",fontWeight:700}}>{description}</p>
      {actionText && actionHref && <Link href={actionHref} className="btn-primary" style={{display:"inline-block",padding:"12px 24px",fontSize:"14px"}}>{actionText}</Link>}
    </div>
  );
}

export function StatCard({ label, value, icon, color, bg, delay = 0 }: { label: string; value: number|string; icon: string; color: string; bg: string; delay?: number }) {
  return (
    <div className="card-hover animate-fade" style={{background:"white",padding:"18px",borderRadius:"14px",border:"1px solid #eee",boxShadow:"0 2px 8px rgba(0,0,0,0.04)",animationDelay:`${delay}ms`}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"10px"}}>
        <span style={{fontSize:"12px",color:"#888",fontWeight:900}}>{label}</span>
        <span style={{width:"32px",height:"32px",borderRadius:"8px",background:bg,display:"flex",alignItems:"center",justifyContent:"center",fontSize:"16px"}}>{icon}</span>
      </div>
      <div style={{fontSize:"26px",fontWeight:900,color}}>{value}</div>
    </div>
  );
}

export function PageHeader({ title, subtitle, action }: { title: string; subtitle?: string; action?: React.ReactNode }) {
  return (
    <div className="animate-fade page-header" style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:"24px",flexWrap:"wrap",gap:"12px"}}>
      <div><h1 style={{fontSize:"22px",fontWeight:900,color:"#1e3a5f",margin:0}}>{title}</h1>{subtitle && <p style={{color:"#888",fontSize:"12px",marginTop:"4px",fontWeight:700}}>{subtitle}</p>}</div>
      {action}
    </div>
  );
}
