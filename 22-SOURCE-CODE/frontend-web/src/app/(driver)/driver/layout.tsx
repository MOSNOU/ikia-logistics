import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import { DriverBottomNav } from "@/components/driver/driver-bottom-nav";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

// Phase D2 — mobile-first, self-contained driver shell.
// Reuses the existing requireRole guard (redirects to /login when there is no
// profile and /unauthorized for the wrong role). Does NOT use DashboardShell.
//
// Phase D6 — driver-area metadata + mobile-web-app polish (installable PWA
// basics). NO service worker / offline / background work is introduced here.

// Scoped to the /driver segment only — does not override global product
// metadata from the root layout. `title.absolute` bypasses the root title
// template so the installed app reads cleanly.
export const metadata: Metadata = {
  title: { absolute: "iKIA Driver | اپ رانندگان آی‌کیا" },
  description:
    "پرتال موبایل رانندگان برای مدیریت سفر، ارسال موقعیت، بارگذاری اسناد تحویل و گزارش مشکل.",
  applicationName: "iKIA Driver",
  appleWebApp: {
    capable: true,
    title: "iKIA Driver",
    statusBarStyle: "default",
  },
};

export const viewport: Viewport = {
  themeColor: "#0f172a",
  // Let content extend under the notch / home-indicator so the safe-area env()
  // insets used by the header and bottom nav resolve to real values.
  viewportFit: "cover",
};

export default async function DriverLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole([ROLES.DRIVER, ROLES.PLATFORM_ADMIN]);

  return (
    <div className="min-h-dvh overflow-x-hidden bg-surface-muted">
      {/* Slim top bar — respects the top safe-area inset in standalone mode. */}
      <header className="sticky top-0 z-30 border-b border-border-soft bg-card/95 pt-[env(safe-area-inset-top)] backdrop-blur">
        <div className="mx-auto flex max-w-md items-center justify-between gap-3 px-4 py-3">
          <span className="text-sm font-semibold tracking-tight">
            اپ راننده iKIA
          </span>
          {profile?.fullName ? (
            <span className="truncate text-xs text-muted-foreground">
              {profile.fullName}
            </span>
          ) : null}
        </div>
      </header>

      {/* Mobile content container — extra bottom padding clears the fixed nav. */}
      <main className="mx-auto max-w-md px-4 pb-24 pt-4">{children}</main>

      <DriverBottomNav />
    </div>
  );
}
