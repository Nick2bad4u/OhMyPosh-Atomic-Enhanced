<#
.SYNOPSIS
Theme preview helper functions.

.DESCRIPTION
Intended for use in your PowerShell profile ($PROFILE) so you get quick commands
to preview themes interactively.

This file lives in .\scripts\ and launches .\scripts\preview-themes.ps1.
#>

$PreviewThemesScript = Join-Path -Path $PSScriptRoot -ChildPath 'preview-themes.ps1'

function Show-AllTheme {
    <#
    .SYNOPSIS
    Show ALL themes (custom + official) in the interactive previewer.
    #>
    & $PreviewThemesScript
}

function Show-CustomTheme {
    <#
    .SYNOPSIS
    Show ONLY custom themes in the interactive previewer.
    #>
    & $PreviewThemesScript -Custom
}

function Show-OfficialTheme {
    <#
    .SYNOPSIS
    Show ONLY official Oh-My-Posh themes in the interactive previewer.
    #>
    & $PreviewThemesScript -Official
}

# Back-compatible plural names remain available as aliases without keeping
# analyzer-invalid plural function nouns.
$aliasScope = if ($ExecutionContext.SessionState.Module) { 'Script' } else { 'Global' }
Set-Alias -Name Show-AllThemes -Value Show-AllTheme -Force -Scope $aliasScope
Set-Alias -Name Show-CustomThemes -Value Show-CustomTheme -Force -Scope $aliasScope
Set-Alias -Name Show-OfficialThemes -Value Show-OfficialTheme -Force -Scope $aliasScope

# Quick aliases
Set-Alias -Name themes -Value Show-AllTheme -Force -Scope $aliasScope
Set-Alias -Name mythemes -Value Show-CustomTheme -Force -Scope $aliasScope
Set-Alias -Name official-themes -Value Show-OfficialTheme -Force -Scope $aliasScope

# Only export when imported as a module (Export-ModuleMember errors when dot-sourced)
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember `
        -Function Show-AllTheme, Show-CustomTheme, Show-OfficialTheme `
        -Alias Show-AllThemes, Show-CustomThemes, Show-OfficialThemes, themes, mythemes, official-themes
}
