"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { LogoNav } from "@/components/Logo";
import { NotificationBell } from "@/components/Notifications";

export function DashboardLayout({ children, role, name, onSignOut }: { children: React.ReactNode; role: string; name?: string; onSignOut: () => void }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [dark, setDark] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const saved = localStorage.getItem("theme");
    if (saved === "dark") { setDark(true); document.documentElement.setAttribute("data-theme", "dark"); }
  }, []);

  const toggleDark = () => {
    const next = !dark;
    setDark(next);
    document.documentElement.setAttribute("data-theme", next ? "dark" : "light");
    localStorage.setItem("theme", next ? "dark" : "light");
  };

  const roleLabels: Record<string,string> = { admin:"ادمین", shipper:"بارفرست", carrier:"حمل‌کننده" };
  const roleColors: Record<string,string> = { admin:"#B22234", shipper:"#1e3a5f", carrier:"#0ea5e9" };

  const shipperLinks = [
    { href:"/shipper", label:"داشبورد", icon:"📊" },
    { href:"/cargo/new", label:"ثبت بار جدید", icon:"➕" },
    { href:"/cargo", label:"لیست بارها", icon:"📦" },
    { href:"/profile", label:"پروفایل", icon:"👤" },
  ];
  const carrierLinks = [
    { href:"/carrier", label:"داشبورد", icon:"📊" },
    { href:"/cargo", label:"جستجوی بار", icon:"🔍" },
    { href:"/profile", label:"پروفایل", icon:"👤" },
  ];
  const adminLinks = [
    { href:"/admin", label:"داشبورد مدیریت", icon:"📊" },
    { href:"/cargo", label:"لیست بارها", icon:"📦" },
    { href:"/profile", label:"پروفایل", icon:"👤" },
  ];

  const links = role === "admin" ? adminLinks : role === "carrier" ? carrierLinks : shipperLinks;

  return (
    <div style={{fontFamily:"Vazirmatn,sans-serif",direction:"rtl",background:"var(--bg)",color:"var(--text2)",minHeight:"100vh"}}>
      <div className={`sidebar-overlay ${sidebarOpen?"open":""}`} onClick={()=>setSidebarOpen(false)} />
      <aside className={`sidebar ${sidebarOpen?"open":""}`} style={{background:dark?"#1e293b":"#ffffff",borderLeftColor:"var(--border)"}}>
        <div style={{padding:"16px 20px 16px",borderBottom:"1px solid var(--border)"}}>
          <Link href="/" style={{textDecoration:"none"}}><LogoNav onDark={dark} /></Link>
        </div>
        <div style={{padding:"16px 12px"}}>
          <div style={{display:"flex",alignItems:"center",gap:"10px",padding:"12px",marginBottom:"12px",background:dark?"#334155":"#f0f4ff",borderRadius:"12px"}}>
            <div style={{width:"36px",height:"36px",borderRadius:"50%",background:`linear-gradient(135deg,${roleColors[role]},#2E75B6)`,display:"flex",alignItems:"center",justifyContent:"center",color:"white",fontSize:"15px",fontWeight:900}}>{name?.[0]||"؟"}</div>
            <div><div style={{fontSize:"13px",fontWeight:900,color:"var(--text)"}}>{name||"کاربر"}</div><div style={{fontSize:"11px",color:"var(--text3)"}}>{roleLabels[role]}</div></div>
          </div>
          <div style={{display:"flex",flexDirection:"column",gap:"4px"}}>
            {links.map(l=>(
              <Link key={l.href} href={l.href} onClick={()=>setSidebarOpen(false)}>
                <div style={{display:"flex",alignItems:"center",gap:"10px",padding:"12px 14px",borderRadius:"10px",fontSize:"14px",fontWeight:pathname===l.href?900:700,color:pathname===l.href?"var(--accent)":"var(--text2)",background:pathname===l.href?(dark?"#334155":"#ecfeff"):"transparent",transition:"all 0.2s"}}>
                  <span style={{fontSize:"18px"}}>{l.icon}</span>{l.label}
                </div>
              </Link>
            ))}
          </div>
        </div>
        <div style={{padding:"12px",borderTop:"1px solid var(--border)",marginTop:"auto"}}>
          <button onClick={toggleDark} style={{width:"100%",display:"flex",alignItems:"center",gap:"10px",padding:"12px 14px",borderRadius:"10px",fontSize:"14px",fontWeight:700,color:"var(--text2)",background:dark?"#334155":"#f0f4ff",border:"none",marginBottom:"8px",cursor:"pointer"}}>
            <span style={{fontSize:"18px"}}>{dark?"☀️":"🌙"}</span>{dark?"حالت روز":"حالت شب"}
          </button>
          <Link href="/about" onClick={()=>setSidebarOpen(false)}>
            <div style={{display:"flex",alignItems:"center",gap:"10px",padding:"12px 14px",borderRadius:"10px",fontSize:"14px",fontWeight:700,color:"var(--text3)"}}>
              <span style={{fontSize:"18px"}}>ℹ️</span>درباره ما
            </div>
          </Link>
          <button onClick={onSignOut} style={{width:"100%",display:"flex",alignItems:"center",gap:"10px",padding:"12px 14px",borderRadius:"10px",fontSize:"14px",fontWeight:900,color:"var(--danger)",background:"none",border:"none",cursor:"pointer"}}>
            <span style={{fontSize:"18px"}}>🚪</span>خروج
          </button>
        </div>
      </aside>

      <div className="main-with-sidebar" style={{background:"var(--bg)"}}>
        <nav className="nav-responsive" style={{padding:"12px 24px",background:dark?"#1e293b":"#ffffff",borderBottom:"1px solid var(--border)",display:"flex",justifyContent:"space-between",alignItems:"center",position:"sticky",top:0,zIndex:30,boxShadow:"0 1px 3px var(--shadow)"}}>
          <div style={{display:"flex",alignItems:"center",gap:"12px"}}>
            <button onClick={()=>setSidebarOpen(!sidebarOpen)} className="show-mobile" style={{display:"none",background:"none",border:"none",fontSize:"22px",padding:"4px",color:"var(--text)"}}>☰</button>
            <span style={{fontSize:"16px",fontWeight:900,color:"var(--text)"}} className="hide-mobile">{links.find(l=>l.href===pathname)?.label || "داشبورد"}</span>
          </div>
          <div style={{display:"flex",alignItems:"center",gap:"10px"}}>
            <NotificationBell />
            <button onClick={toggleDark} className="hide-mobile" style={{background:dark?"#334155":"#f0f4ff",border:"none",width:"34px",height:"34px",borderRadius:"8px",fontSize:"16px",display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer"}}>{dark?"☀️":"🌙"}</button>
          </div>
        </nav>
        <main style={{padding:"28px 24px",maxWidth:"1100px",margin:"0 auto"}} className="main-content animate-fade">
          {children}
        </main>
      </div>
    </div>
  );
}
