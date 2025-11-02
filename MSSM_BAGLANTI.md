# 🔌 MSSM Bağlantı Komutları - ClearDish

## 1. MSSM'de Database Oluştur

### Adım 1: Script'i Çalıştır

1. **SQL Server Management Studio**'yu aç
2. **File** → **Open** → **File**
3. `MSSM_SETUP.sql` dosyasını seç
4. **Execute** (F5) bas
5. ✅ "3 Restaurants, 8 Categories, 20 Menu Items" mesajını gör

### Adım 2: Kontrol Et

```sql
USE ClearDish;
GO

SELECT 'Restaurants' AS TableName, COUNT(*) AS RecordCount FROM restaurants
UNION ALL
SELECT 'Categories', COUNT(*) FROM menu_categories
UNION ALL
SELECT 'Menu Items', COUNT(*) FROM menu_items;
```

**Sonuç görmeli:**
```
Restaurants: 3
Categories: 8
Menu Items: 20
```

## 2. Connection String Oluştur

### Windows Authentication için:

```
Server=localhost;Database=ClearDish;Integrated Security=True;TrustServerCertificate=True;
```

### SQL Server Authentication için:

```
Server=localhost;Database=ClearDish;User Id=sa;Password=your_password;TrustServerCertificate=True;
```

### Remote Server için:

```
Server=192.168.1.100,1433;Database=ClearDish;User Id=sa;Password=your_password;TrustServerCertificate=True;
```

## 3. Flutter'da MSSM Kullanımı

### Seçenek A: Supabase'e Geç (Önerilir)

Supabase zaten PostgreSQL kullanıyor, direkt kullanabilirsin.

### Seçenek B: MSSM ile Devam Et

`pubspec.yaml` dosyasına ekle:

```yaml
dependencies:
  mssql_connection: ^2.0.0
  # veya
  sql_server: ^1.0.0
```

**Connection örneği:**

```dart
import 'package:mssql_connection/mssql_connection.dart';

final MssqlConnection connection = MssqlConnection();
await connection.open(
  host: 'localhost',
  port: 1433,
  databaseName: 'ClearDish',
  username: 'sa',
  password: 'your_password',
);
```

## 4. Test Sorguları

MSSM'de şu sorguları çalıştır:

### Restaurants Listesi:

```sql
SELECT * FROM restaurants WHERE visible = 1;
```

### Menü İçeriği:

```sql
SELECT
    r.name AS Restaurant,
    c.name AS Category,
    m.name AS MenuItem,
    m.price,
    m.allergens
FROM menu_items m
JOIN restaurants r ON m.restaurant_id = r.id
LEFT JOIN menu_categories c ON m.category_id = c.id
ORDER BY r.name, c.sort_order;
```

### Alerjen Filtreleme:

```sql
-- Gluten içeren ürünler
SELECT name, allergens, price
FROM menu_items
WHERE allergens LIKE '%gluten%';
```

## 5. Backend API Oluştur

MSSM kullanacaksan backend API oluşturman gerekiyor:

### Seçenekler:

1. **ASP.NET Core Web API** (C#)
2. **Node.js + Express + mssql**
3. **Python Flask + pyodbc**

**Örnek ASP.NET Core:**

```csharp
// Controllers/RestaurantsController.cs
[ApiController]
[Route("api/[controller]")]
public class RestaurantsController : ControllerBase
{
    private readonly IConfiguration _config;

    public RestaurantsController(IConfiguration config)
    {
        _config = config;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Restaurant>>> GetRestaurants()
    {
        var connectionString = _config.GetConnectionString("ClearDishDb");
        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        var sql = "SELECT * FROM restaurants WHERE visible = 1";
        var restaurants = await connection.QueryAsync<Restaurant>(sql);

        return Ok(restaurants);
    }
}
```

## 📋 Önemli Notlar

1. **Supabase Önerilir** - Zaten PostgreSQL, Flutter ile hazır
2. **MSSM Kullanacaksan** - Backend API gerekli
3. **Connection String** - Güvenli tut
4. **SQL Injection** - Parametreli sorgular kullan

## 🚀 Hızlı Başlangıç

**MSSM için:**
```sql
-- MSSM'de çalıştır
USE ClearDish;
GO
SELECT * FROM restaurants;
```

**Supabase için:**
```dart
// Flutter'da direkt kullan
final restaurants = await _repo.getRestaurants();
```

---

**Not:** Projen Supabase için hazırlandı. MSSM kullanmak istersen backend API eklemelisin!
