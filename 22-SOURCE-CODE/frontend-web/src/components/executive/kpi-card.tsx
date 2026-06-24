import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import type { ExecutiveKpi } from "@/types/database";

const toneBorder: Record<NonNullable<ExecutiveKpi["tone"]>, string> = {
  default: "",
  success: "border-emerald-300/60",
  warning: "border-amber-300/60",
  danger: "border-rose-300/60",
};

interface Props {
  kpi: ExecutiveKpi;
}

export function KpiCard({ kpi }: Props) {
  const tone = kpi.tone ?? "default";
  const body = (
    <Card className={toneBorder[tone]}>
      <CardContent className="p-4 space-y-1">
        <div className="text-xs text-muted-foreground">{kpi.label}</div>
        {kpi.available ? (
          <div className="text-2xl font-semibold tabular-nums">
            {kpi.value.toLocaleString("fa-IR")}
          </div>
        ) : (
          <div className="text-sm text-muted-foreground">در دسترس نیست</div>
        )}
        {kpi.caption ? (
          <div className="text-xs text-muted-foreground">{kpi.caption}</div>
        ) : null}
      </CardContent>
    </Card>
  );
  if (kpi.href && kpi.available) {
    return (
      <Link href={kpi.href} className="block focus:outline-none focus:ring-2 rounded-md">
        {body}
      </Link>
    );
  }
  return body;
}
