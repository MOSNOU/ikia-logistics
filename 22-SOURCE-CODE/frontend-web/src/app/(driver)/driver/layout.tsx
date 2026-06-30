import type { ReactNode } from "react";
import { DriverBottomNav } from "@/components/driver/driver-bottom-nav";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

// Phase D2 — mobile-first, self-contained driver shell.
// Reuses the existing requireRole guard (redirects to /login when there is no
// profile and /unauthorized for the wrong role). Does NOT use DashboardShell.

export default async function DriverLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole([ROLES.DRIVER, ROLES.PLATFORM_ADMIN]);

  return (
    <div className="min-h-dvh bg-surface-muted">
      {/* Slim top bar. */}
      <header className="sticky top-0 z-30 border-b border-border-soft bg-card/95 backdrop-blur">
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
