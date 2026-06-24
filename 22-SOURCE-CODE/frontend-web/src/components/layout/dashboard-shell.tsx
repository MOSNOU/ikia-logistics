import type { ReactNode } from "react";
import { Sidebar } from "./sidebar";
import { TopNav } from "./top-nav";
import type { Portal } from "@/lib/config/nav";
import type { Locale } from "@/lib/config/locale";
import type { AuthProfile } from "@/lib/auth/get-profile";

interface DashboardShellProps {
  portal: Portal;
  profile?: AuthProfile | null;
  locale?: Locale;
  children: ReactNode;
}

export function DashboardShell({
  portal,
  profile,
  locale = "fa",
  children,
}: DashboardShellProps) {
  return (
    <div className="flex min-h-screen bg-muted/30">
      <Sidebar portal={portal} locale={locale} />
      <div className="flex min-w-0 flex-1 flex-col">
        <TopNav profile={profile} locale={locale} />
        <main className="flex-1 p-4 md:p-6">{children}</main>
      </div>
    </div>
  );
}
