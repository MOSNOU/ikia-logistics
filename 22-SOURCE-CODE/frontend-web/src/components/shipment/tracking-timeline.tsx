import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type {
  ShipmentMilestoneRow,
  ShipmentStopRow,
  TrackingTimelineRow,
} from "@/types/database";

interface Props {
  timeline: TrackingTimelineRow[];
  milestones: ShipmentMilestoneRow[];
  stops: ShipmentStopRow[];
  audience: "buyer" | "supplier" | "admin";
}

function kindBadge(kind: TrackingTimelineRow["kind"]) {
  switch (kind) {
    case "milestone":
      return <Badge variant="warning">نقطه عطف</Badge>;
    case "stop":
      return <Badge variant="outline">توقف</Badge>;
    case "status_event":
      return <Badge variant="success">تغییر وضعیت</Badge>;
    default:
      return <Badge variant="outline">{kind}</Badge>;
  }
}

export function TrackingTimeline({ timeline, milestones, stops, audience }: Props) {
  return (
    <>
      <div>
        <h2 className="text-lg font-semibold mb-3">خط زمانی ({timeline.length})</h2>
        {timeline.length === 0 ? (
          <TableEmpty>رویدادی برای نمایش وجود ندارد.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>زمان</TableHead>
                  <TableHead>برچسب</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>یادداشت / دلیل</TableHead>
                  {audience === "admin" ? <TableHead>کاربر</TableHead> : null}
                </TableRow>
              </TableHeader>
              <TableBody>
                {timeline.map((row) => (
                  <TableRow key={`${row.kind}-${row.id}`}>
                    <TableCell>{kindBadge(row.kind)}</TableCell>
                    <TableCell className="text-xs">{row.at}</TableCell>
                    <TableCell><Badge variant="outline">{row.label}</Badge></TableCell>
                    <TableCell>{row.status ? <Badge variant="outline">{row.status}</Badge> : "—"}</TableCell>
                    <TableCell className="text-xs">{row.notes ?? "—"}</TableCell>
                    {audience === "admin" ? (
                      <TableCell className="font-mono text-xs">{row.actor_user_id ?? "—"}</TableCell>
                    ) : null}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">نقاط عطف ({milestones.length})</h2>
        {milestones.length === 0 ? (
          <TableEmpty>نقطه عطفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>نوع</TableHead>
                  <TableHead>وضعیت</TableHead>
                  <TableHead>تاریخ برنامه‌ریزی‌شده</TableHead>
                  <TableHead>تاریخ تکمیل</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {milestones.map((m) => (
                  <TableRow key={m.id}>
                    <TableCell><Badge variant="outline">{m.milestone_type}</Badge></TableCell>
                    <TableCell><Badge variant="outline">{m.status}</Badge></TableCell>
                    <TableCell className="text-xs">{m.planned_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{m.completed_at ?? "—"}</TableCell>
                    <TableCell className="text-xs">{m.notes ?? "—"}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-3">توقف‌ها ({stops.length})</h2>
        {stops.length === 0 ? (
          <TableEmpty>توقفی ثبت نشده است.</TableEmpty>
        ) : (
          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ترتیب</TableHead>
                  <TableHead>نوع</TableHead>
                  <TableHead>شهر</TableHead>
                  <TableHead>کشور</TableHead>
                  <TableHead>ورود برنامه‌ریزی</TableHead>
                  <TableHead>ورود واقعی</TableHead>
                  <TableHead>خروج برنامه‌ریزی</TableHead>
                  <TableHead>خروج واقعی</TableHead>
                  <TableHead>یادداشت</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {[...stops]
                  .sort((a, b) => (a.sequence_number ?? 0) - (b.sequence_number ?? 0))
                  .map((s) => (
                    <TableRow key={s.id}>
                      <TableCell>{s.sequence_number}</TableCell>
                      <TableCell><Badge variant="outline">{s.stop_type}</Badge></TableCell>
                      <TableCell>{s.city ?? "—"}</TableCell>
                      <TableCell>{s.country ?? "—"}</TableCell>
                      <TableCell className="text-xs">{s.planned_arrival_at ?? "—"}</TableCell>
                      <TableCell className="text-xs">{s.actual_arrival_at ?? "—"}</TableCell>
                      <TableCell className="text-xs">{s.planned_departure_at ?? "—"}</TableCell>
                      <TableCell className="text-xs">{s.actual_departure_at ?? "—"}</TableCell>
                      <TableCell className="text-xs">{s.notes ?? "—"}</TableCell>
                    </TableRow>
                  ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>
    </>
  );
}
