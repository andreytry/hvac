-- HVAC BOC — Seed Data
-- Run after schema.sql

insert into hvac.config (key, value, description) values
  ('push_email',              'andrewtry002@gmail.com', 'Where qualified leads are pushed'),
  ('business_phone',          'PENDING',                'Inbound business number'),
  ('emergency_surcharge_pct', '25',                     '% added to estimate for emergency calls'),
  ('currency',                'USD',                    'Estimate currency'),
  ('business_name',           'South Flow Air',         'Company name')
on conflict (key) do update set value = excluded.value, updated_at = now();

insert into hvac.pricing (service_code, service_name, category, unit, price_min, price_max) values
  ('DIAG',              'Diagnostic / Service Call', 'service',  'flat',  89,    149),
  ('AC_REPAIR',         'AC Repair',                 'cooling',  'flat',  150,   650),
  ('AC_INSTALL',        'AC Installation',           'cooling',  'flat',  3500,  7500),
  ('FURNACE_REPAIR',    'Furnace Repair',             'heating',  'flat',  150,   700),
  ('FURNACE_INSTALL',   'Furnace Installation',       'heating',  'flat',  3000,  6500),
  ('HEAT_PUMP_INSTALL', 'Heat Pump Installation',     'heating',  'flat',  4500,  9000),
  ('MINISPLIT_INSTALL', 'Mini-Split Installation',    'cooling',  'flat',  2000,  5000),
  ('TUNEUP',            'Maintenance Tune-Up',        'service',  'flat',  89,    199),
  ('DUCT_CLEAN',        'Duct Cleaning',              'air',      'flat',  300,   700),
  ('THERMOSTAT',        'Thermostat Install',         'controls', 'flat',  150,   400),
  ('REFRIGERANT',       'Refrigerant Recharge',       'cooling',  'flat',  200,   600),
  ('EMERGENCY',         'Emergency Call-Out',         'service',  'flat',  150,   350)
on conflict (service_code) do nothing;
