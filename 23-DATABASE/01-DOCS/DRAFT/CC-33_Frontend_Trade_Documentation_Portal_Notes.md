# CC-33 — Frontend Trade Documentation & Compliance Portal Foundation

## Mission
Frontend-only surface for shipping documents (commercial invoice, packing list,
bill of lading, certificate of origin, certificate of insurance, certificate of
inspection, customs & transit documents) across buyer / supplier / admin
portals. Read-only foundation — no document upload, no status mutations, no DB
changes.

## Scope (Q1–Q10 defaults)
- **Q1** Audience routing: per-portal pages with shared detail card.
- **Q2** Data source: `shipment.shipment_documents` table (RLS-driven SELECT for
  buyer/admin; supplier surfaces shipment summary list and drills into the
  CC-31 per-shipment view).
- **Q3** Filters: document kind, document status, shipment id (buyer/admin),
  organization id (admin only).
- **Q4** Pagination: deterministic 25-row pages by `updated_at desc, id desc`.
- **Q5** Labels: Persian-first with English fallback (`labels.ts` module).
- **Q6** No mutations: read-only foundation; status transitions and uploads are
  deferred to a future CC.
- **Q7** Reuse: CC-21 sidecar pattern for `TradeDocumentRow`, CC-31 shipment
  links, existing `requireRole` portal layouts.
- **Q8** Cross-shipment aggregation via PostgREST embed
  (`shipments(id, shipment_code, status, supplier_id, executed_contract_id,
  organization_id, transport_mode)`) — single round-trip, no N+1.
- **Q9** Supplier RLS workaround: list shipments via
  `shipment.supplier_list_my_shipments` RPC and link to existing
  `/supplier/shipments/[id]` page for per-shipment document inspection.
- **Q10** Validation gates unchanged from CC-32: pgTAP unchanged → typecheck → build → verifier.

## Do-Not-Build (literal)
- No DB schema / migration / RPC / RLS / grant / trigger changes.
- No new business logic. No status mutations on `shipment_documents`.
- No client-side Supabase mutations. Server components only.
- No file upload, no storage interaction.
- No CC-34 work — stop after final validation report.

## Files added

### Server modules (`src/lib/trade-document/`)
- `list-buyer-documents.ts` — `listBuyerTradeDocuments`,
  `getBuyerTradeDocument`. Direct SELECT on `shipment_documents` with embedded
  `shipments(...)`. RLS scopes rows to the buyer's organization.
- `list-supplier-documents.ts` — `listSupplierTradeDocuments`. Wraps existing
  `shipment.supplier_list_my_shipments` RPC and maps results into
  `SupplierShipmentDocSummary`. Drill-in pattern — does not query
  `shipment_documents` directly because supplier RLS may not permit it.
- `list-admin-documents.ts` — `listAdminTradeDocuments`,
  `getAdminTradeDocument`. Direct SELECT, admin RLS bypass. Adds
  `organization_id` filter for cross-tenant queue work.
- `labels.ts` — shared `DOC_KIND_OPTIONS`, `DOC_STATUS_OPTIONS`,
  `docKindLabel`, `docStatusLabel`. Persian-first labels with English fallback
  via raw enum value.

### Shared component
- `src/components/trade-document/document-detail-card.tsx` —
  `DocumentDetailCard` props `{ doc, audience }`. Renders kind/status, all
  metadata fields, shipment cross-link (audience-switched
  `/buyer/shipments/...` vs `/admin/shipments/...`), and a collapsed JSON view
  of `metadata`.

### Routes
| Route | Audience | Purpose |
|---|---|---|
| `/buyer/documents` | buyer | Cross-shipment document list with kind/status/shipmentId filters. |
| `/buyer/documents/[id]` | buyer | Single document detail. |
| `/supplier/trade-documents` | supplier | Read-only shipment summary list; drills into `/supplier/shipments/[id]`. |
| `/admin/documents` | admin | Cross-tenant queue with kind/status/shipmentId/organizationId filters. |
| `/admin/documents/[id]` | admin | Single document detail with admin shipment link. |

Naming note: existing `/supplier/documents` route (CC-07: supplier profile docs
— license, tax cert, registration) was preserved untouched. CC-33's supplier
surface deliberately uses `/supplier/trade-documents` to avoid name collision.

### Verifier
`scripts/verify-admin-route-guards.sh` extended with three CC-33 blocks:
- `/admin/documents`, `/admin/documents/[id]`
- `/supplier/trade-documents`
- `/buyer/documents`, `/buyer/documents/[id]`

### Sidecar types (`src/types/database.compat.ts`)
- `TradeDocumentRow` — row shape from
  `shipment_documents.select(... , shipments(...))`, including all columns plus
  embedded shipment summary.
- `SupplierShipmentDocSummary` — projection used by the supplier shipment
  summary list.

## Validation results

| Gate | Result |
|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 files / 790 assertions / 0 failures (unchanged) |
| `npm run typecheck` | 0 errors |
| `npm run build` | exit 0 — all 5 CC-33 routes present in route table |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED |

## Architectural notes for future CCs

- Document upload + status mutations are intentionally out of scope. A future
  CC introducing those should expose Server Actions named consistently with
  CC-30/CC-31 patterns (`uploadShipmentDocument`, `markDocumentAvailable`,
  etc.) and continue to flow through `shipment_documents` with whatever
  RPC/RLS additions the DB layer needs.
- Supplier direct SELECT on `shipment_documents` is currently routed through
  the drill-in pattern. If supplier RLS is later widened to permit
  cross-shipment reads, the supplier page can switch to the same direct SELECT
  pattern used by the buyer surface — the `TradeDocumentRow` projection is
  ready.
- `DocumentDetailCard` is portal-agnostic and audience-switched at the
  `shipmentHref` only. Adding a supplier-side detail route in the future is a
  one-line swap (`audience: "supplier"` discriminator).
