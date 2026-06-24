"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { upsertPreferences, type InboxActionState } from "@/lib/notify/inbox-actions";
import type { ChannelType, NotificationCategory } from "@/types/database";

const CATEGORIES: { value: NotificationCategory; label: string }[] = [
  { value: "rfq", label: "RFQ" },
  { value: "offer", label: "پیشنهاد" },
  { value: "evaluation", label: "ارزیابی" },
  { value: "contract", label: "قرارداد" },
  { value: "shipment", label: "محموله" },
  { value: "finance", label: "مالی" },
  { value: "settlement", label: "تسویه" },
  { value: "dispute", label: "اختلاف" },
  { value: "supplier_admin", label: "مدیریت تأمین‌کننده" },
  { value: "platform", label: "پلتفرم" },
  { value: "other", label: "سایر" },
];

const CHANNELS: { value: ChannelType; label: string; live: boolean }[] = [
  { value: "in_app", label: "درون‌برنامه", live: true },
  { value: "email", label: "ایمیل", live: false },
  { value: "sms", label: "پیامک", live: false },
  { value: "push", label: "پوش", live: false },
  { value: "webhook", label: "Webhook", live: false },
];

export function PreferencesForm({ organizationId }: { organizationId: string }) {
  const [state, action, pending] = useActionState<InboxActionState | null, FormData>(
    upsertPreferences,
    null,
  );

  return (
    <Card>
      <CardContent className="p-6">
        <form action={action} className="space-y-4">
          <input type="hidden" name="organizationId" value={organizationId} />

          <div className="overflow-x-auto rounded-md border">
            <table className="w-full text-sm">
              <thead className="bg-muted/40 text-muted-foreground">
                <tr>
                  <th className="p-2 text-start">دسته</th>
                  {CHANNELS.map((c) => (
                    <th key={c.value} className="p-2 text-center text-xs">
                      {c.label}
                      {c.live ? null : (
                        <span className="ms-1 text-muted-foreground">
                          (غیرفعال)
                        </span>
                      )}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {CATEGORIES.map((cat) => (
                  <tr key={cat.value} className="border-t">
                    <td className="p-2">{cat.label}</td>
                    {CHANNELS.map((ch) => {
                      const key = `pref:${cat.value}:${ch.value}`;
                      const knownKey = `known:${cat.value}:${ch.value}`;
                      return (
                        <td key={ch.value} className="p-2 text-center">
                          <input type="hidden" name={knownKey} value="1" />
                          <input
                            type="checkbox"
                            id={key}
                            name={key}
                            defaultChecked={ch.value === "in_app"}
                            disabled={!ch.live}
                            className="h-4 w-4"
                          />
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {state?.error ? (
            <p className="text-xs text-destructive">{state.error}</p>
          ) : null}
          {state?.ok ? (
            <p className="text-xs text-emerald-600">تنظیمات ذخیره شد.</p>
          ) : null}

          <Button type="submit" disabled={pending}>
            {pending ? "در حال ذخیره..." : "ذخیره تنظیمات"}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
