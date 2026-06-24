"use client";

import { useActionState } from "react";
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
import {
  archiveDocumentFile,
  type DocumentFileRow,
  type FileActionState,
} from "@/lib/trade-document/actions-files";

interface Props {
  documentId: string;
  files: DocumentFileRow[];
}

function formatBytes(n: number | null): string {
  if (n == null) return "—";
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1024 / 1024).toFixed(2)} MB`;
}

function ArchiveButton({ documentId, fileId }: { documentId: string; fileId: string }) {
  const [state, action, pending] = useActionState<FileActionState | null, FormData>(
    archiveDocumentFile,
    null,
  );
  return (
    <form action={action} className="inline">
      <input type="hidden" name="fileId" value={fileId} />
      <input type="hidden" name="documentId" value={documentId} />
      <Button type="submit" variant="outline" size="sm" disabled={pending || state?.ok}>
        {state?.ok ? "بایگانی شد" : pending ? "..." : "بایگانی"}
      </Button>
    </form>
  );
}

export function DocumentFileList({ documentId, files }: Props) {
  if (files.length === 0) {
    return <TableEmpty>هیچ فایلی برای این مدرک ثبت نشده است.</TableEmpty>;
  }
  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>نام فایل</TableHead>
            <TableHead>نوع</TableHead>
            <TableHead>حجم</TableHead>
            <TableHead>وضعیت</TableHead>
            <TableHead>نسخه</TableHead>
            <TableHead>تاریخ</TableHead>
            <TableHead>عملیات</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {files.map((f) => (
            <TableRow key={f.file_id}>
              <TableCell className="font-mono text-xs">{f.filename}</TableCell>
              <TableCell className="text-xs">{f.mime_type ?? "—"}</TableCell>
              <TableCell className="text-xs">{formatBytes(f.size_bytes)}</TableCell>
              <TableCell><Badge variant="outline">{f.status}</Badge></TableCell>
              <TableCell className="text-xs">v{f.current_version}</TableCell>
              <TableCell className="text-xs">{f.created_at}</TableCell>
              <TableCell>
                {f.status !== "archived" ? (
                  <ArchiveButton documentId={documentId} fileId={f.file_id} />
                ) : null}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
