# ClearDish Kurulum Scripti
# PowerShell'de çalıştır: .\install.ps1

Write-Host "🚀 ClearDish Kurulum Başlatılıyor..." -ForegroundColor Green

# 1. Flutter Kontrolü
Write-Host "`n📦 Flutter kontrol ediliyor..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter kurulu: $($flutterVersion[0])" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Flutter bulunamadı!" -ForegroundColor Red
    Write-Host "   Flutter'ı yüklemek için: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# 2. Proje Dizinini Kontrol Et
Write-Host "`n📁 Proje dizini kontrol ediliyor..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host "✅ Proje dizini bulundu" -ForegroundColor Green
} else {
    Write-Host "❌ pubspec.yaml bulunamadı! Doğru dizinde misin?" -ForegroundColor Red
    exit 1
}

# 3. Bağımlılıkları Yükle
Write-Host "`n📥 Bağımlılıklar yükleniyor..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Bağımlılıklar yüklendi" -ForegroundColor Green
} else {
    Write-Host "❌ Bağımlılık yükleme başarısız!" -ForegroundColor Red
    exit 1
}

# 4. Ortam Değişkenlerini Kontrol Et
Write-Host "`n🔐 Ortam değişkenleri kontrol ediliyor..." -ForegroundColor Yellow
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_ANON_KEY

if ($supabaseUrl -and $supabaseKey -and 
    $supabaseUrl -ne "YOUR_SUPABASE_URL" -and 
    $supabaseKey -ne "YOUR_SUPABASE_ANON_KEY") {
    Write-Host "✅ Ortam değişkenleri ayarlı" -ForegroundColor Green
    Write-Host "   URL: $supabaseUrl" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Ortam değişkenleri ayarlanmamış!" -ForegroundColor Yellow
    Write-Host "`nOrtam değişkenlerini ayarlamak için:" -ForegroundColor Cyan
    Write-Host '   $env:SUPABASE_URL="https://your-project-id.supabase.co"' -ForegroundColor White
    Write-Host '   $env:SUPABASE_ANON_KEY="your-anon-key-here"' -ForegroundColor White
    Write-Host "`nVeya lib/core/config/app_env.dart dosyasını düzenle" -ForegroundColor Cyan
}

# 5. Flutter Analyze
Write-Host "`n🔍 Kod analizi yapılıyor..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Kod analizi tamamlandı" -ForegroundColor Green
} else {
    Write-Host "⚠️  Bazı uyarılar bulundu (normal olabilir)" -ForegroundColor Yellow
}

# 6. Cihaz Kontrolü
Write-Host "`n📱 Bağlı cihazlar kontrol ediliyor..." -ForegroundColor Yellow
$devices = flutter devices
if ($devices -match "device") {
    Write-Host "✅ Cihaz bulundu" -ForegroundColor Green
    Write-Host $devices -ForegroundColor Gray
} else {
    Write-Host "⚠️  Hiç cihaz bulunamadı!" -ForegroundColor Yellow
    Write-Host "   Emulator başlat veya USB ile cihaz bağla" -ForegroundColor Cyan
}

# 7. Özet
Write-Host "`n" -NoNewline
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "📋 Kurulum Özeti" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Cyan

Write-Host "`n✅ Tamamlanan adımlar:" -ForegroundColor Green
Write-Host "   1. Flutter kontrolü" -ForegroundColor White
Write-Host "   2. Bağımlılıklar yüklendi" -ForegroundColor White
Write-Host "   3. Kod analizi yapıldı" -ForegroundColor White

Write-Host "`n⏭️  Sonraki adımlar:" -ForegroundColor Yellow
Write-Host "   1. Supabase projesi oluştur: https://app.supabase.com" -ForegroundColor White
Write-Host "   2. Migration dosyalarını çalıştır (SQL Editor)" -ForegroundColor White
Write-Host "   3. Ortam değişkenlerini ayarla" -ForegroundColor White
Write-Host "   4. flutter run komutuyla uygulamayı başlat" -ForegroundColor White

Write-Host "`n📚 Detaylı kılavuz: KURULUM.md dosyasına bak" -ForegroundColor Cyan
Write-Host "`n🚀 Uygulamayı çalıştırmak için: flutter run" -ForegroundColor Green


