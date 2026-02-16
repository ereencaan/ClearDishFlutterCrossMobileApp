# iOS imza: Codemagic UI ile kurulum (tek seferlik)

**API key nerede eklenir:** [codemagic.io/teams](https://codemagic.io/teams) → **Teams** (sol menü) → **Personal Account** (veya takım adın) → **Integrations** → **Developer Portal** satırında **Connect** / **Manage keys**.

---

**"Cannot save Signing Certificates without certificate private key"** hatası, build script’i içinde `fetch-signing-files --create` kullandığımız için çıkıyordu. Sertifika build sırasında oluşturulunca özel anahtar Codemagic tarafından saklanmıyor; bu yüzden imza başarısız oluyor.

**Çözüm:** Sertifikayı ve profili build script’inde oluşturmayı bırakıp, Codemagic arayüzünde **tek seferlik** ekleyeceksin. Build sırasında Codemagic bu dosyaları otomatik çekecek.

---

## 1. App Store Connect API anahtarını Codemagic’e ekle

**Nerede:** Codemagic’te sol menüden **Teams**’e gir. Sonra:

- **Kişisel proje (tek başına çalışıyorsan):** **Personal Account**’a tıkla.
- **Takım kullanıyorsan:** Takım adına (örn. “My Team”) tıkla.

Açılan sayfada **Integrations** bölümünü bul. Listede **Developer Portal** satırı var; yanında **Connect** (ilk kez) veya **Manage keys** (zaten bağlıysa) butonu. Ona tıkla.

1. **Connect** / **Manage keys** ile açılan yerde **Add key** (veya ilk key için doğrudan form):
   - **App Store Connect API key name:** Örn. `ClearDish AppStore`
   - **Issuer ID:** App Store Connect’teki değer (örn. `a252bc58-de70-4837-9631-2698f3bed618`).
   - **Key ID:** Örn. `P4VY8R33TV`.
   - **API key (.p8):** İndirdiğin `AuthKey_XXXXX.p8` dosyasını sürükle veya seç (içeriği env variable olarak yapıştırma).
4. **Save** ile kaydet.

Bu adımı yalnızca bir kez yapman yeterli; aynı key hem imza hem TestFlight yüklemesi için kullanılacak.

---

## 2. Distribution sertifikasını Codemagic’te oluştur

**Nerede:** Yine **Teams** → **Personal Account** (veya takım adı). Aynı sayfada **codemagic.yaml settings** (veya **Code signing identities**) bölümüne gir → **iOS certificates** sekmesi.

1. **iOS certificates** sekmesinde **Create certificate**.
3. Açılan pencerede:
   - **App Store Connect API key:** Az önce eklediğin key’i seç.
   - **Certificate type:** **Apple Distribution**.
   - **Reference name:** Örn. `ClearDish Distribution`.
4. **Generate certificate** de.

Codemagic sertifikayı Apple’da oluşturur ve **özel anahtarı kendi tarafında güvenli saklar**. Böylece “certificate private key” hatası oluşmaz.

Not: Apple hesabında dağıtım sertifikası sayısı 3 ile sınırlı. Daha önce 3 tane oluşturduysan Apple Developer Portal’dan eski bir tanesini iptal etmen gerekebilir.

---

## 3. Provisioning profile’ı ekle

**Nerede:** Aynı yer: **Teams** → **Personal Account** (veya takım) → **Code signing identities** → **iOS provisioning profiles** sekmesi.

1. **iOS provisioning profiles** sekmesinde **Fetch from Developer Portal** (veya **Download selected**).
2. **Fetch from Developer Portal** (veya **Download selected**).
3. Listeden **com.hitratech.cleardish** için **App Store** tipindeki profili seç.
4. Bir **Reference name** ver (örn. `ClearDish AppStore`) ve **Fetch** / **Fetch profiles** de.

Eğer listede bu bundle id için App Store profili yoksa:

- Önce [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list) → **Identifiers**’da `com.hitratech.cleardish` App ID’sinin tanımlı olduğundan emin ol.
- **Profiles** bölümünde **+** ile yeni profil oluştur → **App Store** → bu App ID’yi seç → az önce Codemagic’te oluşturduğun distribution sertifikasını seç → profil adı ver ve oluştur.
- Sonra Codemagic’te tekrar **Fetch from Developer Portal** yapıp bu profili çek.

---

## 4. codemagic.yaml (zaten güncellendi)

Repodaki `codemagic.yaml` artık:

- **integrations:** `app_store_connect` kullanıyor (UI’da eklediğin key).
- **ios_signing:** `distribution_type: app_store` ve `bundle_identifier: com.hitratech.cleardish` ile build’de sertifika ve profil otomatik çekiliyor.
- **publishing:** `auth: integration` ile TestFlight’a yükleme yine aynı key üzerinden.

Build script’inde `fetch-signing-files`, `keychain add-certificates` veya env’den .p8 okuma **yok**; hepsi UI üzerinden.

---

## 5. Özet kontrol listesi

- [ ] Developer Portal integration’da .p8 key eklendi (Issuer ID, Key ID, dosya).
- [ ] iOS certificates’ta **Create certificate** ile Apple Distribution sertifikası oluşturuldu.
- [ ] iOS provisioning profiles’ta **com.hitratech.cleardish** için App Store profili fetch edildi.
- [ ] `codemagic.yaml` commit edildi (integrations + ios_signing + publishing).

Bunlar tamamsa **main** veya **ereen** branch’e push ettiğinde build çalışıp IPA TestFlight’a yüklenecek. “Cannot save Signing Certificates without certificate private key” hatası bu akışta oluşmamalı.

Sorun devam ederse Codemagic build log’unda hangi adımda (keychain, certificate fetch, profile fetch, vs.) hata aldığını paylaşırsan bir sonraki adımı netleştirebiliriz.
