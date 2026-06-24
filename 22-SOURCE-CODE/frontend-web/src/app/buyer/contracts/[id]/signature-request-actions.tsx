"use client";

import { useActionState, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  buyerSignSignatureRequest,
  buyerDeclineSignatureRequest,
  supplierSignSignatureRequest,
  supplierDeclineSignatureRequest,
  type SignatureActionState,
} from "@/lib/contract/signature-actions";
import type { SignatureStatus } from "@/types/database";

interface Props {
  contractId: string;
  signatureRequestId: string;
  status: SignatureStatus;
  audience: "buyer" | "supplier" | "admin";
}

export function SignatureRequestActions({
  contractId,
  signatureRequestId,
  status,
  audience,
}: Props) {
  const signAction =
    audience === "supplier" ? supplierSignSignatureRequest : buyerSignSignatureRequest;
  const declineAction =
    audience === "supplier" ? supplierDeclineSignatureRequest : buyerDeclineSignatureRequest;

  const [signState, signFormAction, signPending] =
    useActionState<SignatureActionState | null, FormData>(signAction, null);
  const [declineState, declineFormAction, declinePending] =
    useActionState<SignatureActionState | null, FormData>(declineAction, null);
  const [showDecline, setShowDecline] = useState(false);

  const isActive = status === "pending" || status === "viewed";
  if (audience === "admin" || !isActive) {
    return <span className="text-xs text-muted-foreground">{status}</span>;
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <div className="flex flex-wrap gap-2">
        <form action={signFormAction}>
          <input type="hidden" name="signatureRequestId" value={signatureRequestId} />
          <input type="hidden" name="contractId" value={contractId} />
          <Button type="submit" size="sm" disabled={signPending}>
            {signPending ? "..." : "پذیرفتن امضا"}
          </Button>
        </form>
        {!showDecline ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            onClick={() => setShowDecline(true)}
          >
            رد امضا
          </Button>
        ) : (
          <form action={declineFormAction} className="flex items-end gap-2">
            <input type="hidden" name="signatureRequestId" value={signatureRequestId} />
            <input type="hidden" name="contractId" value={contractId} />
            <Input name="reason" required placeholder="دلیل" className="h-9 w-40" />
            <Button type="submit" size="sm" variant="outline" disabled={declinePending}>
              {declinePending ? "..." : "تأیید"}
            </Button>
          </form>
        )}
      </div>
      {signState?.error ? <p className="text-xs text-destructive">{signState.error}</p> : null}
      {declineState?.error ? <p className="text-xs text-destructive">{declineState.error}</p> : null}
    </div>
  );
}
