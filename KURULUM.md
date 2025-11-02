# 🛠️ ClearDish - Tüm Kurulum Komutları

## 📦 1. Flutter SDK Kurulumu (İlk Kurulumsa)

### Windows için Flutter Kurulumu:

```powershell
# 1. Flutter SDK'yı indir
# https://docs.flutter.dev/get-started/install/windows
# veya Chocolatey ile:
choco install flutter

# 2. Flutter'ı PATH'e ekle (PowerShell - Yönetici olarak)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")

# 3. Flutter'ı kontrol et
flutter doctor

# 4. Eksik bileşenleri yükle (örnek: Android Studio)
# Android Studio: https://developer.android.com/studio
# VS Code Flutter Extension: Flutter ve Dart extension'larını yükle
```

### Flutter Doctor Çıktısı Kontrolü:

```powershell
flutter doctor -v
```

✅ **Tüm kontroller yeşil olmalı:**
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ VS Code / Android Studio
- ✅ Connected device (emulator veya fiziksel cihaz)

---

## 🔧 2. Proje Bağımlılıklarını Yükle

```powershell
# Proje dizinine git (zaten oradasın)
cd "C:\Users\ereen\source\repos\Clear Dish"

# Bağımlılıkları yükle
flutter pub get

# Kod üretimi (gerekirse)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🗄️ 3. Supabase Projesi Oluştur ve Ayarla

### 3.1. Supabase Hesabı Oluştur:

```powershell
# Tarayıcıda aç:
start https://app.supabase.com

# Adımlar:
# 1. "Start your project" → Email ile kaydol
# 2. "New Project" → Proje adı: cleardish
# 3. Database password oluştur (kaydet!)
# 4. Region seç (Avrupa: closest)
# 5. "Create new project" → 2-3 dakika bekle
```

### 3.2. Supabase API Anahtarlarını Al:

```powershell
# Dashboard'da:
# Project Settings → API → şunları kopyala:
# - Project URL: https://xxxxx.supabase.co
# - anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3.3. Ortam Değişkenlerini Ayarla:

**Seçenek A: PowerShell Session (Geçici - her terminal açılışında tekrar gerekir):**

```powershell
# Mevcut PowerShell oturumunda:
$env:SUPABASE_URL="https://your-project-id.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key-here"

# Kontrol et:
echo $env:SUPABASE_URL
echo $env:SUPABASE_ANON_KEY
```

**Seçenek B: Kalıcı Ortam Değişkeni (Önerilir):**

```powershell
# PowerShell - Yönetici olarak çalıştır:
[System.Environment]::SetEnvironmentVariable('SUPABASE_URL', 'https://your-project-id.supabase.co', 'User')
[System.Environment]::SetEnvironmentVariable('SUPABASE_ANON_KEY', 'your-anon-key-here', 'User')

# Yeni terminal aç veya:
refreshenv  # (Chocolatey yüklüyse)
```

**Seçenek C: app_env.dart Dosyasını Düzenle (Hızlı Test için):**

```powershell
# Dosyayı düzenle:
code lib/core/config/app_env.dart

# İçeriği şu şekilde değiştir:
# static const String supabaseUrl = 'https://your-project-id.supabase.co';
# static const String supabaseAnonKey = 'your-anon-key-here';
```

---

## 🗃️ 4. Supabase Database Migration

### 4.1. Migration Dosyalarını Çalıştır:

```powershell
# Supabase Dashboard'ı aç:
start https://app.supabase.com/project/your-project-id/sql/new

# SQL Editor'da:

# Adım 1: Schema oluştur
# supabase/migrations/001_initial_schema.sql içeriğini kopyala-yapıştır → "Run"

# Adım 2: Seed data ekle
# supabase/migrations/002_seed_data.sql içeriğini kopyala-yapıştır → "Run"
```

### 4.2. Migration Kontrolü:

```powershell
# Dashboard'da:
# Table Editor → şu tablolar görünmeli:
# ✅ user_profiles
# ✅ restaurants (3 kayıt)
# ✅ menu_categories (8 kayıt)
# ✅ menu_items (20 kayıt)
```

---

## 📱 5. Android Emulator Kurulumu (Test için)

### 5.1. Android Studio ile Emulator:

```powershell
# Android Studio'yu aç:
# File → Settings → Appearance & Behavior → System Settings → Android SDK
# SDK Platforms → Android 13 (API 33) veya daha yeni → Install

# Tools → Device Manager → "Create Device" → 
# Pixel 5 veya benzeri → Android 13 → Finish
```

### 5.2. Emulator'ü Başlat:

```powershell
# Android Studio'dan başlat veya:
flutter emulators --launch Pixel_5_API_33

# Kontrol et:
flutter devices
```

---

## 🚀 6. Uygulamayı Çalıştır

### 6.1. Temel Çalıştırma:

```powershell
# Bağımlılıkları yükle (ilk seferde):
flutter pub get

# Uygulamayı çalıştır:
flutter run

# Belirli cihazda çalıştır:
flutter run -d <device-id>  # flutter devices ile ID'yi gör
```

### 6.2. Debug Modu:

```powershell
# Hot reload için:
# Uygulama çalışırken terminal'de "r" bas (hot reload)
# veya "R" bas (hot restart)
```

### 6.3. Release Build (Android):

```powershell
# APK oluştur:
flutter build apk --release

# APK konumu:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ 7. İlk Test Komutları

### 7.1. Proje Kontrolü:

```powershell
# Flutter versiyonu:
flutter --version

# Bağımlılıkları kontrol et:
flutter pub get

# Lint hatalarını kontrol et:
flutter analyze

# Testleri çalıştır:
flutter test
```

### 7.2. Supabase Bağlantı Kontrolü:

```powershell
# app_env.dart dosyasında değerler doğru mu kontrol et:
cat lib/core/config/app_env.dart

# veya:
Get-Content lib/core/config/app_env.dart
```

---

## 🐛 8. Sorun Giderme Komutları

### Flutter Sorunları:

```powershell
# Flutter'ı temizle ve yeniden yükle:
flutter clean
flutter pub get

# Flutter doctor - detaylı:
flutter doctor -v

# Flutter upgrade:
flutter upgrade

# Cache temizle:
flutter pub cache repair
```

### Supabase Bağlantı Sorunları:

```powershell
# Ortam değişkenlerini kontrol et:
echo $env:SUPABASE_URL
echo $env:SUPABASE_ANON_KEY

# app_env.dart kontrolü:
code lib/core/config/app_env.dart
```

### Build Sorunları:

```powershell
# Clean build:
flutter clean
flutter pub get
flutter run

# Gradle cache temizle (Android):
cd android
./gradlew clean
cd ..
flutter run
```

---

## 📋 9. Hızlı Kontrol Listesi

```powershell
# ✅ Flutter kurulu mu?
flutter --version

# ✅ Bağımlılıklar yüklü mü?
flutter pub get

# ✅ Ortam değişkenleri ayarlı mı?
echo $env:SUPABASE_URL

# ✅ Cihaz bağlı mı?
flutter devices

# ✅ Migration çalıştırıldı mı?
# (Supabase Dashboard'da kontrol et)

# ✅ Uygulama çalışıyor mu?
flutter run
```

---

## 🎯 10. Tüm Komutlar Tek Seferde (Copy-Paste)

```powershell
# Proje dizinine git
cd "C:\Users\ereen\source\repos\Clear Dish"

# Bağımlılıkları yükle
flutter pub get

# Ortam değişkenlerini ayarla (DEĞERLERİ KENDİNE GÖRE DOLDUR!)
$env:SUPABASE_URL="https://your-project-id.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key-here"

# Uygulamayı çalıştır
flutter run
```

---

## 📚 Ek Kaynaklar

- **Flutter Docs**: https://flutter.dev/docs
- **Supabase Docs**: https://supabase.com/docs
- **Flutter + Supabase**: https://supabase.com/docs/guides/getting-started/flutter

---

## 💡 İpuçları

1. **Her terminal açılışında** ortam değişkenlerini tekrar ayarlaman gerekebilir (Seçenek A kullanıyorsan)
2. **Kalıcı çözüm** için Seçenek B veya C'yi kullan
3. **Android Studio** yüklü değilse, VS Code + Flutter extension da yeterli
4. **Emulator yavaşsa**, fiziksel cihaz bağla (USB Debugging açık olmalı)

---

## 🎉 Hazırsın!

Tüm komutları çalıştırdıktan sonra:

```powershell
flutter run
```

Login ekranı görünmeli! 🚀


