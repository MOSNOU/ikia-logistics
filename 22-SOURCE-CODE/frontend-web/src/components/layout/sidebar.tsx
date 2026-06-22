import Link from "next/link";
import { RoleNav } from "@/components/navigation/role-nav";
import { portalNav, portalTitles, type Portal } from "@/lib/config/nav";
import type { Locale } from "@/lib/config/locale";
import { siteConfig } from "@/lib/config/site";

interface SidebarProps {
  portal: Portal;
  locale?: Locale;
}

export function Sidebar({ portal, locale = "fa" }: SidebarProps) {
  const title = locale === "fa" ? portalTitles[portal].fa : portalTitles[portal].en;
  const brand = locale === "fa" ? siteConfig.nameFa : siteConfig.nameEn;

  return (
    <aside className="hidden w-64 shrink-0 flex-col border-e bg-sidebar md:flex">
      <div className="flex h-14 items-center border-b px-4">
        <Link href="/" className="flex flex-col leading-tight">
          <span className="text-sm font-semibold">{brand}</span>
          <span className="text-xs text-muted-foreground">{title}</span>
        </Link>
      </div>
      <div className="flex-1 overflow-y-auto p-3">
        <RoleNav items={portalNav[portal]} locale={locale} />
      </div>
    </aside>
  );
}
