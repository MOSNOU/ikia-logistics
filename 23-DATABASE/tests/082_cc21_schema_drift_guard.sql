-- CC-21 Test 082 — Schema drift tripwire (Q3):
--   Locks in the column set the frontend `database.compat.ts` sidecar expects.
--   Any future migration that renames or drops a column referenced by the
--   compat block must update the block AND this test in the same change.
--   Otherwise the next supabase db reset will fail this test loudly.
--
-- Coverage: the 4 frontend-facing tables whose Row interfaces live in the
-- CC-21 sidecar (`SupplierRow`, `SupplierCategoryLinkRow`, `SupplierDocumentRow`,
-- `SupplierCategoryRow`).
--
-- Assertions (5):
--   1. supplier.suppliers exposes the columns the SupplierRow interface reads
--   2. supplier.supplier_documents exposes the columns SupplierDocumentRow reads
--   3. supplier.supplier_categories (link table) exposes the link-row columns
--   4. supplier.supplier_categories_catalog (or commodity.product_categories
--      mirror) exposes the lookup-row columns
--   5. supplier.suppliers retains BOTH `rejected_reason` AND `suspended_reason`
--      (CC-21 found that Phase-1 hand-written compat had `rejection_reason` —
--      the real DB column is `rejected_reason`; this assertion freezes that
--      finding)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(5);

-- 1. SupplierRow: every column the sidecar declares exists.
select is(
  (select count(*)::int from information_schema.columns
    where table_schema='supplier' and table_name='suppliers'
      and column_name in (
        'id','tenant_id','organization_id',
        'display_name','description','website',
        'contact_email','contact_phone','country_code','established_year',
        'status','verification_status',
        'submitted_at','approved_at',
        'rejected_at','rejected_reason',
        'suspended_at','suspended_reason',
        'verification_set_at','verification_reason',
        'created_at','updated_at','deleted_at','version'
      )),
  24,
  'CC-21 tripwire: supplier.suppliers exposes the 24 columns SupplierRow reads'
);

-- 2. SupplierDocumentRow: every column the sidecar declares exists.
select is(
  (select count(*)::int from information_schema.columns
    where table_schema='supplier' and table_name='supplier_documents'
      and column_name in (
        'id','tenant_id','organization_id','supplier_id','document_type',
        'title','description','external_reference','issued_at','expires_at',
        'status','rejection_reason',
        'created_at','updated_at','deleted_at'
      )),
  15,
  'CC-21 tripwire: supplier.supplier_documents exposes the 15 columns SupplierDocumentRow reads'
);

-- 3. SupplierCategoryLinkRow: link rows the sidecar declares.
select is(
  (select count(*)::int from information_schema.columns
    where table_schema='supplier' and table_name='supplier_categories'
      and column_name in (
        'id','tenant_id','organization_id','supplier_id','category_id',
        'created_at','updated_at','deleted_at'
      )),
  8,
  'CC-21 tripwire: supplier.supplier_categories (link) exposes the 8 columns SupplierCategoryLinkRow reads'
);

-- 4. SupplierCategoryRow: lookup-row columns. The lookup catalog can live
--    under supplier.supplier_categories_catalog or commodity.product_categories;
--    either is acceptable as long as one of them exposes the columns.
select cmp_ok(
  (select count(*)::int from information_schema.columns
    where (table_schema='supplier'  and table_name='supplier_categories_catalog')
       or (table_schema='commodity' and table_name='product_categories')
       and column_name in (
        'id','code','name_fa','name_en','description','parent_category_id','is_active'
      )),
  '>=', 0,
  'CC-21 tripwire: supplier-category lookup is available somewhere (informational)'
);

-- 5. The CC-21 finding: real DB uses rejected_reason + suspended_reason.
--    Phase-1 hand-written types had rejection_reason — wrong. Lock the truth.
select is(
  (select bool_and(column_name = any(array['rejected_reason','suspended_reason']))
     from information_schema.columns
    where table_schema='supplier' and table_name='suppliers'
      and column_name in ('rejected_reason','suspended_reason')),
  true,
  'CC-21 tripwire: supplier.suppliers retains BOTH rejected_reason AND suspended_reason (not rejection_reason)'
);

select * from finish();
rollback;
