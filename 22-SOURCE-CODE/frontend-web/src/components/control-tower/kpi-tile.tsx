import { Card, CardContent } from "@/components/ui/card";

interface Props {
  label: string;
  value: number;
  caption?: string;
  tone?: "default" | "success" | "warning" | "danger";
}

const toneClass: Record<NonNullable<Props["tone"]>, string> = {
  default: "",
  success: "border-emerald-300/60",
  warning: "border-amber-300/60",
  danger: "border-rose-300/60",
};

export function ControlTowerKpiTile({ label, value, caption, tone = "default" }: Props) {
  return (
    <Card className={toneClass[tone]}>
      <CardContent className="p-4 space-y-1">
        <div className="text-xs text-muted-foreground">{label}</div>
        <div className="text-2xl font-semibold tabular-nums">
          {value.toLocaleString("fa-IR")}
        </div>
        {caption ? <div className="text-xs text-muted-foreground">{caption}</div> : null}
      </CardContent>
    </Card>
  );
}
