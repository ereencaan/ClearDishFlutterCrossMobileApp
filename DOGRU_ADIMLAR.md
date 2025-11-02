# ✅ ClearDish - DOĞRU ADIMLAR

## 🎯 Sen Sadece Supabase Kullanacaksın!

**SSMS (SQL Server) GEREK YOK!** Zaten Supabase PostgreSQL kullanıyor.

## 📋 DOĞRU ADIMLAR (SADECE 3!)

### 1️⃣ Supabase'de Migration Çalıştır

1. **Supabase Dashboard** → **SQL Editor**
2. **New query** → `supabase/migrations/001_initial_schema.sql` içeriğini kopyala → **Run**
3. **New query** → `supabase/migrations/002_seed_data.sql` içeriğini kopyala → **Run**

**Tamam! Database hazır! ✅**

### 2️⃣ Flutter'a Bağlan

Supabase Dashboard → **Settings** → **API**:
- **URL:** `https://xxxxx.supabase.co`
- **Anon Key:** `eyJhbGci...`

VS Code'da `lib/core/config/app_env.dart` düzenle:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';  // BURAYA YAPIŞTIR
static const String supabaseAnonKey = 'eyJhbGci...';  // BURAYA YAPIŞTIR
```

**Tamam! Bağlantı hazır! ✅**

### 3️⃣ Uygulamayı Çalıştır

```bash
flutter run -d windows
```

**Bitti! 🎉**

---

## ❌ YANLIŞ

- ❌ SSMS kurmak
- ❌ SQL Server database oluşturmak
- ❌ Connection string yapmak
- ❌ Backend API yazmak

## ✅ DOĞRU

- ✅ Supabase kullan (zaten hazır)
- ✅ PostgreSQL otomatik (Supabase'de)
- ✅ API hazır (Supabase'de)
- ✅ Sadece bilgileri ekle

---

**Sadece 3 adım! Başka bir şey gerekmez! 🚀**
