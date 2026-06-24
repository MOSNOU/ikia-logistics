import { Badge } from "@/components/ui/badge";
import type { DispatchStatus } from "@/types/database";

const LABEL: Record<DispatchStatus, string> = {
  draft: "پیش‌نویس",
  assigned: "تخصیص‌یافته",
  ready: "آماده برداشت",
  released: "آزاد شده",
  cancelled: "لغوشده",
};

function variantFor(s: DispatchStatus): "success" | "warning" | "danger" | "outline" {
  if (s === "released") return "success";
  if (s === "ready") return "success";
  if (s === "assigned" || s === "draft") return "warning";
  if (s === "cancelled") return "danger";
  return "outline";
}

interface Props {
  status: DispatchStatus;
}

export function DispatchStatusBadge({ status }: Props) {
  return <Badge variant={variantFor(status)}>{LABEL[status] ?? status}</Badge>;
}
