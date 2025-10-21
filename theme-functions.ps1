# Add these functions to your PowerShell profile ($PROFILE)
# This gives you quick commands to preview themes interactively

function Show-AllThemes {
    <#
    .SYNOPSIS
    Shows ALL themes (custom + official) - press Enter to advance, Q to quit

    .DESCRIPTION
    Interactive theme previewer - see each theme and manually switch between them

    .EXAMPLE
    Show-AllThemes

    .EXAMPLE
    themes
    #>
    & ".\preview-themes.ps1"
}

function Show-CustomThemes {
    <#
    .SYNOPSIS
    Shows ONLY custom themes (your 4 advanced themes)

    .EXAMPLE
    Show-CustomThemes

    .EXAMPLE
    mythemes
    #>
    & ".\preview-themes.ps1" -Custom
}

function Show-OfficialThemes {
    <#
    .SYNOPSIS
    Shows ONLY official Oh-My-Posh themes

    .EXAMPLE
    Show-OfficialThemes

    .EXAMPLE
    official-themes
    #>
    & ".\preview-themes.ps1" -Official
}

# Quick aliases
Set-Alias -Name themes -Value Show-AllThemes -Force -Scope Global
Set-Alias -Name mythemes -Value Show-CustomThemes -Force -Scope Global
Set-Alias -Name official-themes -Value Show-OfficialThemes -Force -Scope Global

# Export for use in profile
Export-ModuleMember -Function Show-AllThemes, Show-CustomThemes, Show-OfficialThemes -Alias themes, mythemes, official-themes
