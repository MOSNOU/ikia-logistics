import type {
  ShipmentDocumentKind,
  ShipmentDocumentStatus,
} from "@/types/database";

export const DOC_KIND_OPTIONS: { value: ShipmentDocumentKind | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "bill_of_lading", label: "بارنامه" },
  { value: "cmr", label: "CMR" },
  { value: "rail_waybill", label: "بارنامه ریلی" },
  { value: "airway_bill", label: "بارنامه هوایی" },
  { value: "packing_list", label: "فهرست بسته‌بندی" },
  { value: "certificate_of_origin", label: "گواهی مبدأ" },
  { value: "inspection_certificate", label: "گواهی بازرسی" },
  { value: "customs_declaration", label: "اظهارنامه گمرکی" },
  { value: "delivery_order", label: "دستور تحویل" },
  { value: "proof_of_delivery", label: "اثبات تحویل" },
  { value: "other", label: "سایر" },
];

export const DOC_STATUS_OPTIONS: { value: ShipmentDocumentStatus | ""; label: string }[] = [
  { value: "", label: "همه" },
  { value: "pending", label: "در انتظار" },
  { value: "available", label: "موجود" },
  { value: "expired", label: "منقضی" },
  { value: "rejected", label: "ردشده" },
  { value: "archived", label: "بایگانی" },
];

export function docKindLabel(kind: ShipmentDocumentKind): string {
  const opt = DOC_KIND_OPTIONS.find((o) => o.value === kind);
  return opt?.label ?? kind;
}

export function docStatusLabel(status: ShipmentDocumentStatus): string {
  const opt = DOC_STATUS_OPTIONS.find((o) => o.value === status);
  return opt?.label ?? status;
}
