param(
    [string]$FromTag = "",
    [string]$ToTag = "HEAD",
    [string]$OutputFile = "RELEASE_NOTES.md",
    [string]$RepoUrl = "https://github.com/GabrielFerreiraMendes/minusframework"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

$Sections = @{
    "feat"     = @{ Title = ":rocket: Novidades";     Icon = "feat";     Items = @() }
    "fix"      = @{ Title = ":bug: Correcoes";         Icon = "fix";      Items = @() }
    "docs"     = @{ Title = ":books: Documentacao";    Icon = "docs";     Items = @() }
    "refactor" = @{ Title = ":hammer: Refatoracao";    Icon = "refactor"; Items = @() }
    "perf"     = @{ Title = ":zap: Performance";       Icon = "perf";     Items = @() }
    "test"     = @{ Title = ":test_tube: Testes";      Icon = "test";     Items = @() }
    "chore"    = @{ Title = ":wrench: Manutencao";     Icon = "chore";    Items = @() }
    "ci"       = @{ Title = ":construction_worker: CI/CD"; Icon = "ci";   Items = @() }
}

$BreakingItems = @()

function Get-LatestTag {
    $tag = git -C $Root describe --tags --abbrev=0 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    return $tag
}

function Get-Commits($From, $To) {
    $range = "$From..$To"
    if ($From -eq "") {
        $range = $To
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = "-C `"$Root`" -c i18n.logOutputEncoding=utf-8 log --oneline --format=`"%H|%s`" $range"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::Start($psi)

    $utf8Reader = [System.IO.StreamReader]::new(
        $proc.StandardOutput.BaseStream, [Text.Encoding]::UTF8)
    $output = $utf8Reader.ReadToEnd()
    $err = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) {
        Write-Host "Erro ao obter commits. Range: $range" -ForegroundColor Red
        if ($err) { Write-Host $err -ForegroundColor Red }
        exit 1
    }
    $utf8Reader.Dispose()
    return @($output -split "`r`n|`n" | Where-Object { $_.Trim() -ne "" })
}

function Get-ShortlogAuthorCount($Range) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = "-C `"$Root`" -c i18n.logOutputEncoding=utf-8 shortlog -sn $Range"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $utf8Reader = [System.IO.StreamReader]::new(
        $proc.StandardOutput.BaseStream, [Text.Encoding]::UTF8)
    $output = $utf8Reader.ReadToEnd()
    $null = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $utf8Reader.Dispose()
    if ($proc.ExitCode -ne 0) { return 0 }
    $lines = $output -split "`r`n|`n" | Where-Object { $_.Trim() -ne "" }
    return @($lines).Count
}

function Parse-Commit($Line) {
    $parts = $Line -split '\|', 2
    if ($parts.Length -lt 2) { return $null }

    $hash = $parts[0].Trim()
    $msg = $parts[1].Trim()
    $shortHash = $hash.Substring(0, 7)

    $isBreaking = $msg -match '(?i)BREAKING CHANGE'
    $msg = $msg -replace '\(?BREAKING CHANGE\)?:?\s*', ''

    $type = ""
    $scope = ""
    $description = $msg

    if ($msg -match '^(\w+)(\([^)]+\))?:\s*(.*)') {
        $type = $matches[1].ToLower()
        if ($matches[2]) {
            $scope = $matches[2] -replace '^\(|\)$', ''
        }
        $description = $matches[3]
    }

    return @{
        Hash        = $hash
        ShortHash   = $shortHash
        Type        = $type
        Scope       = $scope
        Description = $description
        IsBreaking  = $isBreaking
    }
}

function Format-CommitLine($Commit) {
    $scope = if ($Commit['Scope']) { " **($($Commit['Scope'])):**" } else { ":" }
    $commitUrl = "$RepoUrl/commit/$($Commit['Hash'])"
    return "- $($Commit['Description']) ([$($Commit['ShortHash'])]($commitUrl))"
}

function Build-ReleaseNotes {
    param([string]$Version, [array]$ParsedCommits)

    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("# Release $Version")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("> **Data:** $(Get-Date -Format 'dd/MM/yyyy')")
    [void]$sb.AppendLine()

    if ($ParsedCommits.Count -eq 0) {
        [void]$sb.AppendLine("_Nenhuma mudanca significativa neste release._")
        [void]$sb.AppendLine()
        return $sb.ToString()
    }

    if ($BreakingItems.Count -gt 0) {
        [void]$sb.AppendLine("## :warning: Breaking Changes")
        [void]$sb.AppendLine()
        foreach ($item in $BreakingItems) {
            $line = Format-CommitLine $item; [void]$sb.AppendLine($line)
        }
        [void]$sb.AppendLine()
    }

    foreach ($key in @("feat", "fix", "docs", "perf", "refactor", "test", "ci", "chore")) {
        if ($Sections[$key].Items.Count -eq 0) { continue }
        [void]$sb.AppendLine("## $($Sections[$key].Title)")
        [void]$sb.AppendLine()
        foreach ($item in $Sections[$key].Items) {
            $line = Format-CommitLine $item; [void]$sb.AppendLine($line)
        }
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**Commits:** $($ParsedCommits.Count) | **Autores:** $(Get-ShortlogAuthorCount $range)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Release gerado automaticamente por generate-release-notes.ps1*")
    [void]$sb.AppendLine()

    return $sb.ToString()
}

# --- Main ---

Write-Host "MinusFrameWork - Gerador de Release Notes" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if ($FromTag -eq "") {
    $FromTag = Get-LatestTag
    if ($FromTag -ne "") {
        Write-Host "Tag anterior detectada: $FromTag" -ForegroundColor Yellow
    } else {
        Write-Host "Nenhuma tag encontrada. Usando todo o historico." -ForegroundColor Yellow
    }
}

$range = if ($FromTag -ne "") { "$FromTag..$ToTag" } else { $ToTag }

Write-Host "Range: $range" -ForegroundColor Cyan
Write-Host "Lendo commits..." -ForegroundColor Gray

$logLines = Get-Commits $FromTag $ToTag
$allCommits = @()

foreach ($line in $logLines) {
    if ($line.Trim() -eq "") { continue }
    $commit = Parse-Commit $line
    if ($commit -eq $null) { continue }

    $allCommits += $commit

    if ($commit.IsBreaking) {
        $BreakingItems += $commit
    }

    if ($Sections.ContainsKey($commit.Type)) {
        $Sections[$commit.Type].Items += $commit
    } else {
        # Unrecognized type -- add to manutencao
        $Sections["chore"].Items += $commit
    }
}

$versionLabel = if ($FromTag -ne "") { "$FromTag..$ToTag" } else { $ToTag }
$notes = Build-ReleaseNotes -Version $versionLabel -ParsedCommits $allCommits

$outputPath = Join-Path $Root $OutputFile
[IO.File]::WriteAllText([IO.Path]::GetFullPath($outputPath), $notes, [Text.Encoding]::UTF8)

Write-Host "`nRelease Notes gerado: $outputPath" -ForegroundColor Green
Write-Host "`nResumo:" -ForegroundColor Cyan
foreach ($key in @("feat", "fix", "docs", "perf", "refactor", "test", "ci", "chore")) {
    if ($Sections[$key].Items.Count -gt 0) {
        Write-Host "  $($Sections[$key].Icon): $($Sections[$key].Items.Count) $($Sections[$key].Title)" -ForegroundColor Gray
    }
}
if ($BreakingItems.Count -gt 0) {
    Write-Host "  warning: $($BreakingItems.Count) Breaking Changes" -ForegroundColor Red
}
Write-Host "  Total: $($allCommits.Count) commits" -ForegroundColor Cyan
