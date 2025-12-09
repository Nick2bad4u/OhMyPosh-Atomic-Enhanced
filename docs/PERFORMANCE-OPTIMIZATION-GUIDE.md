# ⚡ Performance Optimization Guide

## Table of Contents

1. [Identifying Performance Issues](#identifying-performance-issues)
2. [Understanding Prompt Rendering](#understanding-prompt-rendering)
3. [Segment Caching Strategies](#segment-caching-strategies)
4. [Disabling Expensive Segments](#disabling-expensive-segments)
5. [Optimization Techniques](#optimization-techniques)
6. [Benchmarking](#benchmarking)
7. [Pre-Built Optimized Configurations](#pre-built-optimized-configurations)
8. [Troubleshooting Slow Prompts](#troubleshooting-slow-prompts)

---

## Identifying Performance Issues

### Symptoms of Performance Problems

- **Delayed prompt rendering** (> 300ms before first character appears)
- **CPU spikes** when entering new directory
- **Laggy typing** (terminal unresponsive while typing)
- **Battery drain** on laptops
- **Network delays** over SSH

### Quick Performance Check

```powershell
# Measure prompt generation time
$sw = [System.Diagnostics.Stopwatch]::StartNew()
oh-my-posh print primary
$sw.Elapsed.TotalMilliseconds

# Goal: < 200ms
# Acceptable: < 300ms
# Problem: > 500ms
```

### Enable Debug Timing

```powershell
# Enable Oh My Posh debug output
$env:OHMYPOSH_DEBUG = "true"

# Reload profile
& $profile

# Check which segments are slow
# Output will show timing for each segment
```

---

## Understanding Prompt Rendering

### Rendering Pipeline

```
┌─────────────────────────────────────────────┐
│ User presses Enter                          │
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│ Oh My Posh initializes                      │ ~10ms
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│ For each block:                             │
│  For each segment:                          │
│   ├─ Check cache                            │ ~1-5ms
│   ├─ Execute segment (if not cached)       │ ~5-100ms
│   └─ Format output                         │ ~1-2ms
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│ Render prompt string                        │ ~5-10ms
└────────────┬────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────┐
│ Total time: 30-300+ ms                      │
└─────────────────────────────────────────────┘
```

### Segment Execution Cost

| Segment Type      | Typical Cost | Cacheable          |
| ----------------- | ------------ | ------------------ |
| **shell**         | 1-2ms        | ✅ Yes             |
| **path**          | 5-10ms       | ⚠️ Sometimes       |
| **git**           | 50-200ms     | ✅ Yes (by folder) |
| **status**        | 1-2ms        | ✅ Yes             |
| **command**       | 10-100ms+    | ✅ Yes             |
| **node**          | 30-80ms      | ✅ Yes             |
| **python**        | 30-80ms      | ✅ Yes             |
| **owm (weather)** | 500ms+       | ⚠️ Network         |

---

## Segment Caching Strategies

### Cache Strategy Types

```json
{
  "cache": {
    "strategy": "session|folder|windows",
    "duration": "5m",
    "skip_cache": false
  }
}
```

#### Strategy: Session

Cache for entire shell session (from startup to close).

**Best for:** Runtime versions, environment variables, fixed state

**Example:**

```json
{
  "type": "node",
  "cache": {
    "strategy": "session",
    "duration": "1h" // Effectively entire session
  }
}
```

**Pros:** ✅ Fastest, ✅ Consistent
**Cons:** ❌ Won't detect version changes mid-session

#### Strategy: Folder

Cache per directory (resets when changing directories).

**Best for:** Git status, file-dependent info

**Example:**

```json
{
  "type": "git",
  "cache": {
    "strategy": "folder",
    "duration": "5m"
  }
}
```

**Pros:** ✅ Updates on directory change, ✅ Good balance
**Cons:** ⚠️ May still be slow in large repos

#### Strategy: Windows

Cache per PowerShell window session.

**Best for:** OS-specific info

**Example:**

```json
{
  "type": "env",
  "cache": {
    "strategy": "windows"
  }
}
```

### Duration Formatting

| Format    | Meaning          | Use Case                 |
| --------- | ---------------- | ------------------------ |
| `"500ms"` | 500 milliseconds | Very frequent updates    |
| `"2s"`    | 2 seconds        | Time display             |
| `"30s"`   | 30 seconds       | Active development       |
| `"5m"`    | 5 minutes        | Git status in slow repos |
| `"1h"`    | 1 hour           | Runtime versions         |

### Recommended Caching Configuration

```json
{
  "blocks": [
    {
      "segments": [
        {
          "type": "shell",
          "cache": {
            "strategy": "session",
            "duration": "1h"
          }
        },
        {
          "type": "path",
          "cache": {
            "strategy": "session",
            "duration": "1h"
          }
        },
        {
          "type": "git",
          "cache": {
            "strategy": "folder",
            "duration": "5m"
          },
          "properties": {
            "fetch_status": true,
            "fetch_upstream_icon": false // Expensive
          }
        },
        {
          "type": "node",
          "cache": {
            "strategy": "folder",
            "duration": "30m"
          }
        },
        {
          "type": "command",
          "cache": {
            "strategy": "session",
            "duration": "5m"
          }
        }
      ]
    }
  ]
}
```

---

## Disabling Expensive Segments

### Method 1: Empty Template

Hide a segment without removing it:

```json
{
  "type": "owm",
  "template": "", // Empty = hidden
  "properties": {
    "api_key": "..." // Won't execute
  }
}
```

### Method 2: Conditional Rendering

Only show in certain directories:

```json
{
  "type": "git",
  "template": "{{ if or .Error .Detached }}{{ .Branch }}{{ end }}"
}
```

### Method 3: Remove Expensive Properties

```json
{
  "type": "git",
  "properties": {
    "fetch_status": false, // Expensive network call
    "fetch_upstream_icon": false, // Upstream tracking
    "fetch_worktree_count": false // Worktree checking
  }
}
```

### High-Cost Segments to Consider Disabling

1. **`owm` (Weather)** - Network-dependent
   - 500ms+ per call
   - Solution: Disable or cache 30m+

2. **`git` with fetch_status** - Large repo scanning
   - 100-500ms in large repos
   - Solution: `fetch_status: false`

3. **`command` with expensive scripts** - Custom logic
   - 50-200ms depending on script
   - Solution: Cache aggressively or replace

4. **`node`, `python`, `ruby` without caching** - File system scans
   - 30-80ms per segment
   - Solution: Add proper caching

---

## Optimization Techniques

### 1. Parallel Segment Execution

Oh My Posh 7.9+ supports parallel segment execution:

```json
{
  "version": 3,
  "parallel": true,  // Enable parallel rendering
  "blocks": [...]
}
```

**Impact:** 20-40% faster on average

### 2. Simplified Git Status

For large repositories:

```json
{
  "type": "git",
  "properties": {
    "fetch_status": false,
    "fetch_upstream_icon": false,
    "windows_registry": false
  },
  "cache": {
    "strategy": "folder",
    "duration": "10m"
  }
}
```

### 3. Remove Unnecessary Segments

**Analyze each segment:**

- Do I need this information in my prompt?
- How often do I look at it?
- What's the actual cost vs. benefit?

**Example: Remove right-aligned segments if not needed**

```json
{
  "blocks": [
    {
      "alignment": "left",
      "segments": [...]
    },
    // {
    //   "alignment": "right",
    //   "segments": [...]  // Disabled
    // }
  ]
}
```

### 4. Use Transient Prompt

Show simplified prompt after command execution:

```json
{
  "transient_prompt": {
    "background": "transparent",
    "foreground": "p:accent_color",
    "template": "❯ ",
    "type": "prompt"
  }
}
```

**Effect:** Only expensive prompt on fresh input

### 5. Optimize Custom Commands

```json
{
  "type": "command",
  "template": "{{ .Output }}",
  "properties": {
    "shell": "powershell",
    // ❌ SLOW: Searches entire filesystem
    // "command": "Get-ChildItem -Recurse | Measure-Object"

    // ✅ FAST: Only checks current directory
    "command": "(Get-ChildItem | Measure-Object).Count"
  },
  "cache": {
    "strategy": "folder",
    "duration": "5m"
  }
}
```

### 6. Reduce Path Depth

```json
{
  "type": "path",
  "properties": {
    "max_depth": 2, // Show only last 2 directories
    "folder_separator_icon": "/"
  }
}
```

---

## Benchmarking

### Measuring Individual Segment Performance

```powershell
# Minimal test theme with single segment
$testTheme = @"
{
  "version": 3,
  "blocks": [{
    "alignment": "left",
    "segments": [{
      "type": "git",
      "background": "#000000",
      "foreground": "#FFFFFF",
      "template": "{{ .Branch }}",
      "properties": {
        "fetch_status": false,
        "fetch_upstream_icon": false
      }
    }]
  }]
}
"@

$testTheme | Out-File -FilePath "test.json"

# Benchmark
$times = @()
for ($i = 0; $i -lt 10; $i++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    oh-my-posh print primary --config test.json | Out-Null
    $sw.Stop()
    $times += $sw.Elapsed.TotalMilliseconds
}

$average = ($times | Measure-Object -Average).Average
$max = ($times | Measure-Object -Maximum).Maximum
$min = ($times | Measure-Object -Minimum).Minimum

Write-Host "Average: ${average}ms"
Write-Host "Min: ${min}ms"
Write-Host "Max: ${max}ms"
```

### Full Theme Benchmark

```powershell
# Compare full theme performance over time
$results = @()
for ($run = 0; $run -lt 5; $run++) {
    $times = @()
    for ($i = 0; $i -lt 10; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        oh-my-posh print primary --config "OhMyPosh-Atomic-Custom.json" | Out-Null
        $sw.Stop()
        $times += $sw.Elapsed.TotalMilliseconds
    }
    $avg = ($times | Measure-Object -Average).Average
    $results += @{
        Run = $run + 1
        Average = [Math]::Round($avg, 2)
    }
}

$results | Format-Table
```

### Expected Performance

| Configuration           | Time      | Notes         |
| ----------------------- | --------- | ------------- |
| Minimal (2-3 segments)  | 30-50ms   | ✅ Excellent  |
| Standard (5-7 segments) | 50-150ms  | ✅ Good       |
| Full-featured           | 150-300ms | ⚠️ Acceptable |
| Poorly optimized        | 500ms+    | ❌ Needs work |

---

## Pre-Built Optimized Configurations

### Minimum Prompt (Fastest)

```json
{
  "version": 3,
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "type": "text",
          "template": "❯ ",
          "foreground": "p:accent"
        }
      ]
    }
  ]
}
```

**Performance:** ~5-10ms

### Quick Prompt (Very Fast)

```json
{
  "version": 3,
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "type": "shell",
          "cache": { "strategy": "session" }
        },
        {
          "type": "path",
          "properties": { "max_depth": 2 },
          "cache": { "strategy": "session" }
        },
        {
          "type": "git",
          "properties": { "fetch_status": false },
          "cache": { "strategy": "folder", "duration": "5m" }
        }
      ]
    }
  ]
}
```

**Performance:** ~30-50ms

### Balanced Prompt (Good Performance)

```json
{
  "version": 3,
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        { "type": "shell", "cache": { "strategy": "session" } },
        { "type": "path", "cache": { "strategy": "session" } },
        {
          "type": "git",
          "cache": { "strategy": "folder", "duration": "5m" },
          "properties": {
            "fetch_status": true,
            "fetch_upstream_icon": false
          }
        },
        {
          "type": "node",
          "cache": { "strategy": "folder", "duration": "30m" }
        },
        { "type": "status", "cache": { "strategy": "session" } }
      ]
    }
  ]
}
```

**Performance:** ~80-150ms

---

## Troubleshooting Slow Prompts

### Issue: Prompt Slow on First Directory Enter

**Cause:** First-time git status evaluation or caching not working

**Solutions:**

1. Increase git cache duration:

   ```json
   {
     "type": "git",
     "cache": {
       "strategy": "folder",
       "duration": "10m" // Longer cache
     }
   }
   ```

2. Disable expensive git features:
   ```json
   {
     "properties": {
       "fetch_status": false,
       "fetch_upstream_icon": false
     }
   }
   ```

### Issue: Slow Over SSH/Network

**Cause:** Network latency amplifies segment delays

**Solutions:**

1. Aggressive caching for remote:

   ```json
   {
     "type": "git",
     "cache": {
       "strategy": "folder",
       "duration": "30m" // Very long cache
     }
   }
   ```

2. Disable network-dependent segments:

   ```json
   {
     "type": "owm",
     "template": "" // Disable weather
   }
   ```

3. Simplify path display:
   ```json
   {
     "type": "path",
     "properties": { "max_depth": 1 } // Only current dir
   }
   ```

### Issue: Slow in Large Git Repositories

**Cause:** Git status checking takes time in large repos

**Solutions:**

1. Disable status checking:

   ```json
   {
     "type": "git",
     "properties": { "fetch_status": false }
   }
   ```

2. Use `.gitignore` to exclude untracked files:

   ```bash
   # .gitignore in repo root
   # This speeds up git status
   node_modules/
   dist/
   build/
   ```

3. Increase git cache significantly:
   ```json
   {
     "cache": {
       "duration": "30m" // Cache for 30 minutes
     }
   }
   ```

### Issue: High CPU Even with Caching

**Cause:** Caching not working or disabled

**Solutions:**

1. Verify cache strategy exists:

   ```json
   {
     "cache": {
       "strategy": "folder",
       "duration": "5m",
       "skip_cache": false // Make sure not skipped
     }
   }
   ```

2. Check for multiple expensive segments
3. Profile with debug:
   ```powershell
   $env:OHMYPOSH_DEBUG = "true"
   ```

---

## Performance Tuning Checklist

- [ ] Measured baseline prompt time (< 300ms?)
- [ ] Enabled parallel execution (`"parallel": true`)
- [ ] Configured cache strategies for all segments
- [ ] Disabled `fetch_status` in git if repo is large
- [ ] Removed unnecessary segments
- [ ] Set appropriate cache durations
- [ ] Tested performance over SSH
- [ ] Profiled with debug enabled
- [ ] Verified caching working (ls -la `.cache`)

---

## Summary

**Performance Optimization Priority:**

1. **Enable caching** - ~50% improvement
2. **Disable expensive features** - ~30% improvement
3. **Remove unnecessary segments** - ~20% improvement
4. **Optimize custom commands** - ~10-20% improvement
5. **Enable parallel execution** - ~20-40% improvement

**Target:** < 200ms for typical usage, < 300ms maximum

For more details on specific segment configuration, see [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md).
