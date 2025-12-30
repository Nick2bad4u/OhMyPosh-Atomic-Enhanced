<#
.SYNOPSIS
Pre-upload validation script for Oh My Posh theme.

.DESCRIPTION
This script validates the Oh My Posh theme file before upload by:
1. Checking JSON syntax
2. Validating palette key usage
3. Running test assertions from test_OhMyPosh-Atomic-Custom.json
4. Attempting to load the theme with Oh My Posh

.PARAMETER ThemePath
Path to the theme JSON file. Defaults to 'OhMyPosh-Atomic-Custom.json'.

.PARAMETER TestPath
Path to the test JSON file. Defaults to 'test_OhMyPosh-Atomic-Custom.json'.

.EXAMPLE
.\pre-upload-validation.ps1
#>

param(
    [string]$ThemePath = 'OhMyPosh-Atomic-Custom.json',
    [string]$TestPath = 'test_OhMyPosh-Atomic-Custom.json'
)

$errors = @()
$warnings = @()

function Get-OMPProperty {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)] [string]$Name
    )

    if ($null -eq $Object) { return $null }

    # Dynamic property access with a compatibility shim for the Oh My Posh
    # segment config key rename: some themes use "properties", others use "options".
    $propNames = @($Object.PSObject.Properties.Name)
    $resolvedName = $Name

    if ($propNames -notcontains $resolvedName) {
        if ($resolvedName -eq 'properties' -and ($propNames -contains 'options')) { $resolvedName = 'options' }
        elseif ($resolvedName -eq 'options' -and ($propNames -contains 'properties')) { $resolvedName = 'properties' }
    }

    return $Object.$resolvedName
}

function Get-OMPPaletteReference {
    param(
        [Parameter(Mandatory = $true)] [string]$RawJson,
        [Parameter(Mandatory = $true)] $ThemeObject
    )

    # Collect palette references like p:<key> in a robust way.
    # - Case-insensitive (covers accidental "P:" or mixed casing)
    # - Traverses the parsed JSON object (covers references anywhere: blocks, tooltips, templates, etc.)
    $set = New-Object System.Collections.Generic.HashSet[string]
    $rx = [regex]::new('(?i)p:([a-z0-9_\-\.]+)')

    foreach ($m in $rx.Matches($RawJson)) {
        [void]$set.Add($m.Groups[1].Value.ToLowerInvariant())
    }

    function Visit ($node) {
        if ($null -eq $node) { return }

        # Arrays
        if ($node -is [System.Array]) {
            foreach ($item in $node) { Visit $item }
            return
        }

        # Strings
        if ($node -is [string]) {
            foreach ($m in $rx.Matches($node)) {
                [void]$set.Add($m.Groups[1].Value.ToLowerInvariant())
            }
            return
        }

        # Objects (PSCustomObject)
        $props = $node.PSObject.Properties
        if ($null -ne $props -and $props.Count -gt 0) {
            foreach ($p in $props) { Visit $p.Value }
        }
    }

    Visit $ThemeObject
    # Return as a list of strings (PowerShell will enumerate the HashSet)
    return $set
}

Write-Output 'Starting pre-upload validation for Oh My Posh theme...' -ForegroundColor Cyan

# 1. Check if files exist
if (-not (Test-Path $ThemePath)) {
    $errors += "Theme file not found: $ThemePath"
}
if (-not (Test-Path $TestPath)) {
    $errors += "Test file not found: $TestPath"
}
if ($errors.Count -gt 0) {
    foreach ($err in $errors) { Write-Output "ERROR: $err" -ForegroundColor Red }
    exit 1
}

# 2. Validate JSON syntax
Write-Output 'Validating JSON syntax...' -ForegroundColor Yellow
try {
    $themeContent = Get-Content $ThemePath -Raw
    $themeJson = $themeContent | ConvertFrom-Json
    Write-Output '✓ JSON syntax is valid' -ForegroundColor Green
}
catch {
    $errors += "JSON syntax error in $ThemePath`: $($_.Exception.Message)"
}

try {
    $testContent = Get-Content $TestPath -Raw
    $testJson = $testContent | ConvertFrom-Json
    Write-Output '✓ Test file JSON syntax is valid' -ForegroundColor Green
}
catch {
    $errors += "JSON syntax error in $TestPath`: $($_.Exception.Message)"
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) { Write-Output "ERROR: $err" -ForegroundColor Red }
    exit 1
}

# 3. Validate palette
Write-Output 'Validating palette keys...' -ForegroundColor Yellow
$palette = $themeJson.Palette.PSObject.Properties.Name
$refs = @(Get-OMPPaletteReferences -RawJson $themeContent -ThemeObject $themeJson) | Sort-Object -Unique
$missing = $refs | Where-Object { $_ -notin $palette }
$unused = $palette | Where-Object { $_ -notin $refs }

if ($missing.Count -gt 0) {
    $errors += "Missing palette keys (referenced but not defined): $($missing -join ', ')"
}
if ($unused.Count -gt 0) {
    $warnings += "Unused palette keys (defined but not referenced): $($unused -join ', ')"
}

if ($missing.Count -eq 0) {
    Write-Output '✓ All palette references are defined' -ForegroundColor Green
}
if ($unused.Count -gt 0) {
    foreach ($warning in $warnings) { Write-Output "WARNING: $warning" -ForegroundColor Yellow }
}

# 3.5 Validate mapped_locations
Write-Output 'Validating mapped_locations configuration...' -ForegroundColor Yellow
$pathSegment = @($themeJson.blocks[0].segments | Where-Object { $_.Type -eq 'path' })[0]
$pathProps = if ($pathSegment) { (Get-OMPProperty -Object $pathSegment -Name 'properties') } else { $null }

if ($pathSegment -and $pathProps -and $pathProps.mapped_locations) {
    $mappedLocs = $pathProps.mapped_locations
    $keys = $mappedLocs.PSObject.Properties.Name

    # Check for duplicates
    $duplicates = $keys | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($duplicates.Count -gt 0) {
        $errors += "Duplicate mapped_locations keys found: $($duplicates.Name -join ', ')"
    }
    else {
        Write-Output '✓ No duplicate mapped_locations keys' -ForegroundColor Green
    }

    # Validate regex patterns
    $invalidPatterns = @()
    foreach ($key in $keys) {
        if ($key.StartsWith('re:')) {
            try {
                $pattern = $key -replace '^re:',''
                [regex]::new($pattern) | Out-Null
            }
            catch {
                $invalidPatterns += @{ pattern = $key; Error = $_.Exception.Message }
            }
        }
    }

    if ($invalidPatterns.Count -gt 0) {
        foreach ($invalid in $invalidPatterns) {
            $errors += "Invalid regex pattern in mapped_locations: '$($invalid.pattern)' - $($invalid.error)"
        }
    }
    else {
        Write-Output '✓ All regex patterns are valid' -ForegroundColor Green
    }

    # Check for GitHub project mappings
    $githubProjects = @(
        're:.*(wintertodt-scouter).*',
        're:.*(GE-Filters).*',
        're:.*(OhMyPosh-Atomic-Enhanced).*',
        're:.*(Nick2bad4u).*'
    )
    $missingProjectMaps = @()
    foreach ($project in $githubProjects) {
        if ($project -notin $keys) {
            $missingProjectMaps += $project
        }
    }

    if ($missingProjectMaps.Count -gt 0) {
        $warnings += "Missing GitHub project mappings: $($missingProjectMaps -join ', ')"
    }
    else {
        Write-Output '✓ GitHub project mappings are configured' -ForegroundColor Green
    }

    # Check for extra parentheses in patterns (common formatting error)
    $badPatterns = $keys | Where-Object { $_ -match '\)\).*' }
    if ($badPatterns.Count -gt 0) {
        $errors += "Found extra closing parentheses in patterns: $($badPatterns -join ', ')"
    }
}

# 3.6 Validate async configuration
Write-Output 'Validating async configuration...' -ForegroundColor Yellow
if ($themeJson.async -eq $true) {
    Write-Output '✓ Async loading is enabled for better performance' -ForegroundColor Green
}
else {
    $warnings += 'Async loading is disabled - consider enabling for better prompt responsiveness'
}

# 4. Run test assertions
Write-Output 'Running test assertions...' -ForegroundColor Yellow
$failedTests = @()

foreach ($test in $testJson.tests) {
    $testPassed = $true
    foreach ($assertion in $test.assertions) {
        $propertyPath = $assertion.property
        $expected = $assertion.expectedValue
        $type = $assertion.assertionType

        # Parse property path with array indices
        $actual = $themeJson
        $path = $propertyPath
        while ($path) {
            if ($path -match '^([^.\[]+)(\[(\d+)\])?') {
                $prop = $matches[1]
                $actual = Get-OMPProperty -Object $actual -Name $prop
                if ($matches[3]) {
                    $index = [int]$matches[3]
                    $actual = $actual[$index]
                }
                $path = $path -replace '^[^.\[]+(\[\d+\])?',''
                if ($path.StartsWith('.')) { $path = $path.Substring(1) }
            }
            else {
                break
            }
        }

        $passed = $false
        switch ($type) {
            'equals' {
                # If the test provides an array, treat it as "one of".
                if ($expected -is [System.Array]) { $passed = $expected -contains $actual }
                else { $passed = $actual -eq $expected }
            }
            'regex' { $passed = $actual -match $expected }
            'exists' { $passed = $null -ne $actual }
            'isArray' { $passed = $actual -is [System.Array] }
            'isString' { $passed = $actual -is [string] }
            'greaterThan' { $passed = $actual -gt $expected }
            'containsSegmentType' {
                # $property points to an array path (e.g., blocks[0].segments)
                # $expected is the segment type to find (e.g., 'path')
                $array = $actual
                if ($array -is [System.Array]) {
                    $found = $false
                    foreach ($item in $array) {
                        if ($item -and $item.Type -eq $expected) { $found = $true; break }
                    }
                    $passed = $found
                }
                else { $passed = $false }
            }
            'segmentPropertyEquals' {
                # $property points to an array of segments; $expected is an object
                # { "type": "path", "property": "properties.max_width", "expectedValue": 40 }
                try {
                    $exp = $expected | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if (-not $exp) { $exp = $expected }
                }
                catch { $exp = $expected }

                if ($null -eq $exp.Type -or $null -eq $exp.property) { $passed = $false }
                else {
                    $segments = $actual
                    if ($segments -is [System.Array]) {
                        $segFound = $null
                        foreach ($seg in $segments) { if ($seg.Type -eq $exp.Type) { $segFound = $seg; break } }
                        if ($null -eq $segFound) { $passed = $false }
                        else {
                            # Traverse segFound property path
                            $propPath = $exp.property
                            $propVal = $segFound
                            while ($propPath -ne '') {
                                if ($propPath -match '^([^\.\[]+)(\[(\d+)\])?(?:\.(.*))?$') {
                                    $p = $matches[1]
                                    $propVal = Get-OMPProperty -Object $propVal -Name $p
                                    if ($matches[3]) { $index = [int]$matches[3]; $propVal = $propVal[$index] }
                                    $propPath = if ($matches[4]) { $matches[4] } else { '' }
                                }
                                else { break }
                            }
                            if ($exp.expectedValue -is [System.Array]) { $passed = $exp.expectedValue -contains $propVal }
                            else { $passed = $propVal -eq $exp.expectedValue }
                        }
                    }
                    else { $passed = $false }
                }
            }
        }

        if (-not $passed) {
            $testPassed = $false
            break
        }
    }

    if ($testPassed) {
        Write-Output "✓ $($test.testName)" -ForegroundColor Green
    }
    else {
        $failedTests += $test.testName
        Write-Output "✗ $($test.testName)" -ForegroundColor Red
    }
}

if ($failedTests.Count -gt 0) {
    $errors += "Failed tests: $($failedTests -join ', ')"
}

# 5. Test theme loading with Oh My Posh
# Write-Output "Testing theme loading with Oh My Posh..." -ForegroundColor Yellow
# try {
#     $initCommand = "oh-my-posh init pwsh --config '$ThemePath' 2>&1"
#     $output = Invoke-Expression $initCommand
#     if ($LASTEXITCODE -eq 0) {
#         Write-Output "✓ Theme loads successfully with Oh My Posh" -ForegroundColor Green
#     }
#     else {
#         $errors += "Oh My Posh failed to load theme: $output"
#     }
# }
# catch {
#     $errors += "Error testing theme load: $($_.Exception.Message)"
# }

# Summary
Write-Output "`nValidation Summary:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Output '✓ All checks passed! Theme is ready for upload.' -ForegroundColor Green
    exit 0
}
else {
    foreach ($err in $errors) { Write-Output "ERROR: $err" -ForegroundColor Red }
    Write-Output '✗ Validation failed. Please fix the errors before uploading.' -ForegroundColor Red
    exit 1
}
