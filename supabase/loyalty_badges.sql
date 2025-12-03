-- ============================================
-- Loyalty Badges: user-level badges and rules
-- ============================================

-- Tables
create table if not exists public.badge_rules (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  type text not null check (type in ('visits')),
  threshold int not null,          -- e.g., 5 visits
  window_days int not null,        -- e.g., 30 days
  reward_type text not null check (reward_type in ('percent_off','free_item')),
  reward_value numeric(6,2) not null, -- percent_off value or ignored for free_item
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  type text not null,             -- e.g., visits
  level int default 1,
  reason text,
  awarded_at timestamptz default now(),
  expires_at timestamptz,
  metadata jsonb default '{}'::jsonb
);

create table if not exists public.badge_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_badge_id uuid not null references public.user_badges(id) on delete cascade,
  promotion_id uuid, -- optional link to promotions row
  redeemed_at timestamptz default now()
);

-- RLS
alter table public.badge_rules enable row level security;
alter table public.user_badges enable row level security;
alter table public.badge_redemptions enable row level security;

drop policy if exists rules_owner_manage on public.badge_rules;
create policy rules_owner_manage
  on public.badge_rules
  for all using (
    exists (select 1 from public.restaurant_admins ra
            where ra.restaurant_id = restaurant_id and ra.user_id = auth.uid())
  )
  with check (
    exists (select 1 from public.restaurant_admins ra
            where ra.restaurant_id = restaurant_id and ra.user_id = auth.uid())
  );

drop policy if exists user_badges_self on public.user_badges;
create policy user_badges_self
  on public.user_badges
  for select using (auth.uid() = user_id);

drop policy if exists user_badges_owner_read on public.user_badges;
create policy user_badges_owner_read
  on public.user_badges
  for select using (
    exists (select 1 from public.restaurant_admins ra
            where ra.restaurant_id = restaurant_id and ra.user_id = auth.uid())
  );

drop policy if exists redemptions_self_read on public.badge_redemptions;
create policy redemptions_self_read
  on public.badge_redemptions
  for select using (
    exists (select 1 from public.user_badges ub
            where ub.id = user_badge_id and ub.user_id = auth.uid())
  );

-- Trigger: award a badge on visit threshold
create or replace function public.award_loyalty_badges()
returns trigger
language plpgsql
as $$
declare
  r record;
  visits_count int;
  expiry timestamptz;
begin
  for r in
    select * from public.badge_rules
    where active = true
      and restaurant_id = new.restaurant_id
      and type = 'visits'
  loop
    select count(*) into visits_count
    from public.restaurant_visits v
    where v.user_id = new.user_id
      and v.restaurant_id = new.restaurant_id
      and v.visited_at >= now() - (r.window_days || ' days')::interval;

    if visits_count >= r.threshold then
      expiry := now() + interval '14 days';
      insert into public.user_badges(user_id, restaurant_id, type, level, reason, expires_at, metadata)
      values (new.user_id, new.restaurant_id, 'visits', 1,
              format('%s visits in %s days', r.threshold, r.window_days),
              expiry,
              jsonb_build_object('reward_type', r.reward_type, 'reward_value', r.reward_value))
      on conflict do nothing;

      -- Create targeted promotion if reward is percent_off
      if r.reward_type = 'percent_off' then
        insert into public.promotions(restaurant_id, title, description, percent_off, starts_at, ends_at, user_id, active)
        values (new.restaurant_id,
                'Loyalty Reward',
                format('Thanks for being a loyal guest! %s%% off', r.reward_value),
                r.reward_value,
                now(),
                expiry,
                new.user_id,
                true);
      end if;
    end if;
  end loop;
  return new;
end $$;

drop trigger if exists trg_award_loyalty_badges on public.restaurant_visits;
create trigger trg_award_loyalty_badges
after insert on public.restaurant_visits
for each row execute function public.award_loyalty_badges();

-- Default rule example: 5 visits in 30 days → 10% off
insert into public.badge_rules(restaurant_id, type, threshold, window_days, reward_type, reward_value)
select id, 'visits', 5, 30, 'percent_off', 10.0
from public.restaurants
where not exists (
  select 1 from public.badge_rules br where br.restaurant_id = restaurants.id
);
