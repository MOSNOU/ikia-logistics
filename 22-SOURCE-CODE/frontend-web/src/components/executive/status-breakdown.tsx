import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";

interface Entry {
  label: string;
  value: number;
  tone?: "default" | "warning" | "danger" | "success";
}

interface Props {
  title: string;
  entries: Entry[];
  caption?: string;
}

function variantFor(tone: Entry["tone"]): "outline" | "success" | "warning" | "danger" {
  if (tone === "success") return "success";
  if (tone === "warning") return "warning";
  if (tone === "danger") return "danger";
  return "outline";
}

export function StatusBreakdown({ title, entries, caption }: Props) {
  return (
    <Card>
      <CardContent className="p-4 space-y-2">
        <div className="flex items-center justify-between">
          <div className="text-sm font-medium">{title}</div>
          {caption ? <div className="text-xs text-muted-foreground">{caption}</div> : null}
        </div>
        <div className="flex flex-wrap gap-2">
          {entries.map((e) => (
            <div
              key={e.label}
              className="flex items-center gap-2 rounded-md border px-2 py-1 text-xs"
            >
              <span className="text-muted-foreground">{e.label}</span>
              <Badge variant={variantFor(e.tone)}>{e.value.toLocaleString("fa-IR")}</Badge>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
