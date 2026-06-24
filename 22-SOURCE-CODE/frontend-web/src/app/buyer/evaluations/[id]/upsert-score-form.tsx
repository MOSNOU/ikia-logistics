"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import { buyerUpsertScore, type EvaluationActionState } from "@/lib/evaluation/buyer-actions";

export function UpsertScoreForm({ evaluationId }: { evaluationId: string }) {
  const [state, action, pending] = useActionState<EvaluationActionState | null, FormData>(
    buyerUpsertScore,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="grid gap-4 md:grid-cols-3">
          <input type="hidden" name="evaluationId" value={evaluationId} />

          <Field htmlFor="dimension" label="بعد امتیاز" className="md:col-span-3">
            <Input id="dimension" name="dimension" required placeholder="price | lead_time | technical" />
          </Field>

          <Field htmlFor="scoreValue" label="امتیاز">
            <Input id="scoreValue" name="scoreValue" type="number" step="0.01" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="maxScore" label="حداکثر">
            <Input id="maxScore" name="maxScore" type="number" step="0.01" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="weight" label="وزن">
            <Input id="weight" name="weight" type="number" step="0.01" min="0" dir="ltr" />
          </Field>

          <Field htmlFor="weightedScore" label="امتیاز وزنی">
            <Input id="weightedScore" name="weightedScore" type="number" step="0.01" dir="ltr" />
          </Field>

          <Field htmlFor="notes" label="یادداشت" className="md:col-span-2">
            <Input id="notes" name="notes" />
          </Field>

          {state?.error ? (
            <p className="md:col-span-3 text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="md:col-span-3 text-xs text-emerald-600">امتیاز ذخیره شد.</p>
          ) : null}

          <div className="md:col-span-3">
            <Button type="submit" disabled={pending}>
              {pending ? "..." : "ذخیره امتیاز"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
