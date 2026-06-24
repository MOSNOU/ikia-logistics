"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/forms/field";
import { signIn } from "@/lib/auth/sign-in";

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(signIn, null);

  return (
    <div className="space-y-6">
      <div className="space-y-1">
        <h1 className="text-xl font-semibold">ورود به سامانه</h1>
        <p className="text-sm text-muted-foreground">
          برای ادامه با حساب کاربری خود وارد شوید
        </p>
      </div>

      <form action={formAction} className="space-y-4">
        <Field htmlFor="email" label="ایمیل">
          <Input id="email" name="email" type="email" required autoComplete="email" dir="ltr" />
        </Field>
        <Field htmlFor="password" label="رمز عبور">
          <Input id="password" name="password" type="password" required autoComplete="current-password" />
        </Field>

        {state?.error ? (
          <p className="text-xs text-destructive">{state.error}</p>
        ) : null}

        <Button type="submit" className="w-full" disabled={pending}>
          {pending ? "در حال ورود..." : "ورود"}
        </Button>
      </form>
    </div>
  );
}
