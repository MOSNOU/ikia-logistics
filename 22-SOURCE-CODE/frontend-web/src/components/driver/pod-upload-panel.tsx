"use client";

import { useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";
import {
  registerPodUpload,
  finalizeAndAttachPod,
} from "@/lib/driver/trip-actions";

// Phase D4 — proof-of-delivery (POD) upload.
//
// Flow: registerPodUpload (app_storage.portal_register_file + signed URL) →
// browser uploadToSignedUrl → finalizeAndAttachPod (finalize + driver_attach_pod).
// Reuses the private "app-documents" bucket. NO offline queue / service worker.

type Feedback = { ok: boolean; message: string };

const ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
]);
const MAX_BYTES = 10 * 1024 * 1024;

const POD_KINDS: { value: string; label: string }[] = [
  { value: "delivery_photo", label: "عکس تحویل" },
  { value: "bill_of_lading", label: "بارنامه" },
  { value: "receipt", label: "رسید" },
  { value: "other", label: "سایر" },
];

export function PodUploadPanel({ dispatchId }: { dispatchId: string }) {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [pending, startTransition] = useTransition();
  const [kind, setKind] = useState<string>("delivery_photo");
  const [feedback, setFeedback] = useState<Feedback | null>(null);

  function handleUpload() {
    setFeedback(null);
    const file = fileInputRef.current?.files?.[0];
    if (!file) {
      setFeedback({ ok: false, message: "ابتدا یک فایل انتخاب کنید." });
      return;
    }
    if (!ALLOWED_MIME.has(file.type)) {
      setFeedback({
        ok: false,
        message: "نوع فایل پشتیبانی نمی‌شود. تصویر یا PDF بارگذاری کنید.",
      });
      return;
    }
    if (file.size > MAX_BYTES) {
      setFeedback({
        ok: false,
        message: "حجم فایل بیش از حد مجاز است (حداکثر ۱۰ مگابایت).",
      });
      return;
    }

    startTransition(async () => {
      // (a) register the file row + signed upload URL.
      const reg = await registerPodUpload(dispatchId, {
        filename: file.name,
        mimeType: file.type,
        sizeBytes: file.size,
      });
      if (!reg.ok) {
        setFeedback({ ok: false, message: reg.message ?? "ثبت فایل ناموفق بود." });
        return;
      }

      // (b) upload the bytes from the browser using the signed token.
      const supabase = createClient();
      const { error: uploadError } = await supabase.storage
        .from(reg.bucket!)
        .uploadToSignedUrl(reg.objectKey!, reg.uploadToken!, file);
      if (uploadError) {
        setFeedback({ ok: false, message: "بارگذاری فایل ناموفق بود." });
        return;
      }

      // (c) finalize + attach as POD.
      const fin = await finalizeAndAttachPod(
        dispatchId,
        reg.fileId!,
        file.size,
        kind,
      );
      setFeedback(fin);
      if (fin.ok) {
        if (fileInputRef.current) fileInputRef.current.value = "";
        router.refresh();
      }
    });
  }

  return (
    <div className="space-y-3">
      <p className="text-xs leading-6 text-muted-foreground">
        عکس رسید، بارنامه یا مدرک تحویل را بارگذاری کنید.
      </p>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*,application/pdf"
        capture="environment"
        disabled={pending}
        className="block w-full text-sm text-foreground file:ml-3 file:rounded-md file:border-0 file:bg-primary file:px-4 file:py-2 file:text-sm file:font-medium file:text-primary-foreground"
      />

      <label className="block space-y-1">
        <span className="text-xs font-medium text-muted-foreground">
          نوع سند
        </span>
        <select
          value={kind}
          onChange={(e) => setKind(e.target.value)}
          disabled={pending}
          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm"
        >
          {POD_KINDS.map((k) => (
            <option key={k.value} value={k.value}>
              {k.label}
            </option>
          ))}
        </select>
      </label>

      <Button
        type="button"
        onClick={handleUpload}
        disabled={pending}
        className="h-12 w-full text-base font-semibold"
      >
        {pending ? "در حال بارگذاری…" : "بارگذاری سند تحویل"}
      </Button>

      {feedback ? (
        <p
          role="status"
          className={cn(
            "text-center text-xs leading-6",
            feedback.ok
              ? "text-emerald-600 dark:text-emerald-400"
              : "text-destructive",
          )}
        >
          {feedback.message}
        </p>
      ) : null}
    </div>
  );
}
