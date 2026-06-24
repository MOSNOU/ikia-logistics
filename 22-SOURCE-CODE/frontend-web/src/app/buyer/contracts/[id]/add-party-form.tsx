"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerAddParty, type ContractActionState } from "@/lib/contract/buyer-actions";

const PARTY_TYPES = [
  { value: "buyer", label: "خریدار" },
  { value: "supplier", label: "تأمین‌کننده" },
  { value: "platform", label: "پلتفرم" },
  { value: "witness", label: "شاهد" },
  { value: "other", label: "سایر" },
] as const;

export function AddPartyForm({ preparationId }: { preparationId: string }) {
  const [state, action, pending] = useActionState<ContractActionState | null, FormData>(
    buyerAddParty,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="preparationId" value={preparationId} />

          <Field htmlFor="displayName" label="نام نمایشی" className="md:col-span-2">
            <Input id="displayName" name="displayName" required />
          </Field>

          <Field htmlFor="partyType" label="نوع طرف">
            <select
              id="partyType"
              name="partyType"
              required
              defaultValue=""
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {PARTY_TYPES.map((p) => (
                <option key={p.value} value={p.value}>{p.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="roleTitle" label="عنوان نقش">
            <Input id="roleTitle" name="roleTitle" />
          </Field>

          <Field htmlFor="signingOrder" label="ترتیب امضا">
            <Input id="signingOrder" name="signingOrder" type="number" min="1" dir="ltr" />
          </Field>

          <Field htmlFor="isRequiredSigner" label="امضا الزامی است">
            <input
              id="isRequiredSigner"
              name="isRequiredSigner"
              type="checkbox"
              className="h-4 w-4"
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">طرف افزوده شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "افزودن طرف"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
