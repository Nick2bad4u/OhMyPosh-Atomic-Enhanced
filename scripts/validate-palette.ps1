<#
.SYNOPSIS
Validates palette key usage in an Oh My Posh config file.

.DESCRIPTION
This script checks that all palette keys referenced in the config file are defined, and reports any unused palette keys.
It outputs lists of defined and referenced keys, missing entries (referenced but not defined), and unused entries (defined but not referenced).

.PARAMETER ConfigPath
Path to the Oh My Posh config JSON file. If not provided, defaults to 'OhMyPosh-Atomic-Custom.json'.

.EXITCODES
0 - No missing palette entries (unused entries are allowed by default).
1 - Config file not found or JSON parse error.
2 - Missing palette entries (referenced but not defined).
3 - Unused palette entries (defined but never referenced) when -FailOnUnused is set.

.EXAMPLE
.\scripts\validate-palette.ps1 -ConfigPath '.\OhMyPosh-Atomic-Custom.json'
#>

# Default value for $ConfigPath is 'OhMyPosh-Atomic-Custom.json'
param(
    [string]$ConfigPath = (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'OhMyPosh-Atomic-Custom.json'),
    [switch]$FailOnUnused,
    [switch]$ShowAll
)

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

$ConfigPath = Resolve-RepoPath -Path $ConfigPath

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Error "Config file not found: $ConfigPath"
    exit 1
}

try {
    $rawContent = Get-Content -LiteralPath $ConfigPath -Raw
    # NOTE: ConvertFrom-Json will throw if the JSON contains duplicate keys.
    # We keep this strict on purpose so generator issues are caught early.
    $json = $rawContent | ConvertFrom-Json -Depth 100
}
catch {
    Write-Error "Failed to parse JSON in config file: $ConfigPath.`nError details: $($_.Exception.Message)"
    exit 1
}
# Extract all palette keys from the JSON object for comparison.
if ($null -eq $json.palette -or -not ($json.palette -is [psobject]) -or -not $json.palette.PSObject.Properties) {
    Write-Error "Palette property is missing or not an object in config file: $ConfigPath"
    exit 1
}

$palette = @($json.palette.PSObject.Properties.Name)
if ($json.extends) {
    $basePath = if ([string]$json.extends -match '^https://') {
        Join-Path -Path $RepoRoot -ChildPath ([System.IO.Path]::GetFileName(([uri]$json.extends).AbsolutePath))
    }
    elseif ([System.IO.Path]::IsPathRooted([string]$json.extends)) {
        [string]$json.extends
    }
    else {
        Join-Path -Path (Split-Path -Path $ConfigPath -Parent) -ChildPath ([string]$json.extends)
    }

    if (-not (Test-Path -LiteralPath $basePath)) {
        Write-Error "Unable to resolve extended base locally: $basePath"
        exit 1
    }

    try {
        $baseRawContent = Get-Content -LiteralPath $basePath -Raw
        $baseJson = $baseRawContent | ConvertFrom-Json -Depth 100
    }
    catch {
        Write-Error "Failed to parse extended base config: $basePath.`nError details: $($_.Exception.Message)"
        exit 1
    }

    $palette = @($palette + @($baseJson.palette.PSObject.Properties.Name) | Sort-Object -Unique)
    $rawContent = $baseRawContent
}

# Find all p:<key> references (including inside templates)
$refs = [regex]::Matches($rawContent, 'p:([a-zA-Z0-9_\-\.]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

$missing = @($refs | Where-Object { $_ -notin $palette })
$unused = @($palette | Where-Object { $_ -notin $refs })

Write-Information -MessageData "Palette keys: $($palette.Count)" -InformationAction Continue
Write-Information -MessageData "Referenced keys: $($refs.Count)" -InformationAction Continue

if ($ShowAll) {
    Write-Information -MessageData "`nPalette keys:" -InformationAction Continue
    ($palette | Sort-Object) | ForEach-Object { Write-Information -MessageData "  - $_" -InformationAction Continue }

    Write-Information -MessageData "`nReferenced keys:" -InformationAction Continue
    ($refs | Sort-Object) | ForEach-Object { Write-Information -MessageData "  - $_" -InformationAction Continue }
}

if ($missing) {
    Write-Information -MessageData "`nMissing palette entries (referenced but not defined):" -InformationAction Continue
    Write-Information -MessageData 'The following referenced keys are missing from the palette:' -InformationAction Continue
    $missingSorted = $missing | Sort-Object
    $missingSorted | ForEach-Object { Write-Information -MessageData "  - $_" -InformationAction Continue }
}
else {
    Write-Information -MessageData "`nNo missing palette entries." -InformationAction Continue
}

if ($unused) {
    Write-Information -MessageData "`nUnused palette entries: $($unused.Count)" -InformationAction Continue
    if ($ShowAll -or $FailOnUnused) {
        Write-Information -MessageData 'Unused palette entries (defined but never referenced):' -InformationAction Continue
        ($unused | Sort-Object) | ForEach-Object { Write-Information -MessageData "  - $_" -InformationAction Continue }
    }
    else {
        $sample = ($unused | Sort-Object | Select-Object -First 25)
        Write-Information -MessageData "Sample (first $($sample.Count)):" -InformationAction Continue
        $sample | ForEach-Object { Write-Information -MessageData "  - $_" -InformationAction Continue }
        Write-Information -MessageData '(Use -ShowAll to list everything.)' -InformationAction Continue
    }
}
else {
    Write-Information -MessageData "`nNo unused palette entries." -InformationAction Continue
}

# Exit code:
# - 2 if missing entries
# - 3 if unused entries and -FailOnUnused
# - 0 otherwise
if ($missing.Count -gt 0) { exit 2 }
if ($FailOnUnused -and $unused.Count -gt 0) { exit 3 }
exit 0
