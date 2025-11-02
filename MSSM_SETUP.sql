-- ============================================
-- ClearDish MSSM Database Setup Script
-- Run this in SQL Server Management Studio
-- ============================================

-- 1. DATABASE OLUŞTUR
USE master;
GO

-- Database var mı kontrol et, yoksa oluştur
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ClearDish')
BEGIN
    CREATE DATABASE ClearDish;
END
GO

USE ClearDish;
GO

-- 2. TABLOLAR OLUŞTUR

-- User Profiles Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'user_profiles')
BEGIN
    CREATE TABLE user_profiles (
        user_id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        full_name NVARCHAR(255),
        allergens NVARCHAR(MAX) DEFAULT '[]', -- JSON format
        diets NVARCHAR(MAX) DEFAULT '[]',     -- JSON format
        created_at DATETIME DEFAULT GETDATE(),
        updated_at DATETIME DEFAULT GETDATE()
    );
END
GO

-- Restaurants Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'restaurants')
BEGIN
    CREATE TABLE restaurants (
        id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        name NVARCHAR(255) NOT NULL,
        address NVARCHAR(500),
        visible BIT DEFAULT 1,
        created_at DATETIME DEFAULT GETDATE()
    );
END
GO

-- Menu Categories Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'menu_categories')
BEGIN
    CREATE TABLE menu_categories (
        id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        restaurant_id UNIQUEIDENTIFIER NOT NULL,
        name NVARCHAR(255) NOT NULL,
        sort_order INT DEFAULT 0,
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
    );
END
GO

-- Menu Items Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'menu_items')
BEGIN
    CREATE TABLE menu_items (
        id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        restaurant_id UNIQUEIDENTIFIER NOT NULL,
        category_id UNIQUEIDENTIFIER NULL,
        name NVARCHAR(255) NOT NULL,
        description NVARCHAR(1000),
        price DECIMAL(10,2),
        allergens NVARCHAR(MAX) DEFAULT '[]', -- JSON format
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES menu_categories(id) ON DELETE SET NULL
    );
END
GO

-- 3. INDEX'LER OLUŞTUR
CREATE NONCLUSTERED INDEX IX_restaurants_visible ON restaurants(visible);
CREATE NONCLUSTERED INDEX IX_menu_categories_restaurant ON menu_categories(restaurant_id);
CREATE NONCLUSTERED INDEX IX_menu_items_restaurant ON menu_items(restaurant_id);
CREATE NONCLUSTERED INDEX IX_menu_items_category ON menu_items(category_id);
GO

-- 4. SEED DATA - ÖRNEK VERİLER

-- Restaurants
INSERT INTO restaurants (id, name, address, visible)
SELECT '00000000-0000-0000-0000-000000000001', 'Green Garden Cafe', '123 Main St, London', 1
WHERE NOT EXISTS (SELECT 1 FROM restaurants WHERE id = '00000000-0000-0000-0000-000000000001');

INSERT INTO restaurants (id, name, address, visible)
SELECT '00000000-0000-0000-0000-000000000002', 'Ocean Breeze Seafood', '456 Harbor Ave, Brighton', 1
WHERE NOT EXISTS (SELECT 1 FROM restaurants WHERE id = '00000000-0000-0000-0000-000000000002');

INSERT INTO restaurants (id, name, address, visible)
SELECT '00000000-0000-0000-0000-000000000003', 'The Vegan Corner', '789 Plant St, Manchester', 1
WHERE NOT EXISTS (SELECT 1 FROM restaurants WHERE id = '00000000-0000-0000-0000-000000000003');
GO

-- Menu Categories
INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Starters', 1
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000001');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Main Courses', 2
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000002');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Desserts', 3
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000003');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002', 'Appetizers', 1
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000004');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'Main Dishes', 2
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000005');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', 'Soups', 1
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000006');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000003', 'Salads', 2
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000007');

INSERT INTO menu_categories (id, restaurant_id, name, sort_order)
SELECT '10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000003', 'Main Courses', 3
WHERE NOT EXISTS (SELECT 1 FROM menu_categories WHERE id = '10000000-0000-0000-0000-000000000008');
GO

-- Menu Items
INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Garlic Bread', 'Fresh baked bread with garlic butter', 5.99, '["gluten","milk"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000001');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Caesar Salad', 'Crisp romaine lettuce with Caesar dressing', 8.99, '["egg","fish","milk"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000002');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Grilled Chicken', 'Tender grilled chicken breast with herbs', 16.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000003');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Vegetable Pasta', 'Mixed vegetables in tomato sauce', 12.99, '["gluten"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000004');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Beef Steak', 'Prime cut with mashed potatoes', 24.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000005');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Chocolate Cake', 'Rich chocolate layer cake', 7.99, '["gluten","egg","milk"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000006');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Ice Cream', 'Vanilla or strawberry', 5.99, '["milk"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000007');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'Shrimp Cocktail', 'Fresh shrimp with cocktail sauce', 12.99, '["shellfish"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000008');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'Calamari Rings', 'Fried squid rings', 10.99, '["shellfish","gluten"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000009');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Grilled Salmon', 'Atlantic salmon with vegetables', 22.99, '["fish"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000010');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Lobster Tail', 'Fresh lobster with butter', 35.99, '["shellfish","milk"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000011');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000005', 'Fish and Chips', 'Classic battered fish with fries', 16.99, '["fish","gluten"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000012');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'Lentil Soup', 'Hearty lentil soup with vegetables', 7.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000013');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000006', 'Tomato Basil Soup', 'Fresh tomato soup with basil', 6.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000014');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000007', 'Garden Salad', 'Mixed greens with vegetables', 8.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000015');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000007', 'Quinoa Salad', 'Quinoa with vegetables and dressing', 10.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000016');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Vegan Burger', 'Plant-based burger with fries', 14.99, '["gluten"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000017');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Tofu Stir Fry', 'Tofu with mixed vegetables', 13.99, '["soy"]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000018');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Chickpea Curry', 'Spiced chickpea curry with rice', 12.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000019');

INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, allergens)
SELECT '20000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000008', 'Mushroom Risotto', 'Creamy mushroom risotto', 15.99, '[]'
WHERE NOT EXISTS (SELECT 1 FROM menu_items WHERE id = '20000000-0000-0000-0000-000000000020');
GO

-- 5. KONTROL SORGULARI
PRINT 'Database oluşturuldu!';
PRINT 'Toplam Restoran sayısı: ' + CAST((SELECT COUNT(*) FROM restaurants) AS NVARCHAR);
PRINT 'Toplam Kategori sayısı: ' + CAST((SELECT COUNT(*) FROM menu_categories) AS NVARCHAR);
PRINT 'Toplam Menü öğesi sayısı: ' + CAST((SELECT COUNT(*) FROM menu_items) AS NVARCHAR);

SELECT '=== RESTAURANTS ===' AS INFO;
SELECT * FROM restaurants;

SELECT '=== MENU CATEGORIES ===' AS INFO;
SELECT * FROM menu_categories;

SELECT '=== MENU ITEMS ===' AS INFO;
SELECT TOP 5 * FROM menu_items;
GO
