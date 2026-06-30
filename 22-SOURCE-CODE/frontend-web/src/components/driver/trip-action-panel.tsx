"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { driverNextAction } from "@/lib/driver/trip-status";
import {
  acceptTrip,
  arrivePickup,
  startLoading,
  confirmLoaded,
  startTransit,
  arriveDelivery,
  startUnloading,
  confirmDelivered,
  type TripActionResult,
} from "@/lib/driver/trip-actions";

// Phase D3 — single-next-action workflow panel. Shows ONLY the next legal
// transition for the current execution status; every other action is
// unreachable. delivered→completed is rendered disabled (POD gate, D4).

type ActionFn = (dispatchId: string) => Promise<TripActionResult>;

const ACTION_FN: Record<string, ActionFn> = {
  accept: acceptTrip,
  arrivePickup,
  startLoading,
  confirmLoaded,
  startTransit,
  arriveDelivery,
  startUnloading,
  confirmDelivered,
};

export function TripActionPanel({
  dispatchId,
  executionStatus,
}: {
  dispatchId: string;
  executionStatus: string | null;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [feedback, setFeedback] = useState<TripActionResult | null>(null);

  const next = driverNextAction(executionStatus);

  // Completed (or unknown terminal state) — nothing to do.
  if (next === null) {
    return (
      <p className="rounded-lg bg-surface-muted p-3 text-center text-sm font-medium text-muted-foreground">
        این سفر تکمیل شده است.
      </p>
    );
  }

  // delivered → completed: gated behind POD upload (D4). Disabled in D3.
  if (next === "complete-gated") {
    return (
      <Button disabled className="h-12 w-full text-sm">
        تکمیل سفر پس از بارگذاری سند تحویل فعال می‌شود
      </Button>
    );
  }

  const run = () => {
    const fn = ACTION_FN[next.key];
    if (!fn) return;
    setFeedback(null);
    startTransition(async () => {
      const res = await fn(dispatchId);
      setFeedback(res);
      if (res.ok) router.refresh();
    });
  };

  return (
    <div className="space-y-2">
      <Button
        type="button"
        onClick={run}
        disabled={pending}
        className="h-12 w-full text-base font-semibold"
      >
        {pending ? "در حال ثبت…" : next.label}
      </Button>
      {feedback ? (
        <p
          role="status"
          className={cn(
            "text-center text-xs leading-6",
            feedback.ok ? "text-emerald-600 dark:text-emerald-400" : "text-destructive",
          )}
        >
          {feedback.message}
        </p>
      ) : null}
    </div>
  );
}
