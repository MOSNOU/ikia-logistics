"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { decideDocument, type KycAdminActionState } from "@/lib/admin/kyc-admin-actions";
import type { KycSubjectType } from "@/types/database";

interface DocumentActionsProps {
  documentId: string;
  subjectType: KycSubjectType;
  verificationId: string;
}

export function DocumentActions({
  documentId,
  subjectType,
  verificationId,
}: DocumentActionsProps) {
  const [state, action, pending] = useActionState<KycAdminActionState | null, FormData>(
    decideDocument,
    null,
  );
  const [showReject, setShowReject] = useState(false);

  const sharedHidden = (
    <>
      <input type="hidden" name="documentId" value={documentId} />
      <input type="hidden" name="subjectType" value={subjectType} />
      <input type="hidden" name="verificationId" value={verificationId} />
    </>
  );

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex flex-wrap gap-2">
        <form action={action}>
          {sharedHidden}
          <input type="hidden" name="decision" value="accepted" />
          <Button type="submit" size="sm" disabled={pending}>
            {pending ? "..." : "پذیرفتن"}
          </Button>
        </form>

        {!showReject ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setShowReject(true)}
          >
            رد
          </Button>
        ) : (
          <form action={action} className="flex items-end gap-2">
            {sharedHidden}
            <input type="hidden" name="decision" value="rejected" />
            <Input name="reason" required placeholder="دلیل رد" className="h-9 w-40" />
            <Button type="submit" size="sm" variant="outline" disabled={pending}>
              {pending ? "..." : "تأیید رد"}
            </Button>
          </form>
        )}

        <form action={action}>
          {sharedHidden}
          <input type="hidden" name="decision" value="superseded" />
          <Button type="submit" size="sm" variant="outline" disabled={pending}>
            {pending ? "..." : "جایگزین"}
          </Button>
        </form>
      </div>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </div>
  );
}
