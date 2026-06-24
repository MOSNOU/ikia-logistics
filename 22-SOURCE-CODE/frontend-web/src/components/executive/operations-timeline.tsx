import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import type { PipelineStep } from "@/types/database";

interface Props {
  steps: PipelineStep[];
}

export function OperationsTimeline({ steps }: Props) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="text-sm font-medium mb-3">خط لوله عملیات</div>
        <ol
          className="flex flex-wrap items-center gap-2 text-sm"
          aria-label="مراحل عملیاتی"
        >
          {steps.map((step, idx) => {
            const inner = (
              <div className="rounded-md border px-3 py-2 space-y-1">
                <div className="text-xs text-muted-foreground">{step.label}</div>
                {step.available ? (
                  <div className="text-base font-semibold tabular-nums">
                    {step.count.toLocaleString("fa-IR")}
                  </div>
                ) : (
                  <Badge variant="outline">N/A</Badge>
                )}
              </div>
            );
            return (
              <li key={step.id} className="flex items-center gap-2">
                {step.available ? (
                  <Link href={step.href} className="block">{inner}</Link>
                ) : (
                  inner
                )}
                {idx < steps.length - 1 ? (
                  <span className="text-muted-foreground">←</span>
                ) : null}
              </li>
            );
          })}
        </ol>
      </CardContent>
    </Card>
  );
}
