"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/forms/field";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { assignRole, type AssignRoleState } from "@/lib/admin/assign-role";
import { ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";
import type { AdminOrganizationRow } from "@/lib/admin/list-organizations";

interface AssignRoleFormProps {
  userId: string;
  roles: Role[];
  organizations: AdminOrganizationRow[];
}

const SCOPE_OPTIONS = [
  { value: "platform", label: "پلتفرم (بدون دامنه)" },
  { value: "organization", label: "سازمان" },
] as const;

export function AssignRoleForm({ userId, roles, organizations }: AssignRoleFormProps) {
  const [state, formAction, pending] = useActionState<AssignRoleState | null, FormData>(
    assignRole,
    null,
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>اختصاص نقش</CardTitle>
        <CardDescription>افزودن یک نقش با محدوده مشخص</CardDescription>
      </CardHeader>
      <CardContent>
        <form action={formAction} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="userId" value={userId} />

          <Field htmlFor="roleCode" label="نقش">
            <select
              id="roleCode"
              name="roleCode"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب —
              </option>
              {roles.map((r) => (
                <option key={r} value={r}>
                  {ROLE_LABELS_FA[r]}
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="scopeType" label="محدوده">
            <select
              id="scopeType"
              name="scopeType"
              defaultValue="organization"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {SCOPE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="scopeId" label="سازمان دامنه (در صورت نیاز)">
            <select
              id="scopeId"
              name="scopeId"
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="">— هیچ —</option>
              {organizations.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.nameFa} ({o.code})
                </option>
              ))}
            </select>
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">نقش اختصاص داده شد</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال اختصاص..." : "اختصاص نقش"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
