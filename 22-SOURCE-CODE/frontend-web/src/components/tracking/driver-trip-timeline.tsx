import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  persianSourceLabel,
  type DriverTripTimelineItem,
  type DriverTripTimelineItemType,
} from "@/lib/telematics/build-driver-trip-timeline";

// CC-51 — Mobile-first Persian/RTL timeline rendering. Pure presentational —
// no fetches, no actions, no state. Receives the composer output as a prop.

type BadgeVariant = "outline" | "success" | "warning" | "danger";

const VARIANT_BY_TYPE: Record<DriverTripTimelineItemType, BadgeVariant> = {
  session_started: "success",
  session_ended: "outline",
  position_reported: "outline",
  signal_lost: "danger",
  signal_restored: "success",
  position_anomaly: "warning",
  dispatch_status: "warning",
  unknown_telemetry_event: "outline",
};

const SHORT_BADGE_FA: Record<DriverTripTimelineItemType, string> = {
  session_started: "نشست — شروع",
  session_ended: "نشست — پایان",
  position_reported: "موقعیت",
  signal_lost: "قطع سیگنال",
  signal_restored: "بازگشت سیگنال",
  position_anomaly: "ناهنجاری",
  dispatch_status: "وضعیت اعزام",
  unknown_telemetry_event: "رویداد",
};

interface Props {
  items: DriverTripTimelineItem[];
  /** Optional anchor id used by inbound deep links (e.g. /trips/[id]#timeline). */
  anchorId?: string;
}

export function DriverTripTimeline({ items, anchorId }: Props) {
  if (items.length === 0) {
    return (
      <Card>
        <CardContent className="p-4 text-sm text-muted-foreground">
          هنوز رویدادی برای نمایش وجود ندارد. پس از شروع نشست تله‌متری و ثبت
          موقعیت، خط زمانی این سفر در همین قسمت ظاهر می‌شود.
        </CardContent>
      </Card>
    );
  }

  return (
    <ol id={anchorId} className="space-y-3">
      {items.map((item) => (
        <li key={item.key}>
          <TimelineCard item={item} />
        </li>
      ))}
    </ol>
  );
}

function TimelineCard({ item }: { item: DriverTripTimelineItem }) {
  return (
    <Card>
      <CardContent className="p-4 space-y-2">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <Badge variant={VARIANT_BY_TYPE[item.type]}>
            {SHORT_BADGE_FA[item.type]}
          </Badge>
          <span className="text-[11px] text-muted-foreground" dir="ltr">
            {item.timestamp}
          </span>
        </div>

        <div className="text-sm font-medium">{item.titleFa}</div>

        {item.descriptionFa ? (
          <p className="text-xs text-muted-foreground leading-6">
            {item.descriptionFa}
          </p>
        ) : null}

        <TimelineMeta item={item} />
      </CardContent>
    </Card>
  );
}

function TimelineMeta({ item }: { item: DriverTripTimelineItem }) {
  const m = item.meta;
  if (!m) return null;

  if (item.type === "position_reported") {
    const hasCoords =
      m.latitude != null && m.longitude != null;
    return (
      <div className="text-[11px] leading-6 text-muted-foreground">
        {hasCoords ? (
          <div dir="ltr" className="font-mono">
            {Number(m.latitude).toFixed(5)}, {Number(m.longitude).toFixed(5)}
          </div>
        ) : null}
        <div className="flex flex-wrap items-center gap-x-3">
          {m.accuracyMeters != null ? (
            <span>دقت: {Math.round(m.accuracyMeters).toLocaleString("fa-IR")} متر</span>
          ) : null}
          <span>منبع: {persianSourceLabel(m.source)}</span>
        </div>
      </div>
    );
  }

  if (item.type === "dispatch_status") {
    return m.actorParty ? (
      <p className="text-[11px] text-muted-foreground">
        ثبت‌کننده: {m.actorParty}
      </p>
    ) : null;
  }

  if (m.eventReason) {
    return (
      <p className="text-[11px] text-muted-foreground">
        توضیح: {m.eventReason}
      </p>
    );
  }
  return null;
}
