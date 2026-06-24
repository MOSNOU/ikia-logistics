import { redirect } from "next/navigation";
import { Card, CardContent } from "@/components/ui/card";
import { getProfile } from "@/lib/auth/get-profile";
import { PreferencesForm } from "./preferences-form";

const isAuthEnabled =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export default async function InboxPreferencesPage() {
  if (!isAuthEnabled) redirect("/");
  const profile = await getProfile();
  if (!profile) redirect("/login");

  const organizationId = profile.primaryOrganizationId ?? null;

  return (
    <div className="mx-auto max-w-3xl space-y-6 px-4 py-10">
      <div>
        <h1 className="text-2xl font-semibold">تنظیمات اعلان</h1>
        <p className="text-sm text-muted-foreground">
          فعال یا غیرفعال‌سازی اعلان‌ها بر اساس دسته و کانال. تنها کانال درون‌برنامه (in_app) در این فاز فعال است؛ بقیه کانال‌ها در فاز بعدی پیاده‌سازی می‌شوند.
        </p>
      </div>

      {organizationId ? (
        <PreferencesForm organizationId={organizationId} />
      ) : (
        <Card>
          <CardContent className="p-6 text-sm text-muted-foreground">
            سازمان فعالی برای این کاربر تعریف نشده است.
          </CardContent>
        </Card>
      )}
    </div>
  );
}
