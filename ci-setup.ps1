param(
    [string]$Token = "",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

$Repos = @(
    @{Name = "minusframework-core";         Dir = "Core"},
    @{Name = "minusframework-orm";          Dir = "ORM"},
    @{Name = "minusframework-migrator";     Dir = "Migrator"},
    @{Name = "minusframework-messaging";    Dir = "Messaging"},
    @{Name = "minusframework-telemetry";    Dir = "Telemetry"},
    @{Name = "minusframework-featureflags"; Dir = "FeatureFlags"},
    @{Name = "minusframework-extensions";   Dir = "Extensions"},
    @{Name = "minusframework-ai";           Dir = "AI"},
    @{Name = "minusframework-cli";          Dir = "Cli"}
)

$OrgUrl = "https://github.com/GabrielFerreiraMendes"

foreach ($repo in $Repos) {
    $dest = Join-Path $Root $repo.Dir
    $repoUrl = if ($Token) {
        "https://GabrielFerreiraMendes:$([Uri]::EscapeDataString($Token))@github.com/GabrielFerreiraMendes/$($repo.Name).git"
    } else {
        "$OrgUrl/$($repo.Name).git"
    }

    if (-not (Test-Path (Join-Path $dest ".git"))) {
        Write-Host "Clonando $($repo.Name)..." -ForegroundColor Yellow
        git clone --branch $Branch $repoUrl $dest 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Falha ao clonar $($repo.Name)" }
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "$($repo.Name) ja existe, atualizando..." -ForegroundColor Yellow
        git -C $dest fetch origin 2>&1
        git -C $dest checkout $Branch 2>&1
        git -C $dest reset --hard "origin/$Branch" 2>&1
        Write-Host "  OK" -ForegroundColor Green
    }
}

Write-Host "Setup concluido: $($Repos.Count) repositorios" -ForegroundColor Cyan
