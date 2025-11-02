# 🐛 Debug Sorun Giderme - ClearDish

## ⚠️ Uyarı: Supabase Config Gerekli!

Debug yaparken "hiç bir şey gelmiyor" hatası Supabase bağlantısı olmadığı için olabilir.

## 🚀 Hızlı Çözüm

### 1. Supabase Bilgilerini Ayarla

**Seçenek A: Ortam Değişkenleri (PowerShell)**

```powershell
$env:SUPABASE_URL="https://your-project-id.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key-here"

# Kontrol et:
echo $env:SUPABASE_URL
```

**Seçenek B: Dosyayı Düzenle**

`lib/core/config/app_env.dart` dosyasını aç ve değiştir:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

### 2. Platform Dosyalarını Oluştur

```bash
flutter create . --platforms=windows,android,web
```

### 3. Debug Çalıştır

**VS Code:**
- `F5` bas
- Veya Run and Debug panel → "ClearDish (Debug)"

**Terminal:**
```bash
flutter run -d windows
```

## 🔍 Olası Sorunlar

### Sorun 1: Android SDK Yok

**Çözüm:**
```bash
# Android Studio yükle:
# https://developer.android.com/studio

# veya Windows/Web'de çalıştır:
flutter run -d windows
flutter run -d chrome
```

### Sorun 2: Supabase Bağlantı Hatası

**Hata:** "Supabase environment variables not configured"

**Çözüm:** Yukarıdaki adım 1'i yap

### Sorun 3: Bağımlılık Hatası

**Hata:** "version solving failed"

**Çözüm:**
```bash
flutter clean
flutter pub get
```

### Sorun 4: Debug Çıktı Yok

**Kontrol:**
- VS Code terminal'ini kontrol et
- Debug Console'u aç (Alt+Shift+D)
- Loglarda hata var mı?

## ✅ Başarılı Debug İşaretleri

Debug başladığında görmen gerekenler:

1. ✅ Terminal'de: "Launching lib\main.dart"
2. ✅ VS Code Debug Console: "Build complete"
3. ✅ Uygulama penceresi açılır

## 🎯 Test Senaryosu

### 1. Windows'ta Test Et:

```bash
flutter run -d windows
```

### 2. Chrome'da Test Et:

```bash
flutter run -d chrome
```

### 3. VS Code Debug:

```
F5 → ClearDish (Debug) seç
```

## 📚 Daha Fazla Yardım

- **Flutter Setup**: https://flutter.dev/docs/get-started/install/windows
- **Supabase Setup**: `SETUP_GUIDE.md`
- **Git Workflow**: `GIT_WORKFLOW.md`

---

**Unutma:** Supabase bilgileri olmadan debug çalışmayacak! 🔑

