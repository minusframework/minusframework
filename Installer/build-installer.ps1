param(
    [string]$Token,
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$StagingDir = Join-Path $PSScriptRoot "Staging"
$DistDir = Join-Path $RootDir "Dist"

$Owner = "GabrielFerreiraMendes"
$ApiBase = "https://api.github.com/repos/$Owner"

$Modules = @(
    "minusframework-telemetry",
    "minusframework-messaging",
    "minusframework-core",
    "minusframework-orm",
    "minusframework-migrator",
    "minusframework-featureflags",
    "minusframework-extensions",
    "minusframework-ai"
)

$Headers = @{ "Accept" = "application/octet-stream" }
if ($Token) {
    $Headers["Authorization"] = "Bearer $Token"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MinusFramework Installer Builder" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Clean staging
Write-Host "`n[1/4] Limpando staging..." -ForegroundColor Yellow
if (Test-Path $StagingDir) { Remove-Item -Recurse -Force $StagingDir }
@("Bpl","Dcp","Bin","Source","Docs","Samples") | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir $_) | Out-Null
}

# Download artifacts from each module
Write-Host "`n[2/4] Baixando artefatos dos modulos..." -ForegroundColor Yellow

# PAT for private repo access (needs zip download support)
$AuthToken = $Token

function Get-ReleaseAsset {
    param([string]$Repo, [string]$AssetName, [string]$DestDir)
    
    $releaseUrl = "$ApiBase/$Repo/releases/$Version"
    
    try {
        # Get release info
        $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ 
            "Accept" = "application/json"
            "Authorization" = "Bearer $AuthToken"
            "User-Agent" = "PowerShell"
        } -ErrorAction Stop
        
        $asset = $release.assets | Where-Object { $_.name -like $AssetName } | Select-Object -First 1
        if (-not $asset) {
            Write-Host "  Asset '$AssetName' not found in $Repo release" -ForegroundColor Red
            return $false
        }
        
        $outFile = Join-Path $DestDir $asset.name
        Write-Host "  Baixando $($asset.name) de $Repo..." -ForegroundColor Yellow
        
        Invoke-RestMethod -Uri $asset.url -Headers @{
            "Accept" = "application/octet-stream"
            "Authorization" = "Bearer $AuthToken"
            "User-Agent" = "PowerShell"
        } -OutFile $outFile
        
        return $true
    } catch {
        Write-Host "  Falha ao baixar de $Repo : $_" -ForegroundColor Red
        return $false
    }
}

function Get-ReleaseZip {
    param([string]$Repo, [string]$DestDir)
    
    $zipUrl = "$ApiBase/$Repo/releases/$Version"
    $zipFile = Join-Path $env:TEMP "$Repo.zip"
    
    try {
        $release = Invoke-RestMethod -Uri $zipUrl -Headers @{ 
            "Accept" = "application/json"
            "Authorization" = "Bearer $AuthToken"
            "User-Agent" = "PowerShell"
        } -ErrorAction Stop
        
        # Download zipball
        $zipballUrl = $release.zipball_url
        Write-Host "  Baixando $Repo..." -ForegroundColor Yellow
        
        Invoke-RestMethod -Uri $zipballUrl -Headers @{
            "Accept" = "application/vnd.github+json"
            "Authorization" = "Bearer $AuthToken"
            "User-Agent" = "PowerShell"
        } -OutFile $zipFile
        
        $extractDir = Join-Path $env:TEMP "$Repo-extract"
        if (Test-Path $extractDir) { Remove-Item -Recurse -Force $extractDir }
        Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force
        
        # The zip contains a top-level dir named {owner}-{repo}-{sha}
        $topDir = Get-ChildItem $extractDir -Directory | Select-Object -First 1
        if ($topDir) {
            Copy-Item "$($topDir.FullName)\*" $DestDir -Recurse -Force
        }
        
        Remove-Item -Force $zipFile -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
        
        return $true
    } catch {
        Write-Host "  Falha ao baixar $Repo : $_" -ForegroundColor Red
        return $false
    }
}

# Download module artifacts
foreach ($mod in $Modules) {
    Write-Host "`n  --- $mod ---" -ForegroundColor Cyan
    
    $modStage = Join-Path $StagingDir "Source\$mod"
    New-Item -ItemType Directory -Force -Path $modStage | Out-Null
    
    # Download source zip
    Get-ReleaseZip -Repo $mod -DestDir $modStage | Out-Null
    
    # Download BPLs
    Get-ReleaseAsset -Repo $mod -AssetName "*.bpl" -DestDir (Join-Path $StagingDir "Bpl") | Out-Null
    
    # Download DCPs
    Get-ReleaseAsset -Repo $mod -AssetName "*.dcp" -DestDir (Join-Path $StagingDir "Dcp") | Out-Null
    
    # Download EXE/DLL
    Get-ReleaseAsset -Repo $mod -AssetName "*.exe" -DestDir (Join-Path $StagingDir "Bin") | Out-Null
    Get-ReleaseAsset -Repo $mod -AssetName "*.dll" -DestDir (Join-Path $StagingDir "Bin") | Out-Null
}

# Copy docs
Write-Host "`n[3/4] Copiando documentacao..." -ForegroundColor Yellow
Copy-Item "$RootDir\README.md" "$StagingDir\Docs\" -ErrorAction SilentlyContinue
Copy-Item "$RootDir\LICENSE" "$StagingDir\Docs\" -ErrorAction SilentlyContinue
Copy-Item "$RootDir\ROADMAP.md" "$StagingDir\Docs\" -ErrorAction SilentlyContinue

# Compile installer
Write-Host "`n[4/4] Compilando instalador..." -ForegroundColor Yellow

$InnoSetup = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $InnoSetup)) {
    Write-Host "  ERRO: Inno Setup nao encontrado em $InnoSetup" -ForegroundColor Red
    Write-Host "  Instale de: https://jrsoftware.org/isdl.php" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

$issFile = Join-Path $PSScriptRoot "MinusFramework.iss"
& $InnoSetup "/O$DistDir" "/FMinusFramework-$Version-Setup" $issFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nInstalador gerado em: $DistDir" -ForegroundColor Green
} else {
    Write-Host "`nErro ao compilar instalador. Codigo: $LASTEXITCODE" -ForegroundColor Red
}
