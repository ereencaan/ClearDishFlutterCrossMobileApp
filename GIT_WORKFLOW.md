# 🌿 Git Branch Workflow - ClearDish

## 📋 Branch'ler

Projede 3 branch var:

1. **`main`** - Production branch (deploy edilecek sürüm)
2. **`ereen`** - Eren'in geliştirme branch'i
3. **`bengisu`** - Bengisu'nun geliştirme branch'i

## 🔄 Çalışma Akışı

### Günlük Çalışma:

```bash
# 1. Kendi branch'ine geç
git checkout ereen     # veya git checkout bengisu

# 2. Güncel kal
git pull origin main   # main'den güncellemeleri çek

# 3. Değişiklik yap, commit et
git add .
git commit -m "Feature: Açıklama"

# 4. Kendi branch'ine push et
git push origin ereen  # veya git push origin bengisu
```

### Main'e Birleştirme:

```bash
# 1. Main branch'ine geç
git checkout main

# 2. Kendi branch'inden merge et
git merge ereen    # veya git merge bengisu

# 3. Main'e push et
git push origin main
```

## 🚀 İlk GitHub'a Push

### GitHub Repository Oluştur:

1. GitHub'da: `ereencaan / ClearDishFlutterCrossMobileApp` repository var
2. URL: `https://github.com/ereencaan/ClearDishFlutterCrossMobileApp`

### İlk Push:

```bash
# Remote ekle
git remote add origin https://github.com/ereencaan/ClearDishFlutterCrossMobileApp.git

# Tüm branch'leri push et
git push -u origin main
git push -u origin ereen
git push -u origin bengisu
```

## 📝 Commit Mesajları

İyi commit mesajı örnekleri:

```bash
# Feature eklendi
git commit -m "Feature: User profile allergen filtering"

# Bug düzeltildi
git commit -m "Fix: Menu safe toggle not working"

# UI güncellemesi
git commit -m "UI: Update restaurant card design"

# Refactor
git commit -m "Refactor: Simplify menu controller logic"
```

**Format**: `[Type]: [Açıklama]`

**Types**: `Feature`, `Fix`, `UI`, `Refactor`, `Docs`, `Test`

## 🔀 Pull Request (Bonus)

GitHub'da Pull Request kullanmak istersen:

1. Kendi branch'inizden değişiklikleri push edin
2. GitHub'da "Compare & pull request" butonuna tıklayın
3. Main'e merge etmeden önce code review yapın

## ⚠️ Önemli Kurallar

1. ✅ **Main branch'e direkt commit YOK**
2. ✅ **Her zaman kendi branch'inde çalış**
3. ✅ **Main'e merge etmeden önce test et**
4. ✅ **Commit mesajlarını açıklayıcı yaz**

## 🆘 Yardımcı Komutlar

```bash
# Branch'leri görüntüle
git branch -a

# Hangi branch'teyim?
git branch

# Değişiklikleri gör
git status

# Son commit'leri gör
git log --oneline -10

# Belirli branch'i sil (dikkatli!)
git branch -d branch-name
```

## 🎯 Hızlı Başlangıç

```bash
# Eren için:
git checkout ereen
git pull origin main  # İlk seferde bu komut çalışmayabilir
# Çalış ve commit et
git push origin ereen

# Bengisu için:
git checkout bengisu
git pull origin main
# Çalış ve commit et
git push origin bengisu
```

---

**Sorun mu var?** `.gitignore` dosyasını kontrol et, gerekirse ekle!

