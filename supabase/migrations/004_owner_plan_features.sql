-- Owner plan-based features:
-- - restaurant_locations: multi-location (Plus = unlimited, Starter/Pro = 1)
-- - restaurant_diet_tags: diet badges (Pro/Plus)
--
-- This migration assumes your app uses:
-- - auth.users user_metadata.role == 'restaurant' for owners
-- - auth.users app_metadata.owner_plan / owner_paid / owner_paid_until set by webhook

-- Ensure mapping table exists (some installs use FULL_MIGRATION_ALL_IN_ONE.sql)
create table if not exists public.restaurant_admins (
  restaurant_id uuid references public.restaurants(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (restaurant_id, user_id)
);

-- ---------- helpers ----------
create or replace function public._cd_user_role()
returns text
language sql
stable
as $$
  select coalesce(auth.jwt()->'user_metadata'->>'role', '');
$$;

create or replace function public._cd_owner_plan()
returns text
language sql
stable
as $$
  select lower(coalesce(auth.jwt()->'app_metadata'->>'owner_plan', ''));
$$;

create or replace function public._cd_owner_is_paid()
returns boolean
language plpgsql
stable
as $$
declare
  paid_until_raw text;
  paid_until timestamptz;
  paid_raw text;
begin
  -- Only applies to restaurant owners
  if public._cd_user_role() <> 'restaurant' then
    return false;
  end if;

  paid_until_raw := auth.jwt()->'app_metadata'->>'owner_paid_until';
  if paid_until_raw is not null and length(paid_until_raw) > 0 then
    begin
      paid_until := paid_until_raw::timestamptz;
    exception when others then
      paid_until := null;
    end;
    if paid_until is not null then
      return paid_until > now();
    end if;
  end if;

  paid_raw := lower(coalesce(auth.jwt()->'app_metadata'->>'owner_paid', ''));
  return paid_raw in ('true','1','yes');
end;
$$;

create or replace function public._cd_can_manage_restaurant(p_restaurant_id uuid)
returns boolean
language sql
stable
as $$
  select exists(
    select 1
    from public.restaurant_admins ra
    where ra.restaurant_id = p_restaurant_id
      and ra.user_id = auth.uid()
  );
$$;

create or replace function public._cd_can_add_location(p_restaurant_id uuid)
returns boolean
language plpgsql
stable
as $$
declare
  plan text;
  cnt int;
begin
  if not public._cd_owner_is_paid() then
    return false;
  end if;
  if not public._cd_can_manage_restaurant(p_restaurant_id) then
    return false;
  end if;

  plan := public._cd_owner_plan();
  if plan = 'plus' then
    return true;
  end if;

  -- Starter/Pro: allow only 1 location
  select count(*) into cnt
  from public.restaurant_locations rl
  where rl.restaurant_id = p_restaurant_id;

  return cnt < 1;
end;
$$;

create or replace function public._cd_can_edit_diet_tags(p_restaurant_id uuid)
returns boolean
language sql
stable
as $$
  select public._cd_owner_is_paid()
    and public._cd_can_manage_restaurant(p_restaurant_id)
    and public._cd_owner_plan() in ('pro','plus');
$$;

-- ---------- restaurant_locations ----------
create table if not exists public.restaurant_locations (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  label text,
  address text not null,
  phone text,
  lat double precision,
  lng double precision,
  is_primary boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_restaurant_locations_restaurant
  on public.restaurant_locations(restaurant_id);

create unique index if not exists ux_restaurant_locations_primary
  on public.restaurant_locations(restaurant_id)
  where is_primary;

alter table public.restaurant_locations enable row level security;

-- Public can read locations for visible restaurants (optional, but useful for multi-branch display)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_locations'
      and policyname = 'public_locations_read'
  ) then
    execute $p$
      create policy public_locations_read
        on public.restaurant_locations
        for select
        using (
          exists (
            select 1 from public.restaurants r
            where r.id = restaurant_id and r.visible = true
          )
        );
    $p$;
  end if;
end $$;

do $$
begin
  -- Inserts: enforce plan limit
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_locations'
      and policyname = 'locations_insert'
  ) then
    execute $p$
      create policy locations_insert
        on public.restaurant_locations
        for insert
        with check (public._cd_can_add_location(restaurant_id));
    $p$;
  end if;

  -- Updates/Deletes: allow only paid owners managing the restaurant
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_locations'
      and policyname = 'locations_update'
  ) then
    execute $p$
      create policy locations_update
        on public.restaurant_locations
        for update
        using (
          public._cd_owner_is_paid()
          and public._cd_can_manage_restaurant(restaurant_id)
        )
        with check (
          public._cd_owner_is_paid()
          and public._cd_can_manage_restaurant(restaurant_id)
        );
    $p$;
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_locations'
      and policyname = 'locations_delete'
  ) then
    execute $p$
      create policy locations_delete
        on public.restaurant_locations
        for delete
        using (
          public._cd_owner_is_paid()
          and public._cd_can_manage_restaurant(restaurant_id)
        );
    $p$;
  end if;
end $$;

-- ---------- restaurant_diet_tags ----------
create table if not exists public.restaurant_diet_tags (
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  tag text not null,
  created_at timestamptz default now(),
  primary key (restaurant_id, tag)
);

create index if not exists idx_restaurant_diet_tags_restaurant
  on public.restaurant_diet_tags(restaurant_id);

alter table public.restaurant_diet_tags enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_diet_tags'
      and policyname = 'public_diet_tags_read'
  ) then
    execute $p$
      create policy public_diet_tags_read
        on public.restaurant_diet_tags
        for select
        using (
          exists (
            select 1 from public.restaurants r
            where r.id = restaurant_id and r.visible = true
          )
        );
    $p$;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'restaurant_diet_tags'
      and policyname = 'diet_tags_manage'
  ) then
    execute $p$
      create policy diet_tags_manage
        on public.restaurant_diet_tags
        for all
        using (public._cd_can_edit_diet_tags(restaurant_id))
        with check (public._cd_can_edit_diet_tags(restaurant_id));
    $p$;
  end if;
end $$;

