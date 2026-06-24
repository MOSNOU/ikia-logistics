"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import {
  publishPriceList,
  pausePriceList,
  archivePriceList,
  type PricingActionState,
} from "@/lib/pricing/portal-actions";
import type { PriceListStatus } from "@/types/database";

export function PriceListStatusActions({
  priceListId,
  status,
}: {
  priceListId: string;
  status: PriceListStatus;
}) {
  const [publishState, publishAction, publishPending] =
    useActionState<PricingActionState | null, FormData>(publishPriceList, null);
  const [pauseState, pauseAction, pausePending] =
    useActionState<PricingActionState | null, FormData>(pausePriceList, null);
  const [archiveState, archiveAction, archivePending] =
    useActionState<PricingActionState | null, FormData>(archivePriceList, null);

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        {status === "draft" ? (
          <form action={publishAction}>
            <input type="hidden" name="priceListId" value={priceListId} />
            <Button type="submit" size="sm" disabled={publishPending}>
              {publishPending ? "..." : "انتشار"}
            </Button>
          </form>
        ) : null}

        {status === "active" ? (
          <form action={pauseAction}>
            <input type="hidden" name="priceListId" value={priceListId} />
            <Button type="submit" size="sm" variant="outline" disabled={pausePending}>
              {pausePending ? "..." : "توقف موقت"}
            </Button>
          </form>
        ) : null}

        {status !== "archived" ? (
          <form action={archiveAction}>
            <input type="hidden" name="priceListId" value={priceListId} />
            <Button type="submit" size="sm" variant="outline" disabled={archivePending}>
              {archivePending ? "..." : "بایگانی"}
            </Button>
          </form>
        ) : null}
      </div>

      {publishState?.error ? (
        <p className="text-xs text-destructive">{publishState.error}</p>
      ) : null}
      {pauseState?.error ? (
        <p className="text-xs text-destructive">{pauseState.error}</p>
      ) : null}
      {archiveState?.error ? (
        <p className="text-xs text-destructive">{archiveState.error}</p>
      ) : null}
    </div>
  );
}
