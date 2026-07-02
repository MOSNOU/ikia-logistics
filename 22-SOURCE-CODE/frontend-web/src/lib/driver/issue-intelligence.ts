import type { StallLevel } from "@/lib/driver/trip-progress";
import type { TripHealthLevel } from "@/lib/driver/trip-intelligence";

// Phase M1 (v1.3) — Operational Issue Intelligence Engine.
//
// A PURE, framework-independent intelligence layer consumed by later Driver /
// Carrier / Admin / Analytics panels. It derives issue age, severity,
// escalation, and combined operational risk from data that existing loaders
// already return — it NEVER requires new DB fields and performs NO side
// effects (no fetch, RPC, Supabase, React, hooks, or browser APIs).
//
// All thresholds/scores/weights are centralized constants (no magic numbers).
// `Date` is used only for age arithmetic and is injectable for testability.

// ---------------------------------------------------------------------------
// Levels
// ---------------------------------------------------------------------------

/** Derived issue severity. */
export type IssueSeverityLevel = "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
/** Derived escalation posture for an issue. */
export type EscalationLevel = "NORMAL" | "WATCH" | "ESCALATED" | "CRITICAL";
/** Combined operational risk for a trip. */
export type OperationalRiskLevel =
  | "ON_TRACK"
  | "WATCH"
  | "ATTENTION"
  | "AT_RISK"
  | "CRITICAL";
/** Optional delay signal (a derived input; not a DB field). */
export type DelayLevel = "none" | "minor" | "moderate" | "severe";

/** Badge variant tokens matching the shared UI Badge component. */
export type BadgeVariant =
  | "default"
  | "secondary"
  | "outline"
  | "success"
  | "warning"
  | "danger"
  | "info"
  | "muted";

/** Centralized presentation metadata for a level. */
export interface LevelMeta {
  /** Persian display label. */
  fa: string;
  /** Stable English identifier. */
  en: string;
  /** Shared Badge variant. */
  badge: BadgeVariant;
  /** Sort/urgency priority (higher = more urgent). */
  priority: number;
  /** Color token (framework-agnostic; consumers map to their palette). */
  color: string;
}

// ---------------------------------------------------------------------------
// Constants (no magic numbers)
// ---------------------------------------------------------------------------

/** Numeric weight per severity level (used by risk scoring). */
export const SEVERITY_SCORE: Record<IssueSeverityLevel, number> = {
  LOW: 1,
  MEDIUM: 2,
  HIGH: 3,
  CRITICAL: 4,
};

/** Base severity per issue category (dispatch.trip_issue_category). */
export const CATEGORY_BASE_SEVERITY: Record<string, IssueSeverityLevel> = {
  accident: "CRITICAL",
  border: "HIGH",
  vehicle: "HIGH",
  delay: "MEDIUM",
  loading: "MEDIUM",
  other: "LOW",
};

/** Minimum numeric issue severity (1..5) to reach a level. */
export const NUMERIC_SEVERITY_MIN = {
  CRITICAL: 5,
  HIGH: 3,
  MEDIUM: 2,
} as const;

/** Age thresholds (minutes) that drive escalation. */
export const AGE_THRESHOLDS_MIN = {
  WATCH: 30,
  ESCALATED: 120,
  CRITICAL: 360,
} as const;

/** Score contribution per stall level. */
export const STALL_SCORE: Record<"warning" | "critical", number> = {
  warning: 2,
  critical: 4,
};

/** Score contribution per delay level. */
export const DELAY_SCORE: Record<DelayLevel, number> = {
  none: 0,
  minor: 1,
  moderate: 2,
  severe: 3,
};

/** Score contribution per trip-health level. */
export const TRIP_HEALTH_SCORE: Record<TripHealthLevel, number> = {
  done: 0,
  on_track: 0,
  attention: 2,
  at_risk: 3,
};

/** Score added when a POD is required but missing (near/at delivery). */
export const POD_MISSING_SCORE = 2;

/** Relative weights for the operational-risk composite. */
export const RISK_WEIGHTS = {
  tripHealth: 1.0,
  issueSeverity: 1.2,
  stall: 1.0,
  delay: 0.8,
  pod: 0.6,
} as const;

/** Weighted-score thresholds mapping to a risk level. */
export const RISK_THRESHOLDS = {
  WATCH: 3,
  ATTENTION: 6,
  AT_RISK: 9,
  CRITICAL: 13,
} as const;

/** Ordered levels for min/max comparisons. */
const SEVERITY_ORDER: IssueSeverityLevel[] = ["LOW", "MEDIUM", "HIGH", "CRITICAL"];
const ESCALATION_ORDER: EscalationLevel[] = [
  "NORMAL",
  "WATCH",
  "ESCALATED",
  "CRITICAL",
];
const RISK_ORDER: OperationalRiskLevel[] = [
  "ON_TRACK",
  "WATCH",
  "ATTENTION",
  "AT_RISK",
  "CRITICAL",
];

// ---------------------------------------------------------------------------
// Labels / presentation metadata (centralized)
// ---------------------------------------------------------------------------

/** Severity presentation metadata. */
export const SEVERITY_META: Record<IssueSeverityLevel, LevelMeta> = {
  LOW: { fa: "کم", en: "LOW", badge: "muted", priority: 1, color: "slate" },
  MEDIUM: { fa: "متوسط", en: "MEDIUM", badge: "info", priority: 2, color: "sky" },
  HIGH: { fa: "زیاد", en: "HIGH", badge: "warning", priority: 3, color: "amber" },
  CRITICAL: { fa: "بحرانی", en: "CRITICAL", badge: "danger", priority: 4, color: "red" },
};

/** Escalation presentation metadata. */
export const ESCALATION_META: Record<EscalationLevel, LevelMeta> = {
  NORMAL: { fa: "عادی", en: "NORMAL", badge: "muted", priority: 1, color: "slate" },
  WATCH: { fa: "تحت نظر", en: "WATCH", badge: "info", priority: 2, color: "sky" },
  ESCALATED: {
    fa: "ارجاع‌شده",
    en: "ESCALATED",
    badge: "warning",
    priority: 3,
    color: "amber",
  },
  CRITICAL: { fa: "بحرانی", en: "CRITICAL", badge: "danger", priority: 4, color: "red" },
};

/** Operational-risk presentation metadata. */
export const RISK_META: Record<OperationalRiskLevel, LevelMeta> = {
  ON_TRACK: {
    fa: "در مسیر عادی",
    en: "ON_TRACK",
    badge: "success",
    priority: 1,
    color: "emerald",
  },
  WATCH: { fa: "تحت نظر", en: "WATCH", badge: "info", priority: 2, color: "sky" },
  ATTENTION: {
    fa: "نیازمند توجه",
    en: "ATTENTION",
    badge: "warning",
    priority: 3,
    color: "amber",
  },
  AT_RISK: { fa: "در معرض خطر", en: "AT_RISK", badge: "danger", priority: 4, color: "red" },
  CRITICAL: { fa: "بحرانی", en: "CRITICAL", badge: "danger", priority: 5, color: "red" },
};

/** Metadata for a severity level. */
export function severityMeta(level: IssueSeverityLevel): LevelMeta {
  return SEVERITY_META[level];
}
/** Metadata for an escalation level. */
export function escalationMeta(level: EscalationLevel): LevelMeta {
  return ESCALATION_META[level];
}
/** Metadata for an operational-risk level. */
export function riskMeta(level: OperationalRiskLevel): LevelMeta {
  return RISK_META[level];
}

// ---------------------------------------------------------------------------
// Inputs
// ---------------------------------------------------------------------------

/** A single issue's fields, sourced from existing loader data. */
export interface IssueInput {
  status?: string | null; // open | acknowledged | resolved
  createdAt?: string | null;
  updatedAt?: string | null;
  category?: string | null; // delay | vehicle | loading | border | accident | other
  /** Optional 1..5 numeric severity already on the issue row. */
  numericSeverity?: number | null;
}

/** Trip-level context for risk composition (all from existing loaders). */
export interface TripContext {
  tripHealth?: TripHealthLevel | null;
  stall?: StallLevel;
  delay?: DelayLevel | null;
  podCount?: number | null;
  openIssueCount?: number | null;
  executionStatus?: string | null;
  updatedAt?: string | null;
  /** Optional worst issue severity already derived for the trip. */
  issueSeverity?: IssueSeverityLevel | null;
}

/** Age breakdown for an issue. */
export interface IssueAge {
  /** Total elapsed whole minutes. */
  minutes: number;
  /** Total elapsed whole hours. */
  hours: number;
  /** Total elapsed whole days. */
  days: number;
  /** Persian formatted text (e.g. «۳ ساعت»). */
  text: string;
}

/** Full derived summary for one issue in trip context. */
export interface IssueSummary {
  age: IssueAge;
  severity: IssueSeverityLevel;
  escalation: EscalationLevel;
  operationalRisk: OperationalRiskLevel;
  severityMeta: LevelMeta;
  escalationMeta: LevelMeta;
  riskMeta: LevelMeta;
}

// ---------------------------------------------------------------------------
// Internal helpers (pure)
// ---------------------------------------------------------------------------

function faNum(n: number): string {
  return Math.trunc(Math.abs(n)).toLocaleString("fa-IR");
}

function maxByOrder<T>(order: T[], a: T, b: T): T {
  return order.indexOf(a) >= order.indexOf(b) ? a : b;
}

function bumpSeverity(level: IssueSeverityLevel): IssueSeverityLevel {
  const i = SEVERITY_ORDER.indexOf(level);
  return SEVERITY_ORDER[Math.min(i + 1, SEVERITY_ORDER.length - 1)]!;
}

function reduceEscalation(level: EscalationLevel): EscalationLevel {
  const i = ESCALATION_ORDER.indexOf(level);
  return ESCALATION_ORDER[Math.max(i - 1, 0)]!;
}

function numericToSeverity(n: number): IssueSeverityLevel {
  if (n >= NUMERIC_SEVERITY_MIN.CRITICAL) return "CRITICAL";
  if (n >= NUMERIC_SEVERITY_MIN.HIGH) return "HIGH";
  if (n >= NUMERIC_SEVERITY_MIN.MEDIUM) return "MEDIUM";
  return "LOW";
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Break an issue's age into total minutes/hours/days plus Persian text.
 *
 * @param createdAt ISO timestamp the issue was created; null/invalid → zeroed.
 * @param now Reference time (injectable for testing); defaults to the clock.
 * @returns An {@link IssueAge} breakdown. Pure — no side effects.
 */
export function calculateIssueAge(
  createdAt: string | null | undefined,
  now: Date = new Date(),
): IssueAge {
  if (!createdAt) return { minutes: 0, hours: 0, days: 0, text: "—" };
  const then = new Date(createdAt);
  if (Number.isNaN(then.getTime())) {
    return { minutes: 0, hours: 0, days: 0, text: "—" };
  }
  const diffMs = Math.max(0, now.getTime() - then.getTime());
  const minutes = Math.floor(diffMs / 60_000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const text =
    minutes < 60
      ? `${faNum(minutes)} دقیقه`
      : hours < 24
        ? `${faNum(hours)} ساعت`
        : `${faNum(days)} روز`;
  return { minutes, hours, days, text };
}

/**
 * Derive an issue's severity level from its category, optional numeric
 * severity, and (optionally) the trip context. Derived only — never trusts a
 * single field blindly. Resolved issues are not special-cased here (severity is
 * intrinsic; see {@link calculateEscalation} for status handling).
 *
 * @param issue The issue fields.
 * @param ctx Optional trip context; a critical stall or at-risk trip elevates.
 * @returns The derived {@link IssueSeverityLevel}.
 */
export function calculateIssueSeverity(
  issue: IssueInput,
  ctx?: TripContext,
): IssueSeverityLevel {
  const base = issue.category
    ? (CATEGORY_BASE_SEVERITY[issue.category] ?? "LOW")
    : "LOW";
  const numeric =
    issue.numericSeverity != null && Number.isFinite(issue.numericSeverity)
      ? numericToSeverity(issue.numericSeverity)
      : "LOW";
  let severity = maxByOrder(SEVERITY_ORDER, base, numeric);
  if (ctx && (ctx.stall === "critical" || ctx.tripHealth === "at_risk")) {
    severity = bumpSeverity(severity);
  }
  return severity;
}

/**
 * Derive an issue's escalation posture from its age and severity, adjusted by
 * status. Resolved → NORMAL. Acknowledged issues (being handled) are reduced by
 * one level. Derived only.
 *
 * @param issue The issue fields (status + createdAt drive age when not given).
 * @param opts Optional precomputed `severity` / `ageMinutes`, and `now`.
 * @returns The derived {@link EscalationLevel}.
 */
export function calculateEscalation(
  issue: IssueInput,
  opts?: {
    severity?: IssueSeverityLevel;
    ageMinutes?: number;
    ctx?: TripContext;
    now?: Date;
  },
): EscalationLevel {
  if (issue.status === "resolved") return "NORMAL";

  const ageMinutes =
    opts?.ageMinutes ?? calculateIssueAge(issue.createdAt, opts?.now).minutes;
  const severity = opts?.severity ?? calculateIssueSeverity(issue, opts?.ctx);

  const ageEscalation: EscalationLevel =
    ageMinutes >= AGE_THRESHOLDS_MIN.CRITICAL
      ? "CRITICAL"
      : ageMinutes >= AGE_THRESHOLDS_MIN.ESCALATED
        ? "ESCALATED"
        : ageMinutes >= AGE_THRESHOLDS_MIN.WATCH
          ? "WATCH"
          : "NORMAL";

  const severityFloor: EscalationLevel =
    severity === "CRITICAL"
      ? "ESCALATED"
      : severity === "HIGH"
        ? "WATCH"
        : "NORMAL";

  let escalation = maxByOrder(ESCALATION_ORDER, ageEscalation, severityFloor);
  if (issue.status === "acknowledged") {
    escalation = reduceEscalation(escalation);
  }
  return escalation;
}

/**
 * Combine trip health, issue severity, stall, delay, and POD state into a
 * single operational-risk level using centralized weights + thresholds, with
 * critical-signal floors. Derived only.
 *
 * @param ctx Trip context; `issueSeverity` is the worst open issue's severity.
 * @returns The derived {@link OperationalRiskLevel}.
 */
export function calculateOperationalRisk(
  ctx: TripContext,
): OperationalRiskLevel {
  const healthScore = ctx.tripHealth ? TRIP_HEALTH_SCORE[ctx.tripHealth] : 0;
  const severityScore = ctx.issueSeverity ? SEVERITY_SCORE[ctx.issueSeverity] : 0;
  const stallScore = ctx.stall ? STALL_SCORE[ctx.stall] : 0;
  const delayScore = ctx.delay ? DELAY_SCORE[ctx.delay] : 0;
  const podScore =
    (ctx.executionStatus === "delivered" || ctx.executionStatus === "completed") &&
    (ctx.podCount ?? 0) <= 0
      ? POD_MISSING_SCORE
      : 0;

  const weighted =
    RISK_WEIGHTS.tripHealth * healthScore +
    RISK_WEIGHTS.issueSeverity * severityScore +
    RISK_WEIGHTS.stall * stallScore +
    RISK_WEIGHTS.delay * delayScore +
    RISK_WEIGHTS.pod * podScore;

  let level: OperationalRiskLevel =
    weighted >= RISK_THRESHOLDS.CRITICAL
      ? "CRITICAL"
      : weighted >= RISK_THRESHOLDS.AT_RISK
        ? "AT_RISK"
        : weighted >= RISK_THRESHOLDS.ATTENTION
          ? "ATTENTION"
          : weighted >= RISK_THRESHOLDS.WATCH
            ? "WATCH"
            : "ON_TRACK";

  // Critical-signal floors: a critical stall or a critical issue is never below
  // AT_RISK; both together are CRITICAL.
  const criticalStall = ctx.stall === "critical";
  const criticalIssue = ctx.issueSeverity === "CRITICAL";
  if (criticalStall && criticalIssue) return "CRITICAL";
  if (criticalStall || criticalIssue) {
    level = maxByOrder(RISK_ORDER, level, "AT_RISK");
  }
  return level;
}

/**
 * Compose the full derived intelligence for one issue in its trip context:
 * age, severity, escalation, operational risk, and their presentation metadata.
 *
 * @param issue The issue fields.
 * @param ctx Optional trip context (health/stall/delay/POD/…).
 * @param now Reference time (injectable for testing); defaults to the clock.
 * @returns An {@link IssueSummary}. Pure — no side effects.
 */
export function issueSummary(
  issue: IssueInput,
  ctx?: TripContext,
  now: Date = new Date(),
): IssueSummary {
  const age = calculateIssueAge(issue.createdAt, now);
  const severity = calculateIssueSeverity(issue, ctx);
  const escalation = calculateEscalation(issue, {
    severity,
    ageMinutes: age.minutes,
    ctx,
    now,
  });
  const operationalRisk = calculateOperationalRisk({
    ...ctx,
    issueSeverity: severity,
  });
  return {
    age,
    severity,
    escalation,
    operationalRisk,
    severityMeta: SEVERITY_META[severity],
    escalationMeta: ESCALATION_META[escalation],
    riskMeta: RISK_META[operationalRisk],
  };
}
