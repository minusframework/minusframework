param([string]$Token)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$AuthUrl = "https://github.com/GabrielFerreiraMendes"

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

$gitOpts = if ($Token) { @("-c", "http.extraheader=AUTHORIZATION: bearer $Token") } else { @() }

foreach ($repo in $Repos) {
    $dest = Join-Path $Root $RepoDirs[$repo]
    if (-not (Test-Path $dest)) {
        Write-Host "Cloning $repo..."
        & git @gitOpts clone "$AuthUrl/$repo.git" $dest 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git clone failed for $repo" }
    } else {
        Write-Host "Updating $repo..."
        & git @gitOpts -C $dest fetch origin 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed for $repo" }
        git -C $dest reset --hard origin/main 2>&1
        if ($LASTEXITCODE -ne 0) { throw "git reset failed for $repo" }
    }
}
