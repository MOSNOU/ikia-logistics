-- CC-08 Test 024 — Commodity seed data consistency.
--
-- Assertions (7):
--   1. 9 categories seeded with the expected codes
--   2. 10 active products seeded
--   3. Every seeded product has at least one document requirement
--   4. Every seeded product has at least 2 mandatory document requirements
--      (COA + TDS minimum)
--   5. Petrochemicals / industrial_chemicals / fuels products carry MSDS_SDS
--      as mandatory
--   6. Bitumen 60/70 has at least 3 active specifications
--   7. Every seeded product references an existing category

set search_path = extensions, public, identity, organization, audit, commodity, tests;
begin;

select plan(7);

select is(
  (select count(*)::int from commodity.categories
    where code in (
      'petrochemicals','bitumen','fuels','fertilizers','polymers',
      'metals','minerals','agricultural','industrial_chemicals'
    )),
  9,
  '9 expected commodity categories seeded'
);

select is(
  (select count(*)::int from commodity.products where status = 'active'),
  10,
  '10 active commodity products seeded'
);

select is(
  (select count(*)::int from commodity.products p
    where p.status = 'active'
      and not exists (
        select 1 from commodity.product_document_requirements d
         where d.product_id = p.id and d.is_active
      )),
  0,
  'every seeded product has at least one document requirement'
);

select is(
  (select count(*)::int from commodity.products p
    where p.status = 'active'
      and (select count(*) from commodity.product_document_requirements d
            where d.product_id = p.id
              and d.requirement_level = 'mandatory'
              and d.is_active) < 2),
  0,
  'every seeded product has at least 2 mandatory document requirements'
);

select is(
  (select count(*)::int from commodity.products p
     join commodity.categories c on c.id = p.category_id
    where c.code in ('petrochemicals','industrial_chemicals','fuels')
      and p.status = 'active'
      and not exists (
        select 1 from commodity.product_document_requirements d
         where d.product_id = p.id
           and d.document_kind = 'msds_sds'
           and d.requirement_level = 'mandatory'
           and d.is_active
      )),
  0,
  'every petrochemicals/chemicals/fuels product carries mandatory MSDS_SDS'
);

select cmp_ok(
  (select count(*)::int from commodity.product_specifications s
     join commodity.products p on p.id = s.product_id
    where p.code = 'bitumen_60_70' and s.is_active),
  '>=', 3,
  'Bitumen 60/70 has at least 3 active specifications'
);

select is(
  (select count(*)::int from commodity.products p
    where not exists (
      select 1 from commodity.categories c where c.id = p.category_id
    )),
  0,
  'every seeded product references an existing category'
);

select * from finish();
rollback;
