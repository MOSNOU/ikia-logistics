"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Menu } from "lucide-react";
import { LogoNav } from "@/components/Logo";
import { Button } from "@/components/ui/Button";
import { MegaMenu } from "./MegaMenu";
import { MobileNav } from "./MobileNav";
import { MEGA_MENU, SIMPLE_NAV, PRODUCT_URLS } from "@/content/navigation";

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
      <header
        ref={headerRef}
        className={`sticky top-0 z-40 border-b bg-white/90 backdrop-blur-md transition-shadow ${
          scrolled ? "border-slate-200 shadow-sm" : "border-transparent"
        }`}
      >
        <div className="mx-auto flex h-18 w-full max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          {/* Right (RTL start): brand */}
          <Link href="/" aria-label="iKIA Logistics — خانه" className="shrink-0">
            <LogoNav />
          </Link>

          {/* Center: desktop mega-menu */}
          <MegaMenu
            groups={MEGA_MENU}
            simpleNav={SIMPLE_NAV}
            openKey={openKey}
            onOpen={setOpenKey}
            onClose={() => setOpenKey(null)}
          />

          {/* Left (RTL end): CTAs + mobile trigger */}
          <div className="flex shrink-0 items-center gap-2">
            <Button href={PRODUCT_URLS.login} variant="ghost" size="sm" className="hidden sm:inline-flex">
              ورود
            </Button>
            <Button href={PRODUCT_URLS.register} variant="primary" size="sm" className="hidden sm:inline-flex">
              شروع کنید
            </Button>
            <button
              type="button"
              onClick={() => setMobileOpen(true)}
              aria-label="باز کردن منو"
              className="rounded-lg p-2 text-navy-900 transition hover:bg-slate-100 lg:hidden"
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
