-- ClearDish Database Schema
-- Run this migration in your Supabase SQL editor

-- User profiles table (extends auth.users)
-- Note: auth.users is managed by Supabase Auth
create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  allergens text[] default '{}',
  diets text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Restaurants table
create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  visible boolean default true,
  created_at timestamptz default now()
);

-- Menu categories table
create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  sort_order int default 0
);

-- Menu items table
create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid references public.menu_categories(id) on delete set null,
  name text not null,
  description text,
  price numeric(10,2),
  allergens text[] default '{}'
);

-- Row Level Security (RLS) Policies

-- User profiles: users can only access their own profile
alter table public.user_profiles enable row level security;
create policy "own_profile"
  on public.user_profiles
  for select using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Restaurants: everyone can read visible restaurants
alter table public.restaurants enable row level security;
create policy "public_restaurants_read"
  on public.restaurants for select using (visible = true);

-- Menu categories: everyone can read
alter table public.menu_categories enable row level security;
create policy "public_menu_categories_read"
  on public.menu_categories for select using (true);

-- Menu items: everyone can read
alter table public.menu_items enable row level security;
create policy "public_menu_items_read"
  on public.menu_items for select using (true);

-- Indexes for better query performance
create index idx_restaurants_visible on public.restaurants(visible);
create index idx_menu_categories_restaurant on public.menu_categories(restaurant_id);
create index idx_menu_items_restaurant on public.menu_items(restaurant_id);
create index idx_menu_items_category on public.menu_items(category_id);

