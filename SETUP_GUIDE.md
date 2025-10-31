# 🚀 ClearDish - Hızlı Başlangıç Kılavuzu

## 1️⃣ Supabase Projesi Oluştur

1. [supabase.com](https://supabase.com) → "Start your project" → Hesap oluştur/giriş yap
2. "New Project" → Proje adı: `cleardish` → Şifre oluştur → "Create new project"
3. Proje oluşturulurken bekle (2-3 dakika)

## 2️⃣ Supabase Ayarlarını Al

Supabase Dashboard → **Project Settings** → **API** bölümünden:

- **Project URL**: `https://xxxxx.supabase.co` (bu `SUPABASE_URL`)
- **anon/public key**: `eyJhbG...` (bu `SUPABASE_ANON_KEY`)

⚠️ Bu anahtarları kaydet, güvenli tut!

## 3️⃣ Flutter Ortam Değişkenlerini Ayarla

### Seçenek A: .env Dosyası (Önerilir - gelecekte flutter_dotenv eklenebilir)

Şu anda `String.fromEnvironment` kullanıyoruz. İki seçenek var:

#### Windows PowerShell:
```powershell
$env:SUPABASE_URL="https://your-project-id.supabase.co"
$env:SUPABASE_ANON_KEY="your-anon-key-here"
```

#### Windows CMD:
```cmd
set SUPABASE_URL=https://your-project-id.supabase.co
set SUPABASE_ANON_KEY=your-anon-key-here
```

#### Alternatif: app_env.dart'ı Düzenle (Geçici)

`lib/core/config/app_env.dart` dosyasını aç ve değerleri değiştir:

```dart
static const String supabaseUrl = 'https://your-project-id.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';
```

## 4️⃣ Database Migration

1. Supabase Dashboard → **SQL Editor**
2. "New query" → Aşağıdaki dosyaları sırayla çalıştır:

   **Adım 1:** `supabase/migrations/001_initial_schema.sql` içeriğini kopyala-yapıştır → "Run"
   
   **Adım 2:** `supabase/migrations/002_seed_data.sql` içeriğini kopyala-yapıştır → "Run"

3. **Table Editor**'da şunları görmelisin:
   - ✅ `user_profiles`
   - ✅ `restaurants` (3 kayıt)
   - ✅ `menu_categories` (8 kayıt)
   - ✅ `menu_items` (20 kayıt)

## 5️⃣ Flutter Projesini Çalıştır

Terminalde:

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır (emulator veya cihaz bağlı olmalı)
flutter run
```

### İlk Açılış Kontrol Listesi:

- ✅ Login ekranı görünüyor mu?
- ✅ "Sign Up" butonu çalışıyor mu?
- ✅ Yeni kullanıcı kaydı yapılabiliyor mu?

## 6️⃣ MVP Akışını Test Et

### Test Senaryosu:

1. **Register** → Yeni hesap oluştur:
   - Email: `test@cleardish.co.uk`
   - Password: `Test123!`

2. **Onboarding** → Alerjen seç:
   - ✅ Gluten
   - ✅ Peanut
   - "Continue" tıkla

3. **Restaurants** → Listede 3 restoran görünmeli:
   - Green Garden Cafe
   - Ocean Breeze Seafood
   - The Vegan Corner

4. **Menu (Green Garden Cafe)** → "Safe Only" toggle'ı aç:
   - Gluten içeren ürünler gizlenmeli
   - "X item(s) hidden" mesajı görünmeli

5. **Profile** → Alerjenleri güncelle:
   - Yeni alerjen ekle (örn: Milk)
   - "Save Profile" → Başarı mesajı görünmeli

## 7️⃣ Sorun Giderme

### Hata: "Supabase environment variables not configured"

**Çözüm:** Ortam değişkenlerini ayarla (Yukarıdaki 3. adım)

### Hata: "Failed to fetch restaurants"

**Kontrol:**
- ✅ Migration dosyaları çalıştırıldı mı?
- ✅ Supabase URL ve Key doğru mu?
- ✅ RLS policies aktif mi? (SQL Editor'da kontrol et)

### Hata: "Unable to connect to Supabase"

**Kontrol:**
- ✅ İnternet bağlantısı var mı?
- ✅ Supabase projesi aktif mi? (Dashboard'da kontrol et)
- ✅ URL'de `https://` var mı?

## 8️⃣ Sonraki Adımlar

Proje çalışıyor mu? 🎉

Şimdi şunlardan birini seç:

1. **UI/UX İyileştirmeleri** → Logo, renkler, animasyonlar
2. **Demo Video Hazırlama** → Endorsement paneli için kayıt
3. **Ödeme Ekranı** → Stripe placeholder geliştirme

---

## 📚 Supabase Nedir?

**Supabase** = Firebase'in açık kaynak alternatifi

- ✅ **Authentication**: Email/şifre, Google, GitHub vb. login
- ✅ **Database**: PostgreSQL (güçlü SQL veritabanı)
- ✅ **Realtime**: Anlık veri güncellemeleri
- ✅ **Storage**: Dosya yükleme (resim, PDF vb.)
- ✅ **Row Level Security (RLS)**: Veri güvenliği

**Neden Supabase?**
- Ücretsiz tier (yeterli MVP için)
- SQL kullanabiliyorsun (PostgreSQL)
- Firebase'den daha esnek
- Açık kaynak

---

## 🔗 Faydalı Linkler

- [Supabase Docs](https://supabase.com/docs)
- [Flutter + Supabase Guide](https://supabase.com/docs/guides/getting-started/flutter)
- [ClearDish README](./README.md)

