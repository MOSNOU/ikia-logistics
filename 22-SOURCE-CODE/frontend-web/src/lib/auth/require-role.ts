import { redirect } from "next/navigation";
import { getProfile, type AuthProfile } from "./get-profile";
import { hasRole } from "@/lib/permissions/can";
import type { Role } from "@/lib/permissions/roles";

const isAuthEnabled =
  !!process.env.NEXT_PUBLIC_SUPABASE_URL && !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export async function requireRole(required: Role | Role[]): Promise<AuthProfile | null> {
  if (!isAuthEnabled) {
    return null;
  }

  const profile = await getProfile();
  if (!profile) {
    redirect("/login");
  }
  if (!hasRole(profile.roles, required)) {
    redirect("/unauthorized");
  }
  return profile;
}
