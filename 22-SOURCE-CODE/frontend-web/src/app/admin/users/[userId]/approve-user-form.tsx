"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { approveUser, type ApproveUserState } from "@/lib/admin/approve-user";
import { ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";
import type { TenantOption } from "@/lib/admin/list-tenants";
import type { AdminOrganizationRow } from "@/lib/admin/list-organizations";

interface ApproveUserFormProps {
  userId: string;
  tenants: TenantOption[];
  organizations: AdminOrganizationRow[];
  roles: Role[];
}

export function ApproveUserForm({ userId, tenants, organizations, roles }: ApproveUserFormProps) {
  const [state, formAction, pending] = useActionState<ApproveUserState | null, FormData>(
    approveUser,
    null,
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>تأیید کاربر</CardTitle>
        <CardDescription>اتصال به تننت، سازمان و نقش</CardDescription>
      </CardHeader>
      <CardContent>
        <form action={formAction} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="userId" value={userId} />

          <Field htmlFor="tenantId" label="تننت">
            <select
              id="tenantId"
              name="tenantId"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب کنید —
              </option>
              {tenants.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.nameFa} ({t.code})
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="organizationId" label="سازمان">
            <select
              id="organizationId"
              name="organizationId"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب کنید —
              </option>
              {organizations.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.nameFa} ({o.code})
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="roleCode" label="نقش در سازمان">
            <select
              id="roleCode"
              name="roleCode"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب کنید —
              </option>
              {roles.map((r) => (
                <option key={r} value={r}>
                  {ROLE_LABELS_FA[r]}
                </option>
              ))}
            </select>
          </Field>

          <Field htmlFor="fullName" label="نام کامل (اختیاری)">
            <Input id="fullName" name="fullName" type="text" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال تأیید..." : "تأیید کاربر"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
