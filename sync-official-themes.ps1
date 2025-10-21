# Update Oh-My-Posh Official Themes (Git Subtree)
# This script updates the themes folder from the official oh-my-posh repo using git subtree

Write-Host "`n🔄 Updating Oh-My-Posh Official Themes (Git Subtree)...`n" -ForegroundColor Cyan

# Update the subtree from upstream
Write-Host "📥 Pulling latest themes from upstream..." -ForegroundColor Yellow
git subtree pull --prefix=ohmyposh-official-themes ohmyposh-themes main --squash

if ($LASTEXITCODE -eq 0) {
    $themeCount = (Get-ChildItem "ohmyposh-official-themes\themes" -Filter "*.json" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "`n✅ Successfully updated official themes!" -ForegroundColor Green
    Write-Host "📁 Location: .\ohmyposh-official-themes\" -ForegroundColor Cyan
    Write-Host "🎨 Total themes: $themeCount`n" -ForegroundColor White
}
else {
    Write-Host "`n❌ Failed to update themes" -ForegroundColor Red
    Write-Host "� Tip: Make sure you've committed any local changes first`n" -ForegroundColor Yellow
}
