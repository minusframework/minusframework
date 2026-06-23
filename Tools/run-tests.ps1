param(
  [string]$Config = "Debug",
  [string]$Platform = "Win32",
  [switch]$SkipDocker,
  [switch]$SkipCompile
)

$Workspace = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# ── Docker ─────────────────────────────────────────────────────────────
if (-not $SkipDocker) {
  Write-Host "Starting Docker containers..." -ForegroundColor Cyan
  docker compose up -d --wait
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker compose failed (Docker running?). Use -SkipDocker if containers are already up." -ForegroundColor Red
    exit 1
  }
}

# ── Environment Variables ──────────────────────────────────────────────
Write-Host "Configuring test environment..." -ForegroundColor Cyan

# Firebird
$env:MINUSORM_TEST_FIREBIRD   = "/firebird/data/minusorm_test.fdb"
$env:MINUSORM_TEST_FB_USER    = "SYSDBA"
$env:MINUSORM_TEST_FB_PASS    = "masterkey"
$env:MINUSORM_TEST_FB_HOST    = "localhost"
$env:MINUSORM_TEST_FB_PORT    = "3050"

# MySQL
$env:MINUSORM_TEST_MYSQLHOST  = "localhost"
$env:MINUSORM_TEST_MYSQLDB    = "minusorm_test"
$env:MINUSORM_TEST_MYSQLUSER  = "root"
$env:MINUSORM_TEST_MYSQLPASS  = "root"
$env:MINUSORM_TEST_MYSQLPORT  = "3307"

# PostgreSQL
$env:MINUSORM_TEST_PGHOST     = "localhost"
$env:MINUSORM_TEST_PGDB       = "minusorm_test"
$env:MINUSORM_TEST_PGUSER     = "postgres"
$env:MINUSORM_TEST_PGPASS     = "postgres"
$env:MINUSORM_TEST_PGPORT     = "5433"

# MariaDB
$env:MINUSORM_TEST_MARIADBHOST = "localhost"
$env:MINUSORM_TEST_MARIADBPORT = "3308"
$env:MINUSORM_TEST_MARIADBDB   = "minusorm_test"
$env:MINUSORM_TEST_MARIADBUSER = "root"
$env:MINUSORM_TEST_MARIADBPASS = "root"

# ── Compile (dcc32) ────────────────────────────────────────────────────
$DCC32 = "c:\program files (x86)\embarcadero\studio\23.0\bin\dcc32.exe"
$BDSLib = "c:\program files (x86)\embarcadero\studio\23.0\lib\Win32\release"
$BDSImports = "c:\program files (x86)\embarcadero\studio\23.0\Imports"
$BDSInclude = "c:\program files (x86)\embarcadero\studio\23.0\include"
$DCPDir = "$env:PUBLIC\Documents\Embarcadero\Studio\23.0\Dcp"
$TestProj = Join-Path $Workspace "Tests\ORM\Test.MinusORM.dpr"
$TestOutDir = Join-Path $Workspace "Tests\ORM\__out"

if (-not $SkipCompile) {
  if (-not (Test-Path $TestOutDir)) { New-Item -ItemType Directory -Path $TestOutDir -Force | Out-Null }

  $SourcePaths = @(
    $BDSLib, "$env:USERPROFILE\Documents\Embarcadero\Studio\23.0\Imports",
    "$env:USERPROFILE\Documents\Embarcadero\Studio\23.0\Imports\Win32",
    $BDSImports, $DCPDir, $BDSInclude,
    (Join-Path $Workspace "Source\Bibliotecas"),
    (Join-Path $Workspace "Source\Bibliotecas\Providers"),
    (Join-Path $Workspace "Source\Core"),
    (Join-Path $Workspace "Source\Extensions"),
    "C:\Libs\Delphi\horse-master\src",
    "C:\Libs\Delphi\jhonson-master\src",
    "C:\Libs\Delphi\horse-jwt-master\src",
    "C:\Libs\Delphi\horse-logger-lumberjack\src",
    "C:\Libs\Delphi\delphi-jose-jwt-master\Source\JOSE",
    "C:\Libs\Delphi\delphi-jose-jwt-master\Source\Common"
  )
  $UnitPath = ($SourcePaths | Where-Object { Test-Path $_ }) -join ';'
  $ObjPath = $UnitPath
  $Define = if ($Config -eq "Debug") { "DEBUG" } else { "RELEASE" }

  $Args = @(
    "-`$O-", "-`$W+", "-`$R+", "-`$Q+", "--no-config", "-B", "-Q"
    "-D$Define"
    "-I`"$UnitPath`"", "-O`"$ObjPath`"", "-R`"$ObjPath`"", "-U`"$UnitPath`""
    "-K00400000", "-N`"$DCPDir`"", "-E`"$TestOutDir`""
    "-NSWinapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap"
    "`"$TestProj`""
  )

  Write-Host "Compiling tests..." -ForegroundColor Cyan
  $proc = Start-Process -FilePath $DCC32 -ArgumentList $Args -NoNewWindow -Wait -PassThru
  if ($proc.ExitCode -ne 0) {
    Write-Host "Build failed with exit code $($proc.ExitCode)" -ForegroundColor Red
    exit $proc.ExitCode
  }
  Write-Host "Build succeeded!" -ForegroundColor Green
}

# ── Copy DLLs ──────────────────────────────────────────────────────────
Write-Host "Copying native DLLs..." -ForegroundColor Cyan
Get-ChildItem (Join-Path $Workspace "Tests\ORM") -Filter "*.dll" | Copy-Item -Destination $TestOutDir -Force

# ── Run ────────────────────────────────────────────────────────────────
$TestExe = Join-Path $TestOutDir "TestMinusORM.exe"
if (-not (Test-Path $TestExe)) {
  $TestExe = Join-Path $Workspace "Tests\ORM\Test.MinusORM.exe"
}
if (Test-Path $TestExe) {
  Write-Host "Running tests..." -ForegroundColor Cyan
  & $TestExe
} else {
  Write-Host "Test executable not found at $TestOutDir or Tests\ORM\" -ForegroundColor Red
}
