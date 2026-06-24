#==============================================================================
# setup-dev.ps1 — Inicializa os submódulos privados do MinusFrameWork
#==============================================================================
param(
    [string]$Token = $env:GH_PAT,
    [string]$Org = "GabrielFerreiraMendes"
)

$ErrorActionPreference = "Stop"

if (-not $Token) {
    Write-Host "ERRO: Informe um PAT ou defina a variavel de ambiente GH_PAT." -ForegroundColor Red
    Write-Host "Crie em: https://github.com/settings/tokens" -ForegroundColor Yellow
    Write-Host "`nUso: .\setup-dev.ps1 -Token ghp_xxxx" -ForegroundColor Yellow
    exit 1
}

$Repos = @(
    "minusframework-core",
    "minusframework-telemetry",
    "minusframework-messaging",
    "minusframework-orm",
    "minusframework-migrator",
    "minusframework-featureflags",
    "minusframework-extensions",
    "minusframework-ai"
)

$DirMap = @{
    "minusframework-core"          = "Core"
    "minusframework-telemetry"     = "Telemetry"
    "minusframework-messaging"     = "Messaging"
    "minusframework-orm"           = "ORM"
    "minusframework-migrator"      = "Migrator"
    "minusframework-featureflags"  = "FeatureFlags"
    "minusframework-extensions"    = "Extensions"
    "minusframework-ai"            = "AI"
}

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RootDir

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  MinusFrameWork - Setup Dev Environment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$authUrl = "https://x-access-token:${Token}@github.com/$Org"

Write-Host "`nInicializando submodulos..." -ForegroundColor Yellow

foreach ($repo in $Repos) {
    $dir = $DirMap[$repo]
    $dirPath = Join-Path $RootDir $dir

    if (Test-Path (Join-Path $dirPath ".git")) {
        Write-Host "  $dir - ja inicializado" -ForegroundColor Green
        continue
    }

    Write-Host "  $dir - clonando..." -ForegroundColor Yellow
    $cloneUrl = "https://x-access-token:${Token}@github.com/$Org/$repo.git"

    Remove-Item "$dirPath\*" -Recurse -Force -ErrorAction SilentlyContinue

    git clone $cloneUrl $dirPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO: falha ao clonar $repo" -ForegroundColor Red
        exit 1
    }
    Write-Host "  $dir - OK" -ForegroundColor Green
}

Write-Host "`nAmbiente de desenvolvimento pronto!" -ForegroundColor Green
Write-Host "Execute o setup do Installer manualmente se necessario:" -ForegroundColor Cyan
Write-Host "  .\Installer\download-deps.ps1 -All" -ForegroundColor White
