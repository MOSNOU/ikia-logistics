"use client";

import { useState } from "react";
import { createClient as createBrowserSupabase } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { Card, CardContent } from "@/components/ui/card";
import {
  registerFileForDocument,
  finalizeDocumentFile,
  createDocumentFileVersion,
  type RegisterFileResult,
  type CreateVersionResult,
} from "@/lib/trade-document/actions-files";

interface Props {
  documentId: string;
  existingFileId?: string;
}

function pickFileType(file: File): "pdf" | "image" | "doc" | "xlsx" | "txt" | "other" {
  const t = file.type.toLowerCase();
  if (t === "application/pdf") return "pdf";
  if (t.startsWith("image/")) return "image";
  if (t.includes("spreadsheet") || file.name.toLowerCase().endsWith(".xlsx")) return "xlsx";
  if (t.includes("msword") || t.includes("officedocument.word")) return "doc";
  if (t.startsWith("text/")) return "txt";
  return "other";
}

export function DocumentFileUpload({ documentId, existingFileId }: Props) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const isNewVersion = !!existingFileId;

  async function onSubmit(formData: FormData) {
    setPending(true);
    setError(null);
    setSuccess(null);
    const file = formData.get("file") as File | null;
    if (!file || file.size === 0) {
      setError("فایلی انتخاب نشده است");
      setPending(false);
      return;
    }

    const meta = new FormData();
    meta.set("documentId", documentId);
    meta.set("filename", file.name);
    meta.set("mimeType", file.type || "application/octet-stream");
    meta.set("sizeBytes", String(file.size));
    meta.set("fileType", pickFileType(file));
    if (isNewVersion) meta.set("fileId", existingFileId!);

    let reg: RegisterFileResult | CreateVersionResult;
    if (isNewVersion) {
      reg = await createDocumentFileVersion(null, meta);
    } else {
      reg = await registerFileForDocument(null, meta);
    }
    if (!reg.ok || !reg.uploadUrl || !reg.bucket || !reg.objectKey) {
      setError(reg.error ?? "ثبت فایل ناموفق بود");
      setPending(false);
      return;
    }

    const fileId = isNewVersion ? existingFileId! : (reg as RegisterFileResult).fileId!;

    const supabase = createBrowserSupabase();
    const { error: uploadErr } = await supabase
      .storage
      .from(reg.bucket)
      .uploadToSignedUrl(reg.objectKey, reg.uploadToken ?? "", file, {
        contentType: file.type || undefined,
        upsert: true,
      });
    if (uploadErr) {
      setError(`بارگذاری ناموفق: ${uploadErr.message}`);
      setPending(false);
      return;
    }

    if (!isNewVersion) {
      const finalize = new FormData();
      finalize.set("fileId", fileId);
      finalize.set("documentId", documentId);
      finalize.set("sizeBytes", String(file.size));
      const fin = await finalizeDocumentFile(null, finalize);
      if (!fin.ok) {
        setError(fin.error ?? "نهایی‌سازی ناموفق بود");
        setPending(false);
        return;
      }
    }

    setSuccess(isNewVersion ? "نسخه جدید بارگذاری شد" : "فایل بارگذاری شد");
    setPending(false);
  }

  return (
    <Card>
      <CardContent className="p-6">
        <form action={onSubmit} className="grid gap-4">
          <Field
            htmlFor="file"
            label={isNewVersion ? "بارگذاری نسخه جدید" : "بارگذاری فایل جدید"}
          >
            <Input id="file" name="file" type="file" required />
          </Field>
          {error ? <p className="text-xs text-destructive">{error}</p> : null}
          {success ? <p className="text-xs text-emerald-600">{success}</p> : null}
          <div>
            <Button type="submit" disabled={pending}>
              {pending ? "در حال بارگذاری..." : "بارگذاری"}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
