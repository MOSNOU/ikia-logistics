import {
  LayoutDashboard,
  Building2,
  Users,
  Shield,
  BarChart3,
  Plug,
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

export const adminNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/admin/dashboard", icon: LayoutDashboard },
  { labelFa: "سازمان‌ها", labelEn: "Organizations", href: "/admin/organizations", icon: Building2 },
  { labelFa: "تأمین‌کنندگان", labelEn: "Suppliers", href: "/admin/suppliers", icon: Factory },
  { labelFa: "کاربران", labelEn: "Users", href: "/admin/users", icon: Users },
  { labelFa: "نقش‌ها و دسترسی", labelEn: "Roles & Access", href: "/admin/roles", icon: Shield },
  { labelFa: "ممیزی", labelEn: "Audit", href: "/admin/audit", icon: BarChart3 },
  { labelFa: "تحلیل‌ها", labelEn: "Analytics", href: "/admin/analytics", icon: BarChart3 },
  { labelFa: "یکپارچه‌سازی", labelEn: "Integrations", href: "/admin/integrations", icon: Plug },
];

export const buyerNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/buyer/dashboard", icon: LayoutDashboard },
  { labelFa: "درخواست‌های خرید", labelEn: "RFQs", href: "/buyer/rfqs", icon: FileText },
  { labelFa: "پیشنهادها", labelEn: "Offers", href: "/buyer/offers", icon: Package },
  { labelFa: "قراردادها", labelEn: "Contracts", href: "/buyer/contracts", icon: FileText },
  { labelFa: "محموله‌ها", labelEn: "Shipments", href: "/buyer/shipments", icon: Truck },
  { labelFa: "مالی", labelEn: "Finance", href: "/buyer/finance", icon: Wallet },
];

export const supplierNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/supplier/dashboard", icon: LayoutDashboard },
  { labelFa: "پروفایل تأمین‌کننده", labelEn: "Supplier Profile", href: "/supplier/profile", icon: Building2 },
  { labelFa: "دسته‌بندی‌ها", labelEn: "Categories", href: "/supplier/categories", icon: Tag },
  { labelFa: "مدارک", labelEn: "Documents", href: "/supplier/documents", icon: FileBadge },
  { labelFa: "کالاها", labelEn: "Commodities", href: "/supplier/commodities", icon: Package },
  { labelFa: "درخواست‌ها", labelEn: "RFQs", href: "/supplier/rfqs", icon: FileText },
  { labelFa: "پیشنهادهای من", labelEn: "My Offers", href: "/supplier/offers", icon: FileText },
  { labelFa: "قراردادها", labelEn: "Contracts", href: "/supplier/contracts", icon: FileText },
  { labelFa: "مالی", labelEn: "Finance", href: "/supplier/finance", icon: Wallet },
];

export const carrierNav: NavItem[] = [
  { labelFa: "داشبورد", labelEn: "Dashboard", href: "/carrier/dashboard", icon: LayoutDashboard },
  { labelFa: "بارها", labelEn: "Loads", href: "/carrier/loads", icon: Truck },
  { labelFa: "محموله‌ها", labelEn: "Shipments", href: "/carrier/shipments", icon: Truck },
  { labelFa: "ردیابی", labelEn: "Tracking", href: "/carrier/tracking", icon: Truck },
  { labelFa: "مالی", labelEn: "Finance", href: "/carrier/finance", icon: Wallet },
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
