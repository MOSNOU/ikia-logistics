"use client";

import Link from "next/link";
import { ChevronDown, ArrowLeft } from "lucide-react";
import type { NavGroup, NavLink } from "@/content/siteArchitecture";

const STATUS_LABEL: Record<string, string> = {
  current: "فعال",
  "near-future": "به‌زودی",
  "strategic-future": "نقشه راه",
};

// Desktop menubar + mega panel. Stateless: Navbar owns openKey and handlers.
// Click-to-open (toggle); the open panel closes on outside click / Escape,
// both handled in Navbar.
export function MegaMenu({
  groups,
  simpleNav,
  openKey,
  onToggle,
  onClose,
}: {
  groups: NavGroup[];
  simpleNav: NavLink[];
  openKey: string | null;
  onToggle: (key: string) => void;
  onClose: () => void;
}) {
  return (
    <nav aria-label="منوی اصلی" className="hidden lg:block">
      <ul className="flex items-center gap-0.5">
        {groups.map((group) => {
          const isOpen = openKey === group.key;
          return (
            <li key={group.key} className="static">
              <button
                type="button"
                aria-haspopup="true"
                aria-expanded={isOpen}
                onClick={() => onToggle(group.key)}
                className={`flex items-center gap-1 rounded-lg px-3 py-2 text-[14px] font-semibold transition-colors ${
                  isOpen ? "bg-soft text-ink" : "text-muted hover:bg-soft hover:text-ink"
                }`}
              >
                {group.label}
                <ChevronDown
                  size={15}
                  className={`transition-transform duration-200 ${isOpen ? "rotate-180" : ""}`}
                  aria-hidden
                />
              </button>

              {isOpen ? (
                <div className="absolute inset-x-0 top-full z-40">
                  <div className="border-t border-line bg-white shadow-[0_24px_48px_-24px_rgba(6,26,47,0.22)]">
                    <div className="mx-auto w-full max-w-7xl px-4 py-7 sm:px-6 lg:px-8">
                      {group.overviewHref ? (
                        <Link
                          href={group.overviewHref}
                          onClick={onClose}
                          className="mb-5 inline-flex items-center gap-1.5 text-[12px] font-bold text-blue transition-all hover:gap-2.5"
                        >
                          {group.overviewLabel ?? `نمای کلی ${group.label}`}
                          <ArrowLeft size={13} aria-hidden />
                        </Link>
                      ) : null}
                      <ul className="grid grid-cols-2 gap-1.5 lg:grid-cols-3">
                        {group.links.map((link) => (
                          <li key={link.href}>
                            <Link
                              href={link.href}
                              onClick={onClose}
                              className="group block rounded-xl border border-transparent p-3.5 transition hover:border-line hover:bg-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue/40"
                            >
                              <span className="flex items-center gap-2">
                                <span className="text-[14px] font-bold text-ink transition-colors group-hover:text-blue">
                                  {link.label}
                                </span>
                                {link.status && link.status !== "current" ? (
                                  <span className="rounded-full bg-soft-2 px-1.5 py-0.5 text-[10px] font-semibold text-muted">
                                    {STATUS_LABEL[link.status]}
                                  </span>
                                ) : null}
                              </span>
                              {link.desc ? (
                                <span className="mt-1 block text-[12px] leading-6 text-muted">{link.desc}</span>
                              ) : null}
                            </Link>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              ) : null}
            </li>
          );
        })}

        {simpleNav.map((link) => (
          <li key={link.href}>
            <Link
              href={link.href}
              onClick={onClose}
              className="rounded-lg px-3 py-2 text-[14px] font-semibold text-muted transition-colors hover:bg-soft hover:text-ink"
            >
              {link.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
