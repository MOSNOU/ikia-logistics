import { Badge } from "@/components/ui/badge";
import type { DriverTripIssueLite } from "@/lib/driver/get-trip";
import {
  issueSummary,
  calculateOperationalRisk,
  riskMeta,
} from "@/lib/driver/issue-intelligence";

// Phase M2 (v1.3) — driver-facing Operational Issue Panel. READ-ONLY. Consumes
// the Phase M1 issue-intelligence engine over the driver's own (RLS-scoped)
// issue rows. No issue creation/editing here; that stays in DriverIssuePanel.

export function DriverIssueIntelligencePanel({
  issues,
  podCount,
  executionStatus,
}: {
  issues: DriverTripIssueLite[];
  podCount: number;
  executionStatus: string | null;
}) {
  const active = issues.filter((i) => i.status !== "resolved");

  if (active.length === 0) {
    return (
      <p className="text-xs leading-6 text-muted-foreground">
        مشکل فعالی ثبت نشده است
      </p>
    );
  }

  const summaries = active.map((i) =>
    issueSummary(
      {
        status: i.status,
        createdAt: i.createdAt,
        category: i.category,
        numericSeverity: i.severity,
      },
      { podCount, executionStatus },
    ),
  );

  const worstSeverity = summaries.reduce((a, b) =>
    b.severityMeta.priority > a.severityMeta.priority ? b : a,
  );
  const worstEscalation = summaries.reduce((a, b) =>
    b.escalationMeta.priority > a.escalationMeta.priority ? b : a,
  );
  const longest = summaries.reduce((a, b) =>
    b.age.minutes > a.age.minutes ? b : a,
  );
  const rMeta = riskMeta(
    calculateOperationalRisk({
      podCount,
      executionStatus,
      issueSeverity: worstSeverity.severity,
    }),
  );

  return (
    <div className="grid grid-cols-2 gap-4">
      <div className="space-y-1">
        <span className="text-xs text-muted-foreground">مشکلات فعال</span>
        <div>
          <Badge variant="warning">
            {active.length.toLocaleString("fa-IR")}
          </Badge>
        </div>
      </div>
      <div className="space-y-1">
        <span className="text-xs text-muted-foreground">بالاترین شدت</span>
        <div>
          <Badge variant={worstSeverity.severityMeta.badge}>
            {worstSeverity.severityMeta.fa}
          </Badge>
        </div>
      </div>
      <div className="space-y-1">
        <span className="text-xs text-muted-foreground">سطح ارجاع</span>
        <div>
          <Badge variant={worstEscalation.escalationMeta.badge}>
            {worstEscalation.escalationMeta.fa}
          </Badge>
        </div>
      </div>
      <div className="space-y-1">
        <span className="text-xs text-muted-foreground">قدیمی‌ترین مشکل باز</span>
        <div className="text-sm font-medium">{longest.age.text}</div>
      </div>
      <div className="col-span-2 space-y-1">
        <span className="text-xs text-muted-foreground">ریسک عملیاتی</span>
        <div>
          <Badge variant={rMeta.badge}>{rMeta.fa}</Badge>
        </div>
      </div>
    </div>
  );
}
