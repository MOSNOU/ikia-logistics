import { Badge } from "@/components/ui/badge";
import type { BookingStatus } from "@/types/database";

const LABEL: Record<BookingStatus, string> = {
  draft: "پیش‌نویس",
  pending_carrier: "در انتظار حمل‌کننده",
  carrier_accepted: "پذیرفته‌شده توسط حمل‌کننده",
  carrier_rejected: "ردشده توسط حمل‌کننده",
  buyer_confirmed: "تأییدشده توسط خریدار",
  buyer_cancelled: "لغوشده",
  expired: "منقضی",
};

function variantFor(s: BookingStatus): "success" | "warning" | "danger" | "outline" {
  if (s === "buyer_confirmed") return "success";
  if (s === "carrier_accepted") return "success";
  if (s === "pending_carrier" || s === "draft") return "warning";
  if (s === "carrier_rejected" || s === "buyer_cancelled" || s === "expired") return "danger";
  return "outline";
}

interface Props {
  status: BookingStatus;
}

export function BookingStatusBadge({ status }: Props) {
  return <Badge variant={variantFor(status)}>{LABEL[status] ?? status}</Badge>;
}
