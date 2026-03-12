"use client";
import { useEffect, useState } from "react";
import { getSupabase } from "@/lib/supabase/client";
import Link from "next/link";

export function NotificationBell() {
  const supabase = getSupabase();
  const [notifications, setNotifications] = useState<any[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const load = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const { data } = await supabase.from("notifications").select("*").eq("user_id", user.id).order("created_at", { ascending: false }).limit(20);
      setNotifications(data || []);
      setUnreadCount((data || []).filter((n: any) => !n.is_read).length);
    };
    load();
    const interval = setInterval(load, 30000);
    return () => clearInterval(interval);
  }, []);

  const markAllRead = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    await supabase.from("notifications").update({ is_read: true }).eq("user_id", user.id).eq("is_read", false);
    setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
    setUnreadCount(0);
  };

  const markRead = async (id: string) => {
    await supabase.from("notifications").update({ is_read: true }).eq("id", id);
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
    setUnreadCount(prev => Math.max(0, prev - 1));
  };

  const timeAgo = (date: string) => {
    const diff = Date.now() - new Date(date).getTime();
    const min = Math.floor(diff / 60000);
    if (min < 1) return "الان";
    if (min < 60) return `${min} دقیقه پیش`;
    const hr = Math.floor(min / 60);
    if (hr < 24) return `${hr} ساعت پیش`;
    return `${Math.floor(hr / 24)} روز پیش`;
  };

  const typeColors: Record<string, string> = { booking: "#f59e0b", confirmed: "#10b981", rejected: "#ef4444", delivered: "#0ea5e9", completed: "#059669", info: "#3b82f6" };

  return (
    <div style={{ position: "relative" }}>
      <button onClick={() => setOpen(!open)} style={{ background: "none", border: "none", fontSize: "20px", position: "relative", padding: "6px", cursor: "pointer" }}>
        🔔
        {unreadCount > 0 && (
          <span style={{ position: "absolute", top: "0", right: "0", background: "#ef4444", color: "white", fontSize: "10px", fontWeight: 900, width: "18px", height: "18px", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", border: "2px solid white", animation: "pulse 2s infinite" }}>
            {unreadCount > 9 ? "۹+" : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <>
          <div onClick={() => setOpen(false)} style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, zIndex: 98 }} />
          <div className="animate-scale" style={{ position: "absolute", top: "44px", left: "0", width: "340px", maxHeight: "440px", overflowY: "auto", background: "white", borderRadius: "16px", boxShadow: "0 8px 30px rgba(0,0,0,0.15)", border: "1px solid #eee", zIndex: 99, direction: "rtl" }}>
            <div style={{ padding: "14px 18px", borderBottom: "1px solid #f0f0f0", display: "flex", justifyContent: "space-between", alignItems: "center", position: "sticky", top: 0, background: "white", borderRadius: "16px 16px 0 0", zIndex: 1 }}>
              <span style={{ fontSize: "15px", fontWeight: 900, color: "#1e3a5f" }}>🔔 اعلان‌ها</span>
              {unreadCount > 0 && (
                <button onClick={markAllRead} style={{ background: "none", border: "none", color: "#0ea5e9", fontSize: "12px", fontWeight: 900, cursor: "pointer" }}>خواندم همه</button>
              )}
            </div>
            {notifications.length === 0 ? (
              <div style={{ padding: "40px 20px", textAlign: "center", color: "#999" }}>
                <div style={{ fontSize: "32px", marginBottom: "8px" }}>🔕</div>
                <p style={{ fontWeight: 700, fontSize: "13px" }}>اعلانی نداری</p>
              </div>
            ) : (
              notifications.map(n => (
                <Link href={n.link || "#"} key={n.id} onClick={() => { markRead(n.id); setOpen(false); }}>
                  <div style={{ padding: "14px 18px", borderBottom: "1px solid #f8f8f8", background: n.is_read ? "white" : "#f0f8ff", cursor: "pointer", transition: "background 0.2s", display: "flex", gap: "12px", alignItems: "flex-start" }}>
                    <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: n.is_read ? "transparent" : typeColors[n.type] || "#3b82f6", marginTop: "6px", flexShrink: 0 }} />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: "13px", fontWeight: 900, color: "#1e3a5f", marginBottom: "3px" }}>{n.title}</div>
                      <div style={{ fontSize: "12px", color: "#666", fontWeight: 700, lineHeight: "1.6" }}>{n.message}</div>
                      <div style={{ fontSize: "11px", color: "#bbb", marginTop: "4px", fontWeight: 700 }}>{timeAgo(n.created_at)}</div>
                    </div>
                  </div>
                </Link>
              ))
            )}
          </div>
        </>
      )}
    </div>
  );
}
