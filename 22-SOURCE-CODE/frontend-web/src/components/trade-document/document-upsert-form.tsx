"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  type TradeDocActionState,
  upsertBuyerDocument,
} from "@/lib/trade-document/actions-buyer";
import {
  DOC_KIND_OPTIONS,
  DOC_STATUS_OPTIONS,
} from "@/lib/trade-document/labels";

interface Props {
  shipmentId: string;
  documentId?: string;
  initial?: {
    documentKind?: string;
    documentStatus?: string;
    requirementId?: string | null;
    shipmentItemId?: string | null;
    externalReference?: string | null;
    issuedAt?: string | null;
    expiresAt?: string | null;
    notes?: string | null;
  };
  submitLabel?: string;
}

function toDateInput(v?: string | null): string {
  if (!v) return "";
  const idx = v.indexOf("T");
  return idx > 0 ? v.slice(0, idx) : v;
}

export function DocumentUpsertForm({
  shipmentId,
  documentId,
  initial,
  submitLabel,
}: Props) {
  const [state, action, pending] = useActionState<TradeDocActionState | null, FormData>(
    upsertBuyerDocument,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="shipmentId" value={shipmentId} />
          {documentId ? (
            <input type="hidden" name="documentId" value={documentId} />
          ) : null}

          <Field
            htmlFor="documentKind"
            label="نوع مدرک"
            error={state?.fieldErrors?.documentKind}
          >
            <select
              id="documentKind"
              name="documentKind"
              required
              defaultValue={initial?.documentKind ?? ""}
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              <option value="" disabled>— انتخاب —</option>
              {DOC_KIND_OPTIONS.filter((o) => o.value !== "").map((k) => (
                <option key={k.value} value={k.value}>{k.label}</option>
              ))}
            </select>
          </Field>

          <Field
            htmlFor="documentStatus"
            label="وضعیت"
            error={state?.fieldErrors?.documentStatus}
          >
            <select
              id="documentStatus"
              name="documentStatus"
              defaultValue={initial?.documentStatus ?? "pending"}
              className="h-9 w-full rounded-md border border-input bg-background px-2 text-sm"
            >
              {DOC_STATUS_OPTIONS.filter((o) => o.value !== "").map((s) => (
                <option key={s.value} value={s.value}>{s.label}</option>
              ))}
            </select>
          </Field>

          <Field htmlFor="externalReference" label="مرجع خارجی">
            <Input
              id="externalReference"
              name="externalReference"
              dir="ltr"
              placeholder="BL/AWB number"
              defaultValue={initial?.externalReference ?? ""}
            />
          </Field>

          <Field htmlFor="issuedAt" label="تاریخ صدور">
            <Input
              id="issuedAt"
              name="issuedAt"
              type="date"
              dir="ltr"
              defaultValue={toDateInput(initial?.issuedAt)}
            />
          </Field>

          <Field htmlFor="expiresAt" label="تاریخ انقضا">
            <Input
              id="expiresAt"
              name="expiresAt"
              type="date"
              dir="ltr"
              defaultValue={toDateInput(initial?.expiresAt)}
            />
          </Field>

          <Field
            htmlFor="requirementId"
            label="نیازمندی مرتبط (UUID)"
            error={state?.fieldErrors?.requirementId}
          >
            <Input
              id="requirementId"
              name="requirementId"
              dir="ltr"
              placeholder="optional"
              defaultValue={initial?.requirementId ?? ""}
            />
          </Field>

          <Field
            htmlFor="shipmentItemId"
            label="آیتم محموله (UUID)"
            error={state?.fieldErrors?.shipmentItemId}
            className="md:col-span-2"
          >
            <Input
              id="shipmentItemId"
              name="shipmentItemId"
              dir="ltr"
              placeholder="optional"
              defaultValue={initial?.shipmentItemId ?? ""}
            />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-3">
            <Input id="notes" name="notes" defaultValue={initial?.notes ?? ""} />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">مدرک ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : (submitLabel ?? "ذخیره مدرک")}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
