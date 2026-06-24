import type { ReactNode } from "react";
import { DashboardShell } from "@/components/layout/dashboard-shell";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

export default async function AdminLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole(ROLES.PLATFORM_ADMIN);
  return (
    <DashboardShell portal="admin" profile={profile}>
      {children}
    </DashboardShell>
  );
}
