import { ROLES, type Role } from "./roles";
import type { Permission } from "@/types/permission";

export function hasRole(
  userRoles: Role[] | null | undefined,
  required: Role | Role[],
): boolean {
  if (!userRoles?.length) return false;
  const requiredList = Array.isArray(required) ? required : [required];
  return requiredList.some((r) => userRoles.includes(r));
}

export function isPlatformAdmin(userRoles: Role[] | null | undefined): boolean {
  return hasRole(userRoles, ROLES.PLATFORM_ADMIN);
}

export function can(
  userPermissions: string[] | null | undefined,
  permission: Permission,
): boolean {
  if (!userPermissions?.length) return false;
  return userPermissions.includes(permission);
}

export function canAny(
  userPermissions: string[] | null | undefined,
  permissions: Permission[],
): boolean {
  if (!userPermissions?.length || !permissions.length) return false;
  return permissions.some((p) => userPermissions.includes(p));
}

export function canAll(
  userPermissions: string[] | null | undefined,
  permissions: Permission[],
): boolean {
  if (!userPermissions?.length || !permissions.length) return false;
  return permissions.every((p) => userPermissions.includes(p));
}
