import type { Metadata } from "next";
import { Vazirmatn } from "next/font/google";
import { siteConfig } from "@/lib/config/site";
import { defaultLocale, direction } from "@/lib/config/locale";
import "./globals.css";

const vazir = Vazirmatn({
  subsets: ["arabic", "latin"],
  variable: "--font-vazir",
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: siteConfig.nameFa,
    template: `%s · ${siteConfig.nameFa}`,
  },
  description: siteConfig.taglineFa,
  metadataBase: new URL(siteConfig.url),
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const locale = defaultLocale;
  return (
    <html lang={locale} dir={direction[locale]} className={vazir.variable}>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
