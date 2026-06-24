-- CC-08 / Migration 0019 — Commodity Foundation
-- Second business domain. Builds on the verified CC-01..CC-07 platform.
-- Append-only. Migrations 0001-0018 are not modified.
--
-- Security model (consistent with CC-07):
--   * RLS on every commodity table
--   * No direct INSERT/UPDATE/DELETE grants on any commodity table
--   * All mutations through SECURITY DEFINER RPCs under commodity.admin_*
--     and commodity.portal_*
--   * search_path = '' on every SECURITY DEFINER function
--   * Portal RPCs derive supplier_id from JWT via supplier.fn_portal_supplier_id()
--     and never accept a p_supplier_id parameter

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists commodity;
grant usage on schema commodity to anon, authenticated, service_role;
comment on schema commodity is
  'iKIA Phase 2 — commodity business domain: categories, products, specifications, document requirements, supplier capabilities.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type commodity.product_status as enum (
  'draft', 'active', 'inactive', 'deprecated'
);

create type commodity.physical_form as enum (
  'solid', 'liquid', 'gas', 'granule', 'powder', 'viscous', 'pellet',
  'sheet', 'bar', 'other'
);

create type commodity.spec_data_type as enum (
  'number', 'integer', 'text', 'enum', 'boolean', 'range'
);

create type commodity.document_requirement_level as enum (
  'mandatory', 'recommended', 'optional'
);

create type commodity.document_kind as enum (
  'tds', 'msds_sds', 'coa', 'product_sheet', 'packing_list',
  'certificate_of_origin', 'inspection_certificate', 'quality_certificate',
  'customs_document', 'other'
);

create type commodity.capability_status as enum (
  'active', 'paused', 'suspended', 'withdrawn'
);

-- ===========================================================================
-- 3. Tables
-- ===========================================================================

-- 3.1 categories (hierarchical, global lookup) -------------------------------
create table commodity.categories (
  id                 uuid primary key default gen_random_uuid(),
  code               citext not null unique,
  name_fa            text not null,
  name_en            text not null,
  description        text,
  parent_category_id uuid references commodity.categories(id) on delete set null,
  sort_order         integer not null default 0,
  is_active          boolean not null default true,
  metadata           jsonb not null default '{}'::jsonb,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

comment on table commodity.categories is
  'Hierarchical commodity category catalog. Seed-managed for now; admin RPCs available.';

create index commodity_categories_parent_idx on commodity.categories(parent_category_id);
create index commodity_categories_active_idx on commodity.categories(is_active);

-- 3.2 products (global lookup) ----------------------------------------------
create table commodity.products (
  id              uuid primary key default gen_random_uuid(),
  category_id     uuid not null references commodity.categories(id) on delete restrict,
  code            citext not null unique,
  slug            citext not null unique,
  name_fa         text not null,
  name_en         text not null,
  description     text,
  hs_code         text,
  cas_number      text,
  physical_form   commodity.physical_form,
  unit_of_trade   text,
  status          commodity.product_status not null default 'draft',
  metadata        jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table commodity.products is
  'Master commodity product catalog. status=active products are visible to portal listings.';

create index commodity_products_category_idx on commodity.products(category_id);
create index commodity_products_status_idx   on commodity.products(status);
create index commodity_products_hs_code_idx  on commodity.products(hs_code)
  where hs_code is not null;

-- 3.3 product_aliases --------------------------------------------------------
create table commodity.product_aliases (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references commodity.products(id) on delete cascade,
  alias      text not null,
  alias_type text not null default 'common',
  language   char(2),
  created_at timestamptz not null default now()
);

comment on table commodity.product_aliases is
  'Alternate names / synonyms for a product. Append-only.';

create index commodity_aliases_product_idx on commodity.product_aliases(product_id);
create index commodity_aliases_search_idx  on commodity.product_aliases(lower(alias));

-- 3.4 product_specifications ------------------------------------------------
create table commodity.product_specifications (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references commodity.products(id) on delete cascade,
  spec_key        citext not null,
  display_name_fa text not null,
  display_name_en text not null,
  description     text,
  data_type       commodity.spec_data_type not null,
  unit            text,
  is_required     boolean not null default false,
  min_value       numeric,
  max_value       numeric,
  enum_values     jsonb,
  default_value   text,
  sort_order      integer not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (product_id, spec_key)
);

comment on table commodity.product_specifications is
  'Per-product specification definitions. Drives future RFQ matching.';

create index commodity_specs_product_idx on commodity.product_specifications(product_id);

-- 3.5 product_document_requirements -----------------------------------------
create table commodity.product_document_requirements (
  id                 uuid primary key default gen_random_uuid(),
  product_id         uuid not null references commodity.products(id) on delete cascade,
  document_kind      commodity.document_kind not null,
  requirement_level  commodity.document_requirement_level not null default 'mandatory',
  display_name_fa    text,
  display_name_en    text,
  notes              text,
  sort_order         integer not null default 0,
  is_active          boolean not null default true,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (product_id, document_kind)
);

comment on table commodity.product_document_requirements is
  'Per-product required/recommended documents. Drives future RFQ / contract / shipment compliance checks.';

create index commodity_doc_req_product_idx on commodity.product_document_requirements(product_id);

-- 3.6 supplier_product_capabilities -----------------------------------------
create table commodity.supplier_product_capabilities (
  id                     uuid primary key default gen_random_uuid(),
  tenant_id              uuid not null references identity.tenants(id) on delete restrict,
  organization_id        uuid not null references organization.organizations(id) on delete cascade,
  supplier_id            uuid not null references supplier.suppliers(id) on delete cascade,
  product_id             uuid not null references commodity.products(id) on delete restrict,
  capability_status      commodity.capability_status not null default 'active',
  monthly_capacity       numeric,
  capacity_unit          text,
  minimum_order_quantity numeric,
  moq_unit               text,
  payment_terms_text     text,
  incoterms              jsonb not null default '[]'::jsonb,
  origin_country         char(2),
  origin_city            text,
  notes                  text,
  metadata               jsonb not null default '{}'::jsonb,
  created_by             uuid references auth.users(id),
  created_at             timestamptz not null default now(),
  updated_by             uuid references auth.users(id),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz,
  version                integer not null default 1
);

comment on table commodity.supplier_product_capabilities is
  'Declared supplier ↔ product capability. Soft-delete via deleted_at; partial unique allows revive on re-add.';

-- Partial unique on active rows so soft-deleted entries can coexist.
create unique index supplier_product_caps_unique_active
  on commodity.supplier_product_capabilities(supplier_id, product_id)
  where deleted_at is null;

create index sp_caps_supplier_idx on commodity.supplier_product_capabilities(supplier_id);
create index sp_caps_product_idx  on commodity.supplier_product_capabilities(product_id);
create index sp_caps_org_idx      on commodity.supplier_product_capabilities(organization_id);
create index sp_caps_status_idx   on commodity.supplier_product_capabilities(capability_status)
  where deleted_at is null;

-- ===========================================================================
-- 4. Seed categories (9 top-level)
-- ===========================================================================
insert into commodity.categories (code, name_fa, name_en, sort_order) values
  ('petrochemicals',       'پتروشیمی',                'Petrochemicals',          10),
  ('bitumen',              'قیر',                     'Bitumen',                 20),
  ('fuels',                'سوخت‌ها',                 'Fuels',                   30),
  ('fertilizers',          'کودها',                   'Fertilizers',             40),
  ('polymers',             'پلیمرها',                 'Polymers',                50),
  ('metals',               'فلزات',                   'Metals',                  60),
  ('minerals',             'مواد معدنی',              'Minerals',                70),
  ('agricultural',         'کالاهای کشاورزی',         'Agricultural Commodities', 80),
  ('industrial_chemicals', 'مواد شیمیایی صنعتی',      'Industrial Chemicals',    90)
on conflict (code) do nothing;

-- ===========================================================================
-- 5. Seed products (10)
-- ===========================================================================
insert into commodity.products (
  category_id, code, slug, name_fa, name_en, hs_code, cas_number,
  physical_form, unit_of_trade, status
)
select c.id, 'bitumen_60_70', 'bitumen-60-70', 'قیر ۶۰/۷۰', 'Bitumen 60/70',
       '27132000', null, 'viscous'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'bitumen'
union all
select c.id, 'bitumen_80_100', 'bitumen-80-100', 'قیر ۸۰/۱۰۰', 'Bitumen 80/100',
       '27132000', null, 'viscous'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'bitumen'
union all
select c.id, 'methanol', 'methanol', 'متانول', 'Methanol',
       '29051100', '67-56-1', 'liquid'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'petrochemicals'
union all
select c.id, 'urea', 'urea', 'اوره', 'Urea',
       '31021010', '57-13-6', 'granule'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'fertilizers'
union all
select c.id, 'ammonia', 'ammonia', 'آمونیاک', 'Ammonia',
       '28141000', '7664-41-7', 'liquid'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'petrochemicals'
union all
select c.id, 'polyethylene', 'polyethylene', 'پلی‌اتیلن', 'Polyethylene',
       '39011000', null, 'pellet'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'polymers'
union all
select c.id, 'polypropylene', 'polypropylene', 'پلی‌پروپیلن', 'Polypropylene',
       '39021000', null, 'pellet'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'polymers'
union all
select c.id, 'base_oil', 'base-oil', 'روغن پایه', 'Base Oil',
       '27101983', null, 'liquid'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'fuels'
union all
select c.id, 'fuel_oil', 'fuel-oil', 'نفت کوره', 'Fuel Oil',
       '27101900', null, 'liquid'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'fuels'
union all
select c.id, 'diesel_en590', 'diesel-en590', 'گازوئیل EN590', 'Diesel EN590',
       '27101941', null, 'liquid'::commodity.physical_form, 'ton', 'active'::commodity.product_status
  from commodity.categories c where c.code = 'fuels'
on conflict (code) do nothing;

-- ===========================================================================
-- 6. Seed document requirements (basic, conservative)
-- ===========================================================================

-- 6.1 Every active product needs COA and TDS (mandatory).
insert into commodity.product_document_requirements
  (product_id, document_kind, requirement_level, display_name_fa, display_name_en, sort_order)
select p.id,
       'coa'::commodity.document_kind,
       'mandatory'::commodity.document_requirement_level,
       'گواهی تجزیه', 'Certificate of Analysis', 10
  from commodity.products p
 where p.status = 'active'
on conflict (product_id, document_kind) do nothing;

insert into commodity.product_document_requirements
  (product_id, document_kind, requirement_level, display_name_fa, display_name_en, sort_order)
select p.id,
       'tds'::commodity.document_kind,
       'mandatory'::commodity.document_requirement_level,
       'دیتاشیت فنی', 'Technical Data Sheet', 20
  from commodity.products p
 where p.status = 'active'
on conflict (product_id, document_kind) do nothing;

-- 6.2 Products in petrochemicals / chemicals categories need MSDS.
insert into commodity.product_document_requirements
  (product_id, document_kind, requirement_level, display_name_fa, display_name_en, sort_order)
select p.id,
       'msds_sds'::commodity.document_kind,
       'mandatory'::commodity.document_requirement_level,
       'برگه اطلاعات ایمنی', 'Safety Data Sheet (MSDS / SDS)', 30
  from commodity.products p
  join commodity.categories c on c.id = p.category_id
 where c.code in ('petrochemicals', 'industrial_chemicals', 'fuels')
on conflict (product_id, document_kind) do nothing;

-- 6.3 All products: certificate of origin (recommended).
insert into commodity.product_document_requirements
  (product_id, document_kind, requirement_level, display_name_fa, display_name_en, sort_order)
select p.id,
       'certificate_of_origin'::commodity.document_kind,
       'recommended'::commodity.document_requirement_level,
       'گواهی مبدأ', 'Certificate of Origin', 40
  from commodity.products p
 where p.status = 'active'
on conflict (product_id, document_kind) do nothing;

-- 6.4 All products: packing list (optional).
insert into commodity.product_document_requirements
  (product_id, document_kind, requirement_level, display_name_fa, display_name_en, sort_order)
select p.id,
       'packing_list'::commodity.document_kind,
       'optional'::commodity.document_requirement_level,
       'لیست بسته‌بندی', 'Packing List', 50
  from commodity.products p
 where p.status = 'active'
on conflict (product_id, document_kind) do nothing;

-- ===========================================================================
-- 7. Seed specifications (illustrative, two products only — extend later)
-- ===========================================================================

insert into commodity.product_specifications (
  product_id, spec_key, display_name_fa, display_name_en, data_type,
  unit, is_required, min_value, max_value, sort_order
)
select p.id, 'penetration', 'نفوذپذیری (۲۵°C)', 'Penetration at 25°C',
       'number'::commodity.spec_data_type, '0.1 mm', true, 60, 70, 10
  from commodity.products p where p.code = 'bitumen_60_70'
union all
select p.id, 'softening_point', 'نقطه نرمی', 'Softening Point',
       'number'::commodity.spec_data_type, '°C', true, 49, 56, 20
  from commodity.products p where p.code = 'bitumen_60_70'
union all
select p.id, 'flash_point', 'نقطه اشتعال', 'Flash Point',
       'number'::commodity.spec_data_type, '°C', true, 230, null, 30
  from commodity.products p where p.code = 'bitumen_60_70'
union all
select p.id, 'purity', 'خلوص', 'Purity',
       'number'::commodity.spec_data_type, '%', true, 99.85, 100, 10
  from commodity.products p where p.code = 'methanol'
union all
select p.id, 'water_content', 'محتوای آب', 'Water Content',
       'number'::commodity.spec_data_type, '%', true, 0, 0.1, 20
  from commodity.products p where p.code = 'methanol'
on conflict (product_id, spec_key) do nothing;

-- ===========================================================================
-- 8. Internal helper: write a commodity audit event
-- ===========================================================================
create or replace function commodity.fn_audit(
  p_action_code   text,
  p_resource_id   uuid,
  p_supplier_id   uuid default null,
  p_payload       jsonb default '{}'::jsonb
) returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_t uuid;
  v_o uuid;
begin
  if p_supplier_id is not null then
    select tenant_id, organization_id into v_t, v_o
      from supplier.suppliers where id = p_supplier_id;
  end if;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'commodity', p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

comment on function commodity.fn_audit(text, uuid, uuid, jsonb) is
  'Writes a commodity-domain audit event. Audit failures are swallowed so they never block lifecycle RPCs.';

-- ===========================================================================
-- 9. Row Level Security
-- ===========================================================================
alter table commodity.categories                      enable row level security;
alter table commodity.products                        enable row level security;
alter table commodity.product_aliases                 enable row level security;
alter table commodity.product_specifications          enable row level security;
alter table commodity.product_document_requirements   enable row level security;
alter table commodity.supplier_product_capabilities   enable row level security;

-- 9.1 categories: authenticated reads; platform_admin modify backstop ------
drop policy if exists categories_select on commodity.categories;
create policy categories_select on commodity.categories
  for select
  using (auth.role() = 'authenticated');

drop policy if exists categories_modify on commodity.categories;
create policy categories_modify on commodity.categories
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 9.2 products ---------------------------------------------------------------
drop policy if exists products_select on commodity.products;
create policy products_select on commodity.products
  for select
  using (auth.role() = 'authenticated');

drop policy if exists products_modify on commodity.products;
create policy products_modify on commodity.products
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 9.3 product_aliases --------------------------------------------------------
drop policy if exists product_aliases_select on commodity.product_aliases;
create policy product_aliases_select on commodity.product_aliases
  for select
  using (auth.role() = 'authenticated');

drop policy if exists product_aliases_modify on commodity.product_aliases;
create policy product_aliases_modify on commodity.product_aliases
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 9.4 product_specifications -------------------------------------------------
drop policy if exists product_specs_select on commodity.product_specifications;
create policy product_specs_select on commodity.product_specifications
  for select
  using (auth.role() = 'authenticated');

drop policy if exists product_specs_modify on commodity.product_specifications;
create policy product_specs_modify on commodity.product_specifications
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 9.5 product_document_requirements ----------------------------------------
drop policy if exists product_doc_reqs_select on commodity.product_document_requirements;
create policy product_doc_reqs_select on commodity.product_document_requirements
  for select
  using (auth.role() = 'authenticated');

drop policy if exists product_doc_reqs_modify on commodity.product_document_requirements;
create policy product_doc_reqs_modify on commodity.product_document_requirements
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 9.6 supplier_product_capabilities -----------------------------------------
drop policy if exists sp_caps_select on commodity.supplier_product_capabilities;
create policy sp_caps_select on commodity.supplier_product_capabilities
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = commodity.supplier_product_capabilities.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists sp_caps_select_deleted on commodity.supplier_product_capabilities;
create policy sp_caps_select_deleted on commodity.supplier_product_capabilities
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists sp_caps_admin_modify on commodity.supplier_product_capabilities;
create policy sp_caps_admin_modify on commodity.supplier_product_capabilities
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- ===========================================================================
-- 10. Admin RPCs (13)
-- ===========================================================================

-- 10.1 list categories ------------------------------------------------------
create or replace function commodity.admin_list_categories(
  p_active boolean default null
)
returns table (
  id uuid, code text, name_fa text, name_en text,
  parent_category_id uuid, sort_order integer, is_active boolean,
  product_count bigint
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_categories: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select c.id, c.code::text, c.name_fa, c.name_en,
           c.parent_category_id, c.sort_order, c.is_active,
           (select count(*) from commodity.products p where p.category_id = c.id) as product_count
      from commodity.categories c
     where (p_active is null or c.is_active = p_active)
     order by c.sort_order, c.code;
end;
$$;

-- 10.2 create category ------------------------------------------------------
create or replace function commodity.admin_create_category(
  p_code               text,
  p_name_fa            text,
  p_name_en            text,
  p_parent_category_id uuid    default null,
  p_description        text    default null,
  p_sort_order         integer default 0
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_create_category: requires platform_admin' using errcode = '42501';
  end if;
  insert into commodity.categories (code, name_fa, name_en, description, parent_category_id, sort_order)
  values (p_code, p_name_fa, p_name_en, p_description, p_parent_category_id, p_sort_order)
  returning id into v_id;
  perform commodity.fn_audit('commodity.category_created', v_id, null,
    jsonb_build_object('code', p_code));
  return v_id;
end;
$$;

-- 10.3 update category ------------------------------------------------------
create or replace function commodity.admin_update_category(
  p_category_id uuid,
  p_name_fa     text    default null,
  p_name_en     text    default null,
  p_description text    default null,
  p_sort_order  integer default null,
  p_is_active   boolean default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_update_category: requires platform_admin' using errcode = '42501';
  end if;
  update commodity.categories
     set name_fa     = coalesce(p_name_fa,     name_fa),
         name_en     = coalesce(p_name_en,     name_en),
         description = coalesce(p_description, description),
         sort_order  = coalesce(p_sort_order,  sort_order),
         is_active   = coalesce(p_is_active,   is_active)
   where id = p_category_id;
  if not found then
    raise exception 'category not found' using errcode = 'P0002';
  end if;
  perform commodity.fn_audit('commodity.category_updated', p_category_id);
end;
$$;

-- 10.4 list products --------------------------------------------------------
create or replace function commodity.admin_list_products(
  p_category_id uuid                         default null,
  p_status      commodity.product_status     default null,
  p_limit       integer                      default 50,
  p_offset      integer                      default 0
)
returns table (
  id uuid, category_id uuid, category_code text, code text, slug text,
  name_fa text, name_en text, hs_code text, status text,
  spec_count bigint, doc_req_count bigint,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_products: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select p.id, p.category_id, c.code::text, p.code::text, p.slug::text,
           p.name_fa, p.name_en, p.hs_code, p.status::text,
           (select count(*) from commodity.product_specifications s
             where s.product_id = p.id and s.is_active),
           (select count(*) from commodity.product_document_requirements d
             where d.product_id = p.id and d.is_active),
           p.created_at, p.updated_at
      from commodity.products p
      join commodity.categories c on c.id = p.category_id
     where (p_category_id is null or p.category_id = p_category_id)
       and (p_status      is null or p.status      = p_status)
     order by p.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 10.5 get product (single) -------------------------------------------------
create or replace function commodity.admin_get_product(p_product_id uuid)
returns table (
  id uuid, category_id uuid, category_code text, code text, slug text,
  name_fa text, name_en text, description text,
  hs_code text, cas_number text, physical_form text,
  unit_of_trade text, status text, metadata jsonb,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_product: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select p.id, p.category_id, c.code::text, p.code::text, p.slug::text,
           p.name_fa, p.name_en, p.description,
           p.hs_code, p.cas_number, p.physical_form::text,
           p.unit_of_trade, p.status::text, p.metadata,
           p.created_at, p.updated_at
      from commodity.products p
      join commodity.categories c on c.id = p.category_id
     where p.id = p_product_id;
end;
$$;

-- 10.6 create product -------------------------------------------------------
create or replace function commodity.admin_create_product(
  p_category_id    uuid,
  p_code           text,
  p_slug           text,
  p_name_fa        text,
  p_name_en        text,
  p_hs_code        text                          default null,
  p_cas_number     text                          default null,
  p_physical_form  commodity.physical_form       default null,
  p_unit_of_trade  text                          default null,
  p_description    text                          default null,
  p_status         commodity.product_status      default 'draft'
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_create_product: requires platform_admin' using errcode = '42501';
  end if;
  insert into commodity.products (
    category_id, code, slug, name_fa, name_en, hs_code, cas_number,
    physical_form, unit_of_trade, description, status
  ) values (
    p_category_id, p_code, p_slug, p_name_fa, p_name_en, p_hs_code, p_cas_number,
    p_physical_form, p_unit_of_trade, p_description, p_status
  ) returning id into v_id;
  perform commodity.fn_audit('commodity.product_created', v_id, null,
    jsonb_build_object('code', p_code, 'category_id', p_category_id::text));
  return v_id;
end;
$$;

-- 10.7 update product -------------------------------------------------------
create or replace function commodity.admin_update_product(
  p_product_id     uuid,
  p_name_fa        text                          default null,
  p_name_en        text                          default null,
  p_description    text                          default null,
  p_hs_code        text                          default null,
  p_cas_number     text                          default null,
  p_physical_form  commodity.physical_form       default null,
  p_unit_of_trade  text                          default null,
  p_status         commodity.product_status      default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_update_product: requires platform_admin' using errcode = '42501';
  end if;
  update commodity.products
     set name_fa       = coalesce(p_name_fa,       name_fa),
         name_en       = coalesce(p_name_en,       name_en),
         description   = coalesce(p_description,   description),
         hs_code       = coalesce(p_hs_code,       hs_code),
         cas_number    = coalesce(p_cas_number,    cas_number),
         physical_form = coalesce(p_physical_form, physical_form),
         unit_of_trade = coalesce(p_unit_of_trade, unit_of_trade),
         status        = coalesce(p_status,        status)
   where id = p_product_id;
  if not found then
    raise exception 'product not found' using errcode = 'P0002';
  end if;
  perform commodity.fn_audit('commodity.product_updated', p_product_id);
end;
$$;

-- 10.8 upsert product specification ----------------------------------------
create or replace function commodity.admin_upsert_product_specification(
  p_product_id      uuid,
  p_spec_key        text,
  p_display_name_fa text,
  p_display_name_en text,
  p_data_type       commodity.spec_data_type,
  p_unit            text     default null,
  p_is_required     boolean  default false,
  p_min_value       numeric  default null,
  p_max_value       numeric  default null,
  p_enum_values     jsonb    default null,
  p_default_value   text     default null,
  p_sort_order      integer  default 0,
  p_description     text     default null
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_upsert_product_specification: requires platform_admin'
      using errcode = '42501';
  end if;
  insert into commodity.product_specifications (
    product_id, spec_key, display_name_fa, display_name_en, description,
    data_type, unit, is_required, min_value, max_value, enum_values,
    default_value, sort_order, is_active
  ) values (
    p_product_id, p_spec_key, p_display_name_fa, p_display_name_en, p_description,
    p_data_type, p_unit, p_is_required, p_min_value, p_max_value, p_enum_values,
    p_default_value, p_sort_order, true
  )
  on conflict (product_id, spec_key) do update set
    display_name_fa = excluded.display_name_fa,
    display_name_en = excluded.display_name_en,
    description     = excluded.description,
    data_type       = excluded.data_type,
    unit            = excluded.unit,
    is_required     = excluded.is_required,
    min_value       = excluded.min_value,
    max_value       = excluded.max_value,
    enum_values     = excluded.enum_values,
    default_value   = excluded.default_value,
    sort_order      = excluded.sort_order,
    is_active       = true
  returning id into v_id;
  perform commodity.fn_audit('commodity.product_spec_upserted', v_id, null,
    jsonb_build_object('product_id', p_product_id::text, 'spec_key', p_spec_key));
  return v_id;
end;
$$;

-- 10.9 remove product specification (soft via is_active=false) -------------
create or replace function commodity.admin_remove_product_specification(p_spec_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_product_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_remove_product_specification: requires platform_admin'
      using errcode = '42501';
  end if;
  update commodity.product_specifications
     set is_active = false
   where id = p_spec_id
  returning product_id into v_product_id;
  if v_product_id is null then
    raise exception 'specification not found' using errcode = 'P0002';
  end if;
  perform commodity.fn_audit('commodity.product_spec_removed', p_spec_id, null,
    jsonb_build_object('product_id', v_product_id::text));
end;
$$;

-- 10.10 upsert document requirement ----------------------------------------
create or replace function commodity.admin_upsert_product_document_requirement(
  p_product_id        uuid,
  p_document_kind     commodity.document_kind,
  p_requirement_level commodity.document_requirement_level default 'mandatory',
  p_display_name_fa   text default null,
  p_display_name_en   text default null,
  p_notes             text default null,
  p_sort_order        integer default 0
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_upsert_product_document_requirement: requires platform_admin'
      using errcode = '42501';
  end if;
  insert into commodity.product_document_requirements (
    product_id, document_kind, requirement_level, display_name_fa, display_name_en,
    notes, sort_order, is_active
  ) values (
    p_product_id, p_document_kind, p_requirement_level, p_display_name_fa, p_display_name_en,
    p_notes, p_sort_order, true
  )
  on conflict (product_id, document_kind) do update set
    requirement_level = excluded.requirement_level,
    display_name_fa   = excluded.display_name_fa,
    display_name_en   = excluded.display_name_en,
    notes             = excluded.notes,
    sort_order        = excluded.sort_order,
    is_active         = true
  returning id into v_id;
  perform commodity.fn_audit('commodity.product_doc_req_upserted', v_id, null,
    jsonb_build_object('product_id', p_product_id::text, 'document_kind', p_document_kind::text));
  return v_id;
end;
$$;

-- 10.11 remove document requirement (soft) ---------------------------------
create or replace function commodity.admin_remove_product_document_requirement(p_doc_req_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_product_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_remove_product_document_requirement: requires platform_admin'
      using errcode = '42501';
  end if;
  update commodity.product_document_requirements
     set is_active = false
   where id = p_doc_req_id
  returning product_id into v_product_id;
  if v_product_id is null then
    raise exception 'document requirement not found' using errcode = 'P0002';
  end if;
  perform commodity.fn_audit('commodity.product_doc_req_removed', p_doc_req_id, null,
    jsonb_build_object('product_id', v_product_id::text));
end;
$$;

-- 10.12 list supplier capabilities (admin review) --------------------------
create or replace function commodity.admin_list_supplier_capabilities(
  p_supplier_id uuid                              default null,
  p_product_id  uuid                              default null,
  p_status      commodity.capability_status       default null,
  p_limit       integer                           default 50,
  p_offset      integer                           default 0
)
returns table (
  id uuid, supplier_id uuid, organization_id uuid,
  product_id uuid, product_code text, product_name_en text,
  capability_status text, monthly_capacity numeric, capacity_unit text,
  origin_country text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_supplier_capabilities: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select sc.id, sc.supplier_id, sc.organization_id,
           sc.product_id, p.code::text, p.name_en,
           sc.capability_status::text, sc.monthly_capacity, sc.capacity_unit,
           sc.origin_country::text, sc.created_at, sc.updated_at
      from commodity.supplier_product_capabilities sc
      join commodity.products p on p.id = sc.product_id
     where sc.deleted_at is null
       and (p_supplier_id is null or sc.supplier_id       = p_supplier_id)
       and (p_product_id  is null or sc.product_id        = p_product_id)
       and (p_status      is null or sc.capability_status = p_status)
     order by sc.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 10.13 set capability status (admin override) -----------------------------
create or replace function commodity.admin_set_capability_status(
  p_capability_id uuid,
  p_status        commodity.capability_status
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_supplier_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_set_capability_status: requires platform_admin'
      using errcode = '42501';
  end if;
  update commodity.supplier_product_capabilities
     set capability_status = p_status,
         updated_by        = auth.uid()
   where id = p_capability_id
  returning supplier_id into v_supplier_id;
  if v_supplier_id is null then
    raise exception 'capability not found' using errcode = 'P0002';
  end if;
  perform commodity.fn_audit('commodity.capability_status_set', p_capability_id, v_supplier_id,
    jsonb_build_object('status', p_status::text));
end;
$$;

-- ===========================================================================
-- 11. Portal RPCs (5)
-- ===========================================================================

-- 11.1 list active categories (no auth scope beyond authenticated) ---------
create or replace function commodity.portal_list_categories()
returns table (
  id uuid, code text, name_fa text, name_en text,
  parent_category_id uuid, sort_order integer
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if auth.role() <> 'authenticated' then
    raise exception 'portal_list_categories: requires authenticated' using errcode = '42501';
  end if;
  return query
    select c.id, c.code::text, c.name_fa, c.name_en, c.parent_category_id, c.sort_order
      from commodity.categories c
     where c.is_active
     order by c.sort_order, c.code;
end;
$$;

-- 11.2 list active products -------------------------------------------------
create or replace function commodity.portal_list_products(
  p_category_id uuid default null
)
returns table (
  id uuid, category_id uuid, category_code text, code text, slug text,
  name_fa text, name_en text, hs_code text, physical_form text, unit_of_trade text
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if auth.role() <> 'authenticated' then
    raise exception 'portal_list_products: requires authenticated' using errcode = '42501';
  end if;
  return query
    select p.id, p.category_id, c.code::text, p.code::text, p.slug::text,
           p.name_fa, p.name_en, p.hs_code, p.physical_form::text, p.unit_of_trade
      from commodity.products p
      join commodity.categories c on c.id = p.category_id
     where p.status = 'active'
       and (p_category_id is null or p.category_id = p_category_id)
     order by p.name_en;
end;
$$;

-- 11.3 get product detail (with specs + doc requirements as JSON) ----------
create or replace function commodity.portal_get_product(p_product_id uuid)
returns table (
  id uuid, category_id uuid, category_code text, code text, slug text,
  name_fa text, name_en text, description text,
  hs_code text, cas_number text, physical_form text, unit_of_trade text,
  status text, specifications jsonb, document_requirements jsonb
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if auth.role() <> 'authenticated' then
    raise exception 'portal_get_product: requires authenticated' using errcode = '42501';
  end if;
  return query
    select p.id, p.category_id, c.code::text, p.code::text, p.slug::text,
           p.name_fa, p.name_en, p.description,
           p.hs_code, p.cas_number, p.physical_form::text, p.unit_of_trade,
           p.status::text,
           (select coalesce(jsonb_agg(jsonb_build_object(
             'spec_key', s.spec_key, 'display_name_fa', s.display_name_fa,
             'display_name_en', s.display_name_en, 'data_type', s.data_type,
             'unit', s.unit, 'is_required', s.is_required,
             'min_value', s.min_value, 'max_value', s.max_value,
             'enum_values', s.enum_values, 'sort_order', s.sort_order
           ) order by s.sort_order, s.spec_key), '[]'::jsonb)
              from commodity.product_specifications s
             where s.product_id = p.id and s.is_active) as specifications,
           (select coalesce(jsonb_agg(jsonb_build_object(
             'document_kind', d.document_kind, 'requirement_level', d.requirement_level,
             'display_name_fa', d.display_name_fa, 'display_name_en', d.display_name_en,
             'sort_order', d.sort_order
           ) order by d.sort_order, d.document_kind), '[]'::jsonb)
              from commodity.product_document_requirements d
             where d.product_id = p.id and d.is_active) as document_requirements
      from commodity.products p
      join commodity.categories c on c.id = p.category_id
     where p.id = p_product_id and p.status = 'active';
end;
$$;

-- 11.4 portal_upsert_my_capability (no p_supplier_id; derives from JWT) ----
create or replace function commodity.portal_upsert_my_capability(
  p_product_id             uuid,
  p_capability_status      commodity.capability_status default 'active',
  p_monthly_capacity       numeric  default null,
  p_capacity_unit          text     default null,
  p_minimum_order_quantity numeric  default null,
  p_moq_unit               text     default null,
  p_payment_terms_text     text     default null,
  p_incoterms              jsonb    default null,
  p_origin_country         char(2)  default null,
  p_origin_city            text     default null,
  p_notes                  text     default null
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_tenant      uuid;
  v_org         uuid;
  v_existing    uuid;
  v_revived     boolean := false;
  v_id          uuid;
begin
  -- Capacity to derive tenant/org from the supplier record.
  select tenant_id, organization_id into v_tenant, v_org
    from supplier.suppliers where id = v_supplier_id;

  -- Verify product is active and exists.
  if not exists (
    select 1 from commodity.products
     where id = p_product_id and status = 'active'
  ) then
    raise exception 'product not found or inactive' using errcode = 'P0002';
  end if;

  -- 1) Revive a soft-deleted row, if any.
  update commodity.supplier_product_capabilities
     set deleted_at             = null,
         capability_status      = p_capability_status,
         monthly_capacity       = p_monthly_capacity,
         capacity_unit          = p_capacity_unit,
         minimum_order_quantity = p_minimum_order_quantity,
         moq_unit               = p_moq_unit,
         payment_terms_text     = p_payment_terms_text,
         incoterms              = coalesce(p_incoterms, '[]'::jsonb),
         origin_country         = p_origin_country,
         origin_city            = p_origin_city,
         notes                  = p_notes,
         updated_by             = v_actor
   where supplier_id = v_supplier_id
     and product_id  = p_product_id
     and deleted_at is not null
  returning id into v_id;

  if v_id is not null then
    v_revived := true;
  else
    -- 2) Update active row or insert.
    select id into v_existing
      from commodity.supplier_product_capabilities
     where supplier_id = v_supplier_id
       and product_id  = p_product_id
       and deleted_at is null;

    if v_existing is not null then
      update commodity.supplier_product_capabilities
         set capability_status      = p_capability_status,
             monthly_capacity       = p_monthly_capacity,
             capacity_unit          = p_capacity_unit,
             minimum_order_quantity = p_minimum_order_quantity,
             moq_unit               = p_moq_unit,
             payment_terms_text     = p_payment_terms_text,
             incoterms              = coalesce(p_incoterms, incoterms),
             origin_country         = p_origin_country,
             origin_city            = p_origin_city,
             notes                  = p_notes,
             updated_by             = v_actor
       where id = v_existing;
      v_id := v_existing;
    else
      insert into commodity.supplier_product_capabilities (
        tenant_id, organization_id, supplier_id, product_id,
        capability_status, monthly_capacity, capacity_unit,
        minimum_order_quantity, moq_unit, payment_terms_text,
        incoterms, origin_country, origin_city, notes,
        created_by, updated_by
      ) values (
        v_tenant, v_org, v_supplier_id, p_product_id,
        p_capability_status, p_monthly_capacity, p_capacity_unit,
        p_minimum_order_quantity, p_moq_unit, p_payment_terms_text,
        coalesce(p_incoterms, '[]'::jsonb), p_origin_country, p_origin_city, p_notes,
        v_actor, v_actor
      ) returning id into v_id;
    end if;
  end if;

  perform commodity.fn_audit(
    'commodity.capability_upserted', v_id, v_supplier_id,
    jsonb_build_object(
      'product_id', p_product_id::text,
      'revived',    v_revived
    )
  );
  return v_id;
end;
$$;

-- 11.5 portal_remove_my_capability (soft-delete) ---------------------------
create or replace function commodity.portal_remove_my_capability(p_product_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_id          uuid;
begin
  update commodity.supplier_product_capabilities
     set deleted_at = now(),
         updated_by = v_actor
   where supplier_id = v_supplier_id
     and product_id  = p_product_id
     and deleted_at is null
  returning id into v_id;

  if v_id is null then
    return;  -- already removed or never existed; idempotent no-op
  end if;

  perform commodity.fn_audit(
    'commodity.capability_removed', v_id, v_supplier_id,
    jsonb_build_object('product_id', p_product_id::text)
  );
end;
$$;

-- ===========================================================================
-- 12. Trigger attachments (set_updated_at + audit)
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
      join information_schema.columns c
        on c.table_schema = t.table_schema and c.table_name = t.table_name
     where t.table_schema = 'commodity'
       and t.table_type   = 'BASE TABLE'
       and c.column_name  = 'updated_at'
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on %I.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
     where t.table_schema = 'commodity'
       and t.table_type   = 'BASE TABLE'
       and exists (
         select 1 from information_schema.columns c
          where c.table_schema = t.table_schema
            and c.table_name   = t.table_name
            and c.column_name  = 'id'
       )
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on %I.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 13. Grants (SELECT only on tables; no INSERT/UPDATE/DELETE)
-- ===========================================================================

-- Lookup tables: authenticated only (NOT anon, consistent with CC-07 categories pattern).
grant select on commodity.categories                    to authenticated;
grant select on commodity.products                      to authenticated;
grant select on commodity.product_aliases               to authenticated;
grant select on commodity.product_specifications        to authenticated;
grant select on commodity.product_document_requirements to authenticated;

-- supplier_product_capabilities: SELECT to anon (RLS=0 rows) + authenticated (RLS filters by org).
grant select on commodity.supplier_product_capabilities to anon, authenticated;

-- ===========================================================================
-- 14. RPC EXECUTE grants
-- ===========================================================================
grant execute on function commodity.admin_list_categories(boolean) to authenticated;
grant execute on function commodity.admin_create_category(text, text, text, uuid, text, integer) to authenticated;
grant execute on function commodity.admin_update_category(uuid, text, text, text, integer, boolean) to authenticated;
grant execute on function commodity.admin_list_products(uuid, commodity.product_status, integer, integer) to authenticated;
grant execute on function commodity.admin_get_product(uuid) to authenticated;
grant execute on function commodity.admin_create_product(uuid, text, text, text, text, text, text, commodity.physical_form, text, text, commodity.product_status) to authenticated;
grant execute on function commodity.admin_update_product(uuid, text, text, text, text, text, commodity.physical_form, text, commodity.product_status) to authenticated;
grant execute on function commodity.admin_upsert_product_specification(uuid, text, text, text, commodity.spec_data_type, text, boolean, numeric, numeric, jsonb, text, integer, text) to authenticated;
grant execute on function commodity.admin_remove_product_specification(uuid) to authenticated;
grant execute on function commodity.admin_upsert_product_document_requirement(uuid, commodity.document_kind, commodity.document_requirement_level, text, text, text, integer) to authenticated;
grant execute on function commodity.admin_remove_product_document_requirement(uuid) to authenticated;
grant execute on function commodity.admin_list_supplier_capabilities(uuid, uuid, commodity.capability_status, integer, integer) to authenticated;
grant execute on function commodity.admin_set_capability_status(uuid, commodity.capability_status) to authenticated;

grant execute on function commodity.portal_list_categories() to authenticated;
grant execute on function commodity.portal_list_products(uuid) to authenticated;
grant execute on function commodity.portal_get_product(uuid) to authenticated;
grant execute on function commodity.portal_upsert_my_capability(
  uuid, commodity.capability_status, numeric, text, numeric, text, text, jsonb, char, text, text
) to authenticated;
grant execute on function commodity.portal_remove_my_capability(uuid) to authenticated;
