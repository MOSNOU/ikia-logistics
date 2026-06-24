"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerInviteSuppliers, type RfqActionState } from "@/lib/rfq/buyer-actions";

export function InviteSuppliersForm({ requestId }: { requestId: string }) {
  const [state, action, pending] = useActionState<RfqActionState | null, FormData>(
    buyerInviteSuppliers,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4">
          <input type="hidden" name="requestId" value={requestId} />

          <Field htmlFor="supplierIds" label="شناسه‌های تأمین‌کننده (UUID جدا با کاما یا فاصله)">
            <textarea
              id="supplierIds"
              name="supplierIds"
              required
              dir="ltr"
              rows={3}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono"
              placeholder="00000000-0000-0000-0000-000000000000"
            />
          </Field>

          <Field htmlFor="message" label="پیام (اختیاری)">
            <Input id="message" name="message" />
          </Field>

          {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
          {state?.ok ? (
            <p className="text-xs text-emerald-600">
              {state.count ?? 0} دعوت ارسال شد.
            </p>
          ) : null}

          <div>
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ارسال دعوت‌ها"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
