# Google Play – Yeni release yükleme (adım adım)

## BÖLÜM A: Bilgisayarda (PowerShell)

### Adım 1 – Proje klasörüne geç
```
cd "C:\Users\ereen\source\repos\Clear Dish"
```

### Adım 2 – AAB oluştur
```
flutter build appbundle --release
```
Bittiğinde şu dosya oluşacak:  
`C:\Users\ereen\source\repos\Clear Dish\build\app\outputs\bundle\release\app-release.aab`

### Adım 3 – Dosyayı kontrol et
Dosya Gezgini ile aç:  
`C:\Users\ereen\source\repos\Clear Dish\build\app\outputs\bundle\release\`  
İçinde **app-release.aab** olmalı. Bu dosyayı yükleyeceksin.

---

## BÖLÜM B: Play Console’da

### Adım 4 – Play Console’u aç
Tarayıcıda: **https://play.google.com/console**  
Giriş yap. **ClearDish** uygulamasını seç.

### Adım 5 – Production release sayfasına git
Sol menüden sırayla:
1. **Release** tıkla  
2. **Production** tıkla  
(Open testing değil, **Production**)

### Adım 6 – Yeni release oluştur
Sayfada **“Create new release”** (veya “Create and roll out a release”) butonuna tıkla.

### Adım 7 – AAB yükle
1. **“App bundles”** bölümünde **“Upload”** (veya “Upload new” / “Upload app bundle”) butonuna tıkla.  
2. Açılan pencerede şu dosyayı seç:  
   `C:\Users\ereen\source\repos\Clear Dish\build\app\outputs\bundle\release\app-release.aab`  
3. Yükleme bitene kadar bekle.  
4. Tabloda “Version 3 (1.0.0)” satırı görünmeli.  
5. Başka AAB ekleme. Sadece bu tek AAB olsun.

### Adım 8 – Release name yaz
**“Release name”** kutusuna yaz (örnek):  
`1.0.0 (3) - Icon fix`

### Adım 9 – Release notes yaz
**“Release notes”** bölümünde **en-GB** (veya zorunlu dil) için örnek:  
`Icon updated to match store listing. No text on app icon.`

### Adım 10 – Store listing ikonunu güncelle (önemli)
1. Sol menüden **“Store presence”** → **“Main store listing”** tıkla.  
2. **“App icon”** alanını bul.  
3. **“Edit”** veya ikon alanına tıkla.  
4. Bilgisayardan **aynı yazısız ikonu** yükle:  
   `C:\Users\ereen\source\repos\Clear Dish\assets\branding\app_icon.png`  
5. Kaydet.  
(Bunu release’ten önce veya aynı gün yap; mağaza ikonu = uygulama ikonu aynı olsun.)

### Adım 11 – Release’i kaydet
Release sayfasına dön (Release → Production).  
Altta **“Save”** butonuna tıkla.

### Adım 12 – İncelemeye gönder
1. **“Review release”** butonuna tıkla.  
2. Açılan ekranda **“Start rollout to Production”** (veya “Send for review”) butonuna tıkla.  
3. Onay ver.  
Release “In review” olacak. Birkaç saat / birkaç gün içinde onaylanır veya red açıklaması gelir.

---

## Özet kontrol listesi

- [ ] `flutter build appbundle --release` çalıştırıldı  
- [ ] `app-release.aab` dosyası var  
- [ ] Play Console → Release → Production  
- [ ] Create new release  
- [ ] AAB yüklendi (Upload)  
- [ ] Release name yazıldı  
- [ ] Release notes yazıldı  
- [ ] Store presence → Main store listing → App icon = app_icon.png (yazısız)  
- [ ] Save → Review release → Start rollout to Production  

Bunların hepsi tamamsa yeni release yüklenmiş ve incelemeye gitmiş demektir.
