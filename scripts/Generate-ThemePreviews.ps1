<#
.SYNOPSIS
    Generates preview images for all custom Oh My Posh themes and updates README.

.DESCRIPTION
    This script finds all custom-generated theme files (excluding official themes),
    generates SVG preview images using Oh My Posh v31 or later, saves them to an assets
    folder, and automatically updates the README.md with a beautiful gallery.

.PARAMETER ThemePattern
    Glob pattern to match theme files. Default matches generated theme variants.

.PARAMETER ImageSettings
    Path to repository-owned SVG settings JSON. Supported keys map to documented
    Oh My Posh v31 image flags; the file is never passed through --settings.
    Default: "image.settings.json"

.PARAMETER OutputDirectory
    Directory where preview images will be saved.
    Default: "assets/theme-previews"

.PARAMETER PreviewData
    Sanitized recorded v1 Oh My Posh segment data used hermetically for every preview.

.PARAMETER ReadmePath
    Path to README.md file to update.
    Default: "README.md"

.PARAMETER Force
    Regenerate all images even if they already exist.

.PARAMETER SkipReadmeUpdate
    Generate images but don't update the README.

.EXAMPLE
    .\scripts\Generate-ThemePreviews.ps1
    Generates previews for all custom themes and updates README

.EXAMPLE
    .\scripts\Generate-ThemePreviews.ps1 -Force
    Regenerates all preview images

.EXAMPLE
    .\scripts\Generate-ThemePreviews.ps1 -SkipReadmeUpdate
    Only generates images without updating README

.NOTES
    Author: GitHub Copilot
    Requires: Oh My Posh v31.0.0 or later installed and in PATH
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$ThemePattern = @(
        # Discover every root JSON theme; non-theme JSON is filtered after parsing.
        '*.json',

        # ExperimentalDividers variants
        'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.*.json',

        # Folder-based variants for each theme family
        'atomic/OhMyPosh-Atomic-Custom.*.json',
        '1_shell/1_shell-Enhanced.omp.*.json',
        'slimfat/slimfat-Enhanced.omp.*.json',
        'atomicBit/atomicBit-Enhanced.omp.*.json',
        'cleanDetailed/clean-detailed-Enhanced.omp.*.json'
    ),

    [Parameter()]
    [string]$ImageSettings = 'image.settings.json',

    [Parameter()]
    [string]$OutputDirectory = 'assets/theme-previews',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PreviewData = 'theme-preview.data.json',

    [Parameter()]
    [string]$ReadmePath = 'README.md',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipReadmeUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

# Resolve repo-relative inputs (so the script works from any current directory)
$ThemePattern = @($ThemePattern | ForEach-Object { Resolve-RepoPath $_ })
$ImageSettings = Resolve-RepoPath $ImageSettings
$OutputDirectory = Resolve-RepoPath $OutputDirectory
$ReadmePath = Resolve-RepoPath $ReadmePath
$PreviewData = Resolve-RepoPath $PreviewData

$OriginalThemeNames = @{
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Original'
    'OhMyPosh-Atomic-Custom.json'                      = 'OhMyPosh-Atomic-Custom.Original'
    '1_shell-Enhanced.omp.json'                        = '1_shell-Enhanced.omp.Original'
    'slimfat-Enhanced.omp.json'                        = 'slimfat-Enhanced.omp.Original'
    'atomicBit-Enhanced.omp.json'                      = 'atomicBit-Enhanced.omp.Original'
    'clean-detailed-Enhanced.omp.json'                 = 'clean-detailed-Enhanced.omp.Original'
}

$GeneratedFamilyBases = @{
    atomic               = 'OhMyPosh-Atomic-Custom.json'
    '1_shell'            = '1_shell-Enhanced.omp.json'
    slimfat              = 'slimfat-Enhanced.omp.json'
    atomicBit            = 'atomicBit-Enhanced.omp.json'
    cleanDetailed        = 'clean-detailed-Enhanced.omp.json'
    experimentalDividers = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
}

# Emit redirectable presentation data while retaining host color and no-newline hints.
function Write-PreviewMessage {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [AllowEmptyString()]
        [object[]]$InputObject,

        [ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $message = [System.Management.Automation.HostInformationMessage]::new()
    $message.Message = ($InputObject | ForEach-Object { "$_" }) -join ''
    $message.NoNewLine = $NoNewline.IsPresent
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $message.ForegroundColor = $ForegroundColor
    }

    Write-Information -MessageData $message -InformationAction Continue
}

# Color scheme for output
$colors = @{
    Header  = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'White'
    Accent  = 'Magenta'
}

function Write-Header {
    param([string]$Text)
    Write-PreviewMessage "`n$('=' * 70)" -ForegroundColor $colors.Header
    Write-PreviewMessage "  $Text" -ForegroundColor $colors.Header
    Write-PreviewMessage "$('=' * 70)`n" -ForegroundColor $colors.Header
}

function Write-Step {
    param([string]$Text)
    Write-PreviewMessage "▶ $Text" -ForegroundColor $colors.Info
}

function Write-Success {
    param([string]$Text)
    Write-PreviewMessage "  ✓ $Text" -ForegroundColor $colors.Success
}

function Write-WarningOutput {
    param([string]$Text)
    Write-PreviewMessage "  ⚠ $Text" -ForegroundColor $colors.Warning
}

function Write-ErrorMessage {
    param([string]$Text)
    Write-PreviewMessage "  ✗ $Text" -ForegroundColor $colors.Error
}

function Get-PreviewSettingDefinition {
    return [ordered]@{
        background_color = @{ Flag = '--background-color'; Type = 'color' }
        font_family      = @{ Flag = '--font-family'; Type = 'string' }
        terminal_width   = @{ Flag = '--terminal-width'; Type = 'integer' }
        cell_width       = @{ Flag = '--cell-width'; Type = 'number' }
        line_height      = @{ Flag = '--line-height'; Type = 'number' }
        fill_ascent      = @{ Flag = '--fill-ascent'; Type = 'number' }
        fill_descent     = @{ Flag = '--fill-descent'; Type = 'number' }
    }
}

function ConvertTo-BoundedInteger {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string]$Description
    )

    try {
        $number = [int]$Value
    }
    catch {
        throw "$Description must be an integer."
    }
    if ($number -lt 20 -or $number -gt 1000) {
        throw "$Description must be between 20 and 1000."
    }

    return $number
}

function ConvertTo-InvariantNumberText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string]$Description
    )

    try {
        $number = [double]$Value
    }
    catch {
        throw "$Description must be numeric."
    }
    if (-not [double]::IsFinite($number) -or $number -le 0 -or $number -gt 10) {
        throw "$Description must be a finite number greater than 0 and no greater than 10."
    }

    return $number.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-PreviewSettingText {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string]$Type
    )

    $description = "Preview setting '$Key'"
    switch ($Type) {
        'color' {
            $text = [string]$Value
            if ($text -notmatch '^#[0-9A-Fa-f]{6}$') {
                throw "$description must be a #RRGGBB color."
            }
            return $text
        }
        'string' {
            $text = [string]$Value
            if ([string]::IsNullOrWhiteSpace($text)) {
                throw "$description must not be empty."
            }
            return $text
        }
        'integer' {
            $number = ConvertTo-BoundedInteger -Value $Value -Description $description
            return $number.ToString([Globalization.CultureInfo]::InvariantCulture)
        }
        'number' {
            return ConvertTo-InvariantNumberText -Value $Value -Description $description
        }
        default {
            throw "Unsupported preview setting type '$Type' for '$Key'."
        }
    }
}

function Get-TerminalWidthOverride {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Settings)

    $terminalWidthOverrides = [ordered]@{}
    if (-not $Settings.Contains('terminal_width_overrides')) {
        return $terminalWidthOverrides
    }

    $rawOverrides = $Settings.terminal_width_overrides
    if ($rawOverrides -isnot [System.Collections.IDictionary]) {
        throw "Preview setting 'terminal_width_overrides' must be an object of theme-name patterns and widths."
    }

    foreach ($pattern in $rawOverrides.Keys) {
        if ([string]::IsNullOrWhiteSpace([string]$pattern)) {
            throw "Preview setting 'terminal_width_overrides' contains an empty theme-name pattern."
        }

        $description = "Terminal width override '$pattern'"
        $terminalWidthOverrides[[string]$pattern] = ConvertTo-BoundedInteger `
            -Value $rawOverrides[$pattern] `
            -Description $description
    }

    return $terminalWidthOverrides
}

function ConvertTo-PreviewSettingArgument {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Preview settings file not found: $Path"
    }

    $settings = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 20 -AsHashtable
    $definitions = Get-PreviewSettingDefinition

    $generatorSettings = @('terminal_width_overrides')
    $unknownKeys = @($settings.Keys | Where-Object {
            -not $definitions.Contains($_) -and $_ -notin $generatorSettings
        })
    if ($unknownKeys.Count -gt 0) {
        throw "Unsupported preview setting(s): $($unknownKeys -join ', '). Use only Oh My Posh v31 SVG flag mappings."
    }

    $arguments = [System.Collections.Generic.List[string]]::new()
    foreach ($key in $definitions.Keys) {
        if (-not $settings.Contains($key) -or $null -eq $settings[$key]) {
            continue
        }

        $definition = $definitions[$key]
        $text = ConvertTo-PreviewSettingText -Key $key -Value $settings[$key] -Type $definition.Type

        $arguments.Add([string]$definition.Flag)
        $arguments.Add($text)
    }

    $terminalWidthOverrides = Get-TerminalWidthOverride -Settings $settings

    return [pscustomobject]@{
        Arguments              = $arguments.ToArray()
        TerminalWidthOverrides = $terminalWidthOverrides
    }
}

function Get-ThemePreviewSettingArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$BaseArguments,
        [Parameter(Mandatory)][System.Collections.IDictionary]$TerminalWidthOverrides,
        [Parameter(Mandatory)][string]$ThemeName
    )

    $matchingPatterns = @($TerminalWidthOverrides.Keys | Where-Object { $ThemeName -like $_ })
    if ($matchingPatterns.Count -gt 1) {
        throw "Theme '$ThemeName' matches multiple terminal-width overrides: $($matchingPatterns -join ', ')."
    }
    if ($matchingPatterns.Count -eq 0) {
        return $BaseArguments
    }

    $arguments = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $BaseArguments.Count; $index++) {
        if ($BaseArguments[$index] -eq '--terminal-width') {
            $index++
            continue
        }
        $arguments.Add($BaseArguments[$index])
    }

    $pattern = $matchingPatterns[0]
    $arguments.Add('--terminal-width')
    $arguments.Add(([int]$TerminalWidthOverrides[$pattern]).ToString([Globalization.CultureInfo]::InvariantCulture))
    return $arguments.ToArray()
}

function Assert-RecordedPreviewData {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Preview data file not found: $Path"
    }

    $data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 -AsHashtable
    if (-not $data.Contains('version') -or [int]$data.version -ne 1) {
        throw "Preview data must use the recorded Oh My Posh v1 format."
    }
    if (-not $data.Contains('env') -or -not $data.Contains('segments')) {
        throw "Preview data must contain both 'env' and 'segments'."
    }

    foreach ($segmentName in $data.segments.Keys) {
        $segment = $data.segments[$segmentName]
        if ($segment -isnot [System.Collections.IDictionary] -or
            -not $segment.Contains('enabled') -or
            $segment.enabled -isnot [bool] -or
            -not $segment.Contains('data') -or
            $segment.data -isnot [System.Collections.IDictionary]) {
            throw "Preview data segment '$segmentName' must contain a boolean 'enabled' and an object 'data'."
        }
    }
}

function Assert-SvgOutput {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Expected SVG output was not created: $Path"
    }

    try {
        [xml]$document = Get-Content -LiteralPath $Path -Raw
    }
    catch {
        throw "Generated preview is not valid XML: $Path"
    }

    if ($document.DocumentElement.LocalName -ne 'svg' -or
        $document.DocumentElement.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
        throw "Generated preview does not have an SVG root element: $Path"
    }
}

function Remove-LegacyPreview {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$ThemeName
    )

    $legacyPath = Join-Path -Path $Directory -ChildPath "$ThemeName.png"
    if ((Test-Path -LiteralPath $legacyPath) -and
        $PSCmdlet.ShouldProcess($legacyPath, 'Remove superseded PNG preview')) {
        Remove-Item -LiteralPath $legacyPath -Force
    }
}

Write-Header '🎨 Oh My Posh Theme Preview Generator'

# Verify oh-my-posh is installed
Write-Step 'Checking oh-my-posh installation...'
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    throw 'oh-my-posh was not found in PATH. Install v31.0.0 or later.'
}

$global:LASTEXITCODE = 0
$ompVersionText = [string](& oh-my-posh version 2>$null | Select-Object -First 1)
$ompVersionExitCode = $LASTEXITCODE
if ($ompVersionExitCode -ne 0 -or $ompVersionText -notmatch '(?<version>\d+\.\d+\.\d+)') {
    throw "Unable to determine the installed Oh My Posh version from '$ompVersionText'."
}
$ompVersion = [version]$Matches.version
$minimumOmpVersion = [version]'31.0.0'
if ($ompVersion -lt $minimumOmpVersion) {
    throw "Oh My Posh v$minimumOmpVersion or later is required for SVG previews; found v$ompVersion."
}
Write-Success "Oh My Posh v$ompVersion detected"

# Translate repository-owned settings into documented Oh My Posh v31 flags.
$previewSettings = ConvertTo-PreviewSettingArgument -Path $ImageSettings
$imageSettingsParam = @($previewSettings.Arguments)
$terminalWidthOverrides = $previewSettings.TerminalWidthOverrides
Write-Success "Loaded SVG settings: $ImageSettings"

Assert-RecordedPreviewData -Path $PreviewData
$previewDataParam = @('--data', (Resolve-Path $PreviewData).Path, '--data-only')
Write-Success "Loaded recorded preview data: $PreviewData"

# Create output directory
Write-Step 'Setting up output directory...'
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-Success "Created: $OutputDirectory"
}
else {
    Write-Success "Using existing: $OutputDirectory"
}

# Find all custom theme files
Write-Step 'Scanning for custom theme files...'
$themeFiles = @()
foreach ($pattern in $ThemePattern) {
    # NOTE: -Filter only matches leaf names and does not support path segments.
    # Use -Path so patterns like 'atomic/*.json' work correctly.
    $found = Get-ChildItem -File -Path $pattern -ErrorAction SilentlyContinue
    if ($found) {
        $themeFiles += $found
    }
}

$themeFiles = @($themeFiles | Sort-Object -Property FullName -Unique | Where-Object {
        try {
            $candidate = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json -Depth 100 -AsHashtable
        }
        catch {
            throw "Unable to parse candidate theme '$($_.FullName)': $($_.Exception.Message)"
        }

        $candidate.Contains('blocks') -or $candidate.Contains('extends')
    })

if ($themeFiles.Count -eq 0) {
    Write-WarningOutput 'No custom theme files found!'
    Write-PreviewMessage "  Patterns searched: $($ThemePattern -join ', ')" -ForegroundColor $colors.Info
    return
}

Write-Success "Found $($themeFiles.Count) theme files"

# Generate preview images
Write-Header '📸 Generating Preview Images'

$results = @()
$successCount = 0
$skipCount = 0
$errorCount = 0

foreach ($theme in $themeFiles) {
    $themeName = if ($OriginalThemeNames.ContainsKey($theme.Name)) {
        $OriginalThemeNames[$theme.Name]
    }
    else {
        [System.IO.Path]::GetFileNameWithoutExtension($theme.Name)
    }
    $resultThemeName = "$themeName.json"
    $outputImage = Join-Path $OutputDirectory "$themeName.svg"
    $readmeDirectory = Split-Path -Parent $ReadmePath
    $relativeImagePath = [IO.Path]::GetRelativePath($readmeDirectory, $outputImage).Replace('\', '/')
    $themeImageSettingsParam = @(Get-ThemePreviewSettingArgument `
            -BaseArguments $imageSettingsParam `
            -TerminalWidthOverrides $terminalWidthOverrides `
            -ThemeName $themeName)

    Write-PreviewMessage "`n[$($results.Count + 1)/$($themeFiles.Count)] " -NoNewline -ForegroundColor $colors.Accent
    Write-PreviewMessage $theme.Name -ForegroundColor $colors.Info

    # Check if image already exists
    if ((Test-Path -LiteralPath $outputImage) -and -not $Force) {
        Assert-SvgOutput -Path $outputImage
        Remove-LegacyPreview -Directory $OutputDirectory -ThemeName $themeName
        Write-WarningOutput 'Image already exists, skipping (use -Force to regenerate)'
        $skipCount++
        $results += [pscustomobject]@{
            Theme        = $resultThemeName
            ThemeName    = $themeName
            Status       = 'Skipped'
            ImagePath    = $outputImage
            RelativePath = $relativeImagePath
        }
        continue
    }

    # Generate image
    $temporaryConfigPath = $null
    $temporaryOutputPath = Join-Path -Path $OutputDirectory -ChildPath ("{0}.{1}.tmp.svg" -f $themeName, [guid]::NewGuid())
    try {
        $configPath = $theme.FullName

        # Tracked palette extensions use an absolute raw GitHub URL so they also
        # work when loaded directly from GitHub or a release. Resolve against the
        # current checkout for deterministic previews of uncommitted base changes.
        $directoryName = Split-Path -Path $theme.DirectoryName -Leaf
        if ($GeneratedFamilyBases.ContainsKey($directoryName)) {
            $declaration = Get-Content -LiteralPath $theme.FullName -Raw | ConvertFrom-Json -Depth 200 -AsHashtable
            if ($declaration.ContainsKey('extends')) {
                $declaration.extends = Join-Path -Path $RepoRoot -ChildPath $GeneratedFamilyBases[$directoryName]
                $temporaryConfigPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("omp-preview-{0}.json" -f [guid]::NewGuid())
                $declaration | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $temporaryConfigPath -Encoding utf8
                $configPath = $temporaryConfigPath
            }
        }

        # Build command arguments (avoid PowerShell automatic variable 'args')
        $exportArgs = @(
            'config', 'export', 'image',
            '--config', $configPath,
            '--output', $temporaryOutputPath
        ) + $themeImageSettingsParam + $previewDataParam

        # Run oh-my-posh export and capture result for diagnostics
        $global:LASTEXITCODE = 0
        $exportResult = & oh-my-posh @exportArgs 2>&1
        $exportExitCode = $LASTEXITCODE

        if ($exportExitCode -ne 0) {
            Write-WarningOutput "oh-my-posh returned exit code $exportExitCode"
            Write-ErrorMessage "Export output: $exportResult"
            throw "oh-my-posh returned exit code $exportExitCode"
        }

        if (-not (Test-Path -LiteralPath $temporaryOutputPath)) {
            Write-ErrorMessage "Export output: $exportResult"
            throw 'oh-my-posh exited successfully but did not create the expected SVG output.'
        }

        Assert-SvgOutput -Path $temporaryOutputPath
        Move-Item -LiteralPath $temporaryOutputPath -Destination $outputImage -Force
        Remove-LegacyPreview -Directory $OutputDirectory -ThemeName $themeName
        Write-Success "Generated: $themeName.svg"
        $successCount++
        $results += [pscustomobject]@{
            Theme        = $resultThemeName
            ThemeName    = $themeName
            Status       = 'Success'
            ImagePath    = $outputImage
            RelativePath = $relativeImagePath
        }
    }
    catch {
        Write-ErrorMessage "Failed: $_"
        $errorCount++
        $results += [pscustomobject]@{
            Theme        = $resultThemeName
            ThemeName    = $themeName
            Status       = 'Error'
            ImagePath    = $null
            RelativePath = $null
        }
    }
    finally {
        if ($temporaryConfigPath -and (Test-Path -LiteralPath $temporaryConfigPath)) {
            Remove-Item -LiteralPath $temporaryConfigPath -Force
        }
        if (Test-Path -LiteralPath $temporaryOutputPath) {
            Remove-Item -LiteralPath $temporaryOutputPath -Force
        }
    }
}

# Summary
Write-Header '📊 Generation Summary'
Write-PreviewMessage '✓ Successfully generated: ' -NoNewline -ForegroundColor $colors.Success
Write-PreviewMessage $successCount -ForegroundColor $colors.Info

if ($skipCount -gt 0) {
    Write-PreviewMessage '⚠ Skipped (existing): ' -NoNewline -ForegroundColor $colors.Warning
    Write-PreviewMessage $skipCount -ForegroundColor $colors.Info
}

if ($errorCount -gt 0) {
    Write-PreviewMessage '✗ Errors: ' -NoNewline -ForegroundColor $colors.Error
    Write-PreviewMessage $errorCount -ForegroundColor $colors.Info
    throw "$errorCount preview(s) failed; README was not updated."
}

# Update README if requested
if (-not $SkipReadmeUpdate) {
    Write-Header '📝 Updating README'

    if (-not (Test-Path $ReadmePath)) {
        throw "README not found: $ReadmePath"
    }

    Write-Step 'Reading README.md...'
    $readmeContent = Get-Content -LiteralPath $ReadmePath -Raw

    # Group themes by base theme (ensure they're arrays even if empty)
    $includeStatuses = @('Success', 'Skipped')
    $experimentalDividersThemes = @($results | Where-Object { $_.Theme -like 'OhMyPosh-Atomic-Custom-ExperimentalDividers.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $atomicThemes = @($results | Where-Object {
            ($_.Theme -like 'OhMyPosh-Atomic-Custom.*' -or $_.Theme -eq 'OhMyPosh-Atomic-Custom-ColorCycle.json') -and
            $_.Status -in $includeStatuses -and
            $_.Theme -notlike 'OhMyPosh-Atomic-Custom-ExperimentalDividers.*'
        } | Sort-Object ThemeName)
    $shellThemes = @($results | Where-Object { $_.Theme -like '1_shell-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $slimfatThemes = @($results | Where-Object { $_.Theme -like 'slimfat-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $atomicBitThemes = @($results | Where-Object { $_.Theme -like 'atomicBit-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $cleanDetailedThemes = @($results | Where-Object { $_.Theme -like 'clean-detailed-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)

    # Function to generate table rows for a theme group
    function Get-ThemeTableRow {
        param(
            [array]$Themes,
            [string]$StripPrefix
        )

        $markdown = ''
        $count = 0

        foreach ($theme in $Themes) {
            if ($count % 2 -eq 0) {
                $markdown += "`n<tr>"
            }

            $displayName = $theme.ThemeName -replace "^$StripPrefix", ''
            $markdown += @"

<td align="center" width="50%">
<h4>$displayName</h4>
<img src="$($theme.RelativePath)" alt="$displayName theme preview" width="100%">
</td>
"@

            $count++
            if ($count % 2 -eq 0) {
                $markdown += "`n</tr>"
            }
        }

        # Close row if odd number
        if ($count % 2 -ne 0) {
            $markdown += "`n</tr>"
        }

        return $markdown
    }

    # Generate gallery markdown
    $galleryMarkdown = @'
## 🎨 Theme Gallery

All themes are available in multiple color palettes. Choose the one that fits your style!
'@
    # Add Experimental Dividers first
    if ($experimentalDividersThemes.Count -gt 0) {
        $galleryMarkdown += @'

### 🌈 Experimental Dividers Variants (NEW)

<table>
'@

        $galleryMarkdown += Get-ThemeTableRow -Themes $experimentalDividersThemes -StripPrefix 'OhMyPosh-Atomic-Custom-ExperimentalDividers\.'

        $galleryMarkdown += @'

</table>
'@
    }

    # Add Atomic themes (non-experimental)
    $galleryMarkdown += @'

### 🚀 OhMyPosh Atomic Custom Variants

<table>
'@
    $galleryMarkdown += Get-ThemeTableRow -Themes $atomicThemes -StripPrefix 'OhMyPosh-Atomic-Custom(?:\.|-)'

    $galleryMarkdown += @'

</table>

### ✨ 1_shell-Enhanced Variants

<table>
'@

    # Add 1_shell themes
    $galleryMarkdown += Get-ThemeTableRow -Themes $shellThemes -StripPrefix '1_shell-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 🎯 Slimfat-Enhanced Variants

<table>
'@

    # Add Slimfat themes
    $galleryMarkdown += Get-ThemeTableRow -Themes $slimfatThemes -StripPrefix 'slimfat-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 📦 AtomicBit-Enhanced Variants

<table>
'@

    # Add AtomicBit themes
    $galleryMarkdown += Get-ThemeTableRow -Themes $atomicBitThemes -StripPrefix 'atomicBit-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 🧹 Clean-Detailed-Enhanced Variants

<table>
'@

    # Add Clean-Detailed themes
    $galleryMarkdown += Get-ThemeTableRow -Themes $cleanDetailedThemes -StripPrefix 'clean-detailed-Enhanced\.omp\.'

    $galleryMarkdown += @"

</table>

### 🎯 Quick Install

To use any theme, copy the command for your preferred variant:

``````pwsh
# Replace <THEME_FOLDER> and <THEME_FILE> with the desired theme names
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/<THEME_FOLDER>/<THEME_FILE>" | Invoke-Expression
``````

**Theme File Naming Convention:**

- `OhMyPosh-Atomic-Custom.<Palette>.json` - Flagship comprehensive theme

- `1_shell-Enhanced.omp.<Palette>.json` - Single-line sleek theme

- `slimfat-Enhanced.omp.<Palette>.json` - Two-line compact theme

- `atomicBit-Enhanced.omp.<Palette>.json` - Box-style technical theme

- `clean-detailed-Enhanced.omp.<Palette>.json` - Minimalist clean theme

**Examples:**
``````pwsh
# Atomic Custom with Nord Frost palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomic/OhMyPosh-Atomic-Custom.NordFrost.json" | Invoke-Expression

# 1_shell Enhanced with Tokyo Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/1_shell/1_shell-Enhanced.omp.TokyoNight.json" | Invoke-Expression

# Slimfat Enhanced with Dracula Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/slimfat/slimfat-Enhanced.omp.DraculaNight.json" | Invoke-Expression

# AtomicBit Enhanced with Gruvbox Dark palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomicBit/atomicBit-Enhanced.omp.GruvboxDark.json" | Invoke-Expression

# Clean-Detailed Enhanced with Catppuccin Mocha palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/cleanDetailed/clean-detailed-Enhanced.omp.CatppuccinMocha.json" | Invoke-Expression
``````

**Available Palettes:**
- **Original** - Your current vibrant tech theme

- **Nord Frost** - Arctic cool tones

- **Gruvbox Dark** - Warm retro earth tones

- **Dracula Night** - Bold purple/pink

- **Tokyo Night** - Modern neon blues

- **Monokai Pro** - Classic neon colors

- **Solarized Dark** - Eye-friendly

- **Catppuccin Mocha** - Soft pastels

- **Forest Ember** - Deep greens with amber

- **Pink Paradise** - Vibrant pink/magenta 💗

- **Purple Reign** - Royal purples 👑

- **Red Alert** - Fiery reds/oranges 🔥

- **Blue Ocean** - Deep ocean blues 🌊

- **Green Matrix** - Matrix-inspired greens 💚

- **Amber Sunset** - Warm sunset tones 🌅

- **Teal Cyan** - Electric teals ⚡

- **Rainbow Bright** - Vibrant rainbow colors 🌈

- **Christmas Cheer** - Festive holiday colors 🎄

- **Halloween Spooky** - Spooky Halloween theme 🎃

- **Easter Pastel** - Soft pastel Easter colors 🐰

- **Fire & Ice** - Dual-tone red/orange and blue/cyan ❄️🔥

- **Midnight Gold** - Deep navy blue and gold ⭐

- **Cherry Mint** - Cherry red and mint green 🍒

- **Lavender Peach** - Soft lavender and warm peach 🍑

---
"@

    # Find insertion point in README
    $galleryMarker = '## 🎨 Theme Gallery'

    if ($readmeContent -match [regex]::Escape($galleryMarker)) {
        Write-Step 'Updating existing gallery section...'

        # Find the end of the gallery section without consuming the Liquid raw
        # block delimiter used to protect Oh My Posh template examples.
        $galleryEndPattern = '(?=^## |^<!-- \{% endraw %\} -->|\z)'
        $galleryPattern = "(?ms)($([regex]::Escape($galleryMarker))).*?$galleryEndPattern"
        if ($readmeContent -match $galleryPattern) {
            $readmeContent = $readmeContent -replace $galleryPattern, ($galleryMarkdown + [Environment]::NewLine)
        }
    }
    else {
        Write-Step 'Adding new gallery section...'
        # Insert before the last section (RepoBeats or end of file)
        if ($readmeContent -match '(?s)(.*)(^!\[RepoBeats.*|\z)') {
            $before = $Matches[1]
            $after = $Matches[2]
            $readmeContent = $before + "`n`n" + $galleryMarkdown + "`n`n" + $after
        }
        else {
            # Append to end
            $readmeContent += "`n`n" + $galleryMarkdown
        }
    }

    # Write updated README
    $readmeContent | Set-Content -LiteralPath $ReadmePath -Encoding UTF8 -NoNewline

    $totalThemes = $experimentalDividersThemes.Count + $atomicThemes.Count + $shellThemes.Count + $slimfatThemes.Count + $atomicBitThemes.Count + $cleanDetailedThemes.Count
    Write-Success "README.md updated with $totalThemes theme previews across 6 families"
}

# Final message
Write-Header '✨ Complete!'

if ($successCount -gt 0) {
    Write-PreviewMessage 'Generated preview images are in: ' -NoNewline -ForegroundColor $colors.Info
    Write-PreviewMessage $OutputDirectory -ForegroundColor $colors.Accent
}

if (-not $SkipReadmeUpdate) {
    $totalGalleryThemes = ($experimentalDividersThemes.Count + $atomicThemes.Count + $shellThemes.Count + $slimfatThemes.Count + $atomicBitThemes.Count + $cleanDetailedThemes.Count)
    if ($totalGalleryThemes -gt 0) {
        Write-PreviewMessage "`n💡 Don't forget to:" -ForegroundColor $colors.Warning
        Write-PreviewMessage '   1. Review the updated README.md' -ForegroundColor $colors.Info
        Write-PreviewMessage '   2. Commit and push the new preview images' -ForegroundColor $colors.Info
        Write-PreviewMessage '   3. Verify the gallery renders correctly on GitHub' -ForegroundColor $colors.Info
        Write-PreviewMessage "`n📊 Gallery Stats:" -ForegroundColor $colors.Accent
        Write-PreviewMessage "   • Experimental Dividers: $($experimentalDividersThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • Atomic Custom: $($atomicThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • 1_shell-Enhanced: $($shellThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • Slimfat-Enhanced: $($slimfatThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • AtomicBit-Enhanced: $($atomicBitThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • Clean-Detailed-Enhanced: $($cleanDetailedThemes.Count) themes" -ForegroundColor $colors.Info
        Write-PreviewMessage "   • Total: $totalGalleryThemes themes in gallery" -ForegroundColor $colors.Success
    }
}
