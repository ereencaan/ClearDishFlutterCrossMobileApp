# 🚀 ClearDish - Sonraki Adımlar

## ✅ Şimdi Ne Yapmalı?

### 1️⃣ Supabase'de Migration Çalıştır
- SQL Editor → `MIGRATION_STEPS.md` içindeki SQL'leri çalıştır
- Table Editor'da kontrol et

### 2️⃣ Flutter'a Supabase Bilgilerini Ekle
Project Settings → API'den alacağın bilgiler:

**URL:** `https://xxxxx.supabase.co`
**Anon Key:** `eyJhbGci...`

**Ekleyeceğin yer:**
```powershell
$env:SUPABASE_URL="https://xxxxx.supabase.co"
$env:SUPABASE_ANON_KEY="eyJhbGci..."
```

### 3️⃣ Debug Çalıştır

```bash
flutter run -d windows
# veya
flutter run -d chrome
# veya VS Code'da F5
```

### 4️⃣ Test Et

1. Register → Yeni kullanıcı oluştur
2. Onboarding → Alerjen seç
3. Restaurants → 3 restoran görmeli
4. Menu → Safe Only toggle test et
5. Profile → Bilgileri güncelle

## 📚 Dosyalar

- `MIGRATION_STEPS.md` - SQL komutları
- `DEBUG_TROUBLESHOOTING.md` - Debug sorunları
- `SETUP_GUIDE.md` - Detaylı kurulum
- `GIT_WORKFLOW.md` - Git kullanımı

## 🎯 Hızlı Komutlar

```bash
# Migration çalıştır (Supabase Dashboard'da)
# SQL Editor → MIGRATION_STEPS.md'deki SQL'leri kopyala-yapıştır

# Supabase bilgilerini ayarla
$env:SUPABASE_URL="..."
$env:SUPABASE_ANON_KEY="..."

# Debug çalıştır
flutter run -d windows

# GitHub'a push
git add .
git commit -m "Feature: açıklama"
git push origin ereen  # veya bengisu
```

---

**Her şey hazır! Supabase migration'dan başla! 🎉**
