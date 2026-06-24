"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpdateEvaluation, type EvaluationActionState } from "@/lib/evaluation/buyer-actions";

interface Defaults {
  overallNotes: string;
  commercialNotes: string;
  technicalNotes: string;
  riskNotes: string;
}

export function NotesForm({
  evaluationId,
  defaults,
}: {
  evaluationId: string;
  defaults: Defaults;
}) {
  const [state, action, pending] = useActionState<EvaluationActionState | null, FormData>(
    buyerUpdateEvaluation,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-2">
          <input type="hidden" name="evaluationId" value={evaluationId} />

          <Field htmlFor="overallNotes" label="یادداشت کلی" className="md:col-span-2">
            <textarea
              id="overallNotes"
              name="overallNotes"
              defaultValue={defaults.overallNotes}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={2}
            />
          </Field>

          <Field htmlFor="commercialNotes" label="یادداشت تجاری">
            <textarea
              id="commercialNotes"
              name="commercialNotes"
              defaultValue={defaults.commercialNotes}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={2}
            />
          </Field>

          <Field htmlFor="technicalNotes" label="یادداشت فنی">
            <textarea
              id="technicalNotes"
              name="technicalNotes"
              defaultValue={defaults.technicalNotes}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={2}
            />
          </Field>

          <Field htmlFor="riskNotes" label="یادداشت ریسک" className="md:col-span-2">
            <textarea
              id="riskNotes"
              name="riskNotes"
              defaultValue={defaults.riskNotes}
              className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              rows={2}
            />
          </Field>

          {state?.error ? (
            <p className="md:col-span-2 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-2 text-xs text-emerald-600">یادداشت‌ها ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-2">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره یادداشت‌ها"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
