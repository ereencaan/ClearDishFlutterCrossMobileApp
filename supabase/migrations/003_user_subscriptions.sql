-- Add subscription columns for regular users (in-app purchase)
alter table public.user_profiles
  add column if not exists user_sub_plan text,
  add column if not exists user_sub_paid_until timestamptz;

