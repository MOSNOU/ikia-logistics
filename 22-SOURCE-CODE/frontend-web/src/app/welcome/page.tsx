import { redirect } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { signOut } from "@/lib/auth/sign-out";
import { getProfile } from "@/lib/auth/get-profile";
import { createClient } from "@/lib/supabase/server";

export default async function WelcomePage() {
  const isAuthEnabled =
    !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!isAuthEnabled) {
    redirect("/");
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const profile = await getProfile();
  if (profile?.hasProfile && profile.primaryOrganizationId) {
    redirect("/dashboard");
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>در انتظار تأیید</CardTitle>
          <CardDescription>Pending approval</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1 text-sm">
            <p>حساب کاربری شما با موفقیت ایجاد شد.</p>
            <p className="text-muted-foreground">
              برای دسترسی به فضای کاری، یک مدیر باید شما را به یک سازمان متصل کند.
              لطفاً با مدیر تماس بگیرید تا حساب شما فعال شود.
            </p>
          </div>
          <div className="rounded-md border bg-muted/40 px-3 py-2 text-xs text-muted-foreground">
            {user.email}
          </div>
          <form action={signOut}>
            <Button type="submit" variant="outline" className="w-full">
              خروج
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
