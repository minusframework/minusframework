param(
  [string]$OutputDir = "Docs\API",
  [string]$PasDocBin = "pasdoc",
  [switch]$OpenAfterBuild
)

$ErrorActionPreference = "Stop"

Write-Host "MinusFramework - Geracao de Documentacao da API" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (!(Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$sourceDirs = @(
  "Source\Core",
  "Source\Extensions",
  "Source\Bibliotecas",
  "Source\Bibliotecas\Providers",
  "Source\FeatureFlags",
  "Source\Messaging",
  "Source\Migrator",
  "Source\Telemetry"
)

$includeDirs = $sourceDirs -join ";"

$argList = @(
  "--output", $OutputDir,
  "--format", "html",
  "--name", "MinusFramework API",
  "--description", "MinusORM v2.0 + MinusMigrator v1.0 + MinusMessaging v1.0 + MinusTelemetry + MinusFeatureFlags",
  "--language", "br",
  "--source", $includeDirs,
  "--include", ".",
  "--write-uses-list",
  "--link-gv-uses",
  "--link-gv-classes",
  "--graphviz-uses",
  "--graphviz-classes",
  "--introduction", "README.md",
  "--auto-abstract",
  "--auto-link",
  "--marker", "en",
  "--staronly",
  "--visible-members", "public,published",
  "--use-tipue-search",
  "--css", "pasdoc_tigris.css"
)

Write-Host ""
Write-Host "Incluindo diretorios:" -ForegroundColor Yellow
foreach ($dir in $sourceDirs) {
  if (Test-Path $dir) {
    Write-Host "  + $dir" -ForegroundColor Green
  } else {
    Write-Host "  - $dir (nao encontrado)" -ForegroundColor Gray
  }
}

Write-Host ""
Write-Host "Executando $PasDocBin..." -ForegroundColor Yellow

try {
  & $PasDocBin @argList
  Write-Host ""
  Write-Host "Documentacao gerada em: $OutputDir" -ForegroundColor Green
  if ($OpenAfterBuild) {
    Start-Process "$OutputDir\index.html"
  }
} catch {
  Write-Host ""
  Write-Host "ERRO: PasDoc nao encontrado. Instale via:" -ForegroundColor Red
  Write-Host "  choco install pasdoc" -ForegroundColor Yellow
  Write-Host "  ou baixe de: https://github.com/pasdoc/pasdoc/releases" -ForegroundColor Yellow
  exit 1
}
