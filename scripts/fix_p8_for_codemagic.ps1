# .p8 dosyasini Codemagic'in kabul edecegi formata cevirir (UTF-8, LF).
# Kullanim: .\scripts\fix_p8_for_codemagic.ps1 "C:\yol\AuthKey_XXXXX.p8"

param(
  [Parameter(Mandatory = $true)]
  [string]$P8Path
)

$fullPath = $PSScriptRoot
if (-not [IO.Path]::IsPathRooted($P8Path)) {
  $P8Path = Join-Path (Get-Location) $P8Path
}
if (-not (Test-Path $P8Path)) {
  Write-Host "Dosya bulunamadi: $P8Path" -ForegroundColor Red
  exit 1
}

$content = [IO.File]::ReadAllText($P8Path)
# CRLF ve diger kirli karakterleri LF yap
$content = $content -replace "`r`n", "`n" -replace "`r", "`n"
# UTF-8, BOM yok
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$outPath = Join-Path (Split-Path $P8Path) "AuthKey_clean.p8"
[IO.File]::WriteAllText($outPath, $content, $utf8NoBom)

Write-Host "Hazir: $outPath" -ForegroundColor Green
Write-Host "Bu dosyayi Codemagic'e yukle (Developer Portal -> API key)." -ForegroundColor Cyan
