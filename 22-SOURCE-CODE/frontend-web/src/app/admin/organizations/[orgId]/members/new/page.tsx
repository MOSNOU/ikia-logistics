import { notFound } from "next/navigation";
import { getAdminOrganization } from "@/lib/admin/list-organizations";
import { listAdminUsers } from "@/lib/admin/list-users";
import { ALL_ROLES } from "@/lib/permissions/roles";
import { AddMembershipForm } from "./add-membership-form";

interface PageProps {
  params: Promise<{ orgId: string }>;
}

export default async function AdminAddMembershipPage({ params }: PageProps) {
  const { orgId } = await params;
  const [org, activeUsers] = await Promise.all([
    getAdminOrganization(orgId),
    listAdminUsers({ pageSize: 100, status: "active" }),
  ]);
  if (!org) notFound();

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">افزودن عضو</h1>
        <p className="text-sm text-muted-foreground">
          سازمان: {org.nameFa} ({org.code})
        </p>
      </div>
      <AddMembershipForm
        organizationId={org.id}
        roles={ALL_ROLES}
        users={activeUsers.rows.map((u) => ({
          userId: u.user_id,
          email: u.email,
          fullName: u.full_name,
        }))}
      />
    </div>
  );
}
