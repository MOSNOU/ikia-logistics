"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  buyerCreateSignatureRequest,
  type SignatureActionState,
} from "@/lib/contract/signature-actions";

interface PartyOption {
  id: string;
  displayName: string;
}

export function CreateSignatureRequestForm({
  contractId,
  parties,
}: {
  contractId: string;
  parties: PartyOption[];
}) {
  const [state, action, pending] = useActionState<SignatureActionState | null, FormData>(
    buyerCreateSignatureRequest,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="contractId" value={contractId} />

          <Field htmlFor="partyId" label="طرف امضاکننده">
            <select
              id="partyId"
              name="partyId"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {parties.map((p) => (
                <option key={p.id} value={p.id}>{p.displayName}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="dueAt" label="سررسید">
            <Input id="dueAt" name="dueAt" type="datetime-local" dir="ltr" />
          </Field>

          <Field htmlFor="requestedToEmail" label="ایمیل گیرنده (اختیاری)">
            <Input id="requestedToEmail" name="requestedToEmail" type="email" dir="ltr" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">درخواست ایجاد شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ایجاد درخواست"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
