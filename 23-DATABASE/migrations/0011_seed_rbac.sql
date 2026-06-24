-- CC-03 / Migration 0011
-- Seed: 9 system roles, permission registry, role-permission map.
-- Idempotent on (code) via ON CONFLICT.

insert into identity.roles (code, scope, label_fa, label_en, description, is_system) values
  ('platform_admin',     'platform',     'مدیر پلتفرم',          'Platform Admin',     'Highest access across all tenants.',                    true),
  ('organization_admin', 'organization', 'مدیر سازمان',          'Organization Admin', 'Full control within a single organization.',            true),
  ('supplier_admin',     'organization', 'مدیر تأمین‌کننده',     'Supplier Admin',     'Manages supplier organization data, commodities and offers.', true),
  ('buyer_admin',        'organization', 'مدیر خریدار',          'Buyer Admin',        'Manages buyer organization RFQs, offers and contracts.', true),
  ('carrier_admin',      'organization', 'مدیر حمل‌کننده',       'Carrier Admin',      'Manages carrier organization fleet, loads and tracking.', true),
  ('compliance_officer', 'organization', 'افسر تطبیق',           'Compliance Officer', 'Read access across all domains for compliance audit.',  true),
  ('finance_officer',    'organization', 'افسر مالی',            'Finance Officer',    'Manages financial operations and settlement.',          true),
  ('operations_user',    'organization', 'کاربر عملیات',         'Operations User',    'Day-to-day operational read/write within scope.',       true),
  ('readonly_user',      'organization', 'کاربر فقط‌خواندنی',    'Readonly User',      'Read-only access within scope.',                        true)
on conflict (code) do nothing;

insert into identity.permissions (code, domain, action, label_fa, label_en) values
  ('supplier.read',       'supplier',  'read',     'مشاهده تأمین‌کننده',   'Read supplier'),
  ('supplier.write',      'supplier',  'write',    'ویرایش تأمین‌کننده',   'Write supplier'),
  ('commodity.read',      'commodity', 'read',     'مشاهده کالا',          'Read commodity'),
  ('commodity.write',     'commodity', 'write',    'ویرایش کالا',          'Write commodity'),
  ('rfq.create',          'rfq',       'create',   'ایجاد درخواست خرید',   'Create RFQ'),
  ('rfq.read',            'rfq',       'read',     'مشاهده درخواست خرید',  'Read RFQ'),
  ('rfq.write',           'rfq',       'write',    'ویرایش درخواست خرید',  'Write RFQ'),
  ('offer.submit',        'offer',     'submit',   'ارسال پیشنهاد',        'Submit offer'),
  ('offer.read',          'offer',     'read',     'مشاهده پیشنهاد',       'Read offer'),
  ('contract.read',       'contract',  'read',     'مشاهده قرارداد',       'Read contract'),
  ('contract.sign',       'contract',  'sign',     'امضای قرارداد',        'Sign contract'),
  ('logistics.read',      'logistics', 'read',     'مشاهده لجستیک',        'Read logistics'),
  ('logistics.write',     'logistics', 'write',    'ویرایش لجستیک',        'Write logistics'),
  ('tracking.read',       'tracking',  'read',     'مشاهده ردیابی',        'Read tracking'),
  ('finance.read',        'finance',   'read',     'مشاهده مالی',          'Read finance'),
  ('finance.write',       'finance',   'write',    'ویرایش مالی',          'Write finance'),
  ('knowledge.read',      'knowledge', 'read',     'مشاهده دانش',          'Read knowledge'),
  ('knowledge.write',     'knowledge', 'write',    'ویرایش دانش',          'Write knowledge'),
  ('admin.platform',      'admin',     'platform', 'مدیریت پلتفرم',        'Admin platform'),
  ('admin.organization',  'admin',     'organization', 'مدیریت سازمان',    'Admin organization'),
  ('admin.tenant',        'admin',     'tenant',   'مدیریت تننت',          'Admin tenant')
on conflict (code) do nothing;

-- platform_admin: every permission
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'platform_admin'
on conflict do nothing;

-- organization_admin: everything except platform/tenant admin
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'organization_admin'
   and p.code not in ('admin.platform', 'admin.tenant')
on conflict do nothing;

-- supplier_admin
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'supplier_admin'
   and p.code in (
     'supplier.read', 'supplier.write',
     'commodity.read', 'commodity.write',
     'offer.submit',   'offer.read',
     'rfq.read',
     'contract.read',
     'finance.read'
   )
on conflict do nothing;

-- buyer_admin
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'buyer_admin'
   and p.code in (
     'rfq.create', 'rfq.read', 'rfq.write',
     'offer.read',
     'contract.read', 'contract.sign',
     'logistics.read', 'tracking.read',
     'finance.read'
   )
on conflict do nothing;

-- carrier_admin
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'carrier_admin'
   and p.code in (
     'logistics.read', 'logistics.write',
     'tracking.read',
     'finance.read'
   )
on conflict do nothing;

-- compliance_officer: every read permission
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'compliance_officer'
   and p.action = 'read'
on conflict do nothing;

-- finance_officer
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'finance_officer'
   and p.code in (
     'finance.read', 'finance.write',
     'contract.read',
     'logistics.read'
   )
on conflict do nothing;

-- operations_user
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'operations_user'
   and p.code in (
     'rfq.read', 'offer.read', 'contract.read',
     'logistics.read', 'logistics.write',
     'tracking.read'
   )
on conflict do nothing;

-- readonly_user
insert into identity.role_permissions (role_id, permission_id)
select r.id, p.id
  from identity.roles r
 cross join identity.permissions p
 where r.code = 'readonly_user'
   and p.code in (
     'supplier.read', 'commodity.read',
     'rfq.read', 'offer.read',
     'contract.read',
     'logistics.read', 'tracking.read'
   )
on conflict do nothing;
