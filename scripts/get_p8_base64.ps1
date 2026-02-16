# Run this to get the base64 of your App Store Connect .p8 key for Codemagic.
# Usage: .\get_p8_base64.ps1 "C:\Users\ereen\Downloads\AuthKey_73FVMBNP9C.p8"
# Outputs: p8_base64.txt (full), p8_base64_part1.txt, p8_base64_part2.txt (for Codemagic env limit workaround).

param(
  [Parameter(Mandatory = $true)]
  [string]$P8Path
)

if (-not (Test-Path $P8Path)) {
  Write-Error "File not found: $P8Path"
  exit 1
}

$bytes = [IO.File]::ReadAllBytes($P8Path)
$b64 = [Convert]::ToBase64String($bytes)
$dir = Split-Path $P8Path

$b64 | Set-Content -Path (Join-Path $dir "p8_base64.txt") -NoNewline -Encoding UTF8
Write-Host "Full base64 length: $($b64.Length)"

# .p8 is ~1675 bytes => base64 ~2230 chars. If much smaller, file is truncated.
if ($b64.Length -lt 2000) {
  Write-Host ""
  Write-Host "WARNING: Your .p8 file is too small ($($b64.Length) chars). A full key is ~2200+ chars." -ForegroundColor Yellow
  Write-Host "Re-download the key from App Store Connect (Users and Access -> Keys -> Download .p8)." -ForegroundColor Yellow
  Write-Host "You can only download it ONCE when the key is created; if you lost it, create a NEW key." -ForegroundColor Yellow
}

# Split for Codemagic (first ~400 chars often truncated; rest in PART2).
$splitAt = 400
$part1 = if ($b64.Length -ge $splitAt) { $b64.Substring(0, $splitAt) } else { $b64 }
$part2 = if ($b64.Length -gt $splitAt) { $b64.Substring($splitAt) } else { "" }
$part1 | Set-Content -Path (Join-Path $dir "p8_base64_part1.txt") -NoNewline -Encoding UTF8
$part2 | Set-Content -Path (Join-Path $dir "p8_base64_part2.txt") -NoNewline -Encoding UTF8
Write-Host "PART1 length: $($part1.Length) -> p8_base64_part1.txt"
Write-Host "PART2 length: $($part2.Length) -> p8_base64_part2.txt"
if ([string]::IsNullOrEmpty($part2)) {
  Write-Host ""
  Write-Host "PART2 is empty because the key file is too short. Use a full .p8 file (~1.6 KB)." -ForegroundColor Red
} else {
  Write-Host ""
  Write-Host "In Codemagic (group: appstore):"
  Write-Host "  1. APP_STORE_CONNECT_PRIVATE_KEY_BASE64 = contents of p8_base64_part1.txt"
  Write-Host "  2. APP_STORE_CONNECT_PRIVATE_KEY_BASE64_PART2 = contents of p8_base64_part2.txt"
  Write-Host "  (No quotes, paste each file content as one line.)"
}
