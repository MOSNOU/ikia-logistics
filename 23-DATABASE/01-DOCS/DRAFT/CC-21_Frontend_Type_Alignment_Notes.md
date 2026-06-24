# CC-21 — Phase 2.14 Frontend Type Alignment & Build Recovery, Notes

Version: 1.0 (DRAFT)
Scope: Fifteenth platform step — frontend-only. Clear the 41 TypeScript errors that CC-20 surfaced when the canonical `supabase gen types` output replaced the Phase-1 hand-written `database.ts`. No DB migration, no SQL changes, no UI additions. **Build green again.**
Migration: **none**.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — expand compat block | Smallest diff, fastest landing. |
| Q2 | Sidecar `database.compat.ts` | Protects against regeneration loop. |
| Q3 | Yes — add `082_cc21_schema_drift_guard.sql` | 5 assertions; tripwire prevents recurrence. |
| Q4 | Fix at consumer | Mid-execution finding: the **real DB column is `rejected_reason`** — Phase-1 hand-written compat had `rejection_reason`. The "consumer fix" became "compat-block fix" because the consumer was correct and the compat was wrong. |
| Q5 | Migrate optional RPC args to `undefined` | Matches Supabase generated optional-arg semantics. |
| Q6 | Tighten selects to current columns | Aligns `.select()` strings and the consuming Row interfaces. |
| Q7 | Match canonical generated types | `string \| null` for nullable cols, not `string \| undefined`. |
| Q8 | JSX edits permitted only for field renames | No JSX edits ended up necessary — the renames lived in `database.compat.ts`. |
| Q9 | Skip interactive spot-render | `typecheck` + `build` + `route-guards` is sufficient. |
| Q10 | Stop at zero errors | No bonus refactoring. |

## What changed

### Files created

1. **`22-SOURCE-CODE/frontend-web/src/types/database.compat.ts`** (159 lines, sidecar).
   - Enum aliases re-exported from `Database["<schema>"]["Enums"]["<name>"]`.
   - Row interfaces (`AdminUserRow`, `AdminAuditRow`, `SupplierRow`, `SupplierCategoryRow`, `SupplierCategoryLinkRow`, `SupplierDocumentRow`, `AdminSupplierListRow`, `AdminSupplierDetailRow`).
   - Header comment documents the regeneration pattern: when `database.ts` is regenerated, this file stays.
2. **`23-DATABASE/tests/082_cc21_schema_drift_guard.sql`** (5 assertions).
   - Locks the column set the sidecar declares against the real DB.
   - Tripwire for future column renames.

### Files modified

| File | Change | Family |
|---|---|---|
| `22-SOURCE-CODE/frontend-web/src/types/database.ts` | Truncated to pure regenerated content (9999 lines) + 4-line `export * from "./database.compat"` barrel. | structural |
| `22-SOURCE-CODE/frontend-web/src/lib/supplier/portal-actions.ts` | 4 `\|\| null` → `\|\| undefined` at RPC arg sites (after CC-20 already fixed 7). | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/approve-user.ts` | 1 `\|\| null` → `\|\| undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/assign-role.ts` | 1 `null` → `undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/list-audit.ts` | 1 `since` → `since ?? undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/list-users.ts` | 1 `status` → `status ?? undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/create-organization.ts` | 3 `\|\| null` → `\|\| undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/list-suppliers.ts` | 2 `?? undefined`. | C |
| `22-SOURCE-CODE/frontend-web/src/lib/admin/get-supplier.ts` | 1 `as AdminSupplierDetailRow[]` → `as unknown as AdminSupplierDetailRow[]` (semantic comment added). | D |

**13 files touched, 0 SQL files touched, 0 migrations created, 0 UI routes added.**

## Mid-execution finding — Phase-1 typo direction was reversed

The CC-21 draft assumed `rejected_reason` was a Phase-1 typo (the prompt said: *"Phase-1 used `rejected_reason`, current DB uses `rejection_reason`"*). Inspection during execution found the opposite:

- **Real DB column**: `supplier.suppliers.rejected_reason` (text, nullable)
- **CC-20 compat block had**: `rejection_reason` ❌ wrong
- **Consumer code at `src/app/supplier/profile/page.tsx`**: `supplier.rejected_reason` ✓ correct

The fix landed in `database.compat.ts` rather than consumer code. Same direction also applies to `suspended_reason`. Both columns are now correctly declared in the sidecar, and the **tripwire test 082/5 locks in this finding** so a future Phase-1-style rename can't reintroduce the bug.

## Validation results

### TypeScript / build

| Check | Pre-CC-21 | Post-CC-21 |
|---|---|---|
| `npm run typecheck` | 41 errors | **0 errors** |
| `npm run build` | FAIL | **22 routes built** (exit 0) |
| `bash scripts/verify-admin-route-guards.sh` | PASSED | **VERIFICATION PASSED** |

### pgTAP suite

```
================================================================
Files: 82 passed, 0 failed
Assertions: 590 passed, 0 failed
================================================================
```

| File range | Assertions | Coverage |
|------|------------|----------|
| 001–081 | 585 | CC-05 through CC-20 (incl. acceptance) |
| **082 cc21 schema-drift guard** | **5** | **CC-21** |
| **Total** | **590** | **across 82 files** |

### Boundaries respected

- ✅ No migration created
- ✅ No SQL files outside the new test 082
- ✅ No `supabase/config.toml` change
- ✅ No new UI routes / components
- ✅ No new dependencies (`package.json` untouched)
- ✅ No re-run of `supabase gen types`
- ✅ All CC-21 directives applied per locked Q1–Q10

## Known limitations / handoff notes

1. **The compat block must be regenerated alongside `database.ts`.** The barrel re-export in `database.ts` (4 lines, clearly labeled) is the link. If `supabase gen types` is re-run, the barrel must be re-appended OR the consumer must `import from "@/types/database.compat"` directly. Test 082 will detect column drift but not the missing re-export.
2. **`AdminSupplierListRow` / `AdminSupplierDetailRow` are RPC-shaped, not table-shaped.** They mirror what `admin_list_suppliers` and `admin_get_supplier` return, not what `supplier.suppliers` exposes. A future migration that changes the RPC return shape will need both the sidecar and the consumer code updated.
3. **`get-supplier.ts` uses `as unknown as AdminSupplierDetailRow[]`** because the RPC returns a flat row that the consumer enriches with `documents`/`categories` arrays from two follow-up queries. The cast is intentional and documented inline.
4. **Tripwire 082 covers 4 tables.** If a future CC adds new row-interface types in `database.compat.ts`, extend test 082 with matching column assertions.
5. **`fn_*` helper EXECUTE-to-PUBLIC** observation from CC-20 still stands. Not addressed in CC-21 (no DB changes). Open for a future hardening CC.
6. **No frontend unit-test harness** added — outside CC-21 scope. The TypeScript compiler is the verification surface.
7. **No PostgREST runtime smoke tests** — outside CC-21 scope (CC-20 Q8 = 8a applies).

## Acceptance criteria (when you're ready to accept)

- [ ] `npm run typecheck` exits 0 in `22-SOURCE-CODE/frontend-web/`. ✓
- [ ] `npm run build` exits 0 (22 routes). ✓
- [ ] `bash 22-SOURCE-CODE/frontend-web/scripts/verify-admin-route-guards.sh` passes. ✓
- [ ] `bash 23-DATABASE/tests/run.sh` reports **82 files / 590 assertions / 0 failures**. ✓
- [ ] Confirm the sidecar pattern is acceptable (vs. eventually deleting it and migrating consumers to `Database['<schema>']['Tables']['<table>']['Row']`).
- [ ] Confirm the inline `as unknown as` cast in `get-supplier.ts` is acceptable (vs. modeling the flat RPC return as its own interface).
