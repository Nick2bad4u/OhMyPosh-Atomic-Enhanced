<#
.SYNOPSIS
  Inspect Oh My Posh theme segments and report common "metadata hygiene" issues.

.DESCRIPTION
  Loads an Oh My Posh theme JSON and flattens blocks/segments into a single list.
  Also includes "non-block" segment containers:
    - tooltips[]
    - transient_prompt / secondary_prompt / debug_prompt / valid_line / error_line
  Useful for checking things like:
    - missing cache on expensive segments
    - missing max width controls
    - which segments are interactive

  By default, prints an overview table for all segments.

.EXAMPLE
  ./scripts/Inspect-ThemeSegments.ps1

.EXAMPLE
  ./scripts/Inspect-ThemeSegments.ps1 -ThemePath .\OhMyPosh-Atomic-Custom-ExperimentalDividers.json -MissingCache

.EXAMPLE
  ./scripts/Inspect-ThemeSegments.ps1 -NoMaxWidth -Type git,owm,battery

.EXAMPLE
  # Show divider segments only
  ./scripts/Inspect-ThemeSegments.ps1 -DividersOnly

.EXAMPLE
  # Segments missing min_width
  ./scripts/Inspect-ThemeSegments.ps1 -NoMinWidth

.EXAMPLE
  # Segments using foreground/background templates
  ./scripts/Inspect-ThemeSegments.ps1 -HasTemplates

.EXAMPLE
  # Emit objects (no formatting) for ad-hoc pipelines
  ./scripts/Inspect-ThemeSegments.ps1 -Raw | Where-Object type -eq 'git' | Format-Table -AutoSize

.EXAMPLE
  # Only analyze blocks (skip tooltips + prompt configs)
  ./scripts/Inspect-ThemeSegments.ps1 -SkipTooltips -SkipPromptConfigs
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$ThemePath = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',

  # Scope controls
  [Parameter()]
  [switch]$SkipTooltips,

  [Parameter()]
  [switch]$SkipPromptConfigs,

  # Filters
  [Parameter()]
  [string[]]$Type,

  [Parameter()]
  [string[]]$Alias,

  # Reports
  [Parameter()]
  [switch]$All,

  [Parameter()]
  [switch]$MissingCache,

  [Parameter()]
  [switch]$NoMaxWidth,

  [Parameter()]
  [switch]$NoMinWidth,

  [Parameter()]
  [switch]$HasTemplates,

  [Parameter()]
  [switch]$DividersOnly,

  [Parameter()]
  [switch]$InteractiveOnly,

  # Output controls
  [Parameter()]
  [ValidateSet('Table', 'Csv', 'Json')]
  [string]$Output = 'Table',

  [Parameter()]
  [switch]$Raw
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-OptionalPropertyValue {
  param(
    $Object,
    [Parameter(Mandatory)][string]$Name
  )

  if ($null -eq $Object) { return $null }
  $prop = $Object.PSObject.Properties[$Name]
  if ($null -eq $prop) { return $null }
  return $prop.Value
}

function Resolve-RepoPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }

  # Prefer current working directory for relative paths.
  $cwdCandidate = Join-Path -Path (Get-Location) -ChildPath $Path
  if (Test-Path -LiteralPath $cwdCandidate) { return $cwdCandidate }

  # Fall back to repository root (script folder is .\scripts\)
  $repoRoot = Split-Path -Path $PSScriptRoot -Parent
  $repoCandidate = Join-Path -Path $repoRoot -ChildPath $Path
  return $repoCandidate
}

function Get-SegmentReportRow {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Segment,
    [Parameter(Mandatory)][string]$Container,
    [Parameter()][string]$ContainerName,
    [Parameter()][int]$BlockIndex = -1,
    [Parameter()][int]$SegmentIndex = -1,
    [Parameter()][int]$TooltipIndex = -1,
    [Parameter()][string]$BlockType,
    [Parameter()][string]$Alignment
  )

  # Effective cache detection: either explicit cache object OR segment-level cache_duration in options.
  $cacheObj = Get-OptionalPropertyValue -Object $Segment -Name 'cache'
  $hasCache = $null -ne $cacheObj
  $cacheDuration = if ($cacheObj) { Get-OptionalPropertyValue -Object $cacheObj -Name 'duration' } else { $null }
  $cacheStrategy = if ($cacheObj) { Get-OptionalPropertyValue -Object $cacheObj -Name 'strategy' } else { $null }
  $optionsObj = Get-OptionalPropertyValue -Object $Segment -Name 'options'
  $optionsCacheDuration = Get-OptionalPropertyValue -Object $optionsObj -Name 'cache_duration'
  $hasEffectiveCache = $hasCache -or [bool]$optionsCacheDuration

  # Effective max width can be defined as `max_width` or `options.max_width`.
  $maxWidth = Get-OptionalPropertyValue -Object $Segment -Name 'max_width'
  $optionsMaxWidth = Get-OptionalPropertyValue -Object $optionsObj -Name 'max_width'
  $maxWidthEffective = if ($maxWidth) { $maxWidth } elseif ($optionsMaxWidth) { $optionsMaxWidth } else { $null }

  $minWidth = Get-OptionalPropertyValue -Object $Segment -Name 'min_width'
  $interactive = Get-OptionalPropertyValue -Object $Segment -Name 'interactive'
  $style = Get-OptionalPropertyValue -Object $Segment -Name 'style'
  $aliasName = Get-OptionalPropertyValue -Object $Segment -Name 'alias'
  $typeName = Get-OptionalPropertyValue -Object $Segment -Name 'type'

  $bgTemplates = Get-OptionalPropertyValue -Object $Segment -Name 'background_templates'
  $fgTemplates = Get-OptionalPropertyValue -Object $Segment -Name 'foreground_templates'
  $template = Get-OptionalPropertyValue -Object $Segment -Name 'template'
  $tips = Get-OptionalPropertyValue -Object $Segment -Name 'tips'

  return [pscustomobject]@{
    container            = $Container
    containerName        = $ContainerName
    blockIndex           = $BlockIndex
    blockType            = $BlockType
    alignment            = $Alignment
    segmentIndex         = $SegmentIndex
    tooltipIndex         = $TooltipIndex

    alias                = $aliasName
    type                 = $typeName
    style                = $style
    minWidth             = $minWidth
    maxWidth             = $maxWidth
    maxWidthEffective    = $maxWidthEffective
    interactive          = $interactive

    hasCache             = $hasCache
    hasEffectiveCache    = $hasEffectiveCache
    cacheDuration        = $cacheDuration
    cacheStrategy        = $cacheStrategy
    optionsCacheDuration = $optionsCacheDuration

    hasBgTemplates       = [bool]$bgTemplates
    hasFgTemplates       = [bool]$fgTemplates
    hasTemplate          = [bool]$template
    templateLength       = if ($template) { ($template | Out-String).Length } else { 0 }
    tipsCount            = if ($tips) { @($tips).Count } else { 0 }
  }
}

$resolvedTheme = Resolve-RepoPath $ThemePath
if (-not (Test-Path -LiteralPath $resolvedTheme)) {
  throw "Theme not found: $resolvedTheme"
}

$theme = Get-Content -LiteralPath $resolvedTheme -Raw | ConvertFrom-Json

$rows = New-Object System.Collections.Generic.List[object]

if ($theme.blocks) {
  for ($bi = 0; $bi -lt $theme.blocks.Count; $bi++) {
    $b = $theme.blocks[$bi]
    if (-not $b.segments) { continue }

    for ($si = 0; $si -lt $b.segments.Count; $si++) {
      $s = $b.segments[$si]
      $rows.Add((Get-SegmentReportRow -Segment $s -Container 'block' -ContainerName $b.type -BlockIndex $bi -SegmentIndex $si -BlockType $b.type -Alignment $b.alignment))
    }
  }
}

if (-not $SkipTooltips) {
  $tooltips = Get-OptionalPropertyValue -Object $theme -Name 'tooltips'
  if ($tooltips) {
    for ($ti = 0; $ti -lt $tooltips.Count; $ti++) {
      $t = $tooltips[$ti]
      $rows.Add((Get-SegmentReportRow -Segment $t -Container 'tooltip' -ContainerName 'tooltips' -TooltipIndex $ti -BlockType 'tooltip' -Alignment 'n/a'))
    }
  }
}

if (-not $SkipPromptConfigs) {
  # These are not "segments" per se, but they use the same template/background/foreground/template arrays,
  # so we include them in the hygiene report.
  $promptKeys = @('transient_prompt', 'secondary_prompt', 'debug_prompt', 'valid_line', 'error_line')
  foreach ($k in $promptKeys) {
    $obj = Get-OptionalPropertyValue -Object $theme -Name $k
    if ($null -eq $obj) { continue }

    # Normalize to a segment-like shape for reporting
    if (-not (Get-OptionalPropertyValue -Object $obj -Name 'alias')) {
      $obj | Add-Member -NotePropertyName 'alias' -NotePropertyValue $k -Force
    }
    if (-not (Get-OptionalPropertyValue -Object $obj -Name 'type')) {
      $obj | Add-Member -NotePropertyName 'type' -NotePropertyValue $k -Force
    }

    $rows.Add((Get-SegmentReportRow -Segment $obj -Container 'promptConfig' -ContainerName $k -BlockType $k -Alignment 'n/a'))
  }
}

# Default behavior
if (-not ($All -or $MissingCache -or $NoMaxWidth -or $NoMinWidth -or $HasTemplates -or $DividersOnly -or $InteractiveOnly)) {
  $All = $true
}

# Apply filters (Type/Alias)
$filtered = $rows
if ($Type) {
  $typeSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($t in $Type) { if ($t) { $null = $typeSet.Add($t) } }
  $filtered = $filtered | Where-Object { $typeSet.Contains($_.type) }
}
if ($Alias) {
  $aliasSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach ($a in $Alias) { if ($a) { $null = $aliasSet.Add($a) } }
  $filtered = $filtered | Where-Object { $aliasSet.Contains($_.alias) }
}

# Build report result
$result = @()

if ($All) {
  $result += $filtered
}

if ($MissingCache) {
  $expensiveTypes = @(
    'git', 'http', 'owm', 'winget', 'upgrade', 'node', 'npm', 'java', 'python',
    'az', 'aws', 'gcp', 'docker', 'deno', 'tauri', 'yarn', 'pnpm', 'bun',
    'sysinfo', 'gitversion', 'ipify'
  )

  $result += ($filtered |
      Where-Object { $_.type -in $expensiveTypes -and -not $_.hasEffectiveCache } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'MissingCache' -PassThru }
  )
}

if ($NoMaxWidth) {
  $result += ($filtered |
      Where-Object { $_.container -ne 'promptConfig' -and $_.type -ne 'text' -and -not $_.maxWidthEffective } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'NoMaxWidth' -PassThru }
  )
}

if ($NoMinWidth) {
  $result += ($filtered |
      Where-Object { $_.container -ne 'promptConfig' -and -not $_.minWidth } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'NoMinWidth' -PassThru }
  )
}

if ($HasTemplates) {
  $result += ($filtered |
      Where-Object { $_.hasBgTemplates -or $_.hasFgTemplates } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'HasTemplates' -PassThru }
  )
}

if ($DividersOnly) {
  $result += ($filtered |
      Where-Object { $_.alias -match '^(?i)divider' } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'Divider' -PassThru }
  )
}

if ($InteractiveOnly) {
  $result += ($filtered |
      Where-Object { $_.interactive -eq $true } |
        ForEach-Object { $_ | Add-Member -NotePropertyName report -NotePropertyValue 'Interactive' -PassThru }
  )
}

# De-dupe identical rows if multiple reports were selected
$result = $result | Sort-Object container, blockIndex, segmentIndex, tooltipIndex, alias, type -Unique

if ($Raw) {
  $result
  return
}

switch ($Output) {
  'Json' {
    $result | ConvertTo-Json -Depth 6
  }
  'Csv' {
    $result | Export-Csv -NoTypeInformation -Path (Join-Path (Get-Location) 'theme-segments.csv')
    Write-Output 'Wrote theme-segments.csv'
  }
  default {
    $result |
      Select-Object report, container, containerName, blockType, alignment, alias, type, style, minWidth, maxWidthEffective, hasEffectiveCache, cacheDuration, optionsCacheDuration, interactive, tipsCount, hasTemplate, templateLength |
        Format-Table -AutoSize
  }
}
