param([string]$Token)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Auth = if ($Token) { "https://x-access-token:$Token@github.com/GabrielFerreiraMendes" } else { "https://github.com/GabrielFerreiraMendes" }

$Repos = @(
    "minusframework-telemetry",
    "minusframework-messaging",
    "minusframework-core",
    "minusframework-orm",
    "minusframework-migrator",
    "minusframework-featureflags",
    "minusframework-extensions",
    "minusframework-ai"
)

$RepoDirs = @{
    "minusframework-telemetry"    = "Telemetry"
    "minusframework-messaging"    = "Messaging"
    "minusframework-core"         = "Core"
    "minusframework-orm"          = "ORM"
    "minusframework-migrator"     = "Migrator"
    "minusframework-featureflags" = "FeatureFlags"
    "minusframework-extensions"   = "Extensions"
    "minusframework-ai"           = "AI"
}

foreach ($repo in $Repos) {
    $dest = Join-Path $Root $RepoDirs[$repo]
    if (-not (Test-Path $dest)) {
        Write-Host "Cloning $repo..."
        git clone "$Auth/$repo.git" $dest 2>&1 | Out-Null
    } else {
        Write-Host "Updating $repo..."
        git -C $dest fetch origin 2>&1 | Out-Null
        git -C $dest reset --hard origin/main 2>&1 | Out-Null
    }
}
