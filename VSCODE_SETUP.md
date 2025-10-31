# 📝 VS Code Kurulum Kılavuzu - ClearDish

## 🔌 Gerekli Extension'lar

### ✅ Zorunlu Extension'lar (Mutlaka Kur)

1. **Dart** (`dart-code.dart-code`)
   - Flutter/Dart geliştirme için temel extension
   - Otomatik format, syntax highlighting, debugging

2. **Flutter** (`dart-code.flutter`)
   - Flutter-specific özellikler
   - Hot reload, device selection, pub commands

### 🎨 Önerilen Extension'lar

3. **Prettier** (`esbenp.prettier-vscode`)
   - Kod formatlama (Dart için de kullanılabilir)

4. **Error Lens** (`usernamehw.errorlens`)
   - Hataları satır içinde gösterir

5. **Better Comments** (`aaron-bond.better-comments`)
   - Daha iyi yorum görünümü

6. **YAML** (`redhat.vscode-yaml`)
   - YAML dosyaları için syntax desteği

---

## 🚀 Hızlı Kurulum

### Yöntem 1: Otomatik (Önerilir)

VS Code'da projeyi açtığında `.vscode/extensions.json` dosyası sayesinde otomatik öneri gelecek:

1. VS Code'u aç
2. Projeyi aç: `File → Open Folder → Clear Dish`
3. Sağ alt köşede bildirim çıkacak: **"Install Recommended Extensions"**
4. Tıkla → Tüm extension'lar otomatik yüklenecek

### Yöntem 2: Manuel Kurulum

VS Code → **Extensions** (Ctrl+Shift+X) → Şu extension'ları ara ve kur:

```
Dart
Flutter
Error Lens
Prettier
Better Comments
YAML
```

---

## ⚙️ VS Code Ayarları

Proje içinde `.vscode/settings.json` dosyası var - otomatik ayarlanır:

- ✅ Format on save (kaydetmede otomatik format)
- ✅ Dart/Flutter lint kuralları
- ✅ Dosya exclude ayarları
- ✅ Editor ayarları

**Eğer global ayarlar istersen:**

VS Code → `File → Preferences → Settings` (Ctrl+,) → Şunları ekle:

```json
{
  "dart.flutterSdkPath": null,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "Dart-Code.dart-code"
}
```

---

## 🐛 Debug Yapılandırması

`.vscode/launch.json` dosyası hazır:

### Debug Modu:
1. VS Code'da `F5` bas
2. Veya sol menüden **Run and Debug** → **ClearDish (Debug)**

### Profile Modu:
- **ClearDish (Profile)** → Performans testi için

### Release Modu:
- **ClearDish (Release)** → Production build

---

## 📋 Kurulum Kontrolü

### Extension'ları Kontrol Et:

1. VS Code → Extensions (Ctrl+Shift+X)
2. "Installed" bölümünde şunlar olmalı:
   - ✅ Dart
   - ✅ Flutter
   - ✅ Error Lens (opsiyonel)
   - ✅ Prettier (opsiyonel)

### Test Et:

1. `lib/main.dart` dosyasını aç
2. Syntax highlighting çalışıyor mu? (renkli kod)
3. Alt kısımda "Flutter" yazıyor mu? (status bar)
4. `Ctrl+Shift+P` → "Flutter: Select Device" çalışıyor mu?

---

## 🎯 VS Code Kısayolları (Flutter için)

| Kısayol | Açıklama |
|---------|----------|
| `F5` | Debug başlat |
| `Ctrl+F5` | Debug olmadan çalıştır |
| `Shift+F5` | Debug'u durdur |
| `Ctrl+Shift+P` → "Flutter: Hot Reload" | Hot reload (r) |
| `Ctrl+Shift+P` → "Flutter: Hot Restart" | Hot restart (R) |
| `Ctrl+Shift+P` → "Flutter: Select Device" | Cihaz seç |
| `Alt+Shift+F` | Format code |

---

## 🔧 Sorun Giderme

### Extension Yüklenmiyor:

```bash
# VS Code'u kapat ve tekrar aç
# Veya:
code --install-extension dart-code.dart-code
code --install-extension dart-code.flutter
```

### Format Çalışmıyor:

1. Settings → "editor.defaultFormatter" → "Dart-Code.dart-code" seç
2. Settings → "editor.formatOnSave" → ✅ işaretle

### Debug Çalışmıyor:

1. Flutter SDK kurulu mu? (`flutter doctor`)
2. Cihaz bağlı mı? (`flutter devices`)
3. `launch.json` doğru mu kontrol et

### Syntax Highlighting Yok:

1. Dart extension kurulu mu?
2. Dosya uzantısı `.dart` mı?
3. VS Code'u yeniden başlat

---

## ✅ Kurulum Tamamlandı!

Artık VS Code'da:

- ✅ Kod yazarken autocomplete çalışır
- ✅ Hatalar kırmızı çizgi ile gösterilir
- ✅ `F5` ile debug yapabilirsin
- ✅ Hot reload ile anında değişiklik görürsün
- ✅ Format otomatik yapılır

---

## 📚 Ek Kaynaklar

- [Flutter VS Code Setup](https://docs.flutter.dev/get-started/editor?tab=vscode)
- [Dart Extension Docs](https://dartcode.org/)
- [VS Code Keyboard Shortcuts](https://code.visualstudio.com/docs/getstarted/keybindings)
