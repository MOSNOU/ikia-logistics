import {
  LayoutDashboard,
  Building2,
  Users,
  Shield,
  BarChart3,
  Bell,
  Package,
  FileText,
  Truck,
  Wallet,
  Factory,
  Tag,
  FileBadge,
  type LucideIcon,
} from "lucide-react";
import type { Role } from "@/lib/permissions/roles";

export interface NavItem {
  labelFa: string;
  labelEn: string;
  href: string;
  icon: LucideIcon;
  roles?: Role[];
}

export type Portal = "admin" | "buyer" | "supplier" | "carrier";

// CC-70 — Admin sidebar realigned to actually-shipped admin pages.
//   • Removed three href dead-ends that returned 404:
//       /admin/roles · /admin/analytics · /admin/integrations
//     None of those routes have a page.tsx in src/app/admin/. They were
//     placeholders from an earlier scaffold. A platform_admin clicking
//     them landed on a Next.js 404.
//   • Added three already-built admin routes that previously had no
//     sidebar entry, so a freshly-logged-in admin has discoverable
//     access to the operational surfaces that already exist on disk:
//       /admin/control-tower · /admin/kyc · /admin/notifications
//   • The remaining admin pages on disk (bookings, contracts,
//     dispatches, disputes, documents, evaluations, executive, finance,
//     marketplace, matching, offers, pricing, rfqs, settlements,
//     shipments) are deliberately NOT added in this minimal CC-70 pass.
//     A follow-up CC should categorise them under sidebar groups
//     ("Operations", "Trade", "Finance", …) once the IA is decided.
export const adminNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/admin/dashboard", icon: LayoutDashboard },
  { labelFa: "سازمان‌ها", labelEn: "Organizations", href: "/admin/organizations", icon: Building2 },
  { labelFa: "تأمین‌کنندگان", labelEn: "Suppliers", href: "/admin/suppliers", icon: Factory },
  { labelFa: "کاربران", labelEn: "Users", href: "/admin/users", icon: Users },
  { labelFa: "احراز هویت سازمانی", labelEn: "KYC / KYB", href: "/admin/kyc", icon: Shield },
  { labelFa: "برج کنترل", labelEn: "Control Tower", href: "/admin/control-tower", icon: BarChart3 },
  { labelFa: "اعلان‌ها", labelEn: "Notifications", href: "/admin/notifications", icon: Bell },
  { labelFa: "ممیزی", labelEn: "Audit", href: "/admin/audit", icon: FileBadge },
];

// CC-71 — Buyer sidebar realigned to actually-shipped pages.
//   • Removed /buyer/offers (no page.tsx — admin sees offer flow as
//     /buyer/rfqs/[id]/evaluate, never as a top-level "Offers" page).
//   • Added /buyer/marketplace and /buyer/control-tower (both already
//     exist on disk and are operationally critical for a buyer).
export const buyerNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/buyer/dashboard", icon: LayoutDashboard },
  { labelFa: "درخواست‌های خرید", labelEn: "RFQs", href: "/buyer/rfqs", icon: FileText },
  { labelFa: "بازار حمل", labelEn: "Marketplace", href: "/buyer/marketplace", icon: Package },
  { labelFa: "قراردادها", labelEn: "Contracts", href: "/buyer/contracts", icon: FileText },
  { labelFa: "محموله‌ها", labelEn: "Shipments", href: "/buyer/shipments", icon: Truck },
  { labelFa: "برج کنترل", labelEn: "Control Tower", href: "/buyer/control-tower", icon: BarChart3 },
  { labelFa: "مالی", labelEn: "Finance", href: "/buyer/finance", icon: Wallet },
];

// CC-71 — Supplier sidebar realigned to actually-shipped pages.
//   • Removed /supplier/commodities (no page.tsx — categorisation lives
//     under the already-linked /supplier/categories).
//   • Added /supplier/kyb (verification gate — already shipped) and
//     /supplier/marketplace (capacity publish flow — already shipped).
export const supplierNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/supplier/dashboard", icon: LayoutDashboard },
  { labelFa: "پروفایل تأمین‌کننده", labelEn: "Supplier Profile", href: "/supplier/profile", icon: Building2 },
  { labelFa: "احراز هویت کسب‌وکار", labelEn: "KYB", href: "/supplier/kyb", icon: Shield },
  { labelFa: "دسته‌بندی‌ها", labelEn: "Categories", href: "/supplier/categories", icon: Tag },
  { labelFa: "مدارک", labelEn: "Documents", href: "/supplier/documents", icon: FileBadge },
  { labelFa: "بازار حمل", labelEn: "Marketplace", href: "/supplier/marketplace", icon: Package },
  { labelFa: "درخواست‌ها", labelEn: "RFQs", href: "/supplier/rfqs", icon: FileText },
  { labelFa: "پیشنهادهای من", labelEn: "My Offers", href: "/supplier/offers", icon: FileText },
  { labelFa: "قراردادها", labelEn: "Contracts", href: "/supplier/contracts", icon: FileText },
  { labelFa: "مالی", labelEn: "Finance", href: "/supplier/finance", icon: Wallet },
];

// CC-71 — Carrier sidebar realigned: previously 4 of 5 items were dead
// hrefs leaving every carrier with only a dashboard.
//   • Removed /carrier/loads, /carrier/shipments, /carrier/tracking,
//     /carrier/finance (none have a page.tsx; carrier execution flows
//     live under /carrier/bookings, /carrier/dispatches and the dynamic
//     /carrier/driver/trips/[shipmentId] surface).
//   • Added /carrier/bookings, /carrier/dispatches, /carrier/control-tower
//     so a carrier user can actually navigate the operational portal.
export const carrierNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/carrier/dashboard", icon: LayoutDashboard },
  { labelFa: "رزروها", labelEn: "Bookings", href: "/carrier/bookings", icon: Package },
  { labelFa: "اعزام‌ها", labelEn: "Dispatches", href: "/carrier/dispatches", icon: Truck },
  { labelFa: "برج کنترل", labelEn: "Control Tower", href: "/carrier/control-tower", icon: BarChart3 },
];

export const portalNav: Record<Portal, NavItem[]> = {
  admin: adminNav,
  buyer: buyerNav,
  supplier: supplierNav,
  carrier: carrierNav,
};

export const portalTitles: Record<Portal, { fa: string; en: string }> = {
  admin: { fa: "پنل مدیریت", en: "Admin Portal" },
  buyer: { fa: "پنل خریدار", en: "Buyer Portal" },
  supplier: { fa: "پنل تأمین‌کننده", en: "Supplier Portal" },
  carrier: { fa: "پنل حمل‌کننده", en: "Carrier Portal" },
};
