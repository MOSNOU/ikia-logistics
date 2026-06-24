import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/permissions/roles";
import type { MembershipStatus } from "@/types/database";

export interface MembershipForOrg {
  membershipId: string;
  userId: string;
  roleId: string;
  roleCode: Role | null;
  status: MembershipStatus;
  joinedAt: string | null;
}

export async function listMembershipsForOrg(orgId: string): Promise<MembershipForOrg[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("organization")
    .from("memberships")
    .select("id, user_id, role_id, status, joined_at")
    .eq("organization_id", orgId)
    .is("deleted_at", null)
    .order("joined_at", { ascending: false });

  if (error || !data?.length) {
    if (error) console.error("list_memberships_for_org", error);
    return [];
  }

  const roleIds = Array.from(new Set(data.map((m) => m.role_id)));
  const rolesById = new Map<string, string>();
  if (roleIds.length > 0) {
    const { data: roles } = await supabase
      .schema("identity")
      .from("roles")
      .select("id, code")
      .in("id", roleIds);
    for (const r of roles ?? []) rolesById.set(r.id, r.code);
  }

  return data.map((m) => ({
    membershipId: m.id,
    userId: m.user_id,
    roleId: m.role_id,
    roleCode: (rolesById.get(m.role_id) as Role | undefined) ?? null,
    status: m.status,
    joinedAt: m.joined_at,
  }));
}

export interface UserRoleAssignment {
  userRoleId: string;
  roleId: string;
  roleCode: Role | null;
  scopeType: string;
  scopeId: string | null;
  grantedAt: string;
}

export async function listUserRoleAssignments(userId: string): Promise<UserRoleAssignment[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .schema("identity")
    .from("user_roles")
    .select("id, role_id, scope_type, scope_id, granted_at")
    .eq("user_id", userId)
    .is("revoked_at", null)
    .is("deleted_at", null)
    .order("granted_at", { ascending: false });

  if (error || !data?.length) {
    if (error) console.error("list_user_role_assignments", error);
    return [];
  }

  const roleIds = Array.from(new Set(data.map((m) => m.role_id)));
  const rolesById = new Map<string, string>();
  if (roleIds.length > 0) {
    const { data: roles } = await supabase
      .schema("identity")
      .from("roles")
      .select("id, code")
      .in("id", roleIds);
    for (const r of roles ?? []) rolesById.set(r.id, r.code);
  }

  return data.map((r) => ({
    userRoleId: r.id,
    roleId: r.role_id,
    roleCode: (rolesById.get(r.role_id) as Role | undefined) ?? null,
    scopeType: r.scope_type,
    scopeId: r.scope_id,
    grantedAt: r.granted_at,
  }));
}
