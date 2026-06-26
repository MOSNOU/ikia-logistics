import { createClient } from "@/lib/supabase/server";
import type { Role } from "@/lib/permissions/roles";

// CC-68B — Production auth profile reader.
//
// Before CC-68B this file performed six separate PostgREST queries against
// identity.user_roles, identity.roles, identity.role_permissions,
// identity.permissions, organization.memberships and
// organization.organizations. Catalog tables (identity.roles,
// identity.permissions) deny SELECT to authenticated callers by RLS, so
// the front-end received an empty `roles` array in production and
// requireRole(platform_admin) redirected freshly-provisioned admins to
// `/unauthorized`.
//
// The fix is a single narrow SECURITY DEFINER RPC,
// `identity.get_current_auth_profile()` (see migration 0041), that derives
// the caller from auth.uid() and returns the entire profile as one jsonb
// document. It accepts no parameters, so a caller cannot ask for another
// user's data.

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

// Shape returned by identity.get_current_auth_profile(). We narrow into
// AuthProfile below; keep this loose so PostgREST type drift is non-fatal.
interface AuthProfileRow {
  userId: string;
  email: string | null;
  fullName: string | null;
  tenantId: string | null;
  primaryOrganizationId: string | null;
  hasProfile: boolean;
  roles: unknown;
  permissions: unknown;
  memberships: unknown;
}

interface MembershipRow {
  membershipId?: string;
  organizationId?: string;
  organizationCode?: string | null;
  organizationNameFa?: string | null;
  organizationNameEn?: string | null;
  roleCode?: string | null;
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === "string");
}

function asMembershipArray(value: unknown): ProfileMembership[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((m): m is MembershipRow => typeof m === "object" && m !== null)
    .map((m) => ({
      membershipId: String(m.membershipId ?? ""),
      organizationId: String(m.organizationId ?? ""),
      organizationCode: m.organizationCode ?? null,
      organizationNameFa: m.organizationNameFa ?? null,
      organizationNameEn: m.organizationNameEn ?? null,
      roleCode: (m.roleCode as Role | null | undefined) ?? null,
    }));
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

  // Single round-trip to the SECURITY DEFINER RPC. The function reads
  // auth.uid() internally; no user id is passed across the wire.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rpcCall = (supabase.schema("identity") as any).rpc(
    "get_current_auth_profile",
  );
  const { data, error } = (await rpcCall) as {
    data: AuthProfileRow | null;
    error: { message: string } | null;
  };

  if (error || !data) {
    // RPC failed or returned null — surface nothing so requireRole()
    // redirects to /login or /unauthorized as appropriate.
    return null;
  }

  return {
    userId: data.userId ?? user.id,
    email: data.email ?? user.email ?? "",
    fullName: data.fullName ?? null,
    tenantId: data.tenantId ?? null,
    primaryOrganizationId: data.primaryOrganizationId ?? null,
    roles: asStringArray(data.roles) as Role[],
    permissions: asStringArray(data.permissions),
    memberships: asMembershipArray(data.memberships),
    hasProfile: Boolean(data.hasProfile),
  };
}
