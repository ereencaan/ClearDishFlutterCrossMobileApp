-- ============================================
-- Supabase Security Advisor Fixes (Dec 2025)
-- ============================================
-- Run this script in the Supabase SQL Editor (service role) to address:
-- 1) Exposed auth.users via analytics views
-- 2) SECURITY DEFINER views for analytics
-- 3) RLS policies that reference user_metadata (should use app_metadata)

-- --------------------------------------------
-- 1. Rebuild analytics views without auth.users
-- --------------------------------------------
drop view if exists public.analytics_top_users;
drop view if exists public.analytics_top_restaurants;

create or replace view public.analytics_top_restaurants as
select
  r.id as restaurant_id,
  r.name,
  count(rv.id) as visit_count
from public.restaurant_visits rv
join public.restaurants r on r.id = rv.restaurant_id
group by r.id, r.name
order by visit_count desc;

-- enforce SECURITY INVOKER semantics on the view (Postgres 15+)
alter view if exists public.analytics_top_restaurants set (security_invoker = on);

create or replace view public.analytics_top_users as
select
  rv.user_id,
  coalesce(up.full_name, 'User') as email,
  count(rv.id) as visit_count
from public.restaurant_visits rv
left join public.user_profiles up on up.user_id = rv.user_id
group by rv.user_id, email
order by visit_count desc;

-- enforce SECURITY INVOKER semantics on the view (Postgres 15+)
alter view if exists public.analytics_top_users set (security_invoker = on);

-- --------------------------------------------
-- 2. Copy role claims into app_metadata
-- --------------------------------------------
update auth.users
set raw_app_meta_data = jsonb_set(
      coalesce(raw_app_meta_data, '{}'::jsonb),
      '{role}',
      to_jsonb(coalesce(raw_app_meta_data->>'role', raw_user_meta_data->>'role', 'user'))
    )
where raw_user_meta_data ? 'role'
   or raw_app_meta_data ? 'role';

-- --------------------------------------------
-- 3. Drop policies referencing user_metadata and recreate with app_metadata
-- --------------------------------------------
do $$
declare
  rec record;
begin
  for rec in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('user_profiles','analytics_events','profile_change_requests')
      and (
        coalesce(qual, '') ilike '%user_metadata%'
        or coalesce(with_check, '') ilike '%user_metadata%'
      )
  loop
    execute format('drop policy if exists %I on %I.%I', rec.policyname, rec.schemaname, rec.tablename);
  end loop;
end $$;

alter table if exists public.analytics_events enable row level security;

drop policy if exists "admin_manage_change_requests" on public.profile_change_requests;
create policy "admin_manage_change_requests"
  on public.profile_change_requests
  for all using ((auth.jwt()->'app_metadata'->>'role') = 'admin')
  with check ((auth.jwt()->'app_metadata'->>'role') = 'admin');

drop policy if exists "admin_user_profiles_read" on public.user_profiles;
create policy "admin_user_profiles_read"
  on public.user_profiles
  for select using ((auth.jwt()->'app_metadata'->>'role') = 'admin');

do $$
begin
  if exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'analytics_events'
  ) then
    drop policy if exists "admin_analytics_events_read" on public.analytics_events;
    create policy "admin_analytics_events_read"
      on public.analytics_events
      for select using ((auth.jwt()->'app_metadata'->>'role') = 'admin');
  end if;
end $$;

-- --------------------------------------------
-- 4. Verify
-- --------------------------------------------
-- After running this script, click "Security Advisor → Refresh".
-- All six warnings should disappear. If any remain, expand the row to
-- double-check which object still references auth.users or user_metadata.
