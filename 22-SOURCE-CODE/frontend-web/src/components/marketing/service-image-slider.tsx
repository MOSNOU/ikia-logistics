"use client";

import { useEffect, useState } from "react";
import Image from "next/image";

// CC-66B (orig) → CC-69-fix — Auto-advancing service image slider.
//
// Behavior:
//   • Each slide enters from the right edge and slides leftward across
//     the viewport (right-to-left motion). 700 ms ease-out per step.
//   • Auto-advance every `intervalMs` (default 4 000 ms).
//   • Continuous loop with wrap-around — slide 0 follows the last slide
//     by computing the modular shortest-distance offset.
//   • Pauses on hover/focus-within so the user can read.
//   • Respects `prefers-reduced-motion: reduce` — shows slide 0 only and
//     skips the interval.
//
// Layout (CC-69-fix):
//   • Image area is now CLEAN — the photo itself usually carries title
//     copy, so the old centered icon + headline + subhead + ghost text
//     stack on top of the image has been removed.
//   • A subtle bottom gradient stays only to keep the indicator dots
//     legible on bright photos.
//   • The active slide's title / description / pills move to a clean
//     light caption panel rendered BELOW the image, so the text never
//     overlaps the photograph.
//
// No deps beyond React + next/image.

export interface ServiceSlide {
  image: string;
  alt: string;
  title: string;
  description: string;
  pills: string[];
  icon: React.ReactNode;
}

interface Props {
  slides: ServiceSlide[];
  /** Time between auto-advances, ms. */
  intervalMs?: number;
  /** Accessible label for the region. */
  ariaLabel?: string;
}

// Compute the signed shortest distance from `current` to `i`, with wrap.
// For 6 slides, distance is in {-3, -2, -1, 0, 1, 2, 3}. Active slide → 0,
// next → +1 (waiting at +100 %), previous → -1 (parked at -100 %).
function getOffset(i: number, current: number, total: number): number {
  const diff = i - current;
  const half = total / 2;
  if (diff > half) return diff - total;
  if (diff < -half) return diff + total;
  return diff;
}

export function ServiceImageSlider({
  slides,
  intervalMs = 4000,
  ariaLabel,
}: Props) {
  const [current, setCurrent] = useState(0);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [paused, setPaused] = useState(false);

  // Track the user's reduced-motion preference.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReducedMotion(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReducedMotion(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  // Auto-advance interval. Skipped under reduced-motion or while paused.
  useEffect(() => {
    if (reducedMotion || paused) return;
    const id = window.setInterval(
      () => setCurrent((c) => (c + 1) % slides.length),
      intervalMs,
    );
    return () => window.clearInterval(id);
  }, [intervalMs, paused, reducedMotion, slides.length]);

  const currentSlide = slides[current] ?? slides[0]!;

  return (
    <div
      role="region"
      aria-label={ariaLabel}
      aria-roledescription="carousel"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
      className="overflow-hidden rounded-[2rem] border border-slate-200/80 bg-white shadow-2xl shadow-slate-950/10"
    >
      {/* ===== Image area — clean. No title / subtitle / icon overlay. ===== */}
      <div className="relative">
        <div className="relative aspect-[4/5] w-full overflow-hidden sm:aspect-[16/9] lg:aspect-[16/8]">
          {slides.map((slide, i) => {
            const offset = getOffset(i, current, slides.length);
            const isActive = offset === 0;
            // translateX is physical (left/right viewport pixels), so the
            // same value reads correctly under RTL document direction.
            const tx = `${offset * 100}%`;
            return (
              <div
                key={slide.image}
                role="group"
                aria-roledescription="slide"
                aria-label={`${i + 1} از ${slides.length}: ${slide.title}`}
                aria-hidden={!isActive}
                className="absolute inset-0 transition-transform duration-700 ease-out"
                style={{ transform: `translateX(${tx})` }}
              >
                <Image
                  src={slide.image}
                  alt={slide.alt}
                  fill
                  sizes="(max-width: 768px) 100vw, (max-width: 1280px) 90vw, 1200px"
                  className="object-cover object-center"
                  priority={i === 0}
                />
              </div>
            );
          })}
          {/* Subtle bottom anchor so the dots stay legible on bright photos. */}
          <div
            aria-hidden
            className="pointer-events-none absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-slate-950/40 to-transparent"
          />
        </div>

        {/* Slide indicator dots — sit just above the image's lower edge. */}
        <div
          aria-hidden
          className="absolute inset-x-0 bottom-3 z-20 flex justify-center gap-1.5"
        >
          {slides.map((_, i) => (
            <span
              key={i}
              className={`block h-1.5 rounded-full transition-all duration-300 ${
                i === current ? "w-6 bg-sky-300" : "w-1.5 bg-white/50"
              }`}
            />
          ))}
        </div>
      </div>

      {/* ===== Caption panel — below the image, clean and on-brand. ===== */}
      <div
        key={current}
        dir="rtl"
        className="border-t border-slate-200/70 bg-white p-5 text-right sm:p-6"
      >
        <div className="flex items-center justify-between gap-3">
          <h3 className="text-xl font-extrabold tracking-tight text-deep-navy sm:text-2xl">
            {currentSlide.title}
          </h3>
          <div
            aria-hidden
            className="inline-flex size-9 shrink-0 items-center justify-center rounded-xl border border-sky-200 bg-sky-50 text-sky-700"
          >
            {currentSlide.icon}
          </div>
        </div>
        <p className="mt-2 max-w-2xl text-sm leading-7 text-slate-600 sm:text-base">
          {currentSlide.description}
        </p>
        {currentSlide.pills.length > 0 ? (
          <ul className="mt-3 flex flex-wrap gap-2">
            {currentSlide.pills.map((pill) => (
              <li
                key={pill}
                className="rounded-full border border-sky-200 bg-sky-50 px-3 py-1 text-xs font-semibold text-sky-700"
              >
                {pill}
              </li>
            ))}
          </ul>
        ) : null}
      </div>
    </div>
  );
}
