"use client";

import { useState } from "react";
import { ChevronDown } from "lucide-react";
import type { FAQItem } from "@/content/faq";

export function FAQAccordion({ items }: { items: FAQItem[] }) {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <div className="mx-auto max-w-3xl divide-y divide-line overflow-hidden rounded-2xl border border-line bg-white shadow-[0_1px_2px_rgba(6,26,47,0.04)]">
      {items.map((item, i) => {
        const isOpen = open === i;
        return (
          <div key={item.q}>
            <button
              type="button"
              aria-expanded={isOpen}
              onClick={() => setOpen(isOpen ? null : i)}
              className="flex w-full items-center justify-between gap-3 px-5 py-4 text-start transition hover:bg-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue/40"
            >
              <span className="text-[15px] font-bold text-ink">{item.q}</span>
              <ChevronDown
                size={18}
                className={`shrink-0 text-blue transition-transform ${isOpen ? "rotate-180" : ""}`}
                aria-hidden
              />
            </button>
            {isOpen ? (
              <div className="px-5 pb-5 text-[14px] leading-8 text-muted">{item.a}</div>
            ) : null}
          </div>
        );
      })}
    </div>
  );
}
