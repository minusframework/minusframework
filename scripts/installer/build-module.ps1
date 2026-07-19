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
$apiBase = "https://api.github.com/repos/minusframework/$Module"

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

$prebuiltDir = "$RootDir\$ModuleDir\Prebuilt"

switch ($Module) {
    "minusframework-core" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp", "$stageDir\Bin" | Out-Null
        Copy-Item "$prebuiltDir\Bpl\MinusFramework_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bpl\MinusFramework_Design.bpl"  "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Dcp\MinusFramework_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Dcp\MinusFramework_Design.dcp"  "$stageDir\Dcp\" -ErrorAction Stop
        if (Test-Path "$prebuiltDir\Bin\MinusCLI.exe") {
            Copy-Item "$prebuiltDir\Bin\MinusCLI.exe" "$stageDir\Bin\MinusCLI.exe" -ErrorAction Stop
        }
    }
    "minusframework-telemetry" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp" | Out-Null
        Copy-Item "$prebuiltDir\Bpl\MinusTelemetry_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Dcp\MinusTelemetry_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
    }
    "minusframework-messaging" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bpl", "$stageDir\Dcp", "$stageDir\Bin" | Out-Null
        Copy-Item "$prebuiltDir\Bpl\MinusMessaging_Runtime.bpl" "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bpl\MinusMessaging_Design.bpl"   "$stageDir\Bpl\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Dcp\MinusMessaging_Runtime.dcp" "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Dcp\MinusMessaging_Design.dcp"   "$stageDir\Dcp\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bin\MinusMessaging_CLI.exe"      "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-orm" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin", "$stageDir\Samples" | Out-Null
        Copy-Item "$prebuiltDir\Bin\MinusORM.dll" "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Samples\*.pas" "$stageDir\Samples\" -ErrorAction SilentlyContinue
        Copy-Item "$prebuiltDir\Samples\*.dfm" "$stageDir\Samples\" -ErrorAction SilentlyContinue
    }
    "minusframework-migrator" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$prebuiltDir\Bin\MinusMigrator_DLL.dll" "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bin\MinusMigrator_CLI.exe" "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bin\MinusMigrator_GUI.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-featureflags" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$prebuiltDir\Bin\MinusFeatureFlags.exe"    "$stageDir\Bin\" -ErrorAction Stop
        Copy-Item "$prebuiltDir\Bin\MinusFeatureFlagsAPI.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-ai" {
        New-Item -ItemType Directory -Force -Path "$stageDir\Bin" | Out-Null
        Copy-Item "$prebuiltDir\Bin\MinusAI_MCP.exe" "$stageDir\Bin\" -ErrorAction Stop
    }
    "minusframework-extensions" {
        # Extensions: no compiled output, no source distribution
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
