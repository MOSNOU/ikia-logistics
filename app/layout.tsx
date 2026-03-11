import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "iKIA Logistics | پلتفرم هوشمند لجستیک",
  description: "اتصال بارفرست‌ها و حمل‌کنندگان در مسیر تهران-مشهد",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <head>
        <link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" rel="stylesheet" />
      </head>
      <body style={{fontFamily:"Vazirmatn,sans-serif",margin:0,background:"#f9fafb",color:"#333"}}>{children}</body>
    </html>
  );
}
