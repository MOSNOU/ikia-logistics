import { Card, CardContent } from "@/components/ui/card";
import { AmountCell } from "./amount-cell";

interface Props {
  label: string;
  amount?: number | null;
  currency?: string | null;
  count?: number | null;
  caption?: string;
  tone?: "default" | "warning" | "danger" | "success";
}

const toneClass: Record<NonNullable<Props["tone"]>, string> = {
  default: "",
  warning: "border-amber-300/60",
  danger: "border-rose-300/60",
  success: "border-emerald-300/60",
};

export function KpiTile({ label, amount, currency, count, caption, tone = "default" }: Props) {
  return (
    <Card className={toneClass[tone]}>
      <CardContent className="p-4 space-y-1">
        <div className="text-xs text-muted-foreground">{label}</div>
        {amount != null ? (
          <div className="text-xl font-semibold">
            <AmountCell value={amount} currency={currency} className="font-semibold" />
          </div>
        ) : null}
        {count != null ? (
          <div className="text-xl font-semibold tabular-nums">
            {count.toLocaleString("fa-IR")}
          </div>
        ) : null}
        {caption ? <div className="text-xs text-muted-foreground">{caption}</div> : null}
      </CardContent>
    </Card>
  );
}
