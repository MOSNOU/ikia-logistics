export const siteConfig = {
  name: "iKIA Logistics",
  nameFa: "آی‌کیا لجستیک",
  nameEn: "iKIA Logistics",
  taglineFa: "سامانه ملی عملیات لجستیک و زنجیره تأمین",
  taglineEn: "National Logistics Operating System",
  url: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",
} as const;

export type SiteConfig = typeof siteConfig;
