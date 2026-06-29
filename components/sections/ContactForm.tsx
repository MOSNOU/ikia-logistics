"use client";

import { useState } from "react";
import { CircleCheckBig } from "lucide-react";

// Client-side contact form. No backend wiring yet (pre-seed) — submitting
// shows a local success state. TODO: connect to a real endpoint / inbox.
export function ContactForm() {
  const [form, setForm] = useState({ name: "", email: "", phone: "", subject: "", message: "" });
  const [sent, setSent] = useState(false);

  function update(key: keyof typeof form, value: string) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  if (sent) {
    return (
      <div className="mx-auto max-w-lg rounded-2xl border border-emerald-200 bg-emerald-50 p-8 text-center">
        <CircleCheckBig className="mx-auto h-10 w-10 text-emerald-500" aria-hidden />
        <h3 className="mt-3 text-lg font-black text-emerald-800">پیام شما ثبت شد</h3>
        <p className="mt-2 text-sm leading-7 text-emerald-700">
          از تماس شما سپاسگزاریم. تیم iKIA در اولین فرصت پاسخ می‌دهد.
        </p>
      </div>
    );
  }

  const inputCls =
    "w-full rounded-xl border-2 border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-[#06b6d4] focus:ring-2 focus:ring-[#06b6d4]/20";

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        setSent(true);
      }}
      className="mx-auto grid max-w-lg gap-4"
    >
      <div className="grid gap-4 sm:grid-cols-2">
        <input
          required
          className={inputCls}
          placeholder="نام و نام خانوادگی"
          value={form.name}
          onChange={(e) => update("name", e.target.value)}
        />
        <input
          className={inputCls}
          placeholder="تلفن"
          inputMode="tel"
          value={form.phone}
          onChange={(e) => update("phone", e.target.value)}
        />
      </div>
      <input
        required
        type="email"
        className={inputCls}
        placeholder="ایمیل"
        dir="ltr"
        value={form.email}
        onChange={(e) => update("email", e.target.value)}
      />
      <input
        className={inputCls}
        placeholder="موضوع"
        value={form.subject}
        onChange={(e) => update("subject", e.target.value)}
      />
      <textarea
        required
        rows={5}
        className={inputCls}
        placeholder="پیام شما"
        value={form.message}
        onChange={(e) => update("message", e.target.value)}
      />
      <button
        type="submit"
        className="rounded-xl bg-[#1e3a5f] px-6 py-3 text-sm font-extrabold text-white transition hover:bg-[#16304d] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#06b6d4] focus-visible:ring-offset-2"
      >
        ارسال پیام
      </button>
    </form>
  );
}
