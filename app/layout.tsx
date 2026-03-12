import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {
  title: "iKIA Logistics | پلتفرم هوشمند حمل‌ونقل بار",
  description: "اتصال مستقیم بارفرست‌ها و حمل‌کنندگان در مسیر تهران-مشهد. کاهش هزینه حمل تا ۳۰٪.",
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fa" dir="rtl">
      <head>
        <link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" rel="stylesheet" />
        <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@700;800;900&display=swap" rel="stylesheet" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#1B3A5C" />
      </head>
      <body style={{fontFamily:"Vazirmatn,sans-serif",margin:0,background:"#f9fafb",color:"#333"}}>{children}</body>
    </html>
  );
}
