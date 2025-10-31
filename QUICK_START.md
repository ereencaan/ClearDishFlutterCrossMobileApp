# ⚡ ClearDish - Hızlı Başlangıç (5 Dakika)

## 🎯 Önkoşullar

1. ✅ **Flutter SDK** yüklü mü?
   - Değilse: [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
   - Windows için: Flutter SDK indir → PATH'e ekle

2. ✅ **Supabase hesabı** var mı?
   - Değilse: [supabase.com](https://supabase.com) → Ücretsiz hesap aç

---

## 📋 Hızlı Adımlar

### 1. Flutter'ı Kontrol Et

```bash
flutter doctor
```

Tüm kontroller ✅ olmalı (Android Studio, VS Code, vb.)

### 2. Supabase Projesi Oluştur

1. [app.supabase.com](https://app.supabase.com) → "New Project"
2. **Project Settings → API** → URL ve anon key'i kopyala

### 3. Ortam Değişkenlerini Ayarla

**Windows PowerShell:**
```powershell
$env:SUPABASE_URL="https://xxxxx.supabase.co"
$env:SUPABASE_ANON_KEY="eyJhbGci..."
```

**Veya `lib/core/config/app_env.dart` dosyasını düzenle:**
```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGci...';
```

### 4. Database Migration

Supabase Dashboard → **SQL Editor** → Şu dosyaları sırayla çalıştır:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_seed_data.sql`

### 5. Uygulamayı Çalıştır

```bash
flutter pub get
flutter run
```

---

## ✅ İlk Test

1. **Register** → Yeni kullanıcı oluştur
2. **Onboarding** → Alerjen seç (Gluten, Peanut)
3. **Restaurants** → 3 restoran görünmeli
4. **Menu** → "Safe Only" toggle → Alerjen içeren ürünler gizlenmeli

---

## 🐛 Sorun mu var?

**"Flutter not found"** → Flutter SDK'yı PATH'e ekle
**"Supabase connection failed"** → URL ve Key'i kontrol et
**"No restaurants found"** → Migration dosyalarını çalıştırdın mı?

Detaylı yardım için: `SETUP_GUIDE.md` dosyasına bak!

