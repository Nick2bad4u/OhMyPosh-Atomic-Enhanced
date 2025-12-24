<#
.SYNOPSIS
Copy the regular ExperimentalDividers theme to a NoShellIntegration variant,
disable shell integration, and remove the "prompt_mark" entry from iterm_features.

.DESCRIPTION
This script copies OhMyPosh-Atomic-Custom-ExperimentalDividers.json to
OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json (overwriting if present),
sets shell_integration to false, and removes only the "prompt_mark" entry from
iterm_features (if present). If iterm_features becomes empty it will be removed.

.PARAMETER Source
Path to the source theme JSON (defaults to the theme in the script's directory).

.PARAMETER Destination
Path to the destination (NoShellIntegration) JSON (defaults to the same folder).

.PARAMETER Backup
If set, back up the existing destination before overwriting.

.EXAMPLE
./Make-NoShellIntegration.ps1 -Backup

# Requires PowerShell 6+ (PowerShell Core / pwsh recommended.)
#>

[CmdletBinding()]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'),
    [string]$Destination = $null,
    [switch]$Backup
)

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Err([string]$Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

try {
    # Resolve script-root defaults (when run interactively from another dir)
    if (-not (Test-Path -LiteralPath $Source)) {
        $leaf = Split-Path -Path $Source -Leaf
        # Try script folder
        $candidate = Join-Path -Path $PSScriptRoot -ChildPath $leaf
        if (Test-Path -LiteralPath $candidate) {
            $Source = $candidate
        }
        else {
            # Try parent folder (repo root)
            $parent = Split-Path -Path $PSScriptRoot -Parent
            $candidate2 = Join-Path -Path $parent -ChildPath $leaf
            if (Test-Path -LiteralPath $candidate2) {
                $Source = $candidate2
            }
            else {
                # Try current working directory
                $candidate3 = Join-Path -Path (Get-Location) -ChildPath $leaf
                if (Test-Path -LiteralPath $candidate3) {
                    $Source = $candidate3
                }
            }
        }
    }

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Err "Source not found: $Source"
        exit 1
    }

    if (-not $Destination) {
        $Destination = Join-Path -Path (Split-Path -Path $Source -Parent) -ChildPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json'
        Write-Info "Using destination: $Destination"
    }

    if (Test-Path -LiteralPath $Destination) {
        if ($Backup) {
            $bak = "$Destination.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
            Copy-Item -LiteralPath $Destination -Destination $bak -Force
            Write-Info "Backed up existing destination to: $bak"
        }
    }

    Write-Info "Reading source JSON: $Source"
    $raw = Get-Content -LiteralPath $Source -Raw -ErrorAction Stop
    $obj = $raw | ConvertFrom-Json -ErrorAction Stop

    # Disable shell integration
    $obj.shell_integration = $false
    Write-Info 'Set shell_integration = false'

    # Remove only the 'prompt_mark' item from iterm_features if present
    if ($obj.PSObject.Properties.Name -contains 'iterm_features') {
        $it = $obj.iterm_features
        if ($null -ne $it) {
            # Ensure we have a list to work with
            $list = @()
            foreach ($item in $it) { $list += $item }
            $filtered = $list | Where-Object { $_ -ne 'prompt_mark' }
            if ($filtered.Count -eq 0) {
                $obj.PSObject.Properties.Remove('iterm_features')
                Write-Info "Removed iterm_features because only 'prompt_mark' was present"
            }
            else {
                $obj.iterm_features = $filtered
                Write-Info "Removed 'prompt_mark' from iterm_features (kept: $($filtered -join ', '))"
            }
        }
    }
    else {
        Write-Info 'No iterm_features found — nothing to remove'
    }

    # Write destination JSON (pretty printed)
    $jsonOut = $obj | ConvertTo-Json -Depth 99
    # Ensure destination directory exists
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    $jsonOut | Out-File -LiteralPath $Destination -Encoding utf8 -Force
    Write-Info "Wrote updated NoShellIntegration JSON to: $Destination"

}
catch {
    Write-Err "An error occurred: $_"
    throw
}

Write-Info "Done. Run 'oh-my-posh debug' inside the target environment to verify."
