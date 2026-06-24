#==============================================================================
# download-deps.ps1 — Baixa bibliotecas de terceiros para uso com MinusFramework
#==============================================================================
param(
    [switch]$All,
    [switch]$Horse,
    [switch]$Jhonson,
    [switch]$HorseCors,
    [switch]$HorseJWT,
    [switch]$HorseLogger,
    [switch]$JoseJWT
)

$ErrorActionPreference = "Stop"
$LibsDir = "C:\Libs\Delphi"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MinusFramework - Download de Dependencias" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $All -and -not $Horse -and -not $Jhonson -and -not $HorseCors -and -not $HorseJWT -and -not $HorseLogger -and -not $JoseJWT) {
    Write-Host "`nUso: .\download-deps.ps1 -All" -ForegroundColor Yellow
    Write-Host "  ou selecione componentes: -Horse -Jhonson -HorseCors -HorseJWT -HorseLogger -JoseJWT"
    exit 0
}

New-Item -ItemType Directory -Force -Path $LibsDir | Out-Null

$Repos = @{
    Horse       = "https://github.com/HashLoad/horse/archive/refs/heads/master.zip"
    Jhonson     = "https://github.com/HashLoad/jhonson/archive/refs/heads/master.zip"
    HorseCors   = "https://github.com/HashLoad/horse-cors/archive/refs/heads/master.zip"
    HorseJWT    = "https://github.com/HashLoad/horse-jwt/archive/refs/heads/master.zip"
    HorseLogger = "https://github.com/HashLoad/horse-logger/archive/refs/heads/lumberjack.zip"
    JoseJWT     = "https://github.com/paolo-rossi/delphi-jose-jwt/archive/refs/heads/master.zip"
}

$Selected = @()
if ($All -or $Horse)       { $Selected += "Horse" }
if ($All -or $Jhonson)     { $Selected += "Jhonson" }
if ($All -or $HorseCors)   { $Selected += "HorseCors" }
if ($All -or $HorseJWT)    { $Selected += "HorseJWT" }
if ($All -or $HorseLogger) { $Selected += "HorseLogger" }
if ($All -or $JoseJWT)     { $Selected += "JoseJWT" }

$TempDir = Join-Path $env:TEMP "MinusFramework_Deps"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

foreach ($lib in $Selected) {
    $url = $Repos[$lib]
    $zipFile = Join-Path $TempDir "$lib.zip"
    $extractDir = Join-Path $TempDir $lib

    Write-Host "`nBaixando $lib..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $url -OutFile $zipFile

    Write-Host "Extraindo..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

    $extractedFolder = Get-ChildItem $extractDir -Directory | Select-Object -First 1
    $destDir = Join-Path $LibsDir $extractedFolder.Name

    Write-Host "Instalando em $destDir..." -ForegroundColor Yellow
    if (Test-Path $destDir) { Remove-Item -Recurse -Force $destDir }
    Move-Item $extractedFolder.FullName $destDir -Force
}

Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue

Write-Host "`nDependencias instaladas em: $LibsDir" -ForegroundColor Green
Write-Host "Adicione ao Library Path do Delphi:" -ForegroundColor Cyan
Write-Host "  $LibsDir\horse-master\src" -ForegroundColor White
Write-Host "  $LibsDir\jhonson-master\src" -ForegroundColor White
Write-Host "  $LibsDir\horse-cors-master\src" -ForegroundColor White
Write-Host "  $LibsDir\horse-jwt-master\src" -ForegroundColor White
Write-Host "  $LibsDir\horse-logger-lumberjack\src" -ForegroundColor White
Write-Host "  $LibsDir\delphi-jose-jwt-master\Source\Common" -ForegroundColor White
Write-Host "  $LibsDir\delphi-jose-jwt-master\Source\JOSE" -ForegroundColor White
