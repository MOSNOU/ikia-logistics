"use client";

import { useState } from "react";
import { CircleCheckBig } from "lucide-react";

// Client-side partnership-request form. No backend wiring yet (pre-seed) —
// submitting shows a local success state. TODO: connect to a real endpoint.
export function ContactForm() {
  const [form, setForm] = useState({ name: "", email: "", phone: "", subject: "", message: "" });
  const [sent, setSent] = useState(false);

  function update(key: keyof typeof form, value: string) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  if (sent) {
    return (
      <div className="mx-auto max-w-xl rounded-3xl border border-[#bbf7d0] bg-[#f0fdf4] p-10 text-center">
        <CircleCheckBig className="mx-auto h-11 w-11 text-[#16a34a]" aria-hidden />
        <h3 className="mt-4 text-lg font-bold text-[#14532d]">درخواست شما ثبت شد</h3>
        <p className="mt-2 text-[14px] leading-7 text-[#14532d]/80">
          از علاقه شما به همکاری سپاسگزاریم. تیم iKIA در اولین فرصت با شما در ارتباط خواهد بود.
        </p>
      </div>
    );
  }

  const inputCls =
    "w-full rounded-xl border border-line bg-white px-4 py-3 text-[15px] text-ink outline-none transition placeholder:text-muted/70 focus:border-blue focus:ring-2 focus:ring-blue/20";

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        setSent(true);
      }}
      className="mx-auto grid max-w-xl gap-4 rounded-3xl border border-line bg-white p-7 shadow-[0_1px_2px_rgba(6,26,47,0.04)] sm:p-8"
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
        placeholder="نوع همکاری (صاحب بار، حمل‌کننده، مرکز لجستیک، شریک فناوری…)"
        value={form.subject}
        onChange={(e) => update("subject", e.target.value)}
      />
      <textarea
        required
        rows={5}
        className={inputCls}
        placeholder="کمی درباره نیاز یا پیشنهاد همکاری خود بنویسید"
        value={form.message}
        onChange={(e) => update("message", e.target.value)}
      />
      <button
        type="submit"
        className="h-12 rounded-xl bg-[#16a34a] px-6 text-[15px] font-semibold text-white shadow-[0_8px_20px_-12px_rgba(22,163,74,0.6)] transition-colors hover:bg-[#15803d] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#16a34a]/40 focus-visible:ring-offset-2"
      >
        ثبت درخواست همکاری
      </button>
    </form>
  );
}
