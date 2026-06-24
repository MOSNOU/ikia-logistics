"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { setUserStatus, type SetUserStatusState } from "@/lib/admin/set-user-status";

interface SetUserStatusFormProps {
  userId: string;
  currentStatus: string;
}

const OPTIONS: { value: "active" | "pending" | "suspended" | "deactivated"; label: string }[] = [
  { value: "active", label: "فعال" },
  { value: "pending", label: "در حال بررسی" },
  { value: "suspended", label: "تعلیق" },
  { value: "deactivated", label: "غیرفعال" },
];

export function SetUserStatusForm({ userId, currentStatus }: SetUserStatusFormProps) {
  const [state, formAction, pending] = useActionState<SetUserStatusState | null, FormData>(
    setUserStatus,
    null,
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>تغییر وضعیت کاربر</CardTitle>
        <CardDescription>Active / Pending / Suspended / Deactivated</CardDescription>
      </CardHeader>
      <CardContent>
        <form action={formAction} className="flex flex-wrap items-end gap-3">
          <input type="hidden" name="userId" value={userId} />
          <div className="space-y-1">
            <label htmlFor="status" className="text-sm font-medium">
              وضعیت جدید
            </label>
            <select
              id="status"
              name="status"
              defaultValue={currentStatus}
              className="h-9 rounded-md border border-input bg-background px-2 text-sm"
            >
              {OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </select>
          </div>
          <Button type="submit" disabled={pending}>
            {pending ? "در حال اعمال..." : "ذخیره"}
          </Button>
          {state?.error ? <span className="text-xs text-destructive">{state.error}</span> : null}
          {state?.ok ? <span className="text-xs text-emerald-600">وضعیت به‌روزرسانی شد</span> : null}
        </form>
      </CardContent>
    </Card>
  );
}
