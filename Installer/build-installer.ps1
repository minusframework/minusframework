#==============================================================================
# build-installer.ps1 — Prepara staging e compila o instalador do MinusFramework
#==============================================================================
param(
    [string]$DelphiVersion = "23.0",  # BDS version: 21.0, 22.0, 23.0
    [string]$Config = "Release",
    [string]$Platform = "Win32",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$StagingDir = Join-Path $PSScriptRoot "Staging"
$DistDir = Join-Path $RootDir "Dist"
$PublicDocs = [Environment]::GetFolderPath("CommonDocuments")
$StudioDir = Join-Path $PublicDocs "Embarcadero\Studio\$DelphiVersion"
$BplDir = Join-Path $StudioDir "Bpl"
$DcpDir = Join-Path $StudioDir "Dcp"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MinusFramework Installer Builder" -ForegroundColor Cyan
Write-Host "  Version: $DelphiVersion ($Config/$Platform)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1 — Clean Staging
Write-Host "`n[1/4] Limpando staging..." -ForegroundColor Yellow
if (Test-Path $StagingDir) { Remove-Item -Recurse -Force $StagingDir }
New-Item -ItemType Directory -Force -Path $StagingDir\Bpl | Out-Null
New-Item -ItemType Directory -Force -Path $StagingDir\Dcp | Out-Null
New-Item -ItemType Directory -Force -Path $StagingDir\Source | Out-Null
New-Item -ItemType Directory -Force -Path $StagingDir\Docs | Out-Null
New-Item -ItemType Directory -Force -Path $StagingDir\Bin | Out-Null
New-Item -ItemType Directory -Force -Path $StagingDir\Samples | Out-Null

# Step 2 — Copy BPLs and DCPs from build output
Write-Host "`n[2/4] Copiando BPLs e DCPs..." -ForegroundColor Yellow

$BplFiles = @(
    "MinusTelemetry_Runtime.bpl",
    "MinusMessaging_Runtime.bpl",
    "MinusFramework_Runtime.bpl",
    "MinusFramework_Design.bpl",
    "MinusMessaging_Design.bpl"
)

$DcpFiles = @(
    "MinusTelemetry_Runtime.dcp",
    "MinusMessaging_Runtime.dcp",
    "MinusFramework_Runtime.dcp",
    "MinusFramework_Design.dcp",
    "MinusMessaging_Design.dcp"
)

foreach ($f in $BplFiles) {
    $src = Join-Path $BplDir $f
    if (Test-Path $src) {
        Copy-Item $src $StagingDir\Bpl\ -Verbose
    } else {
        Write-Host "  ALERTA: $src nao encontrado (compile os packages primeiro)" -ForegroundColor Red
    }
}
foreach ($f in $DcpFiles) {
    $src = Join-Path $DcpDir $f
    if (Test-Path $src) {
        Copy-Item $src $StagingDir\Dcp\ -Verbose
    } else {
        Write-Host "  ALERTA: $src nao encontrado (compile os packages primeiro)" -ForegroundColor Red
    }
}

# Step 3 — Copy Source files
Write-Host "`n[3/4] Copiando sources..." -ForegroundColor Yellow

$SourceDirs = @(
    @{Src="Source\Bibliotecas";            Dest="Source\Bibliotecas"},
    @{Src="Source\Bibliotecas\Providers";  Dest="Source\Bibliotecas\Providers"},
    @{Src="Source\Core";                   Dest="Source\Core"},
    @{Src="Source\Extensions";             Dest="Source\Extensions"},
    @{Src="Source\Migrator";               Dest="Source\Migrator"},
    @{Src="Source\Messaging";              Dest="Source\Messaging"},
    @{Src="Source\Telemetry";              Dest="Source\Telemetry"},
    @{Src="Source\FeatureFlags";           Dest="Source\FeatureFlags"}
)

foreach ($dir in $SourceDirs) {
    $srcDir = Join-Path $RootDir $dir.Src
    $dstDir = Join-Path $StagingDir $dir.Dest
    if (Test-Path $srcDir) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
        Copy-Item "$srcDir\*.pas" $dstDir -Verbose -ErrorAction SilentlyContinue
    }
}

# Copy docs
Copy-Item "$RootDir\README.md"               "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\CHANGELOG.md"            "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\LICENSE"                  "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\LICENSE-ENTERPRISE.md"   "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\CONTRIBUTING.md"         "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\ROADMAP.md"              "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$RootDir\Docs\*.md"               "$StagingDir\Docs\" -Verbose -ErrorAction SilentlyContinue

# Copy Samples
Copy-Item "$RootDir\Samples\*"               "$StagingDir\Samples\" -Recurse -Verbose -ErrorAction SilentlyContinue

# Copy CLI tools (output goes to .\Win32\Debug\ relative to project root)
$cliDebugDir = Join-Path $RootDir "$Platform\Debug"
Copy-Item "$cliDebugDir\MinusMigrator_CLI.exe"   "$StagingDir\Bin\" -Verbose -ErrorAction SilentlyContinue
Copy-Item "$cliDebugDir\MinusMessaging_CLI.exe"  "$StagingDir\Bin\" -Verbose -ErrorAction SilentlyContinue

# Step 4 — Compile installer
Write-Host "`n[4/4] Compilando instalador..." -ForegroundColor Yellow

$InnoSetup = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $InnoSetup)) {
    Write-Host "  ERRO: Inno Setup nao encontrado em $InnoSetup" -ForegroundColor Red
    Write-Host "  Instale de: https://jrsoftware.org/isdl.php" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$issFile = Join-Path $PSScriptRoot "MinusFramework.iss"
& $InnoSetup "/O$DistDir" "/FMinusFramework-$DelphiVersion-$Config-Setup" $issFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nInstalador gerado em: $DistDir" -ForegroundColor Green
} else {
    Write-Host "`nErro ao compilar instalador. Codigo: $LASTEXITCODE" -ForegroundColor Red
}
