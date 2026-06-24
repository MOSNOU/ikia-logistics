import type { ReactNode } from "react";
import { DashboardShell } from "@/components/layout/dashboard-shell";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

export default async function BuyerLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole([ROLES.BUYER_ADMIN, ROLES.ORGANIZATION_ADMIN, ROLES.PLATFORM_ADMIN]);
  return (
    <DashboardShell portal="buyer" profile={profile}>
      {children}
    </DashboardShell>
  );
}
