"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { startOrganization, type KycActionState } from "@/lib/kyc/portal-actions";

export function StartOrgButton({ organizationId }: { organizationId: string }) {
  const [state, action, pending] = useActionState<KycActionState | null, FormData>(
    startOrganization,
    null,
  );
  return (
    <form action={action} className="space-y-2">
      <input type="hidden" name="organizationId" value={organizationId} />
      <Button type="submit" disabled={pending}>
        {pending ? "در حال شروع..." : "شروع احراز سازمان"}
      </Button>
      {state?.error ? <p className="text-xs text-destructive">{state.error}</p> : null}
    </form>
  );
}
