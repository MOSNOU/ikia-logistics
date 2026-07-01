import { Badge } from "@/components/ui/badge";
import { podKindLabel } from "@/lib/driver/issue-meta";

// Phase G (v1.2) — READ-ONLY proof-of-delivery readiness. Surfaces whether a
// POD exists and which kinds are present, and explains the completion gate.
// It does NOT upload or capture metadata (Q3 deferred) — the existing
// PodUploadPanel remains the only write surface.

export function PodReadinessPanel({
  podCount,
  podKinds,
  hasPod,
}: {
  podCount: number;
  podKinds: string[];
  hasPod: boolean;
}) {
  const uniqueKinds = Array.from(new Set(podKinds));

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="text-xs text-muted-foreground">وضعیت سند تحویل</span>
        {hasPod ? (
          <Badge variant="success">
            ثبت‌شده ({podCount.toLocaleString("fa-IR")})
          </Badge>
        ) : (
          <Badge variant="warning">ثبت نشده</Badge>
        )}
      </div>

      {hasPod ? (
        <div className="flex flex-wrap gap-2">
          {uniqueKinds.length > 0 ? (
            uniqueKinds.map((k) => (
              <Badge key={k} variant="muted">
                {podKindLabel(k)}
              </Badge>
            ))
          ) : (
            <span className="text-xs text-muted-foreground">
              سند تحویل ثبت شده است.
            </span>
          )}
        </div>
      ) : (
        <p className="text-xs leading-6 text-muted-foreground">
          برای تکمیل سفر باید حداقل یک سند تحویل بارگذاری شود. از بخش «اسناد تحویل»
          استفاده کنید.
        </p>
      )}
    </div>
  );
}
