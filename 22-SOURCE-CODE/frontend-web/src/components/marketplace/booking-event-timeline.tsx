import { Card, CardContent } from "@/components/ui/card";
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
import type { BookingDetail } from "@/types/database";
import { BookingStatusBadge } from "./booking-status-badge";

const EVENT_LABEL: Record<string, string> = {
  booking_requested: "ثبت درخواست",
  booking_accepted: "پذیرش توسط حمل‌کننده",
  booking_rejected: "رد توسط حمل‌کننده",
  booking_confirmed: "تأیید خریدار",
  booking_cancelled: "لغو",
};

const PARTY_LABEL: Record<string, string> = {
  buyer: "خریدار",
  carrier: "حمل‌کننده",
  admin: "ادمین",
  system: "سامانه",
};

interface Props {
  events: BookingDetail["events"];
}

export function BookingEventTimeline({ events }: Props) {
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">تاریخچه رزرو</div>
        {events.length === 0 ? (
          <TableEmpty>رویدادی برای این رزرو ثبت نشده است.</TableEmpty>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>رویداد</TableHead>
                <TableHead>از</TableHead>
                <TableHead>به</TableHead>
                <TableHead>کنش‌گر</TableHead>
                <TableHead>دلیل</TableHead>
                <TableHead>زمان</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {events.map((e) => (
                <TableRow key={e.id}>
                  <TableCell className="text-xs">
                    {EVENT_LABEL[e.event_type] ?? e.event_type}
                  </TableCell>
                  <TableCell>
                    {e.from_status ? (
                      <BookingStatusBadge status={e.from_status} />
                    ) : (
                      <Badge variant="outline">—</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    <BookingStatusBadge status={e.to_status} />
                  </TableCell>
                  <TableCell className="text-xs">
                    {PARTY_LABEL[e.actor_party] ?? e.actor_party}
                  </TableCell>
                  <TableCell className="text-xs">{e.reason ?? "—"}</TableCell>
                  <TableCell className="text-xs">{e.created_at}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
