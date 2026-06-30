"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, User } from "lucide-react";
import { cn } from "@/lib/utils";

// Phase D2 — self-contained mobile bottom nav for the driver portal.
// Deliberately NOT wired into the desktop DashboardShell/Sidebar/nav.ts
// system (that is keyed by Portal and would risk the other portals).

interface DriverNavItem {
  href: string;
  label: string;
  Icon: typeof LayoutDashboard;
}

const NAV_ITEMS: DriverNavItem[] = [
  { href: "/driver", label: "داشبورد", Icon: LayoutDashboard },
  { href: "/driver/profile", label: "پروفایل", Icon: User },
];

export function DriverBottomNav() {
  const pathname = usePathname();

  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-40 border-t border-border-soft bg-card/95 backdrop-blur"
      aria-label="ناوبری راننده"
    >
      <ul className="mx-auto flex max-w-md items-stretch">
        {NAV_ITEMS.map(({ href, label, Icon }) => {
          const active =
            href === "/driver"
              ? pathname === "/driver"
              : pathname === href || pathname.startsWith(`${href}/`);
          return (
            <li key={href} className="flex-1">
              <Link
                href={href}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex h-14 flex-col items-center justify-center gap-1 text-xs font-medium transition-colors",
                  active
                    ? "text-primary"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <Icon className="h-5 w-5" aria-hidden />
                <span>{label}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
