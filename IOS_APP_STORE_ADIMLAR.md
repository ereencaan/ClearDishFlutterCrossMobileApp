# iOS App Store yayını – Adım adım (Codemagic, Mac yok)

Bundle ID: **com.hitratech.cleardish**  
Codemagic workflow: **iOS - Build & Upload to TestFlight**  
Branch: **ereen** veya **main**

---

## A. App Store Connect API anahtarı (tek seferlik)

Codemagic’in imza atıp TestFlight’a yüklemesi için **tam .p8 dosyası** şart. İndirdiğin dosya **~1,6 KB** olmalı (257 veya 347 byte değil).

### A1. Yeni API key oluştur
1. **https://appstoreconnect.apple.com** → giriş yap.
2. **Users and Access** → **Keys** (App Store Connect API).
3. **+** / **Generate API Key**.
4. **Name:** örn. `Codemagic ClearDish`.
5. **Access:** **App Manager** veya **Admin**.
6. **Generate** tıkla.

### A2. .p8 dosyasını hemen indir
7. Açılan ekranda **Download API Key** tıkla.
8. İnen **AuthKey_XXXXXXXX.p8** dosyasını kaydet (örn. `C:\Users\ereen\Downloads\`).
9. **Dosya boyutunu kontrol et:** ~**1600–1700 byte** olmalı. 300–400 byte ise yanlış/kesik.
10. Aynı ekrandan **Key ID** (10 karakter) ve **Issuer ID** (UUID) not al.

(.p8 dosyası sadece bu anda indirilebilir; sayfadan çıkınca bir daha indiremezsin.)

---

## B. Base64 parçalarını üret (Windows)

### B1. Script çalıştır
PowerShell’de (dosya yolunu kendi indirdiğin .p8 ile değiştir):

```powershell
cd "C:\Users\ereen\source\repos\Clear Dish\scripts"
.\get_p8_base64.ps1 "C:\Users\ereen\Downloads\AuthKey_XXXXXX.p8"
```

### B2. Çıktıyı kontrol et
- **Full base64 length: 22xx** (≈2000+).
- **PART2 length: 18xx** (0 olmamalı).
- `Downloads` içinde **p8_base64_part1.txt** ve **p8_base64_part2.txt** oluşur.

---

## C. Codemagic ortam değişkenleri (group: appstore)

Codemagic → **Team** → **Environment variables** → **appstore** grubu.

| Değişken | Değer |
|----------|--------|
| **APP_STORE_CONNECT_KEY_IDENTIFIER** | A2’de not ettiğin **Key ID** (10 karakter). |
| **APP_STORE_CONNECT_ISSUER_ID** | A2’de not ettiğin **Issuer ID** (UUID). |
| **APP_STORE_CONNECT_PRIVATE_KEY_BASE64** | **p8_base64_part1.txt** dosyasının tam içeriği (tek satır, tırnak yok). |
| **APP_STORE_CONNECT_PRIVATE_KEY_BASE64_PART2** | **p8_base64_part2.txt** dosyasının tam içeriği (tek satır, tırnak yok). |

**APP_STORE_CONNECT_PRIVATE_KEY** tanımlıysa **sil** (sadece PART1 + PART2 kullanılacak).

---

## D. App Store Connect’te uygulama kaydı

1. **https://appstoreconnect.apple.com** → **My Apps**.
2. **+** → **New App**.
3. **Platform:** iOS. **Name:** ClearDish. **Primary language:** English (U.K.) veya istediğin dil.
4. **Bundle ID:** Açılır listeden **com.hitratech.cleardish** seç (Xcode/Codemagic ile aynı).
5. **SKU:** örn. `cleardish-ios`. **User Access:** Full Access.
6. **Create** tıkla.

(Bundle ID yoksa: **Accounts** → **Certificates, Identifiers & Profiles** → **Identifiers** → **+** → **App IDs** → **App** → **Bundle ID:** `com.hitratech.cleardish` → kaydet.)

---

## E. Codemagic’te build

1. **https://codemagic.io** → **ClearDish** uygulaması.
2. **Start new build**.
3. **Branch:** **ereen** (veya `codemagic.yaml`’ın olduğu branch).
4. **Workflow:** **iOS - Build & Upload to TestFlight**.
5. **Start build** tıkla.

Build başarılı olursa IPA TestFlight’a yüklenir (workflow içinde **Upload IPA to TestFlight** adımı var).

---

## F. Build log kontrolü

**Set up keychain & signing** adımında:
- `Key source: base64_split, combined base64 length: 22xx`
- `Key stats: lines=28, bytes=1675` civarı
- Hata olmamalı.

**Upload IPA to TestFlight** adımı yeşil bitmeli.

---

## G. App Store Connect’te sürüm ve inceleme

1. **App Store Connect** → **My Apps** → **ClearDish**.
2. Sol menü **TestFlight** → build’in “Processing” bitene kadar bekle, sonra görünür.
3. **App Store** sekmesi → **+** ile yeni sürüm (örn. 1.0.0).
4. **Build** kısmında **+** → TestFlight’tan gelen build’i seç.
5. **What’s New**, **Description**, **Keywords**, **Screenshots** vb. doldur (store listing zorunlulukları).
6. **Save** → **Add for Review** → **Submit to App Review**.

---

## Özet kontrol

- [ ] App Store Connect’te **yeni** API key oluşturuldu, .p8 **tam boy** indirildi (~1,6 KB).
- [ ] **Key ID** ve **Issuer ID** not alındı.
- [ ] `get_p8_base64.ps1` çalıştırıldı, PART1 ve PART2 dosyaları var, PART2 boş değil.
- [ ] Codemagic **appstore** grubunda: KEY_IDENTIFIER, ISSUER_ID, BASE64 (part1), BASE64_PART2.
- [ ] App Store Connect’te **ClearDish** uygulaması ve **com.hitratech.cleardish** bundle ID kayıtlı.
- [ ] Codemagic’te **ereen** (veya ilgili branch) için **iOS - Build & Upload to TestFlight** çalıştırıldı.
- [ ] Build yeşil, TestFlight’ta build görünüyor.
- [ ] App Store sekmesinde sürüm oluşturuldu, build seçildi, **Submit to App Review** yapıldı.

Sorun çıkarsa: Build log’da **Key source** ve **combined base64 length** satırlarını kontrol et; PART2 boşsa .p8 hâlâ eksik/kesik demektir.
