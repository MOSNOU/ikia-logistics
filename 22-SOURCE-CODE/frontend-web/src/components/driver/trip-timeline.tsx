import { driverTripStatusLabel } from "@/lib/driver/trip-status";
import { faShortDateTime, faRelativeTime } from "@/lib/driver/relative-time";
import type { DriverTripEvent } from "@/lib/driver/get-trip";

// Phase G (v1.2) — read-only driver trip event timeline. Renders the
// driver-visible ledger (RLS-scoped) newest-first. Issue markers (from==to
// with an "issue:" reason) are shown as reports rather than transitions.

function isIssueEvent(ev: DriverTripEvent): boolean {
  return (ev.reason ?? "").startsWith("issue:");
}

export function TripTimeline({ events }: { events: DriverTripEvent[] }) {
  if (events.length === 0) {
    return (
      <p className="text-xs leading-6 text-muted-foreground">
        هنوز رویدادی برای این سفر ثبت نشده است.
      </p>
    );
  }

  // Newest first for reading.
  const ordered = [...events].reverse();

  return (
    <ol className="space-y-3">
      {ordered.map((ev) => {
        const issue = isIssueEvent(ev);
        return (
          <li key={ev.id} className="flex gap-3">
            <span
              className={
                "mt-1 h-2.5 w-2.5 shrink-0 rounded-full " +
                (issue ? "bg-amber-500" : "bg-primary")
              }
              aria-hidden
            />
            <div className="min-w-0 flex-1 space-y-0.5">
              <div className="text-sm">
                {issue ? (
                  <span className="font-medium text-amber-700 dark:text-amber-400">
                    گزارش مشکل
                  </span>
                ) : (
                  <span className="font-medium">
                    {driverTripStatusLabel(ev.toStatus)}
                  </span>
                )}
              </div>
              <div className="text-[11px] leading-5 text-muted-foreground">
                {faShortDateTime(ev.createdAt)} · {faRelativeTime(ev.createdAt)}
              </div>
            </div>
          </li>
        );
      })}
    </ol>
  );
}
