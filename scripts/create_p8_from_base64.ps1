# Base64'ten Codemagic'e yuklenecek temiz .p8 dosyasi olusturur.
# Kullanim: .\create_p8_from_base64.ps1
#   Script, p8_base64.txt dosyasini arar (veya -Base64 parametresi verirsin).
#   Cikti: AuthKey_clean.p8 (UTF-8, LF; Codemagic upload icin).

param(
  [string]$Base64 = "",
  [string]$Base64File = "p8_base64.txt"
)

if ($Base64) {
  $b64 = $Base64.Trim()
} else {
  $paths = @(
    $Base64File,
    (Join-Path $PSScriptRoot $Base64File),
    (Join-Path (Get-Location) $Base64File)
  )
  $found = $null
  foreach ($p in $paths) {
    if (Test-Path $p) {
      $found = $p
      break
    }
  }
  if (-not $found) {
    Write-Host "Base64 bulunamadi. Ya -Base64 '...' ver ya da $Base64File dosyasini script ile ayni klasore koy." -ForegroundColor Red
    Write-Host "Codemagic'teki APP_STORE_CONNECT_PRIVATE_KEY_BASE64 degerini kopyalayip p8_base64.txt olarak kaydet, sonra tekrar calistir." -ForegroundColor Yellow
    exit 1
  }
  $b64 = (Get-Content -Path $found -Raw).Trim().Replace("`r", "").Replace("`n", "").Replace(" ", "")
}

$bytes = [Convert]::FromBase64String($b64)
$outPath = Join-Path (Get-Location) "AuthKey_clean.p8"

# PEM metni ise aynen yaz (LF ile); binary ise binary yaz
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
if ($text -match "BEGIN PRIVATE KEY") {
  # PEM: Windows CRLF'i LF yap, UTF-8 no BOM ile kaydet
  $lines = $text -split "`r?`n"
  $clean = $lines -join "`n"
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($outPath, $clean, $utf8NoBom)
} else {
  [IO.File]::WriteAllBytes($outPath, $bytes)
}

Write-Host "Olusturuldu: $outPath"
Write-Host "Bu dosyayi Codemagic Developer Portal integration'a surukle / sec." -ForegroundColor Green
