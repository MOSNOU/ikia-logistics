"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { driverNextAction, DRIVER_COMPLETE_CONFIRM } from "@/lib/driver/trip-status";
import {
  acceptTrip,
  arrivePickup,
  startLoading,
  confirmLoaded,
  startTransit,
  arriveDelivery,
  startUnloading,
  confirmDelivered,
  completeTrip,
  type TripActionResult,
} from "@/lib/driver/trip-actions";

// Phase D3 — single-next-action workflow panel; shows ONLY the next legal
// transition for the current execution status.
// Phase G (v1.2, Q1) — high-risk / irreversible steps (delivered, completed)
// require an explicit two-tap confirmation; normal forward steps stay one-tap.
// Pending/disabled states are unified across all actions.

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

function Feedback({ feedback }: { feedback: TripActionResult | null }) {
  if (!feedback) return null;
  return (
    <p
      role="status"
      className={cn(
        "text-center text-xs leading-6",
        feedback.ok ? "text-emerald-600 dark:text-emerald-400" : "text-destructive",
      )}
    >
      {feedback.message}
    </p>
  );
}

// One action button with an optional confirmation step. When `confirm` is set,
// the first tap reveals a confirm/cancel prompt; only «تأیید» runs the action.
function ActionButton({
  label,
  confirm,
  pending,
  onRun,
}: {
  label: string;
  confirm?: string;
  pending: boolean;
  onRun: () => void;
}) {
  const [confirming, setConfirming] = useState(false);

  if (confirm && confirming) {
    return (
      <div className="space-y-2">
        <p className="text-center text-xs leading-6 text-muted-foreground">
          {confirm}
        </p>
        <div className="flex gap-2">
          <Button
            type="button"
            onClick={onRun}
            disabled={pending}
            className="h-12 flex-1 text-base font-semibold"
          >
            {pending ? "در حال ثبت…" : "تأیید"}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => setConfirming(false)}
            disabled={pending}
            className="h-12 flex-1 text-base"
          >
            انصراف
          </Button>
        </div>
      </div>
    );
  }

  return (
    <Button
      type="button"
      onClick={() => (confirm ? setConfirming(true) : onRun())}
      disabled={pending}
      className="h-12 w-full text-base font-semibold"
    >
      {pending ? "در حال ثبت…" : label}
    </Button>
  );
}

export function TripActionPanel({
  dispatchId,
  executionStatus,
  hasPod,
}: {
  dispatchId: string;
  executionStatus: string | null;
  hasPod?: boolean;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [feedback, setFeedback] = useState<TripActionResult | null>(null);

  const next = driverNextAction(executionStatus);

  const runAction = (fn: ActionFn) => {
    setFeedback(null);
    startTransition(async () => {
      const res = await fn(dispatchId);
      setFeedback(res);
      if (res.ok) router.refresh();
    });
  };

  // Completed (or unknown terminal state) — nothing to do.
  if (next === null) {
    return (
      <p className="rounded-lg bg-surface-muted p-3 text-center text-sm font-medium text-muted-foreground">
        این سفر تکمیل شده است.
      </p>
    );
  }

  // delivered → completed: POD-gated (D4) + irreversible-confirm (G/Q1).
  if (next === "complete-gated") {
    if (hasPod === true) {
      return (
        <div className="space-y-2">
          <ActionButton
            label="تکمیل سفر"
            confirm={DRIVER_COMPLETE_CONFIRM}
            pending={pending}
            onRun={() => runAction(completeTrip)}
          />
          <Feedback feedback={feedback} />
        </div>
      );
    }
    return (
      <Button disabled className="h-12 w-full text-sm">
        تکمیل سفر پس از بارگذاری سند تحویل فعال می‌شود
      </Button>
    );
  }

  return (
    <div className="space-y-2">
      <ActionButton
        label={next.label}
        confirm={next.confirm}
        pending={pending}
        onRun={() => {
          const fn = ACTION_FN[next.key];
          if (fn) runAction(fn);
        }}
      />
      <Feedback feedback={feedback} />
    </div>
  );
}
