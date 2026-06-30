"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { reportDriverIssue, type TripActionResult } from "@/lib/driver/trip-actions";
import {
  TRIP_ISSUE_CATEGORIES,
  TRIP_ISSUE_SEVERITIES,
} from "@/lib/driver/issue-meta";

// Phase D5 — driver issue reporting form.
//
// The driver picks a category + severity and optionally describes the problem;
// reportDriverIssue calls dispatch.driver_report_issue. NO photo upload in D5
// (future task), NO background work, NO offline queue. Large mobile touch
// targets; only friendly Persian feedback is surfaced.

const DEFAULT_CATEGORY = "delay";

export function DriverIssuePanel({ dispatchId }: { dispatchId: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [category, setCategory] = useState<string>(DEFAULT_CATEGORY);
  const [severity, setSeverity] = useState<number>(1);
  const [description, setDescription] = useState<string>("");
  const [feedback, setFeedback] = useState<TripActionResult | null>(null);

  function handleSubmit() {
    setFeedback(null);
    startTransition(async () => {
      const res = await reportDriverIssue(dispatchId, {
        category,
        severity,
        description,
      });
      setFeedback(res);
      if (res.ok) {
        setDescription("");
        setSeverity(1);
        setCategory(DEFAULT_CATEGORY);
        router.refresh();
      }
    });
  }

  return (
    <div className="space-y-3">
      <p className="text-xs leading-6 text-muted-foreground">
        در صورت تأخیر، مشکل خودرو، بارگیری، مرز یا حادثه، موضوع را برای تیم عملیات
        ثبت کنید.
      </p>

      <label className="block space-y-1">
        <span className="text-xs font-medium text-muted-foreground">دسته مشکل</span>
        <select
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          disabled={pending}
          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm"
        >
          {TRIP_ISSUE_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>
      </label>

      <label className="block space-y-1">
        <span className="text-xs font-medium text-muted-foreground">شدت</span>
        <select
          value={severity}
          onChange={(e) => setSeverity(Number(e.target.value))}
          disabled={pending}
          className="h-11 w-full rounded-md border border-input bg-background px-3 text-sm"
        >
          {TRIP_ISSUE_SEVERITIES.map((s) => (
            <option key={s.value} value={s.value}>
              {s.label}
            </option>
          ))}
        </select>
      </label>

      <label className="block space-y-1">
        <span className="text-xs font-medium text-muted-foreground">
          توضیحات (اختیاری)
        </span>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          disabled={pending}
          rows={3}
          maxLength={1000}
          placeholder="شرح کوتاهی از مشکل بنویسید…"
          className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm leading-7"
        />
      </label>

      <Button
        type="button"
        onClick={handleSubmit}
        disabled={pending}
        className="h-12 w-full text-base font-semibold"
      >
        {pending ? "در حال ثبت گزارش…" : "ثبت گزارش مشکل"}
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
