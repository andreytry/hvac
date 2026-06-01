-- HVAC BOC — Full Schema
-- Supabase project: zkylrolpuwybsksspblj (MyScheduler)
-- Run this first, then seed.sql

create schema if not exists hvac;
create extension if not exists http with schema extensions;

create table hvac.config (
  id bigint generated always as identity primary key,
  key text unique not null, value text, description text,
  updated_at timestamptz not null default now()
);

create table hvac.pricing (
  id bigint generated always as identity primary key,
  service_code text unique not null, service_name text not null,
  category text, unit text not null default 'flat',
  price_min numeric(10,2) not null, price_max numeric(10,2) not null,
  active boolean not null default true, notes text,
  created_at timestamptz not null default now()
);

create table hvac.leads (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  source text not null default 'phone',
  contact_name text, phone text, email text,
  service_requested text,
  matched_service_id bigint references hvac.pricing(id),
  description text, property_type text, system_age_years int,
  urgency text default 'standard',
  qualification_status text not null default 'needs_review',
  qualification_reason text,
  estimate_low numeric(10,2), estimate_high numeric(10,2),
  estimate_currency text not null default 'USD',
  status text not null default 'new',
  push_to_email text, pushed boolean not null default false, pushed_at timestamptz
);

create index leads_status_idx  on hvac.leads(status);
create index leads_qual_idx    on hvac.leads(qualification_status);
create index leads_created_idx on hvac.leads(created_at desc);

-- AUTO QUALIFY + ESTIMATE ON INSERT
create or replace function hvac.qualify_and_estimate()
returns trigger language plpgsql as $$
declare
  v_service hvac.pricing%rowtype;
  v_surcharge numeric := 0;
  v_reasons text[] := array[]::text[];
begin
  if coalesce(new.phone,'') = '' then v_reasons := array_append(v_reasons,'missing phone'); end if;
  if coalesce(new.email,'') = '' then v_reasons := array_append(v_reasons,'missing email'); end if;
  if coalesce(new.service_requested,'') = '' then v_reasons := array_append(v_reasons,'missing service'); end if;

  select * into v_service from hvac.pricing p
  where p.active and (
    lower(p.service_code) = lower(new.service_requested)
    or lower(p.service_name) = lower(new.service_requested)
    or new.service_requested ilike '%'||p.service_name||'%'
    or p.service_name ilike '%'||new.service_requested||'%'
  ) order by p.price_min limit 1;

  if found then
    new.matched_service_id := v_service.id;
    new.estimate_low  := v_service.price_min;
    new.estimate_high := v_service.price_max;
    if new.urgency = 'emergency' then
      select coalesce(nullif(value,'')::numeric,0) into v_surcharge
      from hvac.config where key = 'emergency_surcharge_pct';
      new.estimate_low  := round(new.estimate_low  * (1 + coalesce(v_surcharge,0)/100.0), 2);
      new.estimate_high := round(new.estimate_high * (1 + coalesce(v_surcharge,0)/100.0), 2);
    end if;
  else
    v_reasons := array_append(v_reasons,'no pricing match');
  end if;

  if array_length(v_reasons,1) is null then
    new.qualification_status := 'qualified';
    new.qualification_reason := 'complete contact + matched service + estimate';
  elsif (coalesce(new.phone,'')<>'' or coalesce(new.email,'')<>'') and new.matched_service_id is not null then
    new.qualification_status := 'needs_review';
    new.qualification_reason := array_to_string(v_reasons,'; ');
  else
    new.qualification_status := 'unqualified';
    new.qualification_reason := array_to_string(v_reasons,'; ');
  end if;

  if new.push_to_email is null then
    select value into new.push_to_email from hvac.config where key = 'push_email';
  end if;
  return new;
end;
$$;

create trigger trg_qualify_and_estimate
before insert on hvac.leads
for each row execute function hvac.qualify_and_estimate();

-- PUBLIC API WRAPPERS
create or replace function public.hvac_intake_lead(
  p_contact_name text default null, p_phone text default null,
  p_email text default null, p_service text default null,
  p_description text default null, p_property_type text default null,
  p_system_age_years int default null, p_urgency text default 'standard',
  p_source text default 'voice'
) returns hvac.leads language plpgsql security definer set search_path = hvac, public as $$
declare v_lead hvac.leads;
begin
  insert into hvac.leads(source,contact_name,phone,email,service_requested,description,property_type,system_age_years,urgency)
  values(p_source,p_contact_name,p_phone,p_email,p_service,p_description,p_property_type,p_system_age_years,coalesce(p_urgency,'standard'))
  returning * into v_lead;
  return v_lead;
end;
$$;

create or replace function public.hvac_get_leads()     returns setof hvac.leads   language sql security definer as $$ select * from hvac.leads   order by created_at desc; $$;
create or replace function public.hvac_get_pricing()   returns setof hvac.pricing language sql security definer as $$ select * from hvac.pricing order by category, service_name; $$;
create or replace function public.hvac_get_config()    returns setof hvac.config  language sql security definer as $$ select * from hvac.config  order by key; $$;

create or replace function public.hvac_update_lead_status(p_id bigint, p_status text)
returns hvac.leads language sql security definer as $$
  update hvac.leads set status=p_status where id=p_id returning *; $$;

create or replace function public.hvac_update_pricing(
  p_id bigint, p_service_name text, p_category text, p_unit text,
  p_price_min numeric, p_price_max numeric, p_active boolean, p_notes text
) returns hvac.pricing language sql security definer as $$
  update hvac.pricing set service_name=p_service_name, category=p_category,
    unit=p_unit, price_min=p_price_min, price_max=p_price_max, active=p_active,
    notes=coalesce(p_notes,notes) where id=p_id returning *; $$;

create or replace function public.hvac_update_config(p_key text, p_value text)
returns hvac.config language sql security definer as $$
  update hvac.config set value=p_value, updated_at=now() where key=p_key returning *; $$;

alter table hvac.config  enable row level security;
alter table hvac.pricing enable row level security;
alter table hvac.leads   enable row level security;
create policy "auth read config"  on hvac.config  for select to authenticated using (true);
create policy "auth read pricing" on hvac.pricing for select to authenticated using (true);
create policy "auth manage leads" on hvac.leads   for all    to authenticated using (true) with check (true);

grant usage on schema hvac to anon, authenticated, service_role;
grant all on all tables in schema hvac to service_role;
grant execute on function public.hvac_intake_lead(text,text,text,text,text,text,int,text,text) to anon, authenticated, service_role;
grant execute on function public.hvac_get_leads()    to anon, authenticated;
grant execute on function public.hvac_get_pricing()  to anon, authenticated;
grant execute on function public.hvac_get_config()   to anon, authenticated;
grant execute on function public.hvac_update_lead_status(bigint,text) to anon, authenticated;
grant execute on function public.hvac_update_pricing(bigint,text,text,text,numeric,numeric,boolean,text) to anon, authenticated;
grant execute on function public.hvac_update_config(text,text) to anon, authenticated;
