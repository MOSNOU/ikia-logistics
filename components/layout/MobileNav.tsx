"use client";

import { useState } from "react";
import Link from "next/link";
import { ChevronDown, X } from "lucide-react";
import type { NavGroup, NavLink } from "@/content/navigation";
import { PRODUCT_URLS } from "@/content/navigation";
import { Button } from "@/components/ui/Button";

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
      <div className="fixed inset-0 z-50 bg-navy-950/50 backdrop-blur-sm" onClick={onClose} aria-hidden />
      <div className="fixed inset-y-0 end-0 z-50 flex w-[88%] max-w-sm flex-col overflow-y-auto bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-4">
          <span className="text-sm font-black text-navy-900">منو</span>
          <button
            type="button"
            onClick={onClose}
            aria-label="بستن منو"
            className="rounded-lg p-1.5 text-slate-500 transition hover:bg-slate-100"
          >
            <X size={20} aria-hidden />
          </button>
        </div>

        <ul className="flex-1 px-3 py-3">
          {groups.map((group) => {
            const isOpen = expanded === group.key;
            return (
              <li key={group.key} className="border-b border-slate-50">
                <button
                  type="button"
                  aria-expanded={isOpen}
                  onClick={() => setExpanded(isOpen ? null : group.key)}
                  className="flex w-full items-center justify-between rounded-lg px-2 py-3.5 text-start text-sm font-extrabold text-navy-900"
                >
                  {group.label}
                  <ChevronDown
                    size={16}
                    className={`text-slate-400 transition-transform ${isOpen ? "rotate-180" : ""}`}
                    aria-hidden
                  />
                </button>
                {isOpen ? (
                  <ul className="pb-2 ps-3">
                    {group.href ? (
                      <li>
                        <Link
                          href={group.href}
                          onClick={onClose}
                          className="block rounded-lg px-2 py-2 text-xs font-bold text-brand-600"
                        >
                          نمای کلی {group.label}
                        </Link>
                      </li>
                    ) : null}
                    {group.links.map((link) => (
                      <li key={link.href}>
                        <Link
                          href={link.href}
                          onClick={onClose}
                          className="block rounded-lg px-2 py-2 text-sm text-slate-600 transition hover:bg-surface"
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
            <li key={link.href} className="border-b border-slate-50">
              <Link
                href={link.href}
                onClick={onClose}
                className="block rounded-lg px-2 py-3.5 text-sm font-extrabold text-navy-900"
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>

        <div className="grid gap-2 border-t border-slate-100 p-4">
          <Button href={PRODUCT_URLS.login} variant="outline" size="md" className="w-full">
            ورود
          </Button>
          <Button href={PRODUCT_URLS.register} variant="primary" size="md" className="w-full">
            شروع کنید
          </Button>
        </div>
      </div>
    </div>
  );
}
