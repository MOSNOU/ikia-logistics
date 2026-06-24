import { notFound } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { getAdminUser } from "@/lib/admin/get-user";
import { listTenants } from "@/lib/admin/list-tenants";
import { listAdminOrganizations } from "@/lib/admin/list-organizations";
import { listUserRoleAssignments } from "@/lib/admin/list-memberships";
import { ALL_ROLES, ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";
import { ApproveUserForm } from "./approve-user-form";
import { SetUserStatusForm } from "./set-user-status-form";
import { AssignRoleForm } from "./assign-role-form";

interface PageProps {
  params: Promise<{ userId: string }>;
}

export default async function AdminUserDetailPage({ params }: PageProps) {
  const { userId } = await params;
  const [user, tenants, orgs, roleAssignments] = await Promise.all([
    getAdminUser(userId),
    listTenants(),
    listAdminOrganizations({ pageSize: 100 }),
    listUserRoleAssignments(userId),
  ]);

  if (!user) notFound();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">{user.email}</h1>
        <p className="text-sm text-muted-foreground">{user.user_id}</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>خلاصه کاربر</CardTitle>
          <CardDescription>User summary</CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-4 text-sm">
          <Field label="نام">{user.full_name ?? "—"}</Field>
          <Field label="وضعیت">
            <Badge variant={user.has_profile ? "success" : "warning"}>
              {user.status}
            </Badge>
          </Field>
          <Field label="تننت">{user.tenant_id ?? "—"}</Field>
          <Field label="سازمان فعال">{user.primary_organization_id ?? "—"}</Field>
        </CardContent>
      </Card>

      {!user.has_profile ? (
        <ApproveUserForm
          userId={user.user_id}
          tenants={tenants}
          organizations={orgs.rows}
          roles={ALL_ROLES}
        />
      ) : (
        <SetUserStatusForm userId={user.user_id} currentStatus={user.status} />
      )}

      <AssignRoleForm
        userId={user.user_id}
        roles={ALL_ROLES}
        organizations={orgs.rows}
      />

      <Card>
        <CardHeader>
          <CardTitle>نقش‌های اختصاص‌یافته</CardTitle>
          <CardDescription>{roleAssignments.length} active assignment(s)</CardDescription>
        </CardHeader>
        <CardContent>
          {roleAssignments.length === 0 ? (
            <p className="text-sm text-muted-foreground">هیچ نقشی اختصاص داده نشده.</p>
          ) : (
            <ul className="divide-y">
              {roleAssignments.map((r) => (
                <li key={r.userRoleId} className="flex items-center justify-between py-2 text-sm">
                  <div>
                    <span className="font-medium">
                      {r.roleCode ? ROLE_LABELS_FA[r.roleCode as Role] : "—"}
                    </span>
                    <span className="ms-2 text-xs text-muted-foreground">{r.roleCode}</span>
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {r.scopeType}
                    {r.scopeId ? ` · ${r.scopeId.slice(0, 8)}…` : ""}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="space-y-1">
      <p className="text-xs text-muted-foreground">{label}</p>
      <div className="font-mono text-xs">{children}</div>
    </div>
  );
}
