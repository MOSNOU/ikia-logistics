import type {
  ShipmentDocumentKind,
  ShipmentDocumentStatus,
} from "@/types/database";

export type RequirementLevel = "required" | "recommended" | "optional";

export const DOC_KIND_VALUES: ShipmentDocumentKind[] = [
  "bill_of_lading",
  "cmr",
  "rail_waybill",
  "airway_bill",
  "packing_list",
  "certificate_of_origin",
  "inspection_certificate",
  "customs_declaration",
  "delivery_order",
  "proof_of_delivery",
  "other",
];

export const DOC_STATUS_VALUES: ShipmentDocumentStatus[] = [
  "pending",
  "available",
  "expired",
  "rejected",
  "archived",
];

export const REQUIREMENT_LEVEL_VALUES: RequirementLevel[] = [
  "required",
  "recommended",
  "optional",
];

export interface RequirementInput {
  shipmentId: string;
  documentKind: ShipmentDocumentKind;
  requirementLevel?: RequirementLevel;
  displayNameEn?: string;
  displayNameFa?: string;
  notes?: string;
}

export interface DocumentUpsertInput {
  shipmentId: string;
  documentKind: ShipmentDocumentKind;
  documentStatus?: ShipmentDocumentStatus;
  requirementId?: string;
  shipmentItemId?: string;
  externalReference?: string;
  issuedAt?: string;
  expiresAt?: string;
  notes?: string;
  documentId?: string;
}

export interface FileRegisterInput {
  filename: string;
  mimeType?: string;
  sizeBytes?: number;
  fileType?: "pdf" | "image" | "doc" | "xlsx" | "txt" | "other";
}

export type ValidationResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: string; fieldErrors?: Record<string, string> };

function trimOrUndef(v: FormDataEntryValue | null): string | undefined {
  if (v == null) return undefined;
  const s = String(v).trim();
  return s.length === 0 ? undefined : s;
}

function isUuid(v: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v);
}

export function parseRequirementForm(form: FormData): ValidationResult<RequirementInput> {
  const fieldErrors: Record<string, string> = {};
  const shipmentId = trimOrUndef(form.get("shipmentId")) ?? "";
  const documentKind = trimOrUndef(form.get("documentKind")) as ShipmentDocumentKind | undefined;
  const requirementLevel = trimOrUndef(form.get("requirementLevel")) as
    | RequirementLevel
    | undefined;
  const displayNameEn = trimOrUndef(form.get("displayNameEn"));
  const displayNameFa = trimOrUndef(form.get("displayNameFa"));
  const notes = trimOrUndef(form.get("notes"));

  if (!shipmentId || !isUuid(shipmentId)) fieldErrors.shipmentId = "شناسه محموله نامعتبر";
  if (!documentKind || !DOC_KIND_VALUES.includes(documentKind)) {
    fieldErrors.documentKind = "نوع مدرک الزامی است";
  }
  if (requirementLevel && !REQUIREMENT_LEVEL_VALUES.includes(requirementLevel)) {
    fieldErrors.requirementLevel = "سطح نیازمندی نامعتبر";
  }

  if (Object.keys(fieldErrors).length > 0) {
    return { ok: false, error: "ورودی نامعتبر", fieldErrors };
  }
  return {
    ok: true,
    value: {
      shipmentId,
      documentKind: documentKind!,
      requirementLevel,
      displayNameEn,
      displayNameFa,
      notes,
    },
  };
}

export function parseDocumentForm(form: FormData): ValidationResult<DocumentUpsertInput> {
  const fieldErrors: Record<string, string> = {};
  const shipmentId = trimOrUndef(form.get("shipmentId")) ?? "";
  const documentKind = trimOrUndef(form.get("documentKind")) as ShipmentDocumentKind | undefined;
  const documentStatus = trimOrUndef(form.get("documentStatus")) as
    | ShipmentDocumentStatus
    | undefined;
  const requirementId = trimOrUndef(form.get("requirementId"));
  const shipmentItemId = trimOrUndef(form.get("shipmentItemId"));
  const externalReference = trimOrUndef(form.get("externalReference"));
  const issuedAt = trimOrUndef(form.get("issuedAt"));
  const expiresAt = trimOrUndef(form.get("expiresAt"));
  const notes = trimOrUndef(form.get("notes"));
  const documentId = trimOrUndef(form.get("documentId"));

  if (!shipmentId || !isUuid(shipmentId)) fieldErrors.shipmentId = "شناسه محموله نامعتبر";
  if (!documentKind || !DOC_KIND_VALUES.includes(documentKind)) {
    fieldErrors.documentKind = "نوع مدرک الزامی است";
  }
  if (documentStatus && !DOC_STATUS_VALUES.includes(documentStatus)) {
    fieldErrors.documentStatus = "وضعیت مدرک نامعتبر";
  }
  if (requirementId && !isUuid(requirementId)) fieldErrors.requirementId = "شناسه نیازمندی نامعتبر";
  if (shipmentItemId && !isUuid(shipmentItemId)) fieldErrors.shipmentItemId = "شناسه آیتم نامعتبر";
  if (documentId && !isUuid(documentId)) fieldErrors.documentId = "شناسه مدرک نامعتبر";

  if (Object.keys(fieldErrors).length > 0) {
    return { ok: false, error: "ورودی نامعتبر", fieldErrors };
  }
  return {
    ok: true,
    value: {
      shipmentId,
      documentKind: documentKind!,
      documentStatus,
      requirementId,
      shipmentItemId,
      externalReference,
      issuedAt,
      expiresAt,
      notes,
      documentId,
    },
  };
}

export function parseFileRegisterForm(form: FormData): ValidationResult<FileRegisterInput> {
  const fieldErrors: Record<string, string> = {};
  const filename = trimOrUndef(form.get("filename")) ?? "";
  const mimeType = trimOrUndef(form.get("mimeType"));
  const sizeStr = trimOrUndef(form.get("sizeBytes"));
  const fileType = trimOrUndef(form.get("fileType")) as FileRegisterInput["fileType"];

  if (!filename) fieldErrors.filename = "نام فایل الزامی است";
  let sizeBytes: number | undefined;
  if (sizeStr) {
    const n = Number.parseInt(sizeStr, 10);
    if (Number.isNaN(n) || n < 0) fieldErrors.sizeBytes = "حجم نامعتبر";
    else sizeBytes = n;
  }

  if (Object.keys(fieldErrors).length > 0) {
    return { ok: false, error: "ورودی نامعتبر", fieldErrors };
  }
  return {
    ok: true,
    value: { filename, mimeType, sizeBytes, fileType },
  };
}
