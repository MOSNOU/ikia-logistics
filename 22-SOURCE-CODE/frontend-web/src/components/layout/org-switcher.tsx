"use client";

import { useActionState } from "react";
import { switchOrganization } from "@/lib/auth/switch-organization";
import type { ProfileMembership } from "@/lib/auth/get-profile";
import type { Locale } from "@/lib/config/locale";

interface OrgSwitcherProps {
  memberships: ProfileMembership[];
  currentOrgId: string | null;
  locale?: Locale;
}

export function OrgSwitcher({ memberships, currentOrgId, locale = "fa" }: OrgSwitcherProps) {
  const [state, formAction, pending] = useActionState(switchOrganization, null);

  if (memberships.length < 2) return null;

  return (
    <form action={formAction} className="flex items-center gap-2">
      <label htmlFor="orgSwitcher" className="sr-only">
        {locale === "fa" ? "سازمان فعال" : "Active organization"}
      </label>
      <select
        id="orgSwitcher"
        name="organizationId"
        defaultValue={currentOrgId ?? ""}
        disabled={pending}
        className="h-8 rounded-md border border-input bg-background px-2 text-xs"
      >
        {memberships.map((m) => {
          const name = locale === "fa" ? m.organizationNameFa : m.organizationNameEn;
          return (
            <option key={m.organizationId} value={m.organizationId}>
              {name ?? m.organizationCode ?? m.organizationId}
            </option>
          );
        })}
      </select>
      <button
        type="submit"
        disabled={pending}
        className="h-8 rounded-md border border-input bg-background px-3 text-xs hover:bg-accent disabled:opacity-50"
      >
        {pending
          ? locale === "fa" ? "در حال تغییر..." : "Switching..."
          : locale === "fa" ? "تغییر" : "Switch"}
      </button>
      {state?.error ? (
        <span className="text-xs text-destructive">{state.error}</span>
      ) : null}
    </form>
  );
}
