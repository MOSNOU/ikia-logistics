import type { MetadataRoute } from "next";

// Phase D6 — Product app PWA manifest (driver installability basics).
//
// Served by Next at /manifest.webmanifest. Scoped so the whole product app is
// in scope but the install experience starts on the driver portal. RTL / fa-IR.
// Icons reference the self-contained SVG at /public/icon.svg (no PNG pipeline,
// no new dependencies). NO service worker / offline / caching is registered by
// this manifest — installability only.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "iKIA Driver",
    short_name: "iKIA Driver",
    description:
      "پرتال موبایل رانندگان آی‌کیا برای مدیریت سفر، ارسال موقعیت، بارگذاری اسناد تحویل و گزارش مشکل. iKIA Driver portal.",
    start_url: "/driver",
    scope: "/",
    display: "standalone",
    orientation: "portrait",
    dir: "rtl",
    lang: "fa-IR",
    theme_color: "#0f172a",
    background_color: "#ffffff",
    icons: [
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
        purpose: "any",
      },
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
        purpose: "maskable",
      },
    ],
  };
}
