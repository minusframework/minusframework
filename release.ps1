param(
    [string]$Version = "0.1.0",
    [switch]$SkipBuild,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Dist = Join-Path $Root "dist"
$BuildOrder = @(
    @{Name = "Telemetry";   Dir = "Telemetry";   Type = "package"; Path = "Packages\MinusTelemetry_Runtime.dpk"},
    @{Name = "Messaging";   Dir = "Messaging";   Type = "package"; Path = "Packages\MinusMessaging_Runtime.dpk"},
    @{Name = "Core";        Dir = "Core";        Type = "package"; Path = "Packages\MinusFramework_Runtime.dpk"},
    @{Name = "FeatureFlags";Dir = "FeatureFlags";Type = "project"; Path = "FeatureFlags\MinusFeatureFlags.dpr"},
    @{Name = "Extensions";  Dir = "Extensions";  Type = "package"; Path = "Packages\*.dpk"},
    @{Name = "CLI";         Dir = "Cli";         Type = "project"; Path = "Source\minus.dpr"},
    @{Name = "Migrator";    Dir = "Migrator";    Type = "project"; Path = "MinusMigrator_CLI.dpr"},
    @{Name = "ORM";         Dir = "ORM";         Type = "project"; Path = "MinusORM.dpr"},
    @{Name = "AI";          Dir = "AI";          Type = "project"; Path = "Source\MinusAI_MCP.dpr"}
)

Write-Host "=== Release v$Version ===" -ForegroundColor Cyan

# Step 1: Health check
Write-Host "`n[1/5] Verificando submódulos..." -ForegroundColor Yellow
foreach ($mod in $BuildOrder) {
    $dir = Join-Path $Root $mod.Dir
    if (-not (Test-Path (Join-Path $dir ".git"))) {
        Write-Host "  AVISO: $($mod.Name) não possui .git (submódulo não clonado)" -ForegroundColor DarkYellow
    } else {
        $branch = git -C $dir rev-parse --abbrev-ref HEAD 2>$null
        $hash = git -C $dir rev-parse --short HEAD 2>$null
        Write-Host "  $($mod.Name): branch=$branch commit=$hash" -ForegroundColor Gray
    }
}

# Step 2: Build Docusaurus
Write-Host "`n[2/5] Compilando documentação..." -ForegroundColor Yellow
npx docusaurus build 2>&1
if ($LASTEXITCODE -ne 0) { throw "Falha no build da documentação" }
Write-Host "  OK" -ForegroundColor Green

# Step 3: Build Delphi packages (requires RAD Studio)
if (-not $SkipBuild) {
    Write-Host "`n[3/5] Compilando packages (ordem: Telemetry -> Messaging -> Core -> ...)" -ForegroundColor Yellow
    $msbuild = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\MSBuild.exe"
    if (-not (Test-Path $msbuild)) {
        Write-Host "  AVISO: RAD Studio/MSBuild não encontrado em $msbuild. Pule com -SkipBuild." -ForegroundColor DarkYellow
    } else {
        foreach ($mod in $BuildOrder) {
            $proj = Join-Path $Root ($mod.Dir) $mod.Path
            if (Test-Path $proj) {
                Write-Host "  Compilando $($mod.Name)..." -NoNewline
                & $msbuild $proj /t:Build /p:Config=Release /nologo 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green }
                else { Write-Host " FALHA" -ForegroundColor Red }
            }
        }
    }
}

# Step 4: Run tests
if (-not $SkipTests) {
    Write-Host "`n[4/5] Executando testes..." -ForegroundColor Yellow
    foreach ($mod in $BuildOrder) {
        $testScript = Join-Path $Root ($mod.Dir) "run-tests.ps1"
        if (Test-Path $testScript) {
            Write-Host "  Testando $($mod.Name)..." -NoNewline
            & $testScript 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green }
            else { Write-Host " FALHA" -ForegroundColor Red }
        }
    }
}

# Step 5: Build installer
Write-Host "`n[5/5] Gerando instalador..." -ForegroundColor Yellow
$installerScript = Join-Path $Root "Installer\build-installer.ps1"
if (Test-Path $installerScript) {
    & $installerScript -Version $Version
    Write-Host "  OK" -ForegroundColor Green
} else {
    Write-Host "  AVISO: build-installer.ps1 não encontrado" -ForegroundColor DarkYellow
}

Write-Host "`n=== Release v$Version concluída ===" -ForegroundColor Cyan
