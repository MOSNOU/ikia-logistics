import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
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
  CapacityMatchRow,
  CarrierMatchRow,
  MatchingScoreBreakdown,
} from "@/types/database";

function scoreTone(score: number): "success" | "warning" | "outline" | "danger" {
  if (score >= 80) return "success";
  if (score >= 50) return "warning";
  if (score > 0) return "outline";
  return "danger";
}

function breakdownPills(b: MatchingScoreBreakdown): React.ReactNode {
  const cells: Array<[string, number]> = [
    ["مود", b.transport_mode],
    ["مبدأ", b.origin],
    ["مقصد", b.destination],
    ["تقویم", b.availability],
    ["پروفایل", b.profile],
    ["انتشار", b.visibility],
  ];
  return (
    <div className="flex flex-wrap gap-1 text-[10px]">
      {cells.map(([label, val]) => (
        <span
          key={label}
          className="rounded-md border px-1.5 py-0.5 text-muted-foreground"
        >
          {label}: {val}
        </span>
      ))}
    </div>
  );
}

interface CapacityProps {
  rows: CapacityMatchRow[];
}

export function MatchingCapacityTable({ rows }: CapacityProps) {
  if (rows.length === 0) {
    return <TableEmpty>ظرفیتی برای پیشنهاد یافت نشد.</TableEmpty>;
  }
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">ظرفیت‌های پیشنهادی</div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>امتیاز</TableHead>
              <TableHead>حمل‌کننده</TableHead>
              <TableHead>مود</TableHead>
              <TableHead>مبدأ</TableHead>
              <TableHead>مقصد</TableHead>
              <TableHead>تا تاریخ</TableHead>
              <TableHead>اجزاء</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={r.capacity_listing_id}>
                <TableCell>
                  <Badge variant={scoreTone(r.score)}>{r.score}</Badge>
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {r.carrier_name ?? r.carrier_organization_id}
                </TableCell>
                <TableCell>{r.transport_mode}</TableCell>
                <TableCell className="text-xs">{r.origin_country_code ?? "—"}</TableCell>
                <TableCell className="text-xs">{r.destination_country_code ?? "—"}</TableCell>
                <TableCell className="text-xs">{r.valid_until ?? "—"}</TableCell>
                <TableCell>{breakdownPills(r.score_breakdown)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

interface CarrierProps {
  rows: CarrierMatchRow[];
}

export function MatchingCarriersTable({ rows }: CarrierProps) {
  if (rows.length === 0) {
    return <TableEmpty>حمل‌کننده‌ای برای پیشنهاد یافت نشد.</TableEmpty>;
  }
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">حمل‌کنندگان پیشنهادی</div>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>امتیاز</TableHead>
              <TableHead>حمل‌کننده</TableHead>
              <TableHead>بهترین ظرفیت</TableHead>
              <TableHead>نوع امتیاز</TableHead>
              <TableHead>اجزاء</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={r.carrier_organization_id}>
                <TableCell>
                  <Badge variant={scoreTone(r.score)}>{r.score}</Badge>
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {r.carrier_name ?? r.carrier_organization_id}
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {r.best_listing_id ?? "—"}
                </TableCell>
                <TableCell>
                  {r.score_breakdown.fallback ? (
                    <Badge variant="outline">پروفایل فقط</Badge>
                  ) : (
                    <Badge variant="outline">ظرفیت+پروفایل</Badge>
                  )}
                </TableCell>
                <TableCell>{breakdownPills(r.score_breakdown)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
