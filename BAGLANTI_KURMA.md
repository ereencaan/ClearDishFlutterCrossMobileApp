# 🔌 ClearDish - Supabase Bağlantısı Kurma (HIZLI!)

## ⚡ HIZLI YOL (2 Dakika)

### Adım 1: Supabase Dashboard'da Bilgileri Al

1. **Supabase Dashboard**'ına git: https://app.supabase.com
2. **ClearDishFlutterCrossMobileApp** projesine tıkla
3. **Sol menüden** → **Settings** (⚙️ ikonu) tıkla
4. **API** sekmesine tıkla
5. Şunları kopyala:
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon public key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Adım 2: Flutter'a Ekle

**2 seçenek var:**

#### Seçenek A: Dosyayı Düzenle (EN HIZLI!) ⚡

1. VS Code'da `lib/core/config/app_env.dart` dosyasını aç
2. Şunu görün:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'YOUR_SUPABASE_URL',
);
```

3. **Şöyle değiştir:**

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';  // Senin URL'ini yapıştır
```

ve

```dart
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';  // Senin key'ini yapıştır
```

**TAM HALİ:**

```dart
class AppEnv {
  static const String supabaseUrl = 'https://xxxxx.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...';

  static bool get isConfigured => true;  // Her zaman true döndür
}
```

#### Seçenek B: PowerShell Ortam Değişkeni

```powershell
$env:SUPABASE_URL="https://xxxxx.supabase.co"
$env:SUPABASE_ANON_KEY="eyJhbGci..."
```

### Adım 3: Migration Çalıştır

1. **Supabase Dashboard** → SQL Editor
2. **New query** → `supabase/migrations/001_initial_schema.sql` içeriğini kopyala → **Run**
3. **New query** → `supabase/migrations/002_seed_data.sql` içeriğini kopyala → **Run**

### Adım 4: Uygulamayı Çalıştır

```bash
flutter run -d windows
# veya
flutter run -d chrome
# veya VS Code'da F5
```

## ✅ Kontrol Et

Uygulama açıldığında:
- ✅ Login ekranı görünmeli
- ✅ Hata mesajı OLMAMALI
- ✅ Register butonu çalışmalı

## 🔥 Toplam Süre: 3-5 Dakika!

1. Supabase bilgilerini al (1 dk)
2. `app_env.dart` düzenle (1 dk)
3. Migration çalıştır (2 dk)
4. `flutter run` (1 dk)

**BAŞARILI! 🎉**
