import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://www.ikialogistic.com"),
  title: {
    default: "iKIA Logistics | سیستم‌عامل دیجیتال لجستیک",
    template: "%s | iKIA Logistics",
  },
  description:
    "iKIA Logistics؛ زیرساخت هوشمند حمل‌ونقل بار: تخصیص هوشمند بار، ردیابی لحظه‌ای، مدیریت اسناد و آمادگی تسویه مالی. شفاف، قابل اتکا و در مسیر توسعه.",
  keywords: [
    "iKIA Logistics",
    "لجستیک",
    "حمل بار",
    "حمل جاده‌ای",
    "فورواردر",
    "کریر",
    "ردیابی بار",
    "تخصیص هوشمند بار",
  ],
  openGraph: {
    type: "website",
    locale: "fa_IR",
    siteName: "iKIA Logistics",
    title: "iKIA Logistics | سیستم‌عامل دیجیتال لجستیک",
    description:
      "زیرساخت هوشمند حمل‌ونقل بار: تخصیص هوشمند، ردیابی لحظه‌ای، اسناد و آمادگی تسویه مالی.",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#1B3A5C",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
