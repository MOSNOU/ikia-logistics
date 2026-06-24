# CC-25 — Phase 2.18 Frontend KYC / KYB Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Nineteenth platform step. Frontend-only — wires the CC-22 `kyc.*` RPCs
through Next.js Server Actions + server-rendered pages across user, supplier,
and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all three surfaces | `/profile/kyc`, `/supplier/kyb`, `/admin/kyc(+detail)`. |
| Q2 | A — `/profile/kyc` | Reuses `/profile/page.tsx`'s per-page `getProfile()` guard pattern. |
| Q3 | A — `/supplier/kyb` | Inherits supplier layout's `requireRole(SUPPLIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN)`. |
| Q4 | A — metadata-only document forms | `attachDocument` server action passes `p_storage_path` as text. No file upload UI. |
| Q5 | A — full admin status actions | assign / request-info / approve / reject / document decisions / risk flags. |
| Q6 | A — include risk flag raise + resolve UI | Backed by `admin_raise_risk_flag` / `admin_resolve_risk_flag`. |
| Q7 | A — never render `national_id_number_hash` | Sidecar interfaces do not include the field; admin/detail page reads only `national_id_last4`. |
| Q8 | A — no notification UI | `notify.*` schema is untouched. |
| Q9 | A — verifier extended | New checks for admin kyc + detail, supplier kyb, profile kyc (per-page guard). |
| Q10 | A — stop at typecheck + build + verifier green | No manual browser smoke. |

## What changed

### Files created (16)

**Server modules (6):**

| File | Coverage |
|---|---|
| `src/lib/kyc/get-my-personal-verification.ts` | `kyc.get_my_personal_verification()` |
| `src/lib/kyc/get-my-organization-verification.ts` | `kyc.get_my_organization_verification(p_organization_id)` |
| `src/lib/kyc/portal-actions.ts` | 7 Server Actions: `startPersonal`, `updatePersonalDraft`, `submitPersonal`, `startOrganization`, `updateOrganizationDraft`, `submitOrganization`, `attachDocument` |
| `src/lib/admin/list-kyc-verifications.ts` | `kyc.admin_list_verifications` |
| `src/lib/admin/get-kyc-verification.ts` | `kyc.admin_get_verification` |
| `src/lib/admin/kyc-admin-actions.ts` | 7 Server Actions: `assignVerification`, `requestInfo`, `approveVerification`, `rejectVerification`, `decideDocument`, `raiseRiskFlag`, `resolveRiskFlag` |

**Pages + components (10):**

| Path | Purpose |
|---|---|
| `app/profile/kyc/page.tsx` | KYC status / lifecycle dispatch |
| `app/profile/kyc/start-button.tsx` | start_personal_verification |
| `app/profile/kyc/draft-form.tsx` | update_personal_draft |
| `app/profile/kyc/submit-button.tsx` | submit_personal_verification |
| `app/profile/kyc/attach-document-form.tsx` | shared by personal + KYB; takes subject_type prop |
| `app/supplier/kyb/page.tsx` | KYB status / lifecycle dispatch |
| `app/supplier/kyb/start-org-button.tsx` | start_organization_verification |
| `app/supplier/kyb/org-draft-form.tsx` | update_organization_draft |
| `app/supplier/kyb/submit-org-button.tsx` | submit_organization_verification |
| `app/admin/kyc/page.tsx` | admin queue with subject_type tabs + status filter |
| `app/admin/kyc/[subjectType]/[verificationId]/page.tsx` | detail with verification fields + documents + risk_flags + events |
| `app/admin/kyc/[subjectType]/[verificationId]/verification-actions.tsx` | assign / request-info / approve / reject buttons |
| `app/admin/kyc/[subjectType]/[verificationId]/document-actions.tsx` | accept / reject / supersede per document |
| `app/admin/kyc/[subjectType]/[verificationId]/risk-flag-actions.tsx` | raise + resolve risk flag forms |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-25: KYC / KYB portal types" section with 7 enum aliases + 7 wrapper interfaces. **No interface exposes `national_id_number_hash`** (Q7=A). |
| `scripts/verify-admin-route-guards.sh` | Header updated; added admin KYC pages + supplier KYB + Personal KYC section that verifies `getProfile()` + `redirect("/login")` pattern at `/profile/kyc/page.tsx`. |

**Files NOT touched:** all CC-01..CC-24 migrations, every `kyc.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-23 pricing code, all CC-24 portal code, every `notify.*` / `offer.*` / `contract.*` / `supplier.*` / `commodity.*` / `finance.*` / `settlement.*` / `dispute.*` surface.

### Route inventory

4 new routes:

```
/profile/kyc                                       (authenticated user — per-page guard)
/supplier/kyb                                      (supplier_admin / organization_admin / platform_admin)
/admin/kyc                                         (platform_admin)
/admin/kyc/[subjectType]/[verificationId]          (platform_admin)
```

Build route count: **35 → 39 (+4).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows | **39 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (admin + supplier + buyer + Personal KYC sections all green) |

### Type wiring

- Canonical KYC types come from regenerated `Database['kyc']['Enums'][...]` / `['Tables'][...]['Row']` shapes (no regeneration needed in CC-25).
- 7 sidecar wrapper interfaces model the projected RPC return shapes:
  - `KycSubjectDocumentRow`, `KycPersonalDetail`, `KycOrganizationDetail` (subject views — no hash field by construction)
  - `KycVerificationListRow` (admin list)
  - `KycAdminDocumentRow`, `KycRiskFlagRow`, `KycEventRow`, `KycVerificationAdminDetail` (admin detail)
- 7 enum aliases: `KycSubjectType`, `KycStatus`, `KycDocumentKind`, `KycDocumentStatus`, `KycRiskSeverity`, `KycRiskStatus`, `KycEventKind`.

## Mid-execution findings

None. CC-22's RPC argument shapes mapped cleanly to Server Action signatures on the first pass; typecheck went green without iteration; build went green on the first attempt.

## Boundaries respected

- ✅ No DB schema / RPC / RLS / grant modifications. CC-22 baseline is byte-identical.
- ✅ No new migrations.
- ✅ No government API integration.
- ✅ No sanctions / PEP / adverse-media provider.
- ✅ No biometric / liveness / OCR / file upload.
- ✅ No payment / PSP / banking / tax / insurance code.
- ✅ No `supplier.suppliers.verification_status` rewiring.
- ✅ No pricing / quotation gating; KYC status never read by pricing UI.
- ✅ No hard blocks in existing workflows.
- ✅ No client-side Supabase mutations — all writes through Server Actions.
- ✅ No notification UI.
- ✅ No new dependencies.

## Known limitations / handoff notes

1. **Document attach is metadata-only.** Subjects/admins paste a `storage_path` like `kyc-private/...`. The `kyc-private` bucket creation remains operational (CC-22 finding) — admins must create the bucket and upload bytes out-of-band before paths resolve.
2. **No `withdrawn` / `resume` for verifications.** CC-22 lifecycle does not expose these transitions; admin UI surfaces only what RPCs support.
3. **No real-time inbox or notifications.** When admin requests info, the subject sees `decision_reason` only on next page load.
4. **`/profile/kyc` reuses the per-page guard pattern from `/profile/page.tsx`.** There is no `src/app/profile/layout.tsx`. The verifier explicitly asserts `getProfile() + redirect("/login")` in `/profile/kyc/page.tsx`. Future sibling routes under `/profile/*` should follow the same pattern (or a `profile/layout.tsx` should be introduced — that would be a separate CC).
5. **`KycVerificationAdminDetail.verification` is a `Record<string, unknown>` augmented with the union of personal + organization columns.** The page reads only the columns that match the active `subjectType`. A future CC could split into two strict interfaces if value warrants.
6. **`national_id_number_hash` is hidden at three layers**: (a) revoked at GRANT level (CC-22 migration), (b) absent from the subject's `get_my_personal_verification` RPC return (CC-22), (c) absent from the sidecar admin detail shape (CC-25). Q7=A's "never render" is preserved end-to-end.
7. **Risk flag and document actions render Server Action result errors inline**, matching CC-24 pricing pattern. No global toast / notification system yet.
8. **Detail page is intentionally verbose.** Verification fields, documents, risk flags, events all rendered on the same page. A future polish CC could split into tabs.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 39 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm metadata-only document handling is acceptable for the first KYC iteration (vs. blocking on file-upload UI / `app_storage` integration).
- [ ] Confirm the per-page `/profile/kyc` guard (vs. a new `/profile/layout.tsx`) is the intended pattern.
- [ ] Confirm CC-26 may proceed.
