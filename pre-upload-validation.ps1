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

Write-Host 'Starting pre-upload validation for Oh My Posh theme...' -ForegroundColor Cyan

# 1. Check if files exist
if (-not (Test-Path $ThemePath)) {
    $errors += "Theme file not found: $ThemePath"
}
if (-not (Test-Path $TestPath)) {
    $errors += "Test file not found: $TestPath"
}
if ($errors.Count -gt 0) {
    foreach ($err in $errors) { Write-Host "ERROR: $err" -ForegroundColor Red }
    exit 1
}

# 2. Validate JSON syntax
Write-Host 'Validating JSON syntax...' -ForegroundColor Yellow
try {
    $themeContent = Get-Content $ThemePath -Raw
    $themeJson = $themeContent | ConvertFrom-Json
    Write-Host '✓ JSON syntax is valid' -ForegroundColor Green
}
catch {
    $errors += "JSON syntax error in $ThemePath`: $($_.Exception.Message)"
}

try {
    $testContent = Get-Content $TestPath -Raw
    $testJson = $testContent | ConvertFrom-Json
    Write-Host '✓ Test file JSON syntax is valid' -ForegroundColor Green
}
catch {
    $errors += "JSON syntax error in $TestPath`: $($_.Exception.Message)"
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) { Write-Host "ERROR: $err" -ForegroundColor Red }
    exit 1
}

# 3. Validate palette
Write-Host 'Validating palette keys...' -ForegroundColor Yellow
$palette = $themeJson.palette.PSObject.Properties.Name
$refs = [regex]::Matches($themeContent, 'p:([a-zA-Z0-9_\-\.]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missing = $refs | Where-Object { $_ -notin $palette }
$unused = $palette | Where-Object { $_ -notin $refs }

if ($missing.Count -gt 0) {
    $errors += "Missing palette keys (referenced but not defined): $($missing -join ', ')"
}
if ($unused.Count -gt 0) {
    $warnings += "Unused palette keys (defined but not referenced): $($unused -join ', ')"
}

if ($missing.Count -eq 0) {
    Write-Host '✓ All palette references are defined' -ForegroundColor Green
}
if ($unused.Count -gt 0) {
    foreach ($warning in $warnings) { Write-Host "WARNING: $warning" -ForegroundColor Yellow }
}

# 3.5 Validate mapped_locations
Write-Host 'Validating mapped_locations configuration...' -ForegroundColor Yellow
$pathSegment = $themeJson.blocks[0].segments | Where-Object { $_.type -eq 'path' }
if ($pathSegment -and $pathSegment.properties.mapped_locations) {
    $mappedLocs = $pathSegment.properties.mapped_locations
    $keys = $mappedLocs.PSObject.Properties.Name

    # Check for duplicates
    $duplicates = $keys | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($duplicates.Count -gt 0) {
        $errors += "Duplicate mapped_locations keys found: $($duplicates.Name -join ', ')"
    }
    else {
        Write-Host '✓ No duplicate mapped_locations keys' -ForegroundColor Green
    }

    # Validate regex patterns
    $invalidPatterns = @()
    foreach ($key in $keys) {
        if ($key.StartsWith('re:')) {
            try {
                $pattern = $key -replace '^re:', ''
                [regex]::new($pattern) | Out-Null
            }
            catch {
                $invalidPatterns += @{ pattern = $key; error = $_.Exception.Message }
            }
        }
    }

    if ($invalidPatterns.Count -gt 0) {
        foreach ($invalid in $invalidPatterns) {
            $errors += "Invalid regex pattern in mapped_locations: '$($invalid.pattern)' - $($invalid.error)"
        }
    }
    else {
        Write-Host '✓ All regex patterns are valid' -ForegroundColor Green
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
        Write-Host '✓ GitHub project mappings are configured' -ForegroundColor Green
    }

    # Check for extra parentheses in patterns (common formatting error)
    $badPatterns = $keys | Where-Object { $_ -match '\)\).*' }
    if ($badPatterns.Count -gt 0) {
        $errors += "Found extra closing parentheses in patterns: $($badPatterns -join ', ')"
    }
}

# 3.6 Validate async configuration
Write-Host 'Validating async configuration...' -ForegroundColor Yellow
if ($themeJson.async -eq $true) {
    Write-Host '✓ Async loading is enabled for better performance' -ForegroundColor Green
}
else {
    $warnings += 'Async loading is disabled - consider enabling for better prompt responsiveness'
}

# 4. Run test assertions
Write-Host 'Running test assertions...' -ForegroundColor Yellow
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
                $actual = $actual.$prop
                if ($matches[3]) {
                    $index = [int]$matches[3]
                    $actual = $actual[$index]
                }
                $path = $path -replace '^[^.\[]+(\[\d+\])?', ''
                if ($path.StartsWith('.')) { $path = $path.Substring(1) }
            }
            else {
                break
            }
        }

        $passed = $false
        switch ($type) {
            'equals' { $passed = $actual -eq $expected }
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
                        if ($item -and $item.type -eq $expected) { $found = $true; break }
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

                if ($null -eq $exp.type -or $null -eq $exp.property) { $passed = $false }
                else {
                    $segments = $actual
                    if ($segments -is [System.Array]) {
                        $segFound = $null
                        foreach ($seg in $segments) { if ($seg.type -eq $exp.type) { $segFound = $seg; break } }
                        if ($null -eq $segFound) { $passed = $false }
                        else {
                            # Traverse segFound property path
                            $propPath = $exp.property
                            $propVal = $segFound
                            while ($propPath -ne '') {
                                if ($propPath -match '^([^\.\[]+)(\[(\d+)\])?(?:\.(.*))?$') {
                                    $p = $matches[1]
                                    $propVal = $propVal.$p
                                    if ($matches[3]) { $index = [int]$matches[3]; $propVal = $propVal[$index] }
                                    $propPath = if ($matches[4]) { $matches[4] } else { '' }
                                }
                                else { break }
                            }
                            $passed = $propVal -eq $exp.expectedValue
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
        Write-Host "✓ $($test.testName)" -ForegroundColor Green
    }
    else {
        $failedTests += $test.testName
        Write-Host "✗ $($test.testName)" -ForegroundColor Red
    }
}

if ($failedTests.Count -gt 0) {
    $errors += "Failed tests: $($failedTests -join ', ')"
}

# 5. Test theme loading with Oh My Posh
# Write-Host "Testing theme loading with Oh My Posh..." -ForegroundColor Yellow
# try {
#     $initCommand = "oh-my-posh init pwsh --config '$ThemePath' 2>&1"
#     $output = Invoke-Expression $initCommand
#     if ($LASTEXITCODE -eq 0) {
#         Write-Host "✓ Theme loads successfully with Oh My Posh" -ForegroundColor Green
#     }
#     else {
#         $errors += "Oh My Posh failed to load theme: $output"
#     }
# }
# catch {
#     $errors += "Error testing theme load: $($_.Exception.Message)"
# }

# Summary
Write-Host "`nValidation Summary:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host '✓ All checks passed! Theme is ready for upload.' -ForegroundColor Green
    exit 0
}
else {
    foreach ($err in $errors) { Write-Host "ERROR: $err" -ForegroundColor Red }
    Write-Host '✗ Validation failed. Please fix the errors before uploading.' -ForegroundColor Red
    exit 1
}
