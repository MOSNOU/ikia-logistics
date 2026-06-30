"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import {
  ackDriverIssue,
  resolveDriverIssue,
  type IssueActionResult,
} from "@/lib/driver/admin-issue-actions";

// Phase D5 — operations/admin acknowledge + resolve controls for one issue.
//
// Buttons are gated on the issue's current status (the server RPC is the source
// of truth and re-validates):
//   open         → «تأیید دریافت» + «حل‌شده»
//   acknowledged → «حل‌شده»
//   resolved     → no action
// An optional resolution note can accompany «حل‌شده».

export function AdminDriverIssueActions({
  issueId,
  dispatchId,
  status,
}: {
  issueId: string;
  dispatchId: string;
  status: string | null;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [note, setNote] = useState<string>("");
  const [feedback, setFeedback] = useState<IssueActionResult | null>(null);

  const canAck = status === "open";
  const canResolve = status === "open" || status === "acknowledged";

  function run(action: () => Promise<IssueActionResult>) {
    setFeedback(null);
    startTransition(async () => {
      const res = await action();
      setFeedback(res);
      if (res.ok) {
        setNote("");
        router.refresh();
      }
    });
  }

  if (!canAck && !canResolve) {
    return (
      <p className="text-xs leading-6 text-muted-foreground">
        این مشکل حل‌شده است و اقدام دیگری لازم نیست.
      </p>
    );
  }

  return (
    <div className="space-y-2">
      {canResolve ? (
        <input
          type="text"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          disabled={pending}
          maxLength={500}
          placeholder="یادداشت حل مشکل (اختیاری)"
          className="h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
        />
      ) : null}

      <div className="flex flex-wrap gap-2">
        {canAck ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={pending}
            onClick={() => run(() => ackDriverIssue(issueId, dispatchId))}
          >
            {pending ? "در حال ثبت…" : "تأیید دریافت"}
          </Button>
        ) : null}
        {canResolve ? (
          <Button
            type="button"
            size="sm"
            disabled={pending}
            onClick={() => run(() => resolveDriverIssue(issueId, note, dispatchId))}
          >
            {pending ? "در حال ثبت…" : "حل‌شده"}
          </Button>
        ) : null}
      </div>

      {feedback ? (
        <p
          role="status"
          className={cn(
            "text-xs leading-6",
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
