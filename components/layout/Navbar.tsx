"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Menu, ArrowLeft } from "lucide-react";
import { LogoNav } from "@/components/Logo";
import { Button } from "@/components/ui/Button";
import { MegaMenu } from "./MegaMenu";
import { MobileNav } from "./MobileNav";
import { MEGA_MENU, SIMPLE_NAV, PRODUCT_URLS } from "@/content/siteArchitecture";

export function Navbar() {
  const [openKey, setOpenKey] = useState<string | null>(null);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const headerRef = useRef<HTMLElement>(null);

  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        setOpenKey(null);
        setMobileOpen(false);
      }
    }
    function onClick(e: MouseEvent) {
      if (headerRef.current && !headerRef.current.contains(e.target as Node)) {
        setOpenKey(null);
      }
    }
    function onScroll() {
      setScrolled(window.scrollY > 8);
    }
    document.addEventListener("keydown", onKey);
    document.addEventListener("mousedown", onClick);
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("mousedown", onClick);
      window.removeEventListener("scroll", onScroll);
    };
  }, []);

  return (
    <>
      {/* Announcement bar */}
      <Link
        href="/platform/control-tower"
        className="group block bg-ink text-center text-white"
      >
        <div className="mx-auto flex w-full max-w-7xl items-center justify-center gap-2 px-4 py-2 text-[12px] font-medium text-ondark">
          <span className="inline-flex h-1.5 w-1.5 rounded-full bg-green" aria-hidden />
          <span>برج کنترل iKIA؛ دید زنده بر کل جریان لجستیک</span>
          <ArrowLeft
            size={13}
            className="transition-transform group-hover:-translate-x-0.5"
            aria-hidden
          />
        </div>
      </Link>

      <header
        ref={headerRef}
        className={`sticky top-0 z-40 border-b bg-white/90 backdrop-blur-md transition-shadow ${
          scrolled ? "border-line shadow-sm" : "border-transparent"
        }`}
      >
        <div className="mx-auto flex h-16 w-full max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          {/* Right (RTL start): brand wordmark */}
          <Link href="/" aria-label="iKIA Logistic — خانه" className="shrink-0">
            <LogoNav />
          </Link>

          {/* Center: desktop mega-menu (click-to-open) */}
          <MegaMenu
            groups={MEGA_MENU}
            simpleNav={SIMPLE_NAV}
            openKey={openKey}
            onToggle={(key) => setOpenKey((prev) => (prev === key ? null : key))}
            onClose={() => setOpenKey(null)}
          />

          {/* Left (RTL end): CTAs + mobile trigger.
              Desktop CTAs are wrapped in spans that own the responsive
              visibility — a span has no base `inline-flex`, so `hidden`
              applies cleanly (passing `hidden` onto the Button itself loses
              to the Button base `inline-flex`). */}
          <div className="flex shrink-0 items-center gap-2">
            <span className="hidden md:inline-flex">
              <Button href={PRODUCT_URLS.platform} variant="ghost" size="sm">
                مشاهده پلتفرم
              </Button>
            </span>
            <span className="hidden sm:inline-flex">
              <Button href={PRODUCT_URLS.start} variant="primary" size="sm">
                شروع همکاری
              </Button>
            </span>
            <button
              type="button"
              onClick={() => setMobileOpen(true)}
              aria-label="باز کردن منو"
              className="rounded-lg p-2 text-ink transition hover:bg-soft lg:hidden"
            >
              <Menu size={22} aria-hidden />
            </button>
          </div>
        </div>
      </header>

      {/* Rendered OUTSIDE the backdrop-blur header so the drawer's fixed
          positioning resolves against the viewport, not the header box. */}
      <MobileNav
        groups={MEGA_MENU}
        simpleNav={SIMPLE_NAV}
        open={mobileOpen}
        onClose={() => setMobileOpen(false)}
      />
    </>
  );
}
