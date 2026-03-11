"use client";
import { useEffect, useState } from "react";
import { createBrowserClient } from "@supabase/ssr";
import Link from "next/link";
export default function CargoListPage() {
  const supabase = createBrowserClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
  const [cargos, setCargos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    const f = async () => {
      const { data } = await supabase.from("cargo_posts").select("*").eq("status","open").order("created_at",{ascending:false});
      setCargos(data || []);
      setLoading(false);
    };
    f();
  }, []);
  const formatPrice = (p:number|null) => { if(!p) return "توافقی"; return new Intl.NumberFormat("fa-IR").format(p/10)+" تومان"; };
  return (
    <div style={{minHeight:"100vh",fontFamily:"sans-serif",direction:"rtl",background:"#f9fafb",color:"#333"}}>
      <nav style={{padding:"16px",borderBottom:"1px solid #eee",background:"white",display:"flex",justifyContent:"space-between"}}>
        <Link href="/" style={{fontSize:"24px",fontWeight:"bold",color:"#1B3A5C",textDecoration:"none"}}>🚛 iKIA</Link>
        <Link href="/cargo/new" style={{color:"white",textDecoration:"none",fontSize:"14px",padding:"8px 16px",background:"#1B3A5C",borderRadius:"8px"}}>+ ثبت بار</Link>
      </nav>
      <main style={{maxWidth:"800px",margin:"0 auto",padding:"24px 16px"}}>
        <h1 style={{fontSize:"24px",color:"#1B3A5C",marginBottom:"24px"}}>🔍 بارهای موجود</h1>
        {loading ? <div style={{textAlign:"center",padding:"40px",color:"#999"}}>در حال بارگذاری...</div> : cargos.length===0 ? (
          <div style={{textAlign:"center",padding:"60px",background:"white",borderRadius:"16px",border:"2px dashed #ddd"}}>
            <div style={{fontSize:"48px",marginBottom:"16px"}}>📭</div>
            <h3 style={{color:"#333"}}>باری ثبت نشده</h3>
            <Link href="/cargo/new" style={{display:"inline-block",marginTop:"16px",padding:"12px 24px",background:"#1B3A5C",color:"white",borderRadius:"8px",textDecoration:"none"}}>📦 ثبت بار</Link>
          </div>
        ) : (
          <div style={{display:"flex",flexDirection:"column",gap:"12px"}}>
            {cargos.map(c=>(
              <Link href={"/cargo/"+c.id} key={c.id} style={{textDecoration:"none",color:"inherit"}}>
                <div style={{background:"white",padding:"20px",borderRadius:"12px",border:"1px solid #eee",cursor:"pointer"}}>
                  <div style={{display:"flex",justifyContent:"space-between",marginBottom:"8px"}}>
                    <span style={{fontSize:"18px",fontWeight:"bold",color:"#1B3A5C"}}>{c.origin_city} ← {c.dest_city}</span>
                    <span style={{background:"#e8f0fe",color:"#1B3A5C",padding:"4px 12px",borderRadius:"20px",fontSize:"13px"}}>{c.cargo_type}</span>
                  </div>
                  <div style={{fontSize:"14px",color:"#666"}}>📅 {c.pickup_date} {c.weight_tons && <span> | ⚖️ {c.weight_tons} تن</span>}</div>
                  <div style={{marginTop:"8px",fontSize:"16px",fontWeight:"bold",color:"#2E75B6"}}>{formatPrice(c.price_suggestion)}</div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
