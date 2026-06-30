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
    url: "https://www.ikialogistic.com",
    title: "iKIA Logistics | سیستم‌عامل دیجیتال لجستیک",
    description:
      "زیرساخت هوشمند حمل‌ونقل بار: تخصیص هوشمند، ردیابی لحظه‌ای، اسناد و آمادگی تسویه مالی.",
    images: [{ url: "/brand/ikia-logo-signature.png", alt: "iKIA Logistics" }],
  },
  twitter: {
    card: "summary_large_image",
    images: ["/brand/ikia-logo-signature.png"],
  },
};

// Organization + WebSite structured data for the marketing site. sameAs is
// intentionally empty until official social profiles exist.
const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://www.ikialogistic.com/#organization",
      name: "iKIA Logistic",
      alternateName: "iKIA Logistics",
      url: "https://www.ikialogistic.com",
      logo: "https://www.ikialogistic.com/brand/ikia-logo-signature.png",
      sameAs: [],
    },
    {
      "@type": "WebSite",
      "@id": "https://www.ikialogistic.com/#website",
      name: "iKIA Logistic",
      alternateName: "iKIA Logistics",
      url: "https://www.ikialogistic.com",
      inLanguage: "fa-IR",
      publisher: { "@id": "https://www.ikialogistic.com/#organization" },
    },
  ],
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#1B3A5C",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <body>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        {children}
      </body>
    </html>
  );
}
