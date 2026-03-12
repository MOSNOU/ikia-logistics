"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { Navbar, Footer, Loading } from "@/components/Shared";
export default function ProfilePage() {
  const supabase = getSupabase();
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({ full_name: "", phone: "", company_name: "" });
  const [stats, setStats] = useState({ cargos: 0, bookings: 0, reviews: 0, avgRating: 0 });
  useEffect(() => {
    const f = async () => {
      const { data: { user: u } } = await supabase.auth.getUser();
      if (!u) { router.push("/login"); return; }
      setUser(u);
      const { data: p } = await supabase.from("profiles").select("*").eq("id", u.id).single();
      setProfile(p);
      if (p) setForm({ full_name: p.full_name || "", phone: p.phone || "", company_name: p.company_name || "" });
      if (p?.role === "shipper") {
        const { count: cc } = await supabase.from("cargo_posts").select("*", { count: "exact", head: true }).eq("shipper_id", u.id);
        const { data: bk } = await supabase.from("cargo_posts").select("id").eq("shipper_id", u.id);
        const ids = (bk || []).map((x: any) => x.id);
        let bc = 0;
        if (ids.length > 0) {
          const { count } = await supabase.from("bookings").select("*", { count: "exact", head: true }).in("cargo_post_id", ids);
          bc = count || 0;
        }
        setStats({ cargos: cc || 0, bookings: bc, reviews: 0, avgRating: 0 });
      } else if (p?.role === "carrier") {
        const { count: bc } = await supabase.from("bookings").select("*", { count: "exact", head: true }).eq("carrier_id", u.id);
        const { data: rv } = await supabase.from("reviews").select("rating").eq("reviewee_id", u.id);
        const ratings = rv || [];
        setStats({ cargos: 0, bookings: bc || 0, reviews: ratings.length, avgRating: ratings.length > 0 ? Math.round((ratings.reduce((a: number, x: any) => a + x.rating, 0) / ratings.length) * 10) / 10 : 0 });
      }
      setLoading(false);
    }; f();
  }, []);
  const handleSignOut = async () => { await supabase.auth.signOut(); router.push("/"); };
  const handleSave = async () => {
    setError(""); setSuccess(false); setSaving(true);
    if (!form.full_name.trim()) { setError("نام رو وارد کن"); setSaving(false); return; }
    const { error: e } = await supabase.from("profiles").update({ full_name: form.full_name, phone: form.phone, company_name: form.company_name }).eq("id", user.id);
    if (e) setError("خطا: " + e.message); else { setSuccess(true); setTimeout(() => setSuccess(false), 3000); }
    setSaving(false);
  };
  const roleLabels: Record<string, string> = { admin: "ادمین", shipper: "بارفرست", carrier: "حمل‌کننده" };
  const roleColors: Record<string, string> = { admin: "#B22234", shipper: "#1e3a5f", carrier: "#0ea5e9" };
  const roleBg: Record<string, string> = { admin: "#fef2f2", shipper: "#f0f4ff", carrier: "#ecfeff" };
  if (loading) return <Loading />;
  return (
    <div style={{ minHeight: "100vh", fontFamily: "Vazirmatn,sans-serif", direction: "rtl", background: "#f4f6f9", color: "#333" }}>
      <Navbar role={profile?.role} name={profile?.full_name} onSignOut={handleSignOut} />
      <main style={{ maxWidth: "700px", margin: "0 auto", padding: "32px 20px" }} className="main-content">
        <div className="animate-fade" style={{ background: "linear-gradient(135deg,#0f172a,#1e3a5f)", padding: "32px", borderRadius: "20px", color: "white", marginBottom: "20px", position: "relative", overflow: "hidden" }}>
          <div style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0, background: "radial-gradient(ellipse at 30% 50%, rgba(6,182,212,0.15) 0%, transparent 60%)", pointerEvents: "none" }} />
          <div style={{ position: "relative", zIndex: 1, display: "flex", alignItems: "center", gap: "20px", flexWrap: "wrap" }}>
            <div style={{ width: "72px", height: "72px", borderRadius: "50%", background: `linear-gradient(135deg,${roleColors[profile?.role] || "#1e3a5f"},#2E75B6)`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: "28px", fontWeight: 900, border: "3px solid rgba(255,255,255,0.3)" }}>
              {form.full_name?.[0] || "؟"}
            </div>
            <div>
              <h1 style={{ fontSize: "22px", fontWeight: 900, marginBottom: "4px" }}>{form.full_name || "کاربر"}</h1>
              <div style={{ display: "flex", gap: "8px", alignItems: "center", flexWrap: "wrap" }}>
                <span style={{ background: "rgba(255,255,255,0.15)", padding: "4px 14px", borderRadius: "20px", fontSize: "13px", fontWeight: 900 }}>{roleLabels[profile?.role] || "کاربر"}</span>
                <span style={{ opacity: 0.7, fontSize: "13px", fontWeight: 700 }} dir="ltr">{user?.email}</span>
              </div>
            </div>
          </div>
        </div>

        {profile?.role !== "admin" && (
          <div className="animate-fade stat-grid" style={{ display: "grid", gridTemplateColumns: profile?.role === "shipper" ? "1fr 1fr" : "1fr 1fr 1fr", gap: "14px", marginBottom: "20px" }}>
            {profile?.role === "shipper" && <>
              <div className="card-hover" style={{ background: "white", padding: "18px", borderRadius: "14px", border: "1px solid #eee", textAlign: "center" }}>
                <div style={{ fontSize: "24px", fontWeight: 900, color: "#0ea5e9" }}>{stats.cargos}</div>
                <div style={{ fontSize: "12px", color: "#888", fontWeight: 900, marginTop: "4px" }}>بار ثبت شده</div>
              </div>
              <div className="card-hover" style={{ background: "white", padding: "18px", borderRadius: "14px", border: "1px solid #eee", textAlign: "center" }}>
                <div style={{ fontSize: "24px", fontWeight: 900, color: "#10b981" }}>{stats.bookings}</div>
                <div style={{ fontSize: "12px", color: "#888", fontWeight: 900, marginTop: "4px" }}>رزرو دریافتی</div>
              </div>
            </>}
            {profile?.role === "carrier" && <>
              <div className="card-hover" style={{ background: "white", padding: "18px", borderRadius: "14px", border: "1px solid #eee", textAlign: "center" }}>
                <div style={{ fontSize: "24px", fontWeight: 900, color: "#0ea5e9" }}>{stats.bookings}</div>
                <div style={{ fontSize: "12px", color: "#888", fontWeight: 900, marginTop: "4px" }}>رزرو</div>
              </div>
              <div className="card-hover" style={{ background: "white", padding: "18px", borderRadius: "14px", border: "1px solid #eee", textAlign: "center" }}>
                <div style={{ fontSize: "24px", fontWeight: 900, color: "#f59e0b" }}>{stats.avgRating > 0 ? stats.avgRating : "—"}</div>
                <div style={{ fontSize: "12px", color: "#888", fontWeight: 900, marginTop: "4px" }}>امتیاز</div>
              </div>
              <div className="card-hover" style={{ background: "white", padding: "18px", borderRadius: "14px", border: "1px solid #eee", textAlign: "center" }}>
                <div style={{ fontSize: "24px", fontWeight: 900, color: "#8b5cf6" }}>{stats.reviews}</div>
                <div style={{ fontSize: "12px", color: "#888", fontWeight: 900, marginTop: "4px" }}>نظر</div>
              </div>
            </>}
          </div>
        )}

        <div className="animate-fade-up" style={{ background: "white", padding: "28px", borderRadius: "20px", border: "1px solid #eee", boxShadow: "0 4px 20px rgba(0,0,0,0.06)", marginBottom: "20px" }}>
          <h2 style={{ fontSize: "18px", fontWeight: 900, color: "#1e3a5f", marginBottom: "24px", display: "flex", alignItems: "center", gap: "8px" }}>
            <span style={{ width: "32px", height: "32px", borderRadius: "8px", background: "#f0f4ff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "16px" }}>✏️</span>
            ویرایش اطلاعات
          </h2>
          <div style={{ marginBottom: "18px" }}>
            <label style={{ display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: 900, color: "#444" }}>نام و نام خانوادگی *</label>
            <input type="text" value={form.full_name} onChange={e => setForm({ ...form, full_name: e.target.value })} placeholder="مثلاً: علی احمدی" className="input-field" />
          </div>
          <div style={{ marginBottom: "18px" }}>
            <label style={{ display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: 900, color: "#444" }}>شماره تلفن</label>
            <input type="tel" dir="ltr" value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} placeholder="09123456789" className="input-field" />
          </div>
          <div style={{ marginBottom: "24px" }}>
            <label style={{ display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: 900, color: "#444" }}>نام شرکت (اختیاری)</label>
            <input type="text" value={form.company_name} onChange={e => setForm({ ...form, company_name: e.target.value })} placeholder="مثلاً: حمل‌ونقل احمدی" className="input-field" />
          </div>
          {error && <div className="animate-scale" style={{ background: "#fef2f2", color: "#dc2626", padding: "12px", borderRadius: "10px", marginBottom: "16px", fontSize: "14px", fontWeight: 700, border: "1px solid #fecaca" }}>⚠️ {error}</div>}
          {success && <div className="animate-scale" style={{ background: "#ecfdf5", color: "#059669", padding: "12px", borderRadius: "10px", marginBottom: "16px", fontSize: "14px", fontWeight: 700, border: "1px solid #a7f3d0" }}>✅ اطلاعات ذخیره شد!</div>}
          <button onClick={handleSave} disabled={saving} style={{ width: "100%", padding: "16px", background: "linear-gradient(135deg,#0f172a,#1e3a5f)", color: "white", border: "none", borderRadius: "14px", fontSize: "16px", fontWeight: 900, fontFamily: "inherit", boxShadow: "0 4px 15px rgba(15,23,42,0.3)", cursor: "pointer" }}>
            {saving ? "در حال ذخیره..." : "💾 ذخیره تغییرات"}
          </button>
        </div>

        <div className="animate-fade" style={{ background: "white", padding: "24px", borderRadius: "20px", border: "1px solid #eee", boxShadow: "0 4px 20px rgba(0,0,0,0.06)" }}>
          <h2 style={{ fontSize: "18px", fontWeight: 900, color: "#1e3a5f", marginBottom: "16px" }}>⚙️ تنظیمات حساب</h2>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "14px 0", borderBottom: "1px solid #f0f0f0" }}>
            <div><div style={{ fontSize: "14px", fontWeight: 900, color: "#333" }}>ایمیل</div><div style={{ fontSize: "12px", color: "#888", fontWeight: 700 }} dir="ltr">{user?.email}</div></div>
            <span className="badge" style={{ background: "#ecfdf5", color: "#059669" }}>تأیید شده</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "14px 0", borderBottom: "1px solid #f0f0f0" }}>
            <div><div style={{ fontSize: "14px", fontWeight: 900, color: "#333" }}>نقش</div><div style={{ fontSize: "12px", color: "#888", fontWeight: 700 }}>{roleLabels[profile?.role]}</div></div>
            <span className="badge" style={{ background: roleBg[profile?.role], color: roleColors[profile?.role] }}>{roleLabels[profile?.role]}</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "14px 0" }}>
            <div><div style={{ fontSize: "14px", fontWeight: 900, color: "#333" }}>تاریخ عضویت</div><div style={{ fontSize: "12px", color: "#888", fontWeight: 700 }}>{new Date(user?.created_at).toLocaleDateString("fa-IR")}</div></div>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
