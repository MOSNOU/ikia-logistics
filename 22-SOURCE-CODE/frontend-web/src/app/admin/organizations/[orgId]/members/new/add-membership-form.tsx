"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { addMembership, type AddMembershipState } from "@/lib/admin/add-membership";
import { ROLE_LABELS_FA, type Role } from "@/lib/permissions/roles";

interface UserOption {
  userId: string;
  email: string;
  fullName: string | null;
}

interface AddMembershipFormProps {
  organizationId: string;
  users: UserOption[];
  roles: Role[];
}

export function AddMembershipForm({ organizationId, users, roles }: AddMembershipFormProps) {
  const [state, formAction, pending] = useActionState<AddMembershipState | null, FormData>(
    addMembership,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={formAction} className="space-y-4">
          <input type="hidden" name="organizationId" value={organizationId} />

          <Field htmlFor="userId" label="کاربر">
            <select
              id="userId"
              name="userId"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>
                — انتخاب کنید —
              </option>
              {users.map((u) => (
                <option key={u.userId} value={u.userId}>
                  {u.fullName ? `${u.fullName} — ${u.email}` : u.email}
                </option>
              ))}
            </select>
          </Field>

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

          {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}

          <Button type="submit" disabled={pending}>
            {pending ? "در حال افزودن..." : "افزودن"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
