import { Button } from "@/components/ui/button";
import { signOut } from "@/lib/auth/sign-out";
import { LogOut } from "lucide-react";
import { OrgSwitcher } from "./org-switcher";
import type { Locale } from "@/lib/config/locale";
import type { AuthProfile } from "@/lib/auth/get-profile";

interface TopNavProps {
  profile?: AuthProfile | null;
  locale?: Locale;
}

export function TopNav({ profile, locale = "fa" }: TopNavProps) {
  const t = (fa: string, en: string) => (locale === "fa" ? fa : en);
  const userEmail = profile?.email ?? null;
  const memberships = profile?.memberships ?? [];
  const currentOrgId = profile?.primaryOrganizationId ?? null;

  return (
    <header className="flex h-14 items-center justify-between border-b bg-background px-4 md:px-6">
      <div className="flex items-center gap-3">
        <span className="text-sm font-medium md:hidden">
          {t("منوی پنل", "Portal menu")}
        </span>
      </div>
      <div className="flex items-center gap-3">
        <OrgSwitcher
          memberships={memberships}
          currentOrgId={currentOrgId}
          locale={locale}
        />
        {userEmail ? (
          <span className="hidden text-sm text-muted-foreground sm:inline">{userEmail}</span>
        ) : null}
        <form action={signOut}>
          <Button type="submit" variant="ghost" size="sm">
            <LogOut className="h-4 w-4" />
            <span>{t("خروج", "Sign out")}</span>
          </Button>
        </form>
      </div>
    </header>
  );
}
