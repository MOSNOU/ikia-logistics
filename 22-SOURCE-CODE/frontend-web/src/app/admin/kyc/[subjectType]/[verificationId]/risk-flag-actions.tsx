"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  raiseRiskFlag,
  resolveRiskFlag,
  type KycAdminActionState,
} from "@/lib/admin/kyc-admin-actions";
import type { KycSubjectType } from "@/types/database";

const SEVERITIES = [
  { value: "info", label: "اطلاع" },
  { value: "low", label: "کم" },
  { value: "medium", label: "متوسط" },
  { value: "high", label: "زیاد" },
  { value: "critical", label: "بحرانی" },
] as const;

const RESOLUTIONS = [
  { value: "acknowledged", label: "تأیید شده" },
  { value: "mitigated", label: "کاهش‌یافته" },
  { value: "dismissed", label: "نادیده گرفتن" },
] as const;

function RaiseForm({
  subjectType,
  subjectId,
  verificationId,
}: {
  subjectType: KycSubjectType;
  subjectId: string;
  verificationId: string;
}) {
  const [state, action, pending] = useActionState<KycAdminActionState | null, FormData>(
    raiseRiskFlag,
    null,
  );
  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="subjectType" value={subjectType} />
          <input type="hidden" name="verificationId" value={verificationId} />
          {subjectType === "person" ? (
            <input type="hidden" name="userId" value={subjectId} />
          ) : (
            <input type="hidden" name="organizationId" value={subjectId} />
          )}

          <Field htmlFor="code" label="کد پرچم">
            <Input id="code" name="code" required dir="ltr" placeholder="pep_match" />
          </Field>

          <Field htmlFor="severity" label="شدت">
            <select
              id="severity"
              name="severity"
              defaultValue="medium"
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {SEVERITIES.map((s) => (
                <option key={s.value} value={s.value}>{s.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="source" label="منبع">
            <Input id="source" name="source" defaultValue="manual" dir="ltr" />
          </Field>

          <Field htmlFor="detail" label="توضیح" className="md:col-span-3">
            <Input id="detail" name="detail" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">پرچم ثبت شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "در حال ثبت..." : "ثبت پرچم"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}

function ResolveForm({
  flagId,
  subjectType,
  verificationId,
}: {
  flagId: string;
  subjectType: KycSubjectType;
  verificationId: string;
}) {
  const [state, action, pending] = useActionState<KycAdminActionState | null, FormData>(
    resolveRiskFlag,
    null,
  );
  return (
    <form action={action} className="flex items-end gap-2 flex-wrap">
      <input type="hidden" name="flagId" value={flagId} />
      <input type="hidden" name="subjectType" value={subjectType} />
      <input type="hidden" name="verificationId" value={verificationId} />
      <select
        name="status"
        required
        defaultValue=""
        className="h-9 rounded-md border border-input bg-background px-2 text-xs"
      >
        <option value="" disabled>— تصمیم —</option>
        {RESOLUTIONS.map((r) => (
          <option key={r.value} value={r.value}>{r.label}</option>
        ))}
      </select>
      <Input name="note" placeholder="یادداشت" className="h-9 w-40" />
      <Button type="submit" size="sm" variant="outline" disabled={pending}>
        {pending ? "..." : "حل"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}

export const RiskFlagActions = {
  Raise: RaiseForm,
  Resolve: ResolveForm,
};
