"use client";

import { useEffect, useState } from "react";

// Phase D6 — subtle, non-blocking "add to home screen" hint for the driver
// dashboard. NO beforeinstallprompt handling, NO service worker, NO
// browser-specific logic — it only hides itself once the app is already running
// as an installed standalone PWA. Renders nothing on the server (and while
// installed) to avoid a flash of the hint inside the installed app.

export function DriverInstallHint() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const standalone =
      window.matchMedia?.("(display-mode: standalone)").matches ||
      // iOS Safari legacy flag.
      (window.navigator as unknown as { standalone?: boolean }).standalone ===
        true;
    setShow(!standalone);
  }, []);

  if (!show) return null;

  return (
    <div className="rounded-xl border border-dashed border-border-soft bg-card/60 px-4 py-3">
      <p className="text-xs leading-6 text-muted-foreground">
        برای دسترسی سریع‌تر، این صفحه را به صفحه اصلی موبایل اضافه کنید.
      </p>
    </div>
  );
}
