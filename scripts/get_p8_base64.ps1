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

# Split for Codemagic (first ~400 chars often truncated; rest in PART2).
$splitAt = 400
$part1 = $b64.Substring(0, [Math]::Min($splitAt, $b64.Length))
$part2 = $b64.Substring([Math]::Min($splitAt, $b64.Length))
$part1 | Set-Content -Path (Join-Path $dir "p8_base64_part1.txt") -NoNewline -Encoding UTF8
$part2 | Set-Content -Path (Join-Path $dir "p8_base64_part2.txt") -NoNewline -Encoding UTF8
Write-Host "PART1 length: $($part1.Length) -> p8_base64_part1.txt"
Write-Host "PART2 length: $($part2.Length) -> p8_base64_part2.txt"
Write-Host ""
Write-Host "In Codemagic (group: appstore):"
Write-Host "  1. APP_STORE_CONNECT_PRIVATE_KEY_BASE64 = contents of p8_base64_part1.txt"
Write-Host "  2. APP_STORE_CONNECT_PRIVATE_KEY_BASE64_PART2 = contents of p8_base64_part2.txt"
Write-Host "  (No quotes, paste each file content as one line.)"
