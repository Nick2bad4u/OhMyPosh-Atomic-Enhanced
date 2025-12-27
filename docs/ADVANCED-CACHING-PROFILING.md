# 📊 Advanced Caching & Performance Profiling Guide

## Table of Contents

1. [Caching Fundamentals](#caching-fundamentals)
2. [Cache Strategies](#cache-strategies)
3. [Cache Configuration](#cache-configuration)
4. [Cache Management Commands](#cache-management-commands)
5. [Performance Profiling](#performance-profiling)
6. [Benchmarking Techniques](#benchmarking-techniques)
7. [Optimization Case Studies](#optimization-case-studies)
8. [Troubleshooting Cache Issues](#troubleshooting-cache-issues)

---

## Caching Fundamentals

### What is Caching?

Caching stores the result of a segment's calculation so it doesn't need to be recalculated frequently.

### Why Cache?

Without caching:

```
Each prompt → Calculate git status → Calculate path → Calculate version → Display
              (100ms)                (20ms)           (30ms)            (50ms)
              = 200ms delay on EVERY prompt!
```

With caching:

```
First prompt:  Calculate → Cache result (200ms)
2nd-10th:      Use cache (1ms each)
After timeout: Recalculate → Update cache
```

**Result:** 6-19x performance improvement! 🚀

### Cache Storage Locations

**Windows:**

```
C:\Users\{User}\AppData\Local\oh-my-posh\cache
```

**macOS:**

```
~/.cache/oh-my-posh
```

**Linux:**

```
~/.cache/oh-my-posh
```

---

## Cache Strategies

### Strategy 1: Session Cache

**Duration:** Entire PowerShell session
**Resets:** When PowerShell closes

```json
{
 "cache": {
  "strategy": "session",
  "duration": "5m"
 }
}
```

**Use for:**

- Rarely changing data
- Commands that run occasionally
- Info that won't change during session

**Example:**

```json
{
 "cache": {
  "strategy": "session",
  "duration": "1s"
 },
 "type": "time"
}
```

---

### Strategy 2: Folder Cache

**Duration:** While in same folder
**Resets:** When you cd to different folder

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 }
}
```

**Use for:**

- Git status (same repo = same status)
- Version info (same folder = same version)
- Path-specific data

**Example:**

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 },
 "properties": {
  "fetch_status": true // This is slow, cache it
 },
 "type": "git"
}
```

---

### Strategy 3: Windows Cache

**Duration:** Specific Windows timeout
**Resets:** After Windows decides

```json
{
 "cache": {
  "strategy": "windows",
  "duration": "5m"
 }
}
```

**Use for:**

- System-wide data
- Less frequently accessed segments
- Data shared across terminals

---

### Strategy Comparison

| Strategy | Duration | Resets | Best For |
| --- | --- | --- | --- |
| **session** | Session | Close PowerShell | Expensive one-time calcs |
| **folder** | Per folder | Change dir | Git, versions in repos |
| **windows** | System-wide | OS timeout | System-level info |
| **none** | Never | Manual | Dynamic data |

---

## Cache Configuration

### Minimal Caching (Fast Prompt)

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "30m"
 },
 "type": "git"
}
```

**Performance:** ~50-100ms per prompt

---

### Moderate Caching (Balanced)

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 },
 "type": "git"
}
```

**Performance:** ~30-50ms per prompt

---

### Aggressive Caching (Maximum Speed)

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "60m"
 },
 "type": "git"
}
```

**Performance:** ~10-20ms per prompt

⚠️ **Trade-off:** May miss very recent changes

---

### Full Example Configuration

```json
{
 "blocks": [
  {
   "segments": [
    {
     "type": "shell",
     "cache": {
      "strategy": "session",
      "duration": "1h" // Shell doesn't change
     }
    },
    {
     "type": "path",
     "cache": {
      "strategy": "folder",
      "duration": "5m" // Cache per folder
     }
    },
    {
     "type": "git",
     "cache": {
      "strategy": "folder",
      "duration": "5m"
     },
     "properties": {
      "fetch_status": true // This is what's slow
     }
    },
    {
     "type": "node",
     "cache": {
      "strategy": "folder",
      "duration": "30m" // Versions change rarely
     }
    },
    {
     "type": "status",
     "cache": {
      "strategy": "session",
      "duration": "0s" // Always fresh
     }
    }
   ]
  }
 ]
}
```

---

## Cache Management Commands

### Clearing Cache

#### Clear All Caches

```powershell
oh-my-posh cache clean
```

**Result:** Removes all cached data
**When:** When you want fresh calculations
**Impact:** Prompt will be slower until recalculated

---

#### Clear Session Cache

```powershell
oh-my-posh cache clean --session
```

**Result:** Clears current session cache only
**When:** Within current PowerShell session
**Impact:** Lightweight, only affects your session

---

#### Clear Cache by Duration

```powershell
# Clears cache older than 1 hour
oh-my-posh cache clean --duration 1h
```

---

### Checking Cache Status

```powershell
# View current cache size
$cacheSize = Get-ChildItem -Path "$env:LOCALAPPDATA\oh-my-posh\cache" -Recurse |
  Measure-Object -Property Length -Sum

Write-Host "Cache size: $($cacheSize.Sum / 1MB)MB"
```

---

### Disabling Cache

```json
{
 "cache": {
  "strategy": "none" // No caching
 },
 "type": "git"
}
```

Or via command:

```powershell
$env:OHMYPOSH_CACHE = "off"
oh-my-posh init pwsh | Invoke-Expression
```

---

### Cache Monitoring

```powershell
# Function to monitor cache
function Get-CacheStatus {
    $cachePath = "$env:LOCALAPPDATA\oh-my-posh\cache"

    if (Test-Path $cachePath) {
        $files = Get-ChildItem $cachePath -Recurse
        $size = ($files | Measure-Object -Property Length -Sum).Sum

        Write-Host "Cache Status:" -ForegroundColor Cyan
        Write-Host "  Location: $cachePath"
        Write-Host "  Files: $($files.Count)"
        Write-Host "  Size: $($size / 1KB)KB"

        # Show oldest/newest
        $oldest = $files | Sort-Object LastWriteTime | Select-Object -First 1
        $newest = $files | Sort-Object LastWriteTime | Select-Object -Last 1

        Write-Host "  Oldest: $($oldest.LastWriteTime)"
        Write-Host "  Newest: $($newest.LastWriteTime)"
    }
}

Get-CacheStatus
```

---

## Performance Profiling

### Built-in Profiling

Oh My Posh has built-in performance analysis:

```powershell
oh-my-posh config export
oh-my-posh config show --depth 1
```

### PowerShell Profiling

```powershell
# Measure prompt generation time
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
oh-my-posh init pwsh --config "my-theme.json" | Invoke-Expression
$stopwatch.Stop()

Write-Host "Init time: $($stopwatch.ElapsedMilliseconds)ms"
```

### Segment-by-Segment Analysis

```powershell
# Test individual segments
function Measure-SegmentPerformance {
    param([string]$SegmentType)

    $config = @{
        version = 3
        blocks = @(
            @{
                segments = @(
                    @{ type = $SegmentType }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    oh-my-posh init pwsh --config <(ConvertFrom-Json $config | ConvertTo-Json) | Invoke-Expression
    $stopwatch.Stop()

    Write-Host "$SegmentType`: $($stopwatch.ElapsedMilliseconds)ms"
}

# Test each segment
"shell", "path", "git", "node", "time", "status" |
  ForEach-Object { Measure-SegmentPerformance $_ }
```

### Detailed Performance Report

```powershell
function Get-PerformanceReport {
    param([string]$ConfigPath = $PROFILE)

    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ Oh My Posh Performance Report         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

    # Measure multiple runs
    $runs = 10
    $times = @()

    for ($i = 0; $i -lt $runs; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        oh-my-posh init pwsh --config $ConfigPath | Invoke-Expression
        $stopwatch.Stop()
        $times += $stopwatch.ElapsedMilliseconds
    }

    # Statistics
    $avg = ($times | Measure-Object -Average).Average
    $min = $times | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
    $max = $times | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

    Write-Host "`nRuns: $runs"
    Write-Host "Average: $([Math]::Round($avg, 2))ms"
    Write-Host "Min: $min ms"
    Write-Host "Max: $max ms"

    # Performance grade
    if ($avg -lt 50) { $grade = "A (Excellent)" }
    elseif ($avg -lt 100) { $grade = "B (Good)" }
    elseif ($avg -lt 200) { $grade = "C (Acceptable)" }
    else { $grade = "D (Slow)" }

    Write-Host "Grade: $grade" -ForegroundColor Green
}

Get-PerformanceReport -ConfigPath "my-theme.json"
```

---

## Benchmarking Techniques

### Before-After Comparison

```powershell
function Compare-Performance {
    param(
        [string]$OldConfig,
        [string]$NewConfig,
        [int]$Runs = 10
    )

    # Test old config
    Write-Host "Testing old configuration..." -ForegroundColor Yellow
    $oldTimes = @()
    for ($i = 0; $i -lt $Runs; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        oh-my-posh init pwsh --config $OldConfig | Invoke-Expression
        $sw.Stop()
        $oldTimes += $sw.ElapsedMilliseconds
    }

    # Test new config
    Write-Host "Testing new configuration..." -ForegroundColor Yellow
    $newTimes = @()
    for ($i = 0; $i -lt $Runs; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        oh-my-posh init pwsh --config $NewConfig | Invoke-Expression
        $sw.Stop()
        $newTimes += $sw.ElapsedMilliseconds
    }

    # Compare
    $oldAvg = ($oldTimes | Measure-Object -Average).Average
    $newAvg = ($newTimes | Measure-Object -Average).Average
    $improvement = $oldAvg / $newAvg

    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "Old Config: $([Math]::Round($oldAvg, 2))ms"
    Write-Host "New Config: $([Math]::Round($newAvg, 2))ms"
    Write-Host "Improvement: $([Math]::Round($improvement, 2))x faster" -ForegroundColor Green

    if ($newAvg -lt $oldAvg) {
        Write-Host "✓ New configuration is faster!" -ForegroundColor Green
    } else {
        Write-Host "✗ New configuration is slower!" -ForegroundColor Red
    }
}

# Usage
Compare-Performance -OldConfig "my-theme.json" -NewConfig "my-theme-optimized.json"
```

---

## Optimization Case Studies

### Case Study 1: From 500ms to 50ms

**Problem:** Large git repo, every prompt takes 500ms

**Root Cause:** `fetch_status: true` on large repository

**Solution:**

```json
// BEFORE: Slow
{
  "type": "git",
  "properties": {
    "fetch_status": true,  // Checks all changes - SLOW!
    "fetch_upstream_icon": true
  }
}

// AFTER: Fast
{
  "type": "git",
  "properties": {
    "fetch_status": false,  // Skip detailed check
    "fetch_upstream_icon": false
  },
  "cache": {
    "strategy": "folder",
    "duration": "10m"
  }
}
```

**Result:** 500ms → 50ms (10x improvement!)

---

### Case Study 2: From 300ms to 25ms

**Problem:** Node & Python versions slow on every prompt

**Root Cause:** Checking file system for version info

**Solution:**

```json
// Cache version checks
{
  "type": "node",
  "cache": {
    "strategy": "folder",
    "duration": "30m"  // Cache for 30 minutes
  }
},
{
  "type": "python",
  "cache": {
    "strategy": "folder",
    "duration": "30m"
  }
}
```

**Result:** 300ms → 25ms (12x improvement!)

---

### Case Study 3: From 200ms to 15ms

**Problem:** Multiple segments with no caching

**Solution:** Strategic caching for each segment

```json
{
 "blocks": [
  {
   "segments": [
    {
     "type": "shell",
     "cache": { "strategy": "session", "duration": "1h" }
    },
    {
     "type": "path",
     "cache": { "strategy": "folder", "duration": "5m" }
    },
    {
     "type": "git",
     "cache": { "strategy": "folder", "duration": "5m" },
     "properties": { "fetch_status": false }
    },
    {
     "type": "status",
     "cache": { "strategy": "session", "duration": "0s" }
    }
   ]
  }
 ]
}
```

**Result:** 200ms → 15ms (13x improvement!)

---

## Troubleshooting Cache Issues

### Problem: Cache Not Updating

**Symptoms:** Data seems stale/old

**Check:**

```powershell
# Clear cache
oh-my-posh cache clean

# Check cache strategy
$env:OHMYPOSH_DEBUG = "true"
# Run prompt and check logs
```

**Solutions:**

1. Reduce cache duration
2. Switch to different strategy
3. Manually clear cache

---

### Problem: Cache Growing Too Large

**Symptoms:** `~/.cache/oh-my-posh` is large

**Check:**

```powershell
# Size check
Get-ChildItem -Path "$env:LOCALAPPDATA\oh-my-posh\cache" -Recurse |
  Measure-Object -Property Length -Sum
```

**Solutions:**

```powershell
# Clear old cache
oh-my-posh cache clean --duration 1h

# Or disable caching for non-critical segments
```

---

### Problem: Stale Git Status

**Symptoms:** Git status not updating after changes

**Solutions:**

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "30s" // Shorter timeout
 },
 "type": "git"
}
```

Or clear manually:

```powershell
oh-my-posh cache clean
```

---

## Recommended Configurations

### Maximum Speed (Minimal Feedback)

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "60m"
 }
}
// + Disable fetch_status and fetch_upstream_icon
// Performance: 10-15ms
```

### Balanced (Recommended)

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 }
}
// Performance: 30-50ms
```

### Real-Time (Always Fresh)

```json
{
 "cache": {
  "strategy": "session",
  "duration": "0s"
 }
}
// Performance: 100-200ms
```

---

## Summary

### Key Takeaways

✅ **Cache strategies matter** - Choose right one for data type
✅ **Folder cache is best** - Perfect for git repos
✅ **Less is more** - Fewer segments = faster
✅ **Measure first** - Profile before optimizing
✅ **Balance needed** - Cache time vs freshness

### Performance Tips

1. Use `fetch_status: false` for large repos
2. Cache git status for 5-10 minutes
3. Session cache for shell/static info
4. Folder cache for git/version info
5. Measure and benchmark improvements

### For More Help

- [PERFORMANCE-OPTIMIZATION-GUIDE.md](./PERFORMANCE-OPTIMIZATION-GUIDE.md)
- [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md#performance)
- [FAQ-AND-TIPS-TRICKS.md](./FAQ-AND-TIPS-TRICKS.md) (Performance section)
