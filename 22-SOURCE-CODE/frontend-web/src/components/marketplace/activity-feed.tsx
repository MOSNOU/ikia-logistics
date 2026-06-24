import Link from "next/link";
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
import type { MarketplaceActivityRow } from "@/types/database";

const KIND_LABEL: Record<MarketplaceActivityRow["kind"], string> = {
  shipment_booked: "شیپمنت رزروشده",
  shipment_in_transit: "شیپمنت در حال حمل",
  carrier_added: "حمل‌کننده جدید",
  capacity_published: "ظرفیت منتشرشده",
  capacity_archived: "ظرفیت بایگانی‌شده",
};

interface Props {
  rows: MarketplaceActivityRow[];
  title?: string;
}

export function ActivityFeed({ rows, title = "فعالیت مارکت‌پلیس" }: Props) {
  return (
    <Card>
      <CardContent className="p-4 space-y-3">
        <div className="text-sm font-medium">{title}</div>
        {rows.length === 0 ? (
          <TableEmpty>فعالیتی برای نمایش وجود ندارد.</TableEmpty>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>نوع</TableHead>
                <TableHead>موضوع</TableHead>
                <TableHead>توضیح</TableHead>
                <TableHead>زمان</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell><Badge variant="outline">{KIND_LABEL[r.kind]}</Badge></TableCell>
                  <TableCell className="font-mono text-xs">{r.subject}</TableCell>
                  <TableCell className="text-xs">{r.description}</TableCell>
                  <TableCell className="text-xs">{r.created_at}</TableCell>
                  <TableCell>
                    {r.href ? (
                      <Link href={r.href} className="text-xs underline text-muted-foreground">
                        مشاهده
                      </Link>
                    ) : null}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
