// ===========================================================================
// CC-21 Phase-1 backward-compat sidecar.
//
// Moved here from `database.ts` (CC-20 in-file block) so the generated file
// can be safely overwritten by future `supabase gen types` runs without
// breaking existing imports.
//
// Existing consumers continue to use `import { X } from "@/types/database"`.
// `database.ts` re-exports everything from this file at the bottom.
//
// Each type alias here points at the canonical `Database` shape from the
// regenerated file. Row interfaces are explicit interfaces — they capture the
// shape the admin/supplier consumer code reads from RPC responses.
//
// When a column rename or schema change lands, update this file (and run
// 082_cc21_schema_drift_guard.sql to catch it pgTAP-side).
// ===========================================================================

import type { Database, Json } from "./database";

// --- Enum aliases ----------------------------------------------------------
export type RoleScope = Database["identity"]["Enums"]["role_scope"];
export type OrganizationType = Database["organization"]["Enums"]["organization_type"];
export type OrganizationStatus = Database["organization"]["Enums"]["organization_status"];
export type UserStatus = Database["identity"]["Enums"]["user_status"];
export type TenantStatus = Database["identity"]["Enums"]["tenant_status"];
export type Locale = Database["identity"]["Enums"]["locale"];
export type MembershipStatus = Database["organization"]["Enums"]["membership_status"];
export type SupplierStatus = Database["supplier"]["Enums"]["supplier_status"];
export type VerificationStatus = Database["supplier"]["Enums"]["verification_status"];
export type DocumentType = Database["supplier"]["Enums"]["document_type"];
export type DocumentStatus = Database["supplier"]["Enums"]["document_status"];
export type AdminUserStatus = UserStatus | "pending_profile";

// --- Row interfaces consumed by admin/* ------------------------------------
export interface AdminUserRow {
  user_id: string;
  email: string;
  email_created_at: string;
  full_name: string | null;
  tenant_id: string | null;
  primary_organization_id: string | null;
  status: AdminUserStatus;
  has_profile: boolean;
}

export interface AdminAuditRow {
  id: string;
  occurred_at: string;
  action_code: string;
  actor_user_id: string | null;
  tenant_id: string | null;
  organization_id: string | null;
  resource_type: string | null;
  resource_id: string | null;
  ip_address: string | null;
  payload: Json;
}

// --- Row interfaces consumed by supplier/* ---------------------------------
// SupplierRow mirrors the supplier.suppliers table as of CC-21. Verified
// against information_schema; any column rename will be caught by
// 082_cc21_schema_drift_guard.sql.
export interface SupplierRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  display_name: string | null;
  description: string | null;
  website: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  country_code: string | null;
  established_year: number | null;
  status: SupplierStatus;
  verification_status: VerificationStatus;
  submitted_at: string | null;
  approved_at: string | null;
  rejected_at: string | null;
  rejected_reason: string | null;
  suspended_at: string | null;
  suspended_reason: string | null;
  verification_set_at: string | null;
  verification_reason: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

export interface SupplierCategoryRow {
  id: string;
  code: string;
  name_fa: string;
  name_en: string;
  description: string | null;
  parent_category_id: string | null;
  is_active: boolean;
}

export interface SupplierCategoryLinkRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  supplier_id: string;
  category_id: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// SupplierDocumentRow mirrors supplier.supplier_documents as of CC-21.
// Phase-1 had storage_path / filename / size_bytes / mime_type / uploaded_at;
// the current schema replaced those with a logical descriptor: title,
// description, external_reference, issued_at, expires_at, status,
// rejection_reason. Consumer pages read title / status / issued_at.
export interface SupplierDocumentRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  supplier_id: string;
  document_type: DocumentType;
  title: string | null;
  description: string | null;
  external_reference: string | null;
  issued_at: string | null;
  expires_at: string | null;
  status: DocumentStatus;
  rejection_reason: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
}

// Admin-list returns: minimal columns + denormalised counts.
export interface AdminSupplierListRow {
  id: string;
  supplier_id: string;
  organization_id: string;
  tenant_id: string;
  organization_code: string;
  organization_name_en: string;
  organization_name_fa: string;
  display_name: string | null;
  status: SupplierStatus;
  verification_status: VerificationStatus;
  category_count: number;
  document_count: number;
  submitted_at: string | null;
  approved_at: string | null;
  created_at: string;
  updated_at: string;
}

// Admin-detail extends the list shape with nested arrays + verification field.
export interface AdminSupplierDetailRow extends AdminSupplierListRow {
  description: string | null;
  website: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  country_code: string | null;
  established_year: number | null;
  rejected_reason: string | null;
  suspended_reason: string | null;
  verification_reason: string | null;
  documents: SupplierDocumentRow[];
  categories: SupplierCategoryLinkRow[];
}

// --- CC-24: Pricing portal types ------------------------------------------
// These mirror the SET-returning shapes of pricing.* RPCs. Each interface is
// the projected row exactly as the matching RPC returns it.
export type PriceListStatus = Database["pricing"]["Enums"]["price_list_status"];
export type QuotationStatus = Database["pricing"]["Enums"]["quotation_status"];
export type QuoteCaptureKind = Database["pricing"]["Enums"]["quote_capture_kind"];

// pricing.get_my_price_lists / pricing.admin_list_price_lists row shape.
// The "admin" variant adds tenant_id; both share the rest.
export interface PriceListListRow {
  id: string;
  supplier_id: string;
  organization_id: string;
  code: string;
  name_en: string;
  name_fa?: string | null;
  currency_code: string;
  status: PriceListStatus;
  effective_from: string | null;
  effective_to?: string | null;
  tenant_id?: string;
  created_at?: string;
}

// pricing.portal_list_my_quotations / pricing.admin_list_quotations row shape.
export interface QuotationListRow {
  id: string;
  supplier_id: string;
  buyer_organization_id: string;
  quotation_code: string;
  currency_code: string;
  status: QuotationStatus;
  total_amount: number;
  valid_until: string | null;
  sent_at: string | null;
  created_at: string;
  tenant_id?: string;
}

// pricing.list_currency_rates row shape.
export interface CurrencyRateRow {
  id: string;
  base_code: string;
  quote_code: string;
  rate: number;
  effective_from: string;
  effective_to: string | null;
  source: string;
  created_at: string;
}

// pricing.get_quotation jsonb return wrapper.
export interface QuotationItem {
  id: string;
  tenant_id: string;
  quotation_id: string;
  product_id: string;
  quantity: number;
  unit_of_measure: string;
  unit_price: number;
  line_total: number;
  discount_amount: number;
  notes: string | null;
  position: number;
  created_at: string;
}

export interface QuotationDetail {
  quotation: {
    id: string;
    tenant_id: string;
    supplier_id: string;
    supplier_organization_id: string;
    buyer_organization_id: string;
    rfq_request_id: string | null;
    quotation_code: string;
    currency_code: string;
    status: QuotationStatus;
    valid_from: string | null;
    valid_until: string | null;
    subtotal_amount: number;
    discount_amount: number;
    total_amount: number;
    notes_en: string | null;
    notes_fa: string | null;
    sent_at: string | null;
    responded_at: string | null;
    response_actor_user_id: string | null;
    decision_reason: string | null;
    created_at: string;
    updated_at: string;
  };
  items: QuotationItem[];
}

// --- CC-25: KYC / KYB portal types ----------------------------------------
// Wrapper shapes for the kyc.get_my_* / kyc.admin_get_verification jsonb
// returns and the kyc.admin_list_verifications SET return. Per Q7=A, no
// interface here exposes national_id_number_hash — the column is revoked from
// authenticated and never reaches the UI.
export type KycSubjectType = Database["kyc"]["Enums"]["kyc_subject_type"];
export type KycStatus = Database["kyc"]["Enums"]["kyc_status"];
export type KycDocumentKind = Database["kyc"]["Enums"]["kyc_document_kind"];
export type KycDocumentStatus = Database["kyc"]["Enums"]["kyc_document_status"];
export type KycRiskSeverity = Database["kyc"]["Enums"]["kyc_risk_severity"];
export type KycRiskStatus = Database["kyc"]["Enums"]["kyc_risk_status"];
export type KycEventKind = Database["kyc"]["Enums"]["kyc_event_kind"];

// Each document shape mirrors what the get_my_* RPC projects (no internal
// columns like tenant_id leaked to subject view).
export interface KycSubjectDocumentRow {
  id: string;
  document_kind: KycDocumentKind;
  title: string | null;
  status: KycDocumentStatus;
  rejection_reason: string | null;
  issued_on: string | null;
  expires_on: string | null;
  created_at: string;
}

// kyc.get_my_personal_verification jsonb wrapper. When the user has no
// attempt at all, the RPC returns { status: 'not_started' }; we model the
// "not started" case by allowing every detail field to be optional/null.
export interface KycPersonalDetail {
  id?: string;
  tenant_id?: string;
  attempt_no?: number;
  status: KycStatus | "not_started";
  full_legal_name?: string | null;
  national_id_last4?: string | null;
  date_of_birth?: string | null;
  country_code?: string | null;
  submitted_at?: string | null;
  reviewed_at?: string | null;
  decision_reason?: string | null;
  approved_at?: string | null;
  expires_at?: string | null;
  documents?: KycSubjectDocumentRow[];
}

export interface KycOrganizationDetail {
  id?: string;
  tenant_id?: string;
  organization_id?: string;
  attempt_no?: number;
  status: KycStatus | "not_started";
  legal_name?: string | null;
  registration_number?: string | null;
  tax_id?: string | null;
  country_code?: string | null;
  incorporated_on?: string | null;
  submitted_at?: string | null;
  reviewed_at?: string | null;
  decision_reason?: string | null;
  approved_at?: string | null;
  expires_at?: string | null;
  documents?: KycSubjectDocumentRow[];
}

// kyc.admin_list_verifications row shape (flat).
export interface KycVerificationListRow {
  id: string;
  tenant_id: string;
  subject_type: string;
  subject_id: string;
  attempt_no: number;
  status: string;
  submitted_at: string | null;
  reviewed_at: string | null;
  approved_at: string | null;
  expires_at: string | null;
  created_at: string;
}

// Admin documents/risk_flags/events as projected through admin_get_verification.
// to_jsonb() on the canonical row, so we model the full column set here.
export interface KycAdminDocumentRow {
  id: string;
  tenant_id: string;
  subject_type: KycSubjectType;
  personal_verification_id: string | null;
  organization_verification_id: string | null;
  document_kind: KycDocumentKind;
  title: string | null;
  bucket: string;
  storage_path: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  issued_on: string | null;
  expires_on: string | null;
  status: KycDocumentStatus;
  rejection_reason: string | null;
  reviewed_at: string | null;
  reviewed_by: string | null;
  created_by: string | null;
  created_at: string;
  updated_by: string | null;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

export interface KycRiskFlagRow {
  id: string;
  tenant_id: string;
  subject_type: KycSubjectType;
  user_id: string | null;
  organization_id: string | null;
  source: string;
  severity: KycRiskSeverity;
  status: KycRiskStatus;
  code: string;
  detail: string | null;
  raised_at: string;
  raised_by: string | null;
  resolved_at: string | null;
  resolved_by: string | null;
  resolution_note: string | null;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  version: number;
}

export interface KycEventRow {
  id: string;
  tenant_id: string;
  subject_type: KycSubjectType;
  user_id: string | null;
  organization_id: string | null;
  personal_verification_id: string | null;
  organization_verification_id: string | null;
  event_kind: KycEventKind;
  actor_user_id: string | null;
  payload: Json;
  occurred_at: string;
}

export interface KycVerificationAdminDetail {
  subject_type: KycSubjectType;
  // The RPC pushes the full canonical row via to_jsonb(); we don't enumerate
  // every column here (they vary between personal_verifications and
  // organization_verifications) — the page reads .verification as Record.
  verification: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    status: KycStatus;
    attempt_no: number;
    submitted_at: string | null;
    reviewed_at: string | null;
    decision_reason: string | null;
    approved_at: string | null;
    expires_at: string | null;
    // Personal columns (present when subject_type='person')
    user_id?: string;
    full_legal_name?: string | null;
    national_id_last4?: string | null;
    date_of_birth?: string | null;
    country_code?: string | null;
    // Organization columns (present when subject_type='organization')
    organization_id?: string;
    legal_name?: string | null;
    registration_number?: string | null;
    tax_id?: string | null;
    incorporated_on?: string | null;
  };
  documents: KycAdminDocumentRow[];
  risk_flags: KycRiskFlagRow[];
  events: KycEventRow[];
}

// --- CC-26: Notify portal types --------------------------------------------
// Wrapper interfaces matching the projected shapes of notify.* RPCs.
export type NotificationCategory = Database["notify"]["Enums"]["notification_category"];
export type NotificationPriority = Database["notify"]["Enums"]["notification_priority"];
export type NotificationStatus = Database["notify"]["Enums"]["notification_status"];
export type ChannelType = Database["notify"]["Enums"]["channel_type"];
export type DeliveryStatus = Database["notify"]["Enums"]["delivery_status"];
export type TemplateStatus = Database["notify"]["Enums"]["template_status"];

// notify.portal_list_my_notifications row shape (subject view).
export interface NotificationInboxRow {
  id: string;
  category: NotificationCategory;
  priority: NotificationPriority;
  status: NotificationStatus;
  title_en: string;
  title_fa: string;
  body_en: string | null;
  body_fa: string | null;
  action_url: string | null;
  source_event_type: string | null;
  source_entity_type: string | null;
  source_entity_id: string | null;
  read_at: string | null;
  created_at: string;
}

// notify.portal_get_notification jsonb wrapper.
export interface NotificationDetail {
  id: string;
  category: NotificationCategory;
  priority: NotificationPriority;
  status: NotificationStatus;
  title_en: string;
  title_fa: string;
  body_en: string | null;
  body_fa: string | null;
  action_url: string | null;
  source_event_type: string | null;
  source_entity_type: string | null;
  source_entity_id: string | null;
  payload: Json;
  read_at: string | null;
  created_at: string;
}

// notify.admin_list_notifications row shape (cross-tenant admin queue).
export interface AdminNotificationRow {
  id: string;
  recipient_user_id: string;
  organization_id: string | null;
  category: NotificationCategory;
  status: NotificationStatus;
  title_en: string;
  source_event_type: string | null;
  created_at: string;
}

// notify.admin_list_templates row shape.
export interface NotificationTemplateRow {
  id: string;
  template_code: string;
  organization_id: string | null;
  category: NotificationCategory;
  default_priority: NotificationPriority;
  status: TemplateStatus;
  title_en: string;
}

// notify.admin_list_delivery_attempts row shape.
export interface DeliveryAttemptRow {
  id: string;
  notification_id: string;
  channel: ChannelType;
  status: DeliveryStatus;
  attempted_at: string | null;
  delivered_at: string | null;
  failure_reason: string | null;
  created_at: string;
}

// --- CC-27: Settlement portal types ---------------------------------------
export type SettlementStatus = Database["settlement"]["Enums"]["settlement_status"];
export type SettlementDisputeStatus = Database["settlement"]["Enums"]["dispute_status"];
export type EscrowStatus = Database["settlement"]["Enums"]["escrow_status"];

// settlement.buyer_list_settlements row shape (buyer-side projection).
export interface BuyerSettlementListRow {
  id: string;
  settlement_code: string;
  supplier_id: string;
  escrow_account_id: string | null;
  executed_contract_id: string | null;
  shipment_id: string | null;
  currency: string;
  planned_amount: number;
  held_amount: number;
  released_amount: number;
  status: SettlementStatus;
  created_at: string;
  updated_at: string;
}

// settlement.supplier_list_my_settlements row shape.
export interface SupplierSettlementListRow {
  id: string;
  settlement_code: string;
  executed_contract_id: string | null;
  shipment_id: string | null;
  currency: string;
  planned_amount: number;
  released_amount: number;
  status: SettlementStatus;
  dispute_status: SettlementDisputeStatus;
  created_at: string;
  updated_at: string;
}

// settlement.admin_list_settlements row shape (cross-tenant admin).
export interface AdminSettlementListRow {
  id: string;
  settlement_code: string;
  organization_id: string;
  supplier_id: string;
  currency: string;
  planned_amount: number;
  released_amount: number;
  status: SettlementStatus;
  dispute_status: SettlementDisputeStatus;
  created_at: string;
}

// settlement.admin_list_settlement_events row shape.
export interface SettlementEventRow {
  id: string;
  event_type: string;
  from_status: SettlementStatus | null;
  to_status: SettlementStatus | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// settlement.{buyer|supplier|admin}_get_settlement jsonb wrapper. Pages read
// only the union of columns we enumerate below; the Record allows extras.
export interface SettlementDetail {
  settlement: Record<string, unknown> & {
    id: string;
    settlement_code: string;
    tenant_id: string;
    organization_id: string;
    supplier_id: string;
    escrow_account_id: string | null;
    executed_contract_id: string | null;
    shipment_id: string | null;
    currency: string;
    planned_amount: number;
    held_amount: number;
    released_amount: number;
    fees_amount?: number | null;
    platform_fee_amount?: number | null;
    status: SettlementStatus;
    dispute_status?: SettlementDisputeStatus;
    settlement_terms: string | null;
    notes: string | null;
    created_at: string;
    updated_at: string;
  };
  items?: Array<Record<string, unknown> & {
    id: string;
    description: string;
    amount: number | null;
    fees_amount: number | null;
    platform_fee_amount: number | null;
    sort_order: number | null;
  }>;
  events?: SettlementEventRow[];
}

// --- CC-27: Dispute portal types ------------------------------------------
export type DisputeCaseStatus = Database["dispute"]["Enums"]["dispute_case_status"];
export type DecisionOutcome = Database["dispute"]["Enums"]["decision_outcome"];
export type EvidenceStatus = Database["dispute"]["Enums"]["evidence_status"];
export type EvidenceKind = Database["dispute"]["Enums"]["evidence_kind"];
export type DisputeSettlementAction = Database["dispute"]["Enums"]["settlement_action"];
export type PartyRole = Database["dispute"]["Enums"]["party_role"];

// dispute.buyer_list_disputes / supplier_list_my_disputes / admin_list_disputes row shape.
export interface DisputeListRow {
  id: string;
  dispute_code: string;
  settlement_id: string;
  supplier_id?: string;
  organization_id?: string;
  title: string;
  status: DisputeCaseStatus;
  opened_by_party: PartyRole | string;
  amount_in_dispute: number;
  currency: string;
  created_at: string;
  updated_at?: string;
}

// dispute.admin_list_dispute_events row shape.
export interface DisputeEventRow {
  id: string;
  event_type: string;
  from_status: DisputeCaseStatus | null;
  to_status: DisputeCaseStatus | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// dispute.admin_list_dispute_evidence row shape.
export interface DisputeEvidenceRow {
  id: string;
  evidence_kind: EvidenceKind;
  title: string;
  status: EvidenceStatus;
  submitter_party_role: PartyRole | string;
  created_at: string;
}

// dispute.admin_list_decisions row shape.
export interface DisputeDecisionRow {
  id: string;
  outcome: DecisionOutcome;
  settlement_action: DisputeSettlementAction;
  buyer_share_amount: number;
  supplier_share_amount: number;
  voided_at: string | null;
  created_at: string;
}

// dispute.{buyer|supplier|admin}_get_dispute jsonb wrapper.
export interface DisputeDetail {
  dispute: Record<string, unknown> & {
    id: string;
    dispute_code: string;
    tenant_id: string;
    organization_id: string;
    supplier_id: string;
    settlement_id: string;
    title: string;
    description: string | null;
    status: DisputeCaseStatus;
    opened_by_party: PartyRole | string;
    amount_in_dispute: number;
    currency: string;
    decision_outcome: DecisionOutcome | null;
    decision_reason: string | null;
    assigned_mediator_id: string | null;
    created_at: string;
    updated_at: string;
  };
  evidence?: DisputeEvidenceRow[];
  decisions?: DisputeDecisionRow[];
  events?: DisputeEventRow[];
}

// --- CC-28: RFQ + Offer portal types --------------------------------------
export type RfqStatus = Database["rfq"]["Enums"]["request_status"];
export type RfqVisibilityModel = Database["rfq"]["Enums"]["visibility_model"];
export type InvitationStatus = Database["rfq"]["Enums"]["invitation_status"];
export type OfferStatus = Database["offer"]["Enums"]["offer_status"];

// rfq.buyer_list_rfqs / rfq.admin_list_rfqs / shared list shape.
export interface RfqListRow {
  id: string;
  rfq_code: string;
  title: string;
  status: RfqStatus;
  submission_deadline: string | null;
  validity_until?: string | null;
  visibility?: RfqVisibilityModel | string;
  invitation_count?: number;
  item_count?: number;
  organization_id?: string;
  created_at: string;
  updated_at: string;
}

// rfq.supplier_list_rfq_invitations row shape (invitation-aware).
export interface SupplierRfqInvitationRow {
  invitation_id: string;
  invitation_status: InvitationStatus;
  invited_at: string;
  request_id: string;
  request_status: RfqStatus;
  rfq_code: string;
  submission_deadline: string | null;
  title: string;
}

// rfq.admin_list_invitations row shape (full invitation projection).
export interface AdminRfqInvitationRow {
  id: string;
  request_id: string;
  supplier_id: string;
  status: InvitationStatus;
  invited_at: string;
  viewed_at: string | null;
  responded_at: string | null;
}

// rfq.{buyer|supplier|admin}_get_rfq jsonb wrapper. Pages read the union of
// columns the buyer-detail page consumes; full row passes through as Record.
export interface RfqDetail {
  request: Record<string, unknown> & {
    id: string;
    rfq_code: string;
    tenant_id: string;
    organization_id: string;
    title: string;
    description: string | null;
    status: RfqStatus;
    visibility: RfqVisibilityModel | string;
    preferred_currency: string;
    submission_deadline: string | null;
    validity_until: string | null;
    delivery_country: string | null;
    delivery_city: string | null;
    delivery_port: string | null;
    delivery_location_text: string | null;
    payment_terms_text: string | null;
    internal_notes: string | null;
    created_at: string;
    updated_at: string;
  };
  items?: Array<Record<string, unknown> & {
    id: string;
    product_id: string | null;
    quantity: number | null;
    quantity_unit: string | null;
    sort_order: number | null;
    notes: string | null;
  }>;
  invitations?: AdminRfqInvitationRow[];
  events?: Array<{
    id: string;
    from_status: RfqStatus | null;
    to_status: RfqStatus | null;
    reason: string | null;
    actor_user_id: string | null;
    created_at: string;
  }>;
}

// offer.buyer_list_received_offers / supplier_list_my_offers / admin_list_offers row shapes.
export interface OfferListRow {
  id: string;
  offer_code: string;
  request_id: string;
  rfq_code?: string;
  rfq_title?: string;
  supplier_id?: string;
  supplier_org_id?: string;
  organization_id?: string;
  status: OfferStatus;
  currency: string;
  item_count?: number;
  submitted_at: string | null;
  validity_until?: string | null;
  created_at: string;
  updated_at?: string;
}

// offer.admin_list_offer_status_events row shape.
export interface OfferStatusEventRow {
  id: string;
  from_status: OfferStatus | null;
  to_status: OfferStatus | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// offer.{buyer|supplier|admin}_get_offer jsonb wrapper.
export interface OfferDetail {
  offer: Record<string, unknown> & {
    id: string;
    offer_code: string;
    tenant_id: string;
    request_id: string;
    supplier_id: string;
    organization_id: string;
    status: OfferStatus;
    currency: string;
    incoterm: string | null;
    delivery_country: string | null;
    delivery_city: string | null;
    delivery_port: string | null;
    delivery_location_text: string | null;
    delivery_lead_time_text: string | null;
    payment_terms_text: string | null;
    supplier_notes: string | null;
    validity_until: string | null;
    submitted_at: string | null;
    created_at: string;
    updated_at: string;
  };
  items?: Array<Record<string, unknown> & {
    id: string;
    request_item_id: string | null;
    offered_quantity: number | null;
    quantity_unit: string | null;
    unit_price: number | null;
    total_price: number | null;
    currency: string | null;
    notes: string | null;
    sort_order: number | null;
  }>;
  events?: OfferStatusEventRow[];
}

// --- CC-29: Evaluation portal types ---------------------------------------
// CC-13 design note: an evaluation is per-OFFER (not per-RFQ); each offer
// receives its own evaluation record with free-text "dimension" score lines.
// Decisions (shortlist / reject / select-for-contract) are recorded against
// the offer directly via three buyer RPCs, independent of the evaluation
// status itself. There is NO admin force-status RPC — admin pages are
// strictly read-only.
export type EvaluationStatus = Database["evaluation"]["Enums"]["evaluation_status"];
export type DecisionStatus = Database["evaluation"]["Enums"]["decision_status"];

// evaluation.buyer_list_evaluations / admin_list_evaluations projected row.
export interface EvaluationListRow {
  id: string;
  request_id: string;
  offer_id: string;
  organization_id?: string;
  evaluator_user_id: string | null;
  status: EvaluationStatus;
  score_count?: number;
  created_at: string;
  updated_at: string;
}

// One row inside an evaluation's score sub-array.
export interface EvaluationScoreRow {
  id: string;
  dimension: string;
  score_value: number | null;
  max_score: number | null;
  weight: number | null;
  weighted_score: number | null;
  notes: string | null;
  created_at: string;
  updated_at?: string;
}

// evaluation.admin_list_decisions row.
export interface EvaluationDecisionListRow {
  id: string;
  offer_id: string;
  request_id: string;
  organization_id: string;
  decision_status: DecisionStatus;
  decided_by: string | null;
  decided_at: string;
}

// evaluation.admin_list_decision_events row.
export interface EvaluationDecisionEventRow {
  id: string;
  from_status: DecisionStatus | null;
  to_status: DecisionStatus | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// evaluation.{buyer|admin}_get_evaluation jsonb wrapper.
export interface EvaluationDetail {
  evaluation: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    request_id: string;
    offer_id: string;
    organization_id: string;
    evaluator_user_id: string | null;
    status: EvaluationStatus;
    overall_notes: string | null;
    commercial_notes: string | null;
    technical_notes: string | null;
    risk_notes: string | null;
    created_at: string;
    updated_at: string;
  };
  scores?: EvaluationScoreRow[];
  // Decisions sit on the offer (not the evaluation) but are commonly
  // bundled into the get_evaluation jsonb for convenience.
  decisions?: Array<Record<string, unknown> & {
    id: string;
    offer_id: string;
    request_id: string;
    decision_status: DecisionStatus;
    reason: string | null;
    decision_notes: string | null;
    decided_at: string;
    decided_by: string | null;
  }>;
}

// --- CC-30: Contract portal types -----------------------------------------
// Two phases: preparation (`contract.*_preparation*` RPCs) and executed
// contract (`contract.*_executed_contract*` RPCs). Signatures hang off the
// executed contract via `signature_requests` rows.
export type PreparationStatus = Database["contract"]["Enums"]["preparation_status"];
export type ContractStatus = Database["contract"]["Enums"]["contract_status"];
export type SignatureStatus = Database["contract"]["Enums"]["signature_status"];
export type ContractPartyType = Database["contract"]["Enums"]["party_type"];
export type ContractClauseType = Database["contract"]["Enums"]["preparation_clause_type"];
export type PreparationContractType = Database["contract"]["Enums"]["preparation_contract_type"];

// contract.buyer_list_preparations / admin_list_preparations row.
export interface ContractPreparationListRow {
  id: string;
  preparation_code: string;
  title: string;
  request_id: string;
  offer_id: string;
  decision_id: string;
  supplier_id: string;
  organization_id?: string;
  status: PreparationStatus;
  created_at: string;
  updated_at: string;
}

// contract.buyer_list_executed_contracts / admin_list_executed_contracts row.
export interface ExecutedContractListRow {
  id: string;
  contract_code: string;
  title: string;
  request_id: string;
  offer_id: string;
  preparation_id?: string;
  supplier_id?: string;
  organization_id?: string;
  status: ContractStatus;
  created_at: string;
  updated_at: string;
}

// One signature_request projected row.
export interface SignatureRequestRow {
  id: string;
  contract_id: string;
  party_id: string;
  status: SignatureStatus;
  requested_at: string;
  due_at: string | null;
  responded_at?: string | null;
  decline_reason?: string | null;
}

// Status event row used by both preparation and executed phases.
export interface ContractStatusEventRow {
  id: string;
  from_status: string | null;
  to_status: string | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// contract.buyer_get_preparation jsonb wrapper. The DB returns the full
// preparation row + nested parties + clauses + (optionally) events.
export interface ContractPreparationDetail {
  preparation: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    organization_id: string;
    preparation_code: string;
    title: string;
    status: PreparationStatus;
    contract_type: PreparationContractType | null;
    currency: string | null;
    decision_id: string;
    request_id: string;
    offer_id: string;
    supplier_id: string;
    supplier_organization_id?: string;
    incoterm: string | null;
    delivery_country: string | null;
    delivery_city: string | null;
    delivery_port: string | null;
    delivery_location_text: string | null;
    delivery_terms_text: string | null;
    payment_terms_text: string | null;
    inspection_terms_text: string | null;
    dispute_resolution_text: string | null;
    governing_law_text: string | null;
    special_conditions_text: string | null;
    internal_notes: string | null;
    created_at: string;
    updated_at: string;
  };
  parties?: Array<Record<string, unknown> & {
    id: string;
    party_type: ContractPartyType;
    display_name: string;
    role_title: string | null;
    signer_role: string | null;
    is_required_signer: boolean | null;
    signing_order: number | null;
    party_organization_id: string | null;
    party_supplier_id: string | null;
    party_user_id: string | null;
  }>;
  clauses?: Array<Record<string, unknown> & {
    id: string;
    clause_type: ContractClauseType;
    clause_key: string | null;
    title_en: string | null;
    title_fa: string | null;
    body_en: string | null;
    body_fa: string | null;
    is_required: boolean | null;
    sort_order: number | null;
    source: string | null;
  }>;
  events?: ContractStatusEventRow[];
}

// contract.buyer_get_executed_contract jsonb wrapper.
export interface ExecutedContractDetail {
  contract: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    organization_id: string;
    preparation_id: string;
    contract_code: string;
    title: string;
    status: ContractStatus;
    currency: string | null;
    incoterm: string | null;
    delivery_country: string | null;
    delivery_city: string | null;
    delivery_port: string | null;
    delivery_location_text: string | null;
    delivery_terms_text: string | null;
    payment_terms_text: string | null;
    inspection_terms_text: string | null;
    dispute_resolution_text: string | null;
    governing_law_text: string | null;
    special_conditions_text: string | null;
    internal_notes: string | null;
    effective_date: string | null;
    expiry_date: string | null;
    request_id: string;
    offer_id: string;
    supplier_id: string;
    supplier_organization_id?: string;
    created_at: string;
    updated_at: string;
  };
  parties?: Array<Record<string, unknown> & {
    id: string;
    party_type: ContractPartyType;
    display_name: string;
    role_title: string | null;
    signer_role: string | null;
    is_required_signer: boolean | null;
    signing_order: number | null;
  }>;
  signature_requests?: SignatureRequestRow[];
  events?: ContractStatusEventRow[];
}

// --- CC-31: Shipment portal types -----------------------------------------
// CC-15 design note: shipments do NOT have items; only doc-requirements,
// documents, milestones, and stops hang off the shipment row. Supplier side
// is read-only (no supplier_* mutation RPCs). Admin force surface is
// `admin_close_shipment` + `admin_force_cancel_shipment` (no arbitrary
// status selector).
export type ShipmentStatus = Database["shipment"]["Enums"]["shipment_status"];
export type ShipmentTransportMode = Database["shipment"]["Enums"]["transport_mode"];
export type ShipmentDocumentKind = Database["shipment"]["Enums"]["document_kind"];
export type ShipmentDocumentStatus = Database["shipment"]["Enums"]["document_status"];

// shipment.{buyer|supplier|admin}_list_shipments row projection.
export interface ShipmentListRow {
  id: string;
  shipment_code: string;
  executed_contract_id: string;
  supplier_id?: string;
  organization_id?: string;
  transport_mode: ShipmentTransportMode | null;
  status: ShipmentStatus;
  created_at: string;
  updated_at: string;
}

// One shipment document-requirement row.
export interface ShipmentDocumentRequirementRow {
  id: string;
  shipment_id: string;
  document_kind: ShipmentDocumentKind;
  requirement_level: string;
  display_name_en: string | null;
  display_name_fa: string | null;
  notes: string | null;
  created_at: string;
}

// One shipment document row.
export interface ShipmentDocumentRow {
  id: string;
  shipment_id: string;
  shipment_item_id?: string | null;
  requirement_id: string | null;
  document_kind: ShipmentDocumentKind;
  document_status: ShipmentDocumentStatus;
  external_reference: string | null;
  issued_at: string | null;
  expires_at: string | null;
  notes: string | null;
  created_at: string;
}

// shipment.admin_list_shipment_events row.
export interface ShipmentEventRow {
  id: string;
  event_type: string;
  from_status: ShipmentStatus | null;
  to_status: ShipmentStatus | null;
  reason: string | null;
  actor_user_id: string | null;
  created_at: string;
}

// shipment.{buyer|supplier|admin}_get_shipment jsonb wrapper.
export interface ShipmentDetail {
  shipment: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    organization_id: string;
    executed_contract_id: string;
    shipment_code: string;
    status: ShipmentStatus;
    transport_mode: ShipmentTransportMode | null;
    incoterm: string | null;
    origin_country: string | null;
    origin_city: string | null;
    origin_port: string | null;
    origin_location_text: string | null;
    destination_country: string | null;
    destination_city: string | null;
    destination_port: string | null;
    destination_location_text: string | null;
    planned_pickup_date: string | null;
    planned_delivery_date: string | null;
    carrier_name: string | null;
    tracking_reference: string | null;
    vehicle_reference: string | null;
    supplier_id: string | null;
    supplier_organization_id?: string | null;
    notes: string | null;
    created_at: string;
    updated_at: string;
  };
  doc_requirements?: ShipmentDocumentRequirementRow[];
  documents?: ShipmentDocumentRow[];
  events?: ShipmentEventRow[];
  milestones?: ShipmentMilestoneRow[];
  stops?: ShipmentStopRow[];
}

// --- CC-32: Tracking & Visibility portal types ----------------------------
// CC-15 design: milestones and stops hang off the shipment row. Buyer is the
// only audience with mutators (buyer_upsert_milestone + buyer_upsert_stop);
// supplier + admin tracking pages are strictly read-only.
export type ShipmentMilestoneType = Database["shipment"]["Enums"]["milestone_type"];
export type ShipmentMilestoneStatus = Database["shipment"]["Enums"]["milestone_status"];
export type ShipmentStopType = Database["shipment"]["Enums"]["stop_type"];

export interface ShipmentMilestoneRow {
  id: string;
  shipment_id: string;
  milestone_type: ShipmentMilestoneType;
  status: ShipmentMilestoneStatus;
  planned_at: string | null;
  completed_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at?: string;
}

export interface ShipmentStopRow {
  id: string;
  shipment_id: string;
  sequence_number: number;
  stop_type: ShipmentStopType;
  city: string | null;
  country: string | null;
  port: string | null;
  location_text: string | null;
  planned_arrival_at: string | null;
  planned_departure_at: string | null;
  actual_arrival_at: string | null;
  actual_departure_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at?: string;
}

// Q3=A: combined chronological row used by the timeline component.
export interface TrackingTimelineRow {
  kind: "milestone" | "stop" | "status_event";
  id: string;
  at: string;                       // resolved timestamp used for sort ordering
  label: string;                    // milestone_type / stop_type / event_type
  status?: string;                  // milestone status / shipment status / null
  notes?: string | null;
  actor_user_id?: string | null;    // populated on status_event for admin audience
  raw_milestone?: ShipmentMilestoneRow;
  raw_stop?: ShipmentStopRow;
  raw_event?: ShipmentEventRow;
}

// --- CC-33: Trade Documentation & Compliance portal types ----------------
// Direct SELECT-based projection of shipment.shipment_documents joined with
// shipment metadata via PostgREST relationship embedding. RLS filters rows
// to the audience's scope (buyer org for buyer; admin sees all).
export interface TradeDocumentRow {
  id: string;
  tenant_id: string;
  organization_id: string;
  shipment_id: string;
  shipment_item_id: string | null;
  requirement_id: string | null;
  document_kind: ShipmentDocumentKind;
  document_status: ShipmentDocumentStatus;
  external_reference: string | null;
  issued_at: string | null;
  expires_at: string | null;
  notes: string | null;
  metadata: Json;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  version: number;
  // PostgREST-embedded shipment context. Filtered via RLS on shipments.
  shipments?: {
    id: string;
    shipment_code: string;
    status: ShipmentStatus;
    supplier_id: string | null;
    executed_contract_id: string;
    organization_id: string;
    transport_mode: ShipmentTransportMode | null;
  } | null;
}

// /supplier/trade-documents row: a shipment + doc summary, since supplier
// RLS on shipment_documents may not allow direct SELECT. Supplier drills in
// via the existing /supplier/shipments/[id] view to see the full docs list.
export interface SupplierShipmentDocSummary {
  shipment_id: string;
  shipment_code: string;
  status: ShipmentStatus;
  transport_mode: ShipmentTransportMode | null;
  executed_contract_id: string;
  updated_at: string;
}

// --- CC-36: Financial Operations & Settlement Control Center types -------
export type InvoiceStatus = Database["finance"]["Enums"]["invoice_status"];
export type PaymentStatus = Database["finance"]["Enums"]["payment_status"];

// finance.buyer_list_invoices / supplier_list_my_invoices / admin_list_invoices row.
export interface InvoiceSummaryRow {
  id: string;
  invoice_code: string;
  executed_contract_id: string | null;
  shipment_id: string | null;
  supplier_id: string | null;
  organization_id?: string | null;
  status: InvoiceStatus | string;
  currency: string;
  total_amount: number;
  paid_amount: number;
  invoice_date: string | null;
  due_date: string | null;
  created_at: string;
  updated_at?: string;
}

// settlement.admin_list_escrow_accounts row.
export interface AdminEscrowAccountRow {
  id: string;
  account_code: string;
  organization_id: string;
  supplier_id: string | null;
  status: EscrowStatus | string;
  currency: string;
  available_balance: number;
  total_held: number;
  total_credited: number;
  total_released: number;
  created_at: string;
}

// Direct SELECT projection used for buyer/supplier escrow visibility (RLS-scoped).
export interface OrgEscrowAccountRow {
  id: string;
  account_code: string;
  organization_id: string;
  supplier_id: string | null;
  status: EscrowStatus | string;
  currency: string;
  available_balance: number;
  total_held: number;
  total_credited: number;
  total_released: number;
  created_at: string;
  updated_at: string;
}

// Aggregated KPI bundle for the finance dashboards. Computed entirely in TS
// over data returned by existing RPCs/SELECTs; no new RPC required.
export interface FinanceKpiBundle {
  currency: string | null;
  invoices: {
    count: number;
    totalAmount: number;
    paidAmount: number;
    outstandingAmount: number;
    overdueCount: number;
  };
  settlements: {
    count: number;
    plannedAmount: number;
    heldAmount: number;
    releasedAmount: number;
    holdCount: number;
  };
  escrow: {
    accountCount: number;
    availableBalance: number;
    totalHeld: number;
    frozenCount: number;
  };
}

// Admin exception row — synthesized from settlements + escrow accounts via
// direct SELECT. No backend RPC introduced.
export type FinanceExceptionKind =
  | "settlement_held_with_balance"
  | "settlement_disputed"
  | "escrow_frozen"
  | "escrow_closed_with_balance";

export interface FinanceExceptionRow {
  kind: FinanceExceptionKind;
  subject_id: string;
  subject_code: string;
  organization_id: string;
  supplier_id: string | null;
  currency: string;
  amount: number;
  status_label: string;
  updated_at: string;
  detail_href: string;
}

// --- CC-37: Executive Operations Dashboard types -------------------------
export type ExecutiveAudience = "admin" | "buyer" | "supplier";

// One KPI cell on the executive dashboard. `value` is the headline number,
// `caption` is an optional short Persian gloss, `tone` controls badge color,
// `available=false` lets the route render an "N/A" tile without crashing.
export interface ExecutiveKpi {
  id: string;
  label: string;
  value: number;
  caption?: string;
  tone?: "default" | "success" | "warning" | "danger";
  available: boolean;
  href?: string;
}

// Operational pipeline step. `count` is the number of items currently in that
// stage; `href` points to the canonical list for the audience.
export interface PipelineStep {
  id: "rfq" | "offer" | "evaluation" | "contract" | "shipment" | "settlement";
  label: string;
  count: number;
  href: string;
  available: boolean;
}

// Risk-panel item. `severity` drives ordering/tone; `href` deep-links.
export interface RiskItem {
  id: string;
  label: string;
  count: number;
  severity: "info" | "warning" | "danger";
  href?: string;
  available: boolean;
}

// Recent activity item (mixed-feed). `category` colors the row, `subject`
// is the short identifier shown to the user.
export interface ActivityRow {
  id: string;
  category: "rfq" | "offer" | "shipment" | "dispute" | "notification";
  subject: string;
  description: string;
  href?: string;
  created_at: string;
}

// Quick-link entry shown in the action grid.
export interface QuickLink {
  href: string;
  label: string;
  caption?: string;
}

// Complete bundle consumed by each executive dashboard route.
export interface ExecutiveDashboardBundle {
  audience: ExecutiveAudience;
  kpis: ExecutiveKpi[];
  pipeline: PipelineStep[];
  risks: RiskItem[];
  activity: ActivityRow[];
  quickLinks: QuickLink[];
  unavailableSections: string[];
}

// --- CC-38 + CC-40: Capacity & Carrier Marketplace types -----------------
// CC-38 introduced these as frontend stubs over `organization.organizations`.
// CC-40 reshapes them to match the CC-39 RPC return shapes:
//   - CarrierSummary maps onto `marketplace.buyer_list_carriers` /
//     `admin_list_carriers` row projections.
//   - CapacityListing maps onto `marketplace.buyer_list_capacity` /
//     `supplier_list_my_capacity` / `admin_list_capacity` projections.
//   - MarketplaceActivityRow kinds extended for `capacity_archived`.
//   - publishCapacity Server Action now calls `marketplace.supplier_publish_capacity`.
export type TransportMode = Database["shipment"]["Enums"]["transport_mode"];
// CC-40: typecheck proved `database.ts` needed regeneration (the supabase
// client narrows schema names to the literal set declared in the generated
// types, and the pre-CC-39 file did not include `marketplace`). After
// regeneration the marketplace enums are pulled from the generated types so
// the union stays in lock-step with SQL.
export type CarrierProfileStatus =
  Database["marketplace"]["Enums"]["carrier_profile_status"];
export type CapacityStatus =
  Database["marketplace"]["Enums"]["capacity_status"];

// Projected from `marketplace.buyer_list_carriers` (and admin variant). `id`
// is the carrier_profile row id, NOT the organization id (which is exposed
// separately as `organization_id`). RPC-returned columns differ between buyer
// and admin variants; optional fields cover that.
export interface CarrierSummary {
  id: string;
  organization_id: string;
  code: string;
  name_fa: string;
  name_en: string;
  display_name_fa?: string | null;
  display_name_en?: string | null;
  status: CarrierProfileStatus;
  transport_modes?: TransportMode[] | null;
  service_country_codes?: string[] | null;
  country_code?: string | null;
  is_public?: boolean;
  created_at: string;
}

// Projected from the three `*_list_capacity` RPCs. Field set is the union;
// `status` is omitted by `buyer_list_capacity` (only active rows surface for
// buyers), so it is optional. carrier_name_* come from a join in supplier and
// admin variants; the supplier list omits them.
export interface CapacityListing {
  id: string;
  carrier_organization_id: string;
  carrier_name_fa?: string | null;
  carrier_name_en?: string | null;
  transport_mode: TransportMode;
  origin_country_code: string | null;
  origin_city: string | null;
  destination_country_code: string | null;
  destination_city: string | null;
  capacity_units: number | null;
  capacity_unit_label: string | null;
  valid_from: string | null;
  valid_until: string | null;
  status?: CapacityStatus;
  created_at: string;
}

export interface MarketplaceKpiBundle {
  carriers: { count: number; available: boolean };
  capacityListings: { count: number; available: boolean };
  shipmentsByMode: Array<{ mode: TransportMode | "unknown"; count: number }>;
  recentShipmentCount: number;
  available: boolean;
}

export interface MarketplaceActivityRow {
  id: string;
  // CC-40: extended with capacity_archived for `marketplace.admin_list_activity`.
  kind:
    | "shipment_booked"
    | "shipment_in_transit"
    | "carrier_added"
    | "capacity_published"
    | "capacity_archived";
  subject: string;
  description: string;
  href?: string;
  created_at: string;
}

// --- CC-41: Carrier Matching & Capacity Discovery types ------------------
// Mirrors the RETURNS TABLE shapes of marketplace.find_matching_capacity
// and marketplace.find_matching_carriers. score_breakdown is the per-bucket
// jsonb produced by fn_score_capacity_for_shipment.
export interface MatchingScoreBreakdown {
  transport_mode: number;
  origin: number;
  destination: number;
  availability: number;
  profile: number;
  visibility: number;
  total: number;
  fallback?: boolean;
}

export interface CapacityMatchRow {
  capacity_listing_id: string;
  carrier_organization_id: string;
  carrier_name: string | null;
  transport_mode: TransportMode;
  origin_country_code: string | null;
  destination_country_code: string | null;
  valid_from: string | null;
  valid_until: string | null;
  score: number;
  score_breakdown: MatchingScoreBreakdown;
}

export interface CarrierMatchRow {
  carrier_organization_id: string;
  carrier_name: string | null;
  best_listing_id: string | null;
  score: number;
  score_breakdown: MatchingScoreBreakdown;
}

export interface MatchingSummary {
  total_match_requests: number;
  average_score: number;
  unmatched_shipments: number;
  top_carriers: Array<{
    carrier_organization_id: string;
    matches: number;
  }>;
  eligibility_window: string;
}

// --- CC-42: Carrier Booking Foundation types -----------------------------
// Mirrors marketplace.booking_status enum and the row projections returned by
// the audience-scoped list RPCs.
export type BookingStatus =
  Database["marketplace"]["Enums"]["booking_status"];

export interface BookingListRow {
  id: string;
  shipment_id: string;
  capacity_listing_id: string;
  carrier_organization_id: string;
  buyer_organization_id: string;
  status: BookingStatus;
  requested_pickup_at: string | null;
  expires_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface BookingDetail {
  booking: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    shipment_id: string;
    capacity_listing_id: string;
    buyer_organization_id: string;
    carrier_organization_id: string;
    status: BookingStatus;
    requested_quantity_units: number | null;
    requested_unit_label: string | null;
    requested_pickup_at: string | null;
    expires_at: string | null;
    notes_fa: string | null;
    notes_en: string | null;
    requested_by: string | null;
    responded_by: string | null;
    responded_at: string | null;
    confirmed_by: string | null;
    confirmed_at: string | null;
    cancelled_by: string | null;
    cancelled_at: string | null;
    cancelled_reason: string | null;
    created_at: string;
    updated_at: string;
    deleted_at: string | null;
    version: number;
  };
  events: Array<{
    id: string;
    booking_request_id: string;
    from_status: BookingStatus | null;
    to_status: BookingStatus;
    event_type: string;
    actor_party: string;
    actor_user_id: string | null;
    actor_organization_id: string | null;
    reason: string | null;
    payload: Json;
    created_at: string;
  }>;
}

// --- CC-43: Dispatch Foundation types ------------------------------------
// Mirrors dispatch.dispatch_status enum and the row projections returned by
// the audience-scoped list/get RPCs.
export type DispatchStatus =
  Database["dispatch"]["Enums"]["dispatch_status"];

export interface DispatchListRow {
  id: string;
  booking_request_id: string;
  buyer_organization_id: string;
  carrier_organization_id: string;
  status: DispatchStatus;
  vehicle_reference?: string | null;
  driver_name?: string | null;
  planned_pickup_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface DispatchDetail {
  dispatch: Record<string, unknown> & {
    id: string;
    tenant_id: string;
    booking_request_id: string;
    buyer_organization_id: string;
    carrier_organization_id: string;
    status: DispatchStatus;
    vehicle_reference: string | null;
    vehicle_type: string | null;
    driver_name: string | null;
    driver_phone: string | null;
    planned_pickup_at: string | null;
    notes_fa: string | null;
    notes_en: string | null;
    created_by: string | null;
    assigned_by: string | null;
    assigned_at: string | null;
    ready_by: string | null;
    ready_at: string | null;
    released_by: string | null;
    released_at: string | null;
    cancelled_by: string | null;
    cancelled_at: string | null;
    cancelled_reason: string | null;
    created_at: string;
    updated_at: string;
    deleted_at: string | null;
    version: number;
  };
  events: Array<{
    id: string;
    dispatch_id: string;
    from_status: DispatchStatus | null;
    to_status: DispatchStatus;
    event_type: string;
    actor_party: string;
    actor_user_id: string | null;
    actor_organization_id: string | null;
    reason: string | null;
    payload: Json;
    created_at: string;
  }>;
}

// --- CC-44: Operational Control Tower types ------------------------------
// All projections are derived on-the-fly by SECURITY DEFINER RPCs in the
// `public` schema. There is no control_tower schema and no persistence.
export interface ControlTowerBuyerSummary {
  audience: "buyer";
  organization_id: string | null;
  active_shipments: number;
  pending_bookings: number;
  confirmed_bookings: number;
  active_dispatches: number;
  ready_dispatches: number;
  recent_cancellations: number;
}

export interface ControlTowerCarrierSummary {
  audience: "carrier";
  organization_id: string | null;
  incoming_pending: number;
  accepted_bookings: number;
  active_dispatches: number;
  ready_dispatches: number;
  released_recently: number;
  rejected_recently: number;
}

export interface ControlTowerAdminSummary {
  audience: "admin";
  active_shipments: number;
  pending_bookings: number;
  confirmed_bookings: number;
  active_dispatches: number;
  disputed_settlements: number;
  open_disputes: number;
  exception_count: number;
}

export interface ControlTowerActivityRow {
  event_id: string;
  source_domain: string;
  source_event: string;
  subject_id: string;
  from_status: string | null;
  to_status: string | null;
  actor_party: string | null;
  organization_id: string | null;
  created_at: string;
}

export type ControlTowerExceptionCategory =
  | "booking_stale_pending"
  | "dispatch_stale_draft"
  | "settlement_disputed"
  | "dispute_open"
  | "shipment_planned_no_booking";

export interface ControlTowerExceptionRow {
  category: ControlTowerExceptionCategory;
  subject_type: string;
  subject_id: string;
  subject_code: string | null;
  organization_id: string | null;
  severity: "info" | "warning" | "danger" | string;
  age_hours: number;
  detail_href: string;
  created_at: string;
}

// --- CC-46: Telematics map projections -----------------------------------
// Lightweight projection used by the map UI. Mirrors the columns returned by
// telematics.{buyer|carrier|admin}_list_positions / _get_telemetry_snapshot.
export interface TelematicsPosition {
  id: string;
  dispatch_id: string;
  latitude: number;
  longitude: number;
  speed_kmh: number | null;
  heading_degrees: number | null;
  reported_at: string;
  received_at?: string | null;
  source: string | null;
}

export interface TelematicsEvent {
  id: string;
  dispatch_id: string;
  event_type: string;
  actor_party: string;
  reason: string | null;
  created_at: string;
}

export interface TelematicsSnapshot {
  dispatch_id: string;
  latest_position: TelematicsPosition | null;
  recent_events: TelematicsEvent[];
}

// admin_list_active_sessions row projection.
export interface TelematicsActiveSession {
  dispatch_id: string;
  carrier_organization_id: string;
  session_started_at: string;
  last_position_at: string | null;
  latitude: number | null;
  longitude: number | null;
  age_minutes: number | null;
}

// --- CC-53: Carrier batch telemetry session status row ------------------
// One row per carrier-visible dispatch returned by
// telematics.carrier_list_my_telemetry_session_statuses. Replaces per-trip
// snapshot fan-out from the CC-50 driver trips list.
export type TelematicsStalenessStatus = "missing" | "fresh" | "stale";

export interface TelematicsCarrierSessionStatus {
  dispatch_id: string;
  shipment_id: string | null;
  session_active: boolean;
  latest_session_id: string | null;
  latest_session_started_at: string | null;
  latest_session_ended_at: string | null;
  last_position_at: string | null;
  last_latitude: number | null;
  last_longitude: number | null;
  last_accuracy_meters: number | null;
  last_source: string | null;
  last_event_type: string | null;
  last_event_at: string | null;
  position_count: number;
  event_count: number;
  staleness_status: TelematicsStalenessStatus;
}
