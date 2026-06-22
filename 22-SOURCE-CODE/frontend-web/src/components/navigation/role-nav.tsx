import { NavLink } from "./nav-link";
import type { NavItem } from "@/lib/config/nav";
import type { Locale } from "@/lib/config/locale";

interface RoleNavProps {
  items: NavItem[];
  locale?: Locale;
}

export function RoleNav({ items, locale = "fa" }: RoleNavProps) {
  return (
    <nav className="flex flex-col gap-1">
      {items.map((item) => {
        const Icon = item.icon;
        const label = locale === "fa" ? item.labelFa : item.labelEn;
        return (
          <NavLink key={item.href} href={item.href}>
            <Icon className="h-4 w-4 shrink-0" />
            <span className="truncate">{label}</span>
          </NavLink>
        );
      })}
    </nav>
  );
}
