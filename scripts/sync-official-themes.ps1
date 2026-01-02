# Update Oh-My-Posh Official Themes (Git Subtree)
# This script updates the themes folder from the official oh-my-posh repo using git subtree.
#
# Note: This script lives in .\scripts\, but must run git commands from the repository root.

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

Write-Output "`n🔄 Updating Oh-My-Posh Official Themes (Git Subtree)...`n" -ForegroundColor Cyan

Push-Location -LiteralPath $RepoRoot
try {
    # Update the subtree from upstream
    Write-Output "📥 Pulling latest themes from upstream..." -ForegroundColor Yellow
    git subtree pull --prefix=ohmyposh-official-themes ohmyposh-themes main --squash
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -eq 0) {
    $themesPath = Join-Path -Path $RepoRoot -ChildPath 'ohmyposh-official-themes\themes'
    $themeCount = (Get-ChildItem $themesPath -Filter "*.json" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Output "`n✅ Successfully updated official themes!" -ForegroundColor Green
    Write-Output "📁 Location: .\ohmyposh-official-themes\" -ForegroundColor Cyan
    Write-Output "🎨 Total themes: $themeCount`n" -ForegroundColor White
}
else {
    Write-Output "`n❌ Failed to update themes" -ForegroundColor Red
    Write-Output "� Tip: Make sure you've committed any local changes first`n" -ForegroundColor Yellow
}
