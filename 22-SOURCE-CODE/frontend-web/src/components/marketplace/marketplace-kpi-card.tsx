import { Card, CardContent } from "@/components/ui/card";

interface Props {
  label: string;
  value: number;
  caption?: string;
  available: boolean;
  tone?: "default" | "success" | "warning";
}

const tones: Record<NonNullable<Props["tone"]>, string> = {
  default: "",
  success: "border-emerald-300/60",
  warning: "border-amber-300/60",
};

export function MarketplaceKpiCard({
  label,
  value,
  caption,
  available,
  tone = "default",
}: Props) {
  return (
    <Card className={tones[tone]}>
      <CardContent className="p-4 space-y-1">
        <div className="text-xs text-muted-foreground">{label}</div>
        {available ? (
          <div className="text-2xl font-semibold tabular-nums">
            {value.toLocaleString("fa-IR")}
          </div>
        ) : (
          <div className="text-sm text-muted-foreground">در دسترس نیست</div>
        )}
        {caption ? <div className="text-xs text-muted-foreground">{caption}</div> : null}
      </CardContent>
    </Card>
  );
}
