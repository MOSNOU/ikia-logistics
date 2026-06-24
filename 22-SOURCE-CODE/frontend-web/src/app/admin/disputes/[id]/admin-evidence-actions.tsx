"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  adminReviewEvidence,
  type DisputeAdminActionState,
} from "@/lib/admin/dispute-admin-actions";

export function AdminEvidenceActions({
  evidenceId,
  disputeId,
  title,
}: {
  evidenceId: string;
  disputeId: string;
  title: string;
}) {
  const [state, action, pending] = useActionState<DisputeAdminActionState | null, FormData>(
    adminReviewEvidence,
    null,
  );

  const sharedHidden = (
    <>
      <input type="hidden" name="evidenceId" value={evidenceId} />
      <input type="hidden" name="disputeId" value={disputeId} />
    </>
  );

  return (
    <div className="rounded-md border p-3 space-y-2">
      <div className="text-sm font-medium">{title}</div>
      <div className="flex flex-wrap gap-2">
        <form action={action}>
          {sharedHidden}
          <input type="hidden" name="status" value="accepted" />
          <Button type="submit" size="sm" disabled={pending}>
            {pending ? "..." : "پذیرفتن"}
          </Button>
        </form>

        <form action={action} className="flex items-end gap-2">
          {sharedHidden}
          <input type="hidden" name="status" value="rejected" />
          <Input name="notes" placeholder="یادداشت رد" className="h-9 w-40" />
          <Button type="submit" size="sm" variant="outline" disabled={pending}>
            {pending ? "..." : "رد"}
          </Button>
        </form>
      </div>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </div>
  );
}
