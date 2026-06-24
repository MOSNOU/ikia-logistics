import type { ReactNode } from "react";
import { DashboardShell } from "@/components/layout/dashboard-shell";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

export default async function CarrierLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole([ROLES.CARRIER_ADMIN, ROLES.ORGANIZATION_ADMIN, ROLES.PLATFORM_ADMIN]);
  return (
    <DashboardShell portal="carrier" profile={profile}>
      {children}
    </DashboardShell>
  );
}
