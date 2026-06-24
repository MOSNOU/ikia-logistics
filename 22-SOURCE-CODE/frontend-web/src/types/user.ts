import type { Role } from "@/lib/permissions/roles";

export interface UserProfile {
  id: string;
  email: string;
  fullName: string | null;
  avatarUrl: string | null;
  locale: "fa" | "en";
  tenantId: string | null;
  organizationId: string | null;
  roles: Role[];
  createdAt: string;
  updatedAt: string;
}

export interface SessionUser {
  id: string;
  email: string;
  profile: UserProfile | null;
}
