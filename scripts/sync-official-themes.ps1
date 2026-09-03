# Update Oh-My-Posh Official Themes (Git Subtree)
# This script updates the themes folder from the official oh-my-posh repo using git subtree.
#
# Note: This script lives in .\scripts\, but must run git commands from the repository root.

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$PreflightOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Write-SyncMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter()]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Gray
    )

    $hostMessage = [Management.Automation.HostInformationMessage]@{
        Message         = $Message
        ForegroundColor = $ForegroundColor
    }
    Write-Information -MessageData $hostMessage -InformationAction Continue
}

function Test-IsLiteralOAuthCredential {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [AllowNull()]
        [object]$Value
    )

    return $Name -in @('access_token', 'refresh_token') -and
        $Value -is [string] -and
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notmatch '^\{\{\s*\.Env\.[A-Za-z_][A-Za-z0-9_]*\s*\}\}$'
}

function Test-ObjectContainsLiteralOAuthToken {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            $value = $InputObject[$key]
            if (Test-IsLiteralOAuthCredential -Name $key -Value $value) {
                return $true
            }

            if (Test-ObjectContainsLiteralOAuthToken -InputObject $value) {
                return $true
            }
        }

        return $false
    }

    if ($InputObject -is [pscustomobject]) {
        foreach ($property in $InputObject.PSObject.Properties) {
            if (Test-IsLiteralOAuthCredential -Name $property.Name -Value $property.Value) {
                return $true
            }

            if (Test-ObjectContainsLiteralOAuthToken -InputObject $property.Value) {
                return $true
            }
        }

        return $false
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        foreach ($item in $InputObject) {
            if (Test-ObjectContainsLiteralOAuthToken -InputObject $item) {
                return $true
            }
        }
    }

    return $false
}

function Test-UpstreamThemeSnapshot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RemoteUrl
    )

    $temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    $temporaryPath = [System.IO.Path]::GetFullPath(
        (Join-Path -Path $temporaryBase -ChildPath "omp-official-preflight-$([guid]::NewGuid().ToString('N'))")
    )
    $comparison = if ($IsWindows) {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else {
        [System.StringComparison]::Ordinal
    }

    if (-not $temporaryPath.StartsWith($temporaryBase, $comparison) -or
        [System.IO.Path]::GetFileName($temporaryPath) -notlike 'omp-official-preflight-*') {
        throw "Refusing to use unexpected preflight path: $temporaryPath"
    }

    try {
        $null = & git clone --quiet --depth 1 --filter=blob:none --sparse --single-branch --branch main --no-tags -- $RemoteUrl $temporaryPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to clone the configured ohmyposh-themes remote for security preflight (exit code $LASTEXITCODE)."
        }

        $null = & git -C $temporaryPath sparse-checkout set themes 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to check out the upstream themes directory for security preflight (exit code $LASTEXITCODE)."
        }

        $upstreamCommit = (& git -C $temporaryPath rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $upstreamCommit -notmatch '^[0-9a-f]{40}$') {
            throw 'Unable to resolve the preflighted upstream commit.'
        }

        $upstreamThemesPath = Join-Path -Path $temporaryPath -ChildPath 'themes'
        $themeFiles = @(Get-ChildItem -LiteralPath $upstreamThemesPath -Filter '*.json' -File -Recurse)
        if ($themeFiles.Count -eq 0) {
            throw 'The upstream security preflight found no theme JSON files.'
        }

        $unsafeFiles = foreach ($themeFile in $themeFiles) {
            try {
                $theme = Get-Content -LiteralPath $themeFile.FullName -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
            }
            catch {
                throw "The upstream theme '$($themeFile.Name)' is not valid JSON: $($_.Exception.Message)"
            }

            if (Test-ObjectContainsLiteralOAuthToken -InputObject $theme) {
                [System.IO.Path]::GetRelativePath($temporaryPath, $themeFile.FullName) -replace '\\', '/'
            }
        }

        $unsafeFiles = @($unsafeFiles)
        if ($unsafeFiles.Count -gt 0) {
            throw "Upstream contains literal OAuth credentials in $($unsafeFiles.Count) theme file(s): $($unsafeFiles -join ', '). Sync stopped before creating a subtree commit; correct those files upstream first."
        }

        return $upstreamCommit
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Recurse -Force
        }
    }
}

Write-SyncMessage -Message "`n🔄 Updating Oh-My-Posh Official Themes (Git Subtree)...`n" -ForegroundColor Cyan

Push-Location -LiteralPath $RepoRoot
try {
    $remoteUrl = (& git remote get-url ohmyposh-themes).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
        throw 'The ohmyposh-themes Git remote is not configured.'
    }

    Write-SyncMessage -Message '🔎 Preflighting the exact upstream snapshot for literal OAuth credentials...' -ForegroundColor Yellow
    $upstreamCommit = Test-UpstreamThemeSnapshot -RemoteUrl $remoteUrl

    if ($PreflightOnly) {
        Write-SyncMessage -Message "✅ Upstream commit $($upstreamCommit.Substring(0, 12)) passed the security preflight; no subtree changes were made." -ForegroundColor Green
        return
    }

    # Update the subtree from upstream
    Write-SyncMessage -Message "📥 Pulling preflighted upstream commit $($upstreamCommit.Substring(0, 12))..." -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    & git subtree pull --prefix=ohmyposh-official-themes ohmyposh-themes $upstreamCommit --squash
    $gitExitCode = $LASTEXITCODE

    if ($gitExitCode -ne 0) {
        throw "git subtree pull failed with exit code $gitExitCode. Commit or stash local changes, verify the ohmyposh-themes remote, and retry."
    }
}
finally {
    Pop-Location
}

$themesPath = Join-Path -Path $RepoRoot -ChildPath 'ohmyposh-official-themes\themes'
$themeCount = (Get-ChildItem -LiteralPath $themesPath -Filter '*.json' -File -ErrorAction SilentlyContinue | Measure-Object).Count
Write-SyncMessage -Message "`n✅ Successfully updated official themes!" -ForegroundColor Green
Write-SyncMessage -Message '📁 Location: .\ohmyposh-official-themes\' -ForegroundColor Cyan
Write-SyncMessage -Message "🎨 Total themes: $themeCount`n" -ForegroundColor White
