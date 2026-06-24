import { redirect } from "next/navigation";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { getProfile } from "@/lib/auth/get-profile";
import { ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";

const isAuthEnabled =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export default async function ProfilePage() {
  if (!isAuthEnabled) {
    redirect("/");
  }

  const profile = await getProfile();
  if (!profile) redirect("/login");
  if (!profile.hasProfile || !profile.primaryOrganizationId) redirect("/welcome");

  const activeMembership = profile.memberships.find(
    (m) => m.organizationId === profile.primaryOrganizationId,
  );

  return (
    <div className="mx-auto max-w-3xl space-y-6 px-4 py-10">
      <div>
        <h1 className="text-2xl font-semibold">پروفایل من</h1>
        <p className="text-sm text-muted-foreground">My profile</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>هویت</CardTitle>
          <CardDescription>Identity</CardDescription>
        </CardHeader>
        <CardContent>
          <DescList
            items={[
              { label: "ایمیل", value: profile.email },
              { label: "نام", value: profile.fullName ?? "—" },
              { label: "شناسه کاربر", value: profile.userId, mono: true },
            ]}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>فضای کاری فعال</CardTitle>
          <CardDescription>Active workspace</CardDescription>
        </CardHeader>
        <CardContent>
          <DescList
            items={[
              { label: "تننت", value: profile.tenantId ?? "—", mono: true },
              {
                label: "سازمان فعال",
                value:
                  activeMembership?.organizationNameFa ??
                  profile.primaryOrganizationId ??
                  "—",
              },
              {
                label: "نقش در سازمان",
                value: activeMembership?.roleCode
                  ? ROLE_LABELS_FA[activeMembership.roleCode as Role]
                  : "—",
              },
            ]}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>نقش‌ها</CardTitle>
          <CardDescription>{profile.roles.length} role(s)</CardDescription>
        </CardHeader>
        <CardContent>
          {profile.roles.length === 0 ? (
            <p className="text-sm text-muted-foreground">هیچ نقشی اختصاص داده نشده.</p>
          ) : (
            <ul className="flex flex-wrap gap-2">
              {profile.roles.map((role) => (
                <li
                  key={role}
                  className="rounded-md border bg-muted/40 px-3 py-1 text-xs"
                >
                  {ROLE_LABELS_FA[role]}
                  <span className="ms-2 text-muted-foreground">{role}</span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>سازمان‌های من</CardTitle>
          <CardDescription>{profile.memberships.length} membership(s)</CardDescription>
        </CardHeader>
        <CardContent>
          {profile.memberships.length === 0 ? (
            <p className="text-sm text-muted-foreground">عضو هیچ سازمانی نیستید.</p>
          ) : (
            <ul className="divide-y">
              {profile.memberships.map((m) => (
                <li
                  key={m.membershipId}
                  className="flex items-center justify-between gap-4 py-3"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium">
                      {m.organizationNameFa ?? m.organizationCode ?? m.organizationId}
                    </p>
                    {m.organizationNameEn ? (
                      <p className="truncate text-xs text-muted-foreground">
                        {m.organizationNameEn}
                      </p>
                    ) : null}
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {m.roleCode ? ROLE_LABELS_FA[m.roleCode as Role] : "—"}
                    {m.organizationId === profile.primaryOrganizationId ? (
                      <span className="ms-2 rounded-md border px-2 py-0.5 text-[10px] text-foreground">
                        فعال
                      </span>
                    ) : null}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>دسترسی‌ها</CardTitle>
          <CardDescription>{profile.permissions.length} permission(s)</CardDescription>
        </CardHeader>
        <CardContent>
          {profile.permissions.length === 0 ? (
            <p className="text-sm text-muted-foreground">هیچ دسترسی‌ای محاسبه نشده.</p>
          ) : (
            <details>
              <summary className="cursor-pointer text-sm text-muted-foreground">
                نمایش {profile.permissions.length} دسترسی
              </summary>
              <ul className="mt-3 grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
                {profile.permissions.sort().map((p) => (
                  <li key={p} className="font-mono text-muted-foreground">{p}</li>
                ))}
              </ul>
            </details>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function DescList({
  items,
}: {
  items: { label: string; value: string; mono?: boolean }[];
}) {
  return (
    <dl className="grid grid-cols-[max-content_1fr] gap-x-6 gap-y-2 text-sm">
      {items.map((it) => (
        <div key={it.label} className="contents">
          <dt className="text-muted-foreground">{it.label}</dt>
          <dd className={it.mono ? "font-mono text-xs" : ""}>{it.value}</dd>
        </div>
      ))}
    </dl>
  );
}
