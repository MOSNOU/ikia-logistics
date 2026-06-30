// Phase D5 — driver trip issue metadata (labels shared by the driver report
// form and the admin operations views).
//
// Mirrors the D1 enums exactly:
//   dispatch.trip_issue_category = delay | vehicle | loading | border | accident | other
//   dispatch.trip_issue_status   = open | acknowledged | resolved
//   severity smallint            = 1 (کم) … 5 (فوری)
// READ-ONLY display metadata; no DB shape is mutated here.

export interface LabeledOption {
  value: string;
  label: string;
}

export const TRIP_ISSUE_CATEGORIES: readonly LabeledOption[] = [
  { value: "delay", label: "تأخیر" },
  { value: "vehicle", label: "مشکل خودرو" },
  { value: "loading", label: "مشکل بارگیری" },
  { value: "border", label: "مشکل مرزی یا گمرکی" },
  { value: "accident", label: "حادثه یا اضطراری" },
  { value: "other", label: "سایر" },
] as const;

export interface SeverityOption {
  value: number;
  label: string;
}

export const TRIP_ISSUE_SEVERITIES: readonly SeverityOption[] = [
  { value: 1, label: "کم" },
  { value: 2, label: "متوسط" },
  { value: 3, label: "مهم" },
  { value: 4, label: "خیلی مهم" },
  { value: 5, label: "فوری" },
] as const;

export const TRIP_ISSUE_STATUSES: readonly LabeledOption[] = [
  { value: "open", label: "باز" },
  { value: "acknowledged", label: "تأیید دریافت‌شده" },
  { value: "resolved", label: "حل‌شده" },
] as const;

export function issueCategoryLabel(value: string | null | undefined): string {
  if (!value) return "نامشخص";
  return TRIP_ISSUE_CATEGORIES.find((c) => c.value === value)?.label ?? value;
}

export function issueSeverityLabel(value: number | null | undefined): string {
  if (value == null) return "نامشخص";
  return TRIP_ISSUE_SEVERITIES.find((s) => s.value === value)?.label ?? String(value);
}

export function issueStatusLabel(value: string | null | undefined): string {
  if (!value) return "نامشخص";
  return TRIP_ISSUE_STATUSES.find((s) => s.value === value)?.label ?? value;
}

// Badge tone for an issue status — consistent with the shared Badge variants.
export function issueStatusBadgeVariant(
  value: string | null | undefined,
): "warning" | "info" | "success" | "muted" {
  switch (value) {
    case "open":
      return "warning";
    case "acknowledged":
      return "info";
    case "resolved":
      return "success";
    default:
      return "muted";
  }
}

// POD kinds (dispatch.trip_pod_kind) — Persian labels for the admin POD list.
export function podKindLabel(value: string | null | undefined): string {
  switch (value) {
    case "delivery_photo":
      return "عکس تحویل";
    case "bill_of_lading":
      return "بارنامه";
    case "receipt":
      return "رسید";
    case "other":
      return "سایر";
    default:
      return value ?? "نامشخص";
  }
}
