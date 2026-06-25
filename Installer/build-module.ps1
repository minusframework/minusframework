param(
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$RootDir,
    [Parameter(Mandatory)][string]$Token
)

$ErrorActionPreference = "Stop"

$ModuleDir = switch ($Module) {
    "minusframework-core"         { "Core" }
    "minusframework-orm"          { "ORM" }
    "minusframework-migrator"     { "Migrator" }
    "minusframework-featureflags" { "FeatureFlags" }
    "minusframework-messaging"    { "Messaging" }
    "minusframework-telemetry"    { "Telemetry" }
    "minusframework-extensions"   { "Extensions" }
    "minusframework-ai"           { "AI" }
    default { throw "Unknown module: $Module" }
}

$headers = @{
    "Authorization" = "Bearer $Token"
    "User-Agent"    = "PowerShell"
    "Accept"        = "application/vnd.github+json"
}
$apiBase = "https://api.github.com/repos/GabrielFerreiraMendes/$Module"

function Invoke-GitHub {
    param([string]$Method, [string]$Uri, $Body)
    $params = @{ Method = $Method; Uri = $Uri; Headers = $headers; ContentType = "application/json" }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10) }
    return Invoke-RestMethod @params
}

$relBody = @{
    tag_name             = $Tag
    name                 = "$Module $Tag"
    draft                = $true
    generate_release_notes = $false
}
try {
    $release = Invoke-GitHub -Method POST -Uri "$apiBase/releases" -Body $relBody
    Write-Host "Release created: $($release.html_url)"
} catch {
    $existing = Invoke-GitHub -Method GET -Uri "$apiBase/releases/tags/$Tag"
    $release = $existing
    Write-Host "Release already exists: $($release.html_url)"
}

$stageDir = Join-Path $RootDir "stage"
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

$bplDir = "$env:PUBLIC\Documents\Embarcadero\Studio\23.0\Bpl"
$dcpDir = "$env:PUBLIC\Documents\Embarcadero\Studio\23.0\Dcp"
$outDir = "$RootDir\$ModuleDir\Win32\Release"

switch ($Module) {
    "minusframework-core" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp" | Out-Null
        Copy-Item "$bplDir\MinusFramework_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$bplDir\MinusFramework_Design.bpl"  "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$dcpDir\MinusFramework_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$dcpDir\MinusFramework_Design.dcp"  "$stageDir\Dcp\" -ErrorAction Stop
    }
    "minusframework-telemetry" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp" | Out-Null
        Copy-Item "$bplDir\MinusTelemetry_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$dcpDir\MinusTelemetry_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
    }
    "minusframework-messaging" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp", "$stageDir\Bin" | Out-Null
        Copy-Item "$bplDir\MinusMessaging_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$bplDir\MinusMessaging_Design.bpl"   "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$dcpDir\MinusMessaging_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$dcpDir\MinusMessaging_Design.dcp"   "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$outDir\MinusMessaging_CLI.exe"      "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-orm" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$outDir\MinusORM.dll" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-migrator" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$outDir\MinusMigrator_DLL.dll" "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$outDir\MinusMigrator_CLI.exe" "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$outDir\MinusMigrator_GUI.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-featureflags" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$outDir\MinusFeatureFlags.exe"    "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$outDir\MinusFeatureFlagsAPI.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-ai" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$outDir\MinusAI_MCP.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-extensions" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Source" | Out-Null
        Copy-Item "$RootDir\$ModuleDir\Source\*.pas" "$stageDir\Source\" -ErrorAction SilentlyContinue
        Copy-Item "$RootDir\$ModuleDir\Source\*.dfm" "$stageDir\Source\" -ErrorAction SilentlyContinue
    }
}

$artifacts = Get-ChildItem -Recurse $stageDir -File
foreach ($artifact in $artifacts) {
    $relPath = $artifact.FullName.Substring($stageDir.Length + 1)
    $uploadUrl = $release.upload_url -replace '\{.*\}', "?name=$relPath"
    Write-Host "Uploading $relPath..."
    try {
        Invoke-RestMethod -Method POST -Uri $uploadUrl -Headers $headers -ContentType "application/octet-stream" -InFile $artifact.FullName | Out-Null
    } catch {
        Write-Host "Upload failed for $relPath : $_" -ForegroundColor Yellow
    }
}

Invoke-GitHub -Method PATCH -Uri "$apiBase/releases/$($release.id)" -Body @{ draft = $false } | Out-Null
Write-Host "Release $Tag published for $Module"
