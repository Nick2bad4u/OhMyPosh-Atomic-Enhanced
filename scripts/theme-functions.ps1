<#
.SYNOPSIS
Theme preview helper functions.

.DESCRIPTION
Intended for use in your PowerShell profile ($PROFILE) so you get quick commands
to preview themes interactively.

This file lives in .\scripts\ and launches .\scripts\preview-themes.ps1.
#>

$PreviewThemesScript = Join-Path -Path $PSScriptRoot -ChildPath 'preview-themes.ps1'

function Show-AllThemes {
    <#
    .SYNOPSIS
    Show ALL themes (custom + official) in the interactive previewer.
    #>
    & $PreviewThemesScript
}

function Show-CustomThemes {
    <#
    .SYNOPSIS
    Show ONLY custom themes in the interactive previewer.
    #>
    & $PreviewThemesScript -Custom
}

function Show-OfficialThemes {
    <#
    .SYNOPSIS
    Show ONLY official Oh-My-Posh themes in the interactive previewer.
    #>
    & $PreviewThemesScript -Official
}

# Back-compat names (older docs / muscle memory)
function Show-AllTheme { Show-AllThemes }
function Show-CustomTheme { Show-CustomThemes }
function Show-OfficialTheme { Show-OfficialThemes }

# Quick aliases
Set-Alias -Name themes -Value Show-AllThemes -Force -Scope Global
Set-Alias -Name mythemes -Value Show-CustomThemes -Force -Scope Global
Set-Alias -Name official-themes -Value Show-OfficialThemes -Force -Scope Global

# Only export when imported as a module (Export-ModuleMember errors when dot-sourced)
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Show-AllThemes, Show-CustomThemes, Show-OfficialThemes -Alias themes, mythemes, official-themes
}
