import type { ReactNode } from "react";
import { DashboardShell } from "@/components/layout/dashboard-shell";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

export default async function SupplierLayout({ children }: { children: ReactNode }) {
  const profile = await requireRole([ROLES.SUPPLIER_ADMIN, ROLES.ORGANIZATION_ADMIN, ROLES.PLATFORM_ADMIN]);
  return (
    <DashboardShell portal="supplier" profile={profile}>
      {children}
    </DashboardShell>
  );
}
