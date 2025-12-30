<#
.SYNOPSIS
Validates palette key usage in an Oh My Posh config file.

.DESCRIPTION
This script checks that all palette keys referenced in the config file are defined, and reports any unused palette keys.
It outputs lists of defined and referenced keys, missing entries (referenced but not defined), and unused entries (defined but not referenced).

.PARAMETER ConfigPath
Path to the Oh My Posh config JSON file. If not provided, defaults to 'OhMyPosh-Atomic-Custom.json'.

.EXITCODES
0 - No missing or unused palette entries.
1 - Config file not found or JSON parse error.
2 - Missing palette entries (referenced but not defined). Takes precedence if both missing and unused entries exist.
3 - Unused palette entries (defined but never referenced), only if there are no missing entries.

.EXAMPLE
.\validate-palette.ps1 -ConfigPath '.\OhMyPosh-Atomic-Custom.json'
#>

# Default value for $ConfigPath is 'OhMyPosh-Atomic-Custom.json'
param(
    [string]$ConfigPath = 'OhMyPosh-Atomic-Custom.json'
)

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found: $ConfigPath"
    exit 1
}

try {
    $rawContent = Get-Content $ConfigPath -Raw
    $json = $rawContent | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse JSON in config file: $ConfigPath.`nError details: $($_.Exception.Message)"
    exit 1
}
# Extract all palette keys from the JSON object for comparison
if ($null -eq $json.Palette -or -not ($json.Palette -is [psobject]) -or -not $json.Palette.PSObject.Properties) {
    Write-Error "Palette property is missing or not an object in config file: $ConfigPath"
    exit 1
}
$palette = $json.Palette.PSObject.Properties.Name

# Find all p:<key> references (including inside templates)
$refs = [regex]::Matches($rawContent,'p:([a-zA-Z0-9_\-\.]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

$missing = $refs | Where-Object { $_ -notin $palette }
$unused = $palette | Where-Object { $_ -notin $refs }

Write-Output "Palette keys ($($palette.Count)):" -ForegroundColor Cyan
$paletteSorted = $palette | Sort-Object
$paletteSorted | ForEach-Object { Write-Output "  - $_" }

Write-Output "`nReferenced keys ($($refs.Count)):" -ForegroundColor Cyan
$refsSorted = $refs | Sort-Object
$refsSorted | ForEach-Object { Write-Output "  - $_" }

if ($missing) {
    Write-Output "`nMissing palette entries (referenced but not defined):" -ForegroundColor Red
    Write-Output "The following referenced keys are missing from the palette:" -ForegroundColor Red
    $missingSorted = $missing | Sort-Object
    $missingSorted | ForEach-Object { Write-Output "  - $_" }
}
else {
    Write-Output "`nNo missing palette entries." -ForegroundColor Green
}

if ($unused) {
    Write-Output "`nUnused palette entries (defined but never referenced):" -ForegroundColor Yellow
    $unusedSorted = $unused | Sort-Object
    $unusedSorted | ForEach-Object { Write-Output "  - $_" }
}
else {
    Write-Output "`nNo unused palette entries." -ForegroundColor Green
}

# Exit code: 0 if clean, 1 if file not found or JSON parse error, 2 if missing, 3 if unused only
if ($missing) { exit 2 }
elseif ($unused) { exit 3 }
else { exit 0 }
