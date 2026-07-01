// Phase G (v1.2) — Persian relative-time + short datetime helpers for the
// driver trip surfaces (last-ping age, timeline, stepper timestamps). Pure
// formatting; computed at request time in the (dynamic) server components.

function faNum(n: number): string {
  return Math.abs(n).toLocaleString("fa-IR");
}

/** e.g. «۳ ساعت پیش», «همین الان», «۲ روز پیش». Returns "—" for missing input. */
export function faRelativeTime(iso: string | null | undefined, now?: Date): string {
  if (!iso) return "—";
  const then = new Date(iso);
  if (Number.isNaN(then.getTime())) return "—";
  const ref = now ?? new Date();
  const diffMs = ref.getTime() - then.getTime();
  const sec = Math.floor(diffMs / 1000);

  if (sec < 45) return "همین الان";
  const min = Math.floor(sec / 60);
  if (min < 60) return `${faNum(min)} دقیقه پیش`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${faNum(hr)} ساعت پیش`;
  const day = Math.floor(hr / 24);
  return `${faNum(day)} روز پیش`;
}

/** Short localized fa-IR date+time, or "—". */
export function faShortDateTime(iso: string | null | undefined): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("fa-IR", { dateStyle: "short", timeStyle: "short" });
}

/** Whole hours elapsed since the timestamp, or null. Used for stall heuristics. */
export function hoursSince(iso: string | null | undefined, now?: Date): number | null {
  if (!iso) return null;
  const then = new Date(iso);
  if (Number.isNaN(then.getTime())) return null;
  const ref = now ?? new Date();
  return (ref.getTime() - then.getTime()) / 3_600_000;
}
