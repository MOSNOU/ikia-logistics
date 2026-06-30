"use client";

import { useState } from "react";
import Link from "next/link";
import { ChevronDown, X } from "lucide-react";
import type { NavGroup, NavLink } from "@/content/siteArchitecture";
import { PRODUCT_URLS } from "@/content/siteArchitecture";
import { Button } from "@/components/ui/Button";
import { LogoNav } from "@/components/Logo";

// Mobile slide-in navigation with tap accordion behavior.
export function MobileNav({
  groups,
  simpleNav,
  open,
  onClose,
}: {
  groups: NavGroup[];
  simpleNav: NavLink[];
  open: boolean;
  onClose: () => void;
}) {
  const [expanded, setExpanded] = useState<string | null>(null);

  if (!open) return null;

  return (
    <div className="lg:hidden" role="dialog" aria-modal="true" aria-label="منوی موبایل">
      <div className="fixed inset-0 z-50 bg-ink/50 backdrop-blur-sm" onClick={onClose} aria-hidden />
      <div className="fixed inset-y-0 end-0 z-50 flex w-[88%] max-w-sm flex-col overflow-y-auto bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-line px-5 py-4">
          <LogoNav variant="header" />
          <button
            type="button"
            onClick={onClose}
            aria-label="بستن منو"
            className="rounded-lg p-1.5 text-muted transition hover:bg-soft"
          >
            <X size={20} aria-hidden />
          </button>
        </div>

        <ul className="flex-1 px-3 py-3">
          {groups.map((group) => {
            const isOpen = expanded === group.key;
            return (
              <li key={group.key} className="border-b border-line/60">
                <button
                  type="button"
                  aria-expanded={isOpen}
                  onClick={() => setExpanded(isOpen ? null : group.key)}
                  className="flex w-full items-center justify-between rounded-lg px-2 py-3.5 text-start text-[14px] font-bold text-ink"
                >
                  {group.label}
                  <ChevronDown
                    size={16}
                    className={`text-muted transition-transform ${isOpen ? "rotate-180" : ""}`}
                    aria-hidden
                  />
                </button>
                {isOpen ? (
                  <ul className="pb-2 ps-3">
                    {group.overviewHref ? (
                      <li>
                        <Link
                          href={group.overviewHref}
                          onClick={onClose}
                          className="block rounded-lg px-2 py-2 text-[12px] font-bold text-blue"
                        >
                          {group.overviewLabel ?? `نمای کلی ${group.label}`}
                        </Link>
                      </li>
                    ) : null}
                    {group.links.map((link) => (
                      <li key={link.href}>
                        <Link
                          href={link.href}
                          onClick={onClose}
                          className="block rounded-lg px-2 py-2 text-[14px] text-muted transition hover:bg-soft"
                        >
                          {link.label}
                        </Link>
                      </li>
                    ))}
                  </ul>
                ) : null}
              </li>
            );
          })}

          {simpleNav.map((link) => (
            <li key={link.href} className="border-b border-line/60">
              <Link
                href={link.href}
                onClick={onClose}
                className="block rounded-lg px-2 py-3.5 text-[14px] font-bold text-ink"
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>

        <div className="grid gap-2 border-t border-line p-4">
          <Button href={PRODUCT_URLS.platform} variant="outline" size="md" className="w-full">
            مشاهده پلتفرم
          </Button>
          <Button href={PRODUCT_URLS.start} variant="primary" size="md" className="w-full">
            شروع همکاری
          </Button>
        </div>
      </div>
    </div>
  );
}
