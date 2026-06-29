"use client";

import Link from "next/link";
import { ChevronDown, ArrowLeft } from "lucide-react";
import type { NavGroup, NavLink } from "@/content/navigation";

// Desktop menubar + mega panel. Stateless: Navbar owns openKey and handlers.
export function MegaMenu({
  groups,
  simpleNav,
  openKey,
  onOpen,
  onClose,
}: {
  groups: NavGroup[];
  simpleNav: NavLink[];
  openKey: string | null;
  onOpen: (key: string) => void;
  onClose: () => void;
}) {
  return (
    <nav aria-label="منوی اصلی" className="hidden lg:block" onMouseLeave={onClose}>
      <ul className="flex items-center gap-1">
        {groups.map((group) => {
          const isOpen = openKey === group.key;
          return (
            <li key={group.key} className="static">
              <button
                type="button"
                aria-haspopup="true"
                aria-expanded={isOpen}
                onMouseEnter={() => onOpen(group.key)}
                onFocus={() => onOpen(group.key)}
                onClick={() => onOpen(group.key)}
                className={`flex items-center gap-1 rounded-lg px-3.5 py-2 text-sm font-bold transition ${
                  isOpen ? "bg-slate-100 text-navy-900" : "text-slate-600 hover:bg-slate-50 hover:text-navy-900"
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
                <div
                  className="absolute inset-x-0 top-full z-40"
                  onMouseEnter={() => onOpen(group.key)}
                >
                  <div className="border-t border-slate-100 bg-white shadow-[0_24px_48px_-24px_rgba(7,26,45,0.25)]">
                    <div className="mx-auto w-full max-w-7xl px-4 py-7 sm:px-6 lg:px-8">
                      {group.href ? (
                        <Link
                          href={group.href}
                          onClick={onClose}
                          className="mb-5 inline-flex items-center gap-1.5 text-xs font-bold text-brand-600 hover:gap-2.5 transition-all"
                        >
                          نمای کلی {group.label}
                          <ArrowLeft size={13} aria-hidden />
                        </Link>
                      ) : null}
                      <ul className="grid grid-cols-2 gap-2 lg:grid-cols-3">
                        {group.links.map((link) => (
                          <li key={link.href}>
                            <Link
                              href={link.href}
                              onClick={onClose}
                              className="group block rounded-xl border border-transparent p-3.5 transition hover:border-slate-100 hover:bg-surface focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
                            >
                              <span className="block text-sm font-extrabold text-navy-900 transition-colors group-hover:text-brand-600">
                                {link.label}
                              </span>
                              {link.desc ? (
                                <span className="mt-1 block text-xs leading-6 text-slate-500">{link.desc}</span>
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
              onMouseEnter={onClose}
              className="rounded-lg px-3.5 py-2 text-sm font-bold text-slate-600 transition hover:bg-slate-50 hover:text-navy-900"
            >
              {link.label}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
