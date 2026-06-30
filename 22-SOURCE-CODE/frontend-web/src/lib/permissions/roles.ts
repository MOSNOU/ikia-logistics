export const ROLES = {
  PLATFORM_ADMIN: "platform_admin",
  ORGANIZATION_ADMIN: "organization_admin",
  SUPPLIER_ADMIN: "supplier_admin",
  BUYER_ADMIN: "buyer_admin",
  CARRIER_ADMIN: "carrier_admin",
  COMPLIANCE_OFFICER: "compliance_officer",
  FINANCE_OFFICER: "finance_officer",
  OPERATIONS_USER: "operations_user",
  READONLY_USER: "readonly_user",
  DRIVER: "driver",
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];

export const ALL_ROLES: Role[] = Object.values(ROLES);

export const ROLE_LABELS_FA: Record<Role, string> = {
  platform_admin: "مدیر پلتفرم",
  organization_admin: "مدیر سازمان",
  supplier_admin: "مدیر تأمین‌کننده",
  buyer_admin: "مدیر خریدار",
  carrier_admin: "مدیر حمل‌کننده",
  compliance_officer: "افسر تطبیق",
  finance_officer: "افسر مالی",
  operations_user: "کاربر عملیات",
  readonly_user: "کاربر فقط‌خواندنی",
  driver: "راننده",
};

export const ROLE_LABELS_EN: Record<Role, string> = {
  platform_admin: "Platform Admin",
  organization_admin: "Organization Admin",
  supplier_admin: "Supplier Admin",
  buyer_admin: "Buyer Admin",
  carrier_admin: "Carrier Admin",
  compliance_officer: "Compliance Officer",
  finance_officer: "Finance Officer",
  operations_user: "Operations User",
  readonly_user: "Readonly User",
  driver: "Driver",
};
