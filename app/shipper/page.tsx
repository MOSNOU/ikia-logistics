"use client";
import Link from "next/link";
import { createBrowserClient } from "@supabase/ssr";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function ShipperDashboard() {
  const router = useRouter();
  const supabase = createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
  const [count, setCount] = useState(0);

  useEffect(() => {
    const fetchCount = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { count } = await supabase.from("cargo_posts").select("*", { count: "exact", head: true }).eq("shipper_id", user.id);
        setCount(count || 0);
      }
    };
    fetchCount();
  }, []);

  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };

  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <div style={{display:"flex",gap:"8px",alignItems:"center"}}>
          <span style={{background:"#e8f0fe",padding:"4px 12px",borderRadius:"20px",fontSize:"13px",color:"#1B3A5C"}}>بارفرست</span>
          <button onClick={handleSignOut} style={{color:"#ef4444",background:"none",border:"none",cursor:"pointer",fontSize:"14px"}}>خروج</button>
        </div>
      </nav>
      <main style={{maxWidth:"800px",margin:"0 auto",padding:"32px 16px"}}>
        <h1 style={{fontSize:"28px",color:"#1B3A5C",marginBottom:"32px"}}>سلام بارفرست 👋</h1>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(200px,1fr))",gap:"16px",marginBottom:"32px"}}>
          <Link href="/cargo/new" style={{textDecoration:"none"}}>
            <div style={{background:"#1B3A5C",color:"white",padding:"24px",borderRadius:"16px",cursor:"pointer"}}>
              <div style={{fontSize:"32px",marginBottom:"8px"}}>📦</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold"}}>ثبت بار جدید</h3>
              <p style={{fontSize:"14px",opacity:0.8}}>بار خودت رو ثبت کن</p>
            </div>
          </Link>
          <Link href="/cargo" style={{textDecoration:"none",color:"inherit"}}>
            <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
              <div style={{fontSize:"32px",marginBottom:"8px"}}>📋</div>
              <h3 style={{fontSize:"18px",fontWeight:"bold"}}>بارهای من</h3>
              <div style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C"}}>{count}</div>
            </div>
          </Link>
          <div style={{background:"white",padding:"24px",borderRadius:"16px",border:"1px solid #eee"}}>
            <div style={{fontSize:"32px",marginBottom:"8px"}}>🤝</div>
            <h3 style={{fontSize:"18px",fontWeight:"bold"}}>رزروها</h3>
            <div style={{fontSize:"28px",fontWeight:"bold",color:"#1B3A5C"}}>۰</div>
          </div>
        </div>
      </main>
    </div>
  );
}
