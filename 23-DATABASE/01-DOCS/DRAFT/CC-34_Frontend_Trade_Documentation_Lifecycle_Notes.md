# CC-34 — Frontend Trade Documentation Lifecycle Portal (Buyer Mutations + File Attachments)

## Mission
Promote CC-33's read-only Trade Documentation surface to a full lifecycle portal:
buyer-side document requirement management, document upserts (kind / status /
dates / refs / notes, with requirement and item linking), and file attachments
on shipment documents — all via Server Actions over existing RPCs.

## Scope (Q1–Q10 accepted)
- **Q1** Server Actions only against `shipment.buyer_upsert_doc_requirement`,
  `shipment.buyer_upsert_document`, `app_storage.portal_*`.
- **Q2** Buyer-side requirements list + edit at
  `/buyer/shipments/[id]/requirements` (+ `/[reqId]/edit`).
- **Q3** Two document upsert entry points: `/buyer/documents/new` and
  `/buyer/documents/[id]/edit`.
- **Q4** File attachments at `/buyer/documents/[id]/files`:
  `portal_register_file` → signed PUT to Storage → `portal_finalize_file_upload`
  → `portal_link_file_to_entity` (entity_type = `shipment_document`).
- **Q5** *Adapted from default.* Plan-time default said "Zod schemas"; the
  project has no `zod` dependency. Implemented as plain-TS validation helpers
  (`schemas.ts`) returning `{ ok, value? | error?, fieldErrors? }`, matching
  the existing `buyer-actions.ts` pattern. No new dependency added.
- **Q6** Status transitions surfaced as a dropdown on the edit form
  (`pending → available → expired / rejected / archived`); RPC enforces.
- **Q7** Supplier & admin views unchanged from CC-33 (read-only).
- **Q8** Persian-first labels via `labels.ts` (`docKindLabel`, etc.); RTL
  preserved.
- **Q9** Verifier extended with five CC-34 buyer routes.
- **Q10** Gates unchanged from CC-33: pgTAP unchanged → typecheck → build → verifier.

## Do-Not-Build (literal — observed)
- No DB schema / migration / RPC / RLS / grant / trigger / business-logic changes.
- No supplier or admin mutation paths on documents/files (the RPCs do not exist).
- No client-side Supabase **mutations** — the only client-side step is the
  signed-URL PUT to Storage, which is binary-only.
- No bulk import, no template generation, no PDF rendering, no OCR.
- No CC-35 work.

## Files added

### Server modules (`src/lib/trade-document/`)
- `schemas.ts` — validation helpers + enum value arrays
  (`DOC_KIND_VALUES`, `DOC_STATUS_VALUES`, `REQUIREMENT_LEVEL_VALUES`) plus
  `parseRequirementForm`, `parseDocumentForm`, `parseFileRegisterForm`.
- `actions-buyer.ts` — `upsertDocRequirement`, `upsertBuyerDocument`,
  `archiveBuyerDocument` (the archive action is a thin wrapper over
  `buyer_upsert_document` with `p_document_status = 'archived'` and the
  `p_document_id` set).
- `actions-files.ts` — `registerFileForDocument`, `finalizeDocumentFile`,
  `archiveDocumentFile`, `createDocumentFileVersion`, `listDocumentFiles`.
  `register*` and `createVersion*` return a signed upload URL so the client
  can PUT the binary without holding Supabase credentials.
- `list-document-requirements.ts` — `listShipmentDocumentRequirements`,
  `getShipmentDocumentRequirement` (direct SELECT on
  `shipment_document_requirements` via RLS).

### Components (`src/components/trade-document/`)
- `doc-requirement-form.tsx` — kind / level / display names / notes.
- `document-upsert-form.tsx` — kind / status / external_ref / issued_at /
  expires_at / requirementId / shipmentItemId / notes. Same form serves create
  and edit (driven by optional `documentId` prop).
- `document-file-upload.tsx` — client component that calls the register /
  create-version Server Action, then PUTs via the returned signed URL, then
  calls finalize. Same component serves first-upload and new-version flows
  (driven by `existingFileId` prop).
- `document-file-list.tsx` — file table with inline archive action.

### Routes
| Route | Purpose |
|---|---|
| `/buyer/shipments/[id]/requirements` | Requirements list + add/update form. |
| `/buyer/shipments/[id]/requirements/[reqId]/edit` | Single requirement edit. |
| `/buyer/documents/new?shipmentId=...` or `?requirementId=...` | New document. |
| `/buyer/documents/[id]/edit` | Edit existing document. |
| `/buyer/documents/[id]/files` | Attach files + new versions + archive. |

### Verifier
`scripts/verify-admin-route-guards.sh` — CC-34 block added under the buyer
section (5 routes). Header comment bumped to include CC-34.

## Validation results

| Gate | Result |
|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 — unchanged |
| `npm run typecheck` | 0 errors |
| `npm run build` | exit 0; all 5 CC-34 routes present in the Next route table |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED |

## Architectural notes for future CCs

- **Validation library.** Q5 was adapted away from Zod because the codebase
  has no Zod dep. If Zod is later adopted (e.g., as part of a broader form
  hardening CC), `schemas.ts` is the natural place to swap in Zod schemas —
  the action signatures wouldn't change.
- **Storage bucket.** Hardcoded to `app-documents` (the RPC default), matching
  CC-15's foundation. If a per-tenant bucket policy is later introduced, only
  `actions-files.ts` and `portal_register_file` callers need to change.
- **Supplier/admin mutations.** Still blocked by RPC surface (no
  `supplier_upsert_document` / `admin_force_archive_document`). A future DB CC
  could open these; the frontend Server Actions can then mirror the buyer
  ones with audience-discriminated dispatch.
- **Document archive UX.** Archive is currently a status transition through
  `buyer_upsert_document`. If a hard archive RPC is introduced later, the
  `archiveBuyerDocument` action can switch without touching the UI.
- **Coexistence with CC-31's `UpsertDocumentForm`.** CC-31 left an in-line
  buyer document-creation form on `/buyer/shipments/[id]`. It now coexists
  with the richer `/buyer/documents/new` flow — the CC-31 form is a fast-path
  (kind / ref / dates / notes only), and the new route is the full surface
  (adds status, requirement linking, item linking, and edit support). Both
  call the same underlying RPC. A future cleanup CC could collapse them.
