import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { requireRole } from "@/lib/auth/require-role";
import { ROLES } from "@/lib/permissions/roles";

// Phase D2 — driver profile (READ-ONLY placeholder). Persian RTL.

// D7 — this page is auth-gated and renders the signed-in driver's own PII
// (name/email). Force dynamic rendering so it is never statically prerendered
// or cached, regardless of build-time auth-env presence. Matches the
// convention already used by the admin/driver-trips pages.
export const dynamic = "force-dynamic";

export default async function DriverProfilePage() {
  const profile = await requireRole([ROLES.DRIVER, ROLES.PLATFORM_ADMIN]);

  return (
    <div className="space-y-5">
      <Card className="border-border-soft shadow-elevated">
        <CardContent className="space-y-1 p-5">
          <h1 className="text-xl font-semibold tracking-tight">پروفایل راننده</h1>
          <p className="text-sm leading-7 text-muted-foreground">
            اطلاعات حساب شما. ویرایش در فاز بعد فعال می‌شود.
          </p>
        </CardContent>
      </Card>

      {/* Driver profile. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-3 p-4">
          <h2 className="text-sm font-semibold tracking-tight">مشخصات راننده</h2>
          <dl className="space-y-2 text-sm">
            <div className="flex items-center justify-between gap-3">
              <dt className="text-muted-foreground">نام</dt>
              <dd className="font-medium">{profile?.fullName ?? "—"}</dd>
            </div>
            <div className="flex items-center justify-between gap-3">
              <dt className="text-muted-foreground">ایمیل</dt>
              <dd className="break-all font-mono text-xs">{profile?.email ?? "—"}</dd>
            </div>
          </dl>
        </CardContent>
      </Card>

      {/* Vehicle info placeholder. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-2 p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="text-sm font-semibold tracking-tight">اطلاعات خودرو</h2>
            <Badge variant="muted">به‌زودی</Badge>
          </div>
          <p className="text-xs leading-6 text-muted-foreground">
            مشخصات خودروی اختصاص‌یافته در فاز بعد نمایش داده می‌شود.
          </p>
        </CardContent>
      </Card>

      {/* Document status placeholder. */}
      <Card className="border-border-soft shadow-card">
        <CardContent className="space-y-2 p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="text-sm font-semibold tracking-tight">وضعیت مدارک</h2>
            <Badge variant="muted">به‌زودی</Badge>
          </div>
          <p className="text-xs leading-6 text-muted-foreground">
            وضعیت گواهینامه و مدارک خودرو در فاز بعد اضافه می‌شود.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
