import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/permissions/roles";

export interface ProfileMembership {
  membershipId: string;
  organizationId: string;
  organizationCode: string | null;
  organizationNameFa: string | null;
  organizationNameEn: string | null;
  roleCode: Role | null;
}

export interface AuthProfile {
  userId: string;
  email: string;
  fullName: string | null;
  tenantId: string | null;
  primaryOrganizationId: string | null;
  roles: Role[];
  permissions: string[];
  memberships: ProfileMembership[];
  hasProfile: boolean;
}

export async function getProfile(): Promise<AuthProfile | null> {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) {
    return null;
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const identity = supabase.schema("identity");
  const organization = supabase.schema("organization");

  const { data: profileRow } = await identity
    .from("user_profiles")
    .select("tenant_id, primary_organization_id, full_name")
    .eq("id", user.id)
    .maybeSingle();

  const { data: userRoleRows } = await identity
    .from("user_roles")
    .select("role_id")
    .eq("user_id", user.id)
    .is("revoked_at", null)
    .is("deleted_at", null);

  const roleIds = Array.from(
    new Set((userRoleRows ?? []).map((r) => r.role_id).filter(Boolean)),
  );

  let roles: Role[] = [];
  let permissions: string[] = [];

  if (roleIds.length > 0) {
    const { data: roleRows } = await identity
      .from("roles")
      .select("code")
      .in("id", roleIds);
    roles = (roleRows ?? []).map((r) => r.code as Role);

    const { data: rpRows } = await identity
      .from("role_permissions")
      .select("permission_id")
      .in("role_id", roleIds);

    const permissionIds = Array.from(
      new Set((rpRows ?? []).map((r) => r.permission_id).filter(Boolean)),
    );

    if (permissionIds.length > 0) {
      const { data: permRows } = await identity
        .from("permissions")
        .select("code")
        .in("id", permissionIds);
      permissions = Array.from(new Set((permRows ?? []).map((r) => r.code)));
    }
  }

  const { data: membershipRows } = await organization
    .from("memberships")
    .select("id, organization_id, role_id")
    .eq("user_id", user.id)
    .eq("status", "active")
    .is("deleted_at", null);

  const memberships: ProfileMembership[] = [];
  const memberOrgIds = Array.from(
    new Set((membershipRows ?? []).map((m) => m.organization_id).filter(Boolean)),
  );
  const memberRoleIds = Array.from(
    new Set((membershipRows ?? []).map((m) => m.role_id).filter(Boolean)),
  );

  let orgsById = new Map<string, { code: string; name_fa: string; name_en: string }>();
  if (memberOrgIds.length > 0) {
    const { data: orgRows } = await organization
      .from("organizations")
      .select("id, code, name_fa, name_en")
      .in("id", memberOrgIds);
    orgsById = new Map(
      (orgRows ?? []).map((o) => [
        o.id,
        { code: o.code, name_fa: o.name_fa, name_en: o.name_en },
      ]),
    );
  }

  let rolesById = new Map<string, string>();
  if (memberRoleIds.length > 0) {
    const { data: roleRows } = await identity
      .from("roles")
      .select("id, code")
      .in("id", memberRoleIds);
    rolesById = new Map((roleRows ?? []).map((r) => [r.id, r.code]));
  }

  for (const m of membershipRows ?? []) {
    const org = orgsById.get(m.organization_id);
    memberships.push({
      membershipId: m.id,
      organizationId: m.organization_id,
      organizationCode: org?.code ?? null,
      organizationNameFa: org?.name_fa ?? null,
      organizationNameEn: org?.name_en ?? null,
      roleCode: (rolesById.get(m.role_id) as Role | undefined) ?? null,
    });
  }

  return {
    userId: user.id,
    email: user.email ?? "",
    fullName: profileRow?.full_name ?? null,
    tenantId: profileRow?.tenant_id ?? null,
    primaryOrganizationId: profileRow?.primary_organization_id ?? null,
    roles,
    permissions,
    memberships,
    hasProfile: Boolean(profileRow),
  };
}
