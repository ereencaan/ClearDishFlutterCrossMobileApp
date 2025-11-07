-- ============================================
-- ClearDish FULL DATABASE SETUP
-- Copy-paste entire content in Supabase SQL Editor and run ONCE
-- ============================================

-- 1. CREATE TABLES
create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  allergens text[] default '{}',
  diets text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  visible boolean default true,
  created_at timestamptz default now()
);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  sort_order int default 0
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid references public.menu_categories(id) on delete set null,
  name text not null,
  description text,
  price numeric(10,2),
  allergens text[] default '{}'
);

-- 2. ROW LEVEL SECURITY
alter table public.user_profiles enable row level security;
create policy "own_profile_select" on public.user_profiles for select using (auth.uid() = user_id);
create policy "own_profile_insert" on public.user_profiles for insert with check (auth.uid() = user_id);
create policy "own_profile_update" on public.user_profiles for update using (auth.uid() = user_id);

alter table public.restaurants enable row level security;
create policy "public_restaurants_read" on public.restaurants for select using (visible = true);

alter table public.menu_categories enable row level security;
create policy "public_menu_categories_read" on public.menu_categories for select using (true);

alter table public.menu_items enable row level security;
create policy "public_menu_items_read" on public.menu_items for select using (true);

-- 3. INDEXES
create index idx_restaurants_visible on public.restaurants(visible);
create index idx_menu_categories_restaurant on public.menu_categories(restaurant_id);
create index idx_menu_items_restaurant on public.menu_items(restaurant_id);
create index idx_menu_items_category on public.menu_items(category_id);

-- 4. INSERT RESTAURANTS
insert into public.restaurants (id, name, address, visible) values
  ('00000000-0000-0000-0000-000000000001', 'Green Garden Cafe', '123 Main St, London', true),
  ('00000000-0000-0000-0000-000000000002', 'Ocean Breeze Seafood', '456 Harbor Ave, Brighton', true),
  ('00000000-0000-0000-0000-000000000003', 'The Vegan Corner', '789 Plant St, Manchester', true);

-- 5. INSERT MENU CATEGORIES
insert into public.menu_categories (id, restaurant_id, name, sort_order) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Starters', 1),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Main Courses', 2),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Desserts', 3),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'Appetizers', 1),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'Main Dishes', 2),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', 'Soups', 1),
  ('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000003', 'Salads', 2),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000003', 'Main Courses', 3);

-- 6. INSERT MENU ITEMS
insert into public.menu_items (id, restaurant_id, category_id, name, description, price, allergens) values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Garlic Bread', 'Fresh baked bread with garlic butter', 5.99, ARRAY['gluten', 'milk']),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Caesar Salad', 'Crisp romaine lettuce with Caesar dressing', 8.99, ARRAY['egg', 'fish', 'milk']),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Grilled Chicken', 'Tender grilled chicken breast with herbs', 16.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Vegetable Pasta', 'Mixed vegetables in tomato sauce', 12.99, ARRAY['gluten']),
  ('20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Beef Steak', 'Prime cut with mashed potatoes', 24.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Chocolate Cake', 'Rich chocolate layer cake', 7.99, ARRAY['gluten', 'egg', 'milk']),
  ('20000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Ice Cream', 'Vanilla or strawberry', 5.99, ARRAY['milk']),
  ('20000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'Shrimp Cocktail', 'Fresh shrimp with cocktail sauce', 12.99, ARRAY['shellfish']),
  ('20000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'Calamari Rings', 'Fried squid rings', 10.99, ARRAY['shellfish', 'gluten']),
  ('20000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Grilled Salmon', 'Atlantic salmon with vegetables', 22.99, ARRAY['fish']),
  ('20000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Lobster Tail', 'Fresh lobster with butter', 35.99, ARRAY['shellfish', 'milk']),
  ('20000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Fish and Chips', 'Classic battered fish with fries', 16.99, ARRAY['fish', 'gluten']),
  ('20000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'Lentil Soup', 'Hearty lentil soup with vegetables', 7.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'Tomato Basil Soup', 'Fresh tomato soup with basil', 6.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000007', 'Garden Salad', 'Mixed greens with vegetables', 8.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000007', 'Quinoa Salad', 'Quinoa with vegetables and dressing', 10.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Vegan Burger', 'Plant-based burger with fries', 14.99, ARRAY['gluten']),
  ('20000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Tofu Stir Fry', 'Tofu with mixed vegetables', 13.99, ARRAY['soy']),
  ('20000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Chickpea Curry', 'Spiced chickpea curry with rice', 12.99, ARRAY[]::text[]),
  ('20000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Mushroom Risotto', 'Creamy mushroom risotto', 15.99, ARRAY[]::text[]);

-- DONE! Check Table Editor for: 3 restaurants, 8 categories, 20 menu items
