import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableEmpty,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listKycVerifications } from "@/lib/admin/list-kyc-verifications";
import type { KycStatus, KycSubjectType } from "@/types/database";

const STATUS_OPTIONS: { value: KycStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "draft", label: "پیش‌نویس" },
  { value: "submitted", label: "ارسال‌شده" },
  { value: "in_review", label: "در حال بررسی" },
  { value: "info_requested", label: "اطلاعات بیشتر" },
  { value: "approved", label: "تأییدشده" },
  { value: "rejected", label: "ردشده" },
  { value: "expired", label: "منقضی" },
];

const SUBJECT_TABS: { value: KycSubjectType; label: string }[] = [
  { value: "person", label: "فردی (KYC)" },
  { value: "organization", label: "سازمانی (KYB)" },
];

interface PageProps {
  searchParams: Promise<{ subject?: string; status?: string; page?: string }>;
}

export default async function AdminKycPage({ searchParams }: PageProps) {
  const { subject, status, page: pageParam } = await searchParams;
  const subjectType: KycSubjectType =
    subject === "organization" ? "organization" : "person";
  const page = Math.max(0, Number.parseInt(pageParam ?? "0", 10) || 0);
  const statusFilter =
    status && STATUS_OPTIONS.some((o) => o.value === status)
      ? (status as KycStatus)
      : null;

  const { rows, pageSize } = await listKycVerifications({
    subjectType,
    status: statusFilter,
    page,
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">صف بررسی احراز هویت</h1>
        <p className="text-sm text-muted-foreground">
          ارجاع، درخواست اطلاعات بیشتر، تأیید یا رد احراز هویت فردی و سازمانی.
        </p>
      </div>

      <div className="flex flex-wrap gap-2 border-b pb-3">
        {SUBJECT_TABS.map((t) => (
          <Button
            key={t.value}
            asChild
            variant={subjectType === t.value ? "default" : "outline"}
            size="sm"
          >
            <Link href={`/admin/kyc?subject=${t.value}`}>{t.label}</Link>
          </Button>
        ))}
      </div>

      <form className="flex flex-wrap items-end gap-3">
        <input type="hidden" name="subject" value={subjectType} />
        <div className="space-y-1">
          <label htmlFor="status" className="text-sm font-medium">وضعیت</label>
          <select
            id="status"
            name="status"
            defaultValue={statusFilter ?? ""}
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
          >
            {STATUS_OPTIONS.map((o) => (
              <option key={o.value} value={o.value}>{o.label}</option>
            ))}
          </select>
        </div>
        <Button type="submit" variant="outline">اعمال فیلتر</Button>
      </form>

      {rows.length === 0 ? (
        <TableEmpty>هیچ تلاش احراز هویتی با این فیلتر یافت نشد.</TableEmpty>
      ) : (
        <div className="rounded-md border">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>شناسه موضوع</TableHead>
                <TableHead>تلاش</TableHead>
                <TableHead>وضعیت</TableHead>
                <TableHead>ارسال در</TableHead>
                <TableHead>بررسی در</TableHead>
                <TableHead>انقضا</TableHead>
                <TableHead>عملیات</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs">{r.subject_id}</TableCell>
                  <TableCell>{r.attempt_no}</TableCell>
                  <TableCell><Badge variant="outline">{r.status}</Badge></TableCell>
                  <TableCell className="text-xs">{r.submitted_at ?? "—"}</TableCell>
                  <TableCell className="text-xs">{r.reviewed_at ?? "—"}</TableCell>
                  <TableCell className="text-xs">{r.expires_at ?? "—"}</TableCell>
                  <TableCell>
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/admin/kyc/${subjectType}/${r.id}`}>مشاهده</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>صفحه {page + 1} — {rows.length} ردیف</span>
        <div className="flex gap-2">
          {page > 0 ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/kyc?subject=${subjectType}&status=${statusFilter ?? ""}&page=${page - 1}`}
              >قبلی</Link>
            </Button>
          ) : null}
          {rows.length === pageSize ? (
            <Button asChild variant="outline" size="sm">
              <Link
                href={`/admin/kyc?subject=${subjectType}&status=${statusFilter ?? ""}&page=${page + 1}`}
              >بعدی</Link>
            </Button>
          ) : null}
        </div>
      </div>
    </div>
  );
}
