param(
  [Parameter(Mandatory)]
  [string]$Token,
  [string]$Ref = "main"
)

$modules = @(
  "minusframework-core",
  "minusframework-orm",
  "minusframework-migrator",
  "minusframework-cli",
  "minusframework-featureflags",
  "minusframework-messaging",
  "minusframework-extensions",
  "minusframework-telemetry",
  "minusframework-ai"
)

$metaRepo = "GabrielFerreiraMendes/minusframework"

$templateBuild   = "$metaRepo/.github/workflows/templates/build.yml@$Ref"
$templateRelease = "$metaRepo/.github/workflows/templates/release.yml@$Ref"
$templateReview  = "$metaRepo/.github/workflows/templates/review-pr.yml@$Ref"

foreach ($module in $modules) {
  Write-Host "=== $module ===" -ForegroundColor Cyan

  try {
    $dir = "c:\dev\$module"
    if (-not (Test-Path "$dir\.github\workflows")) {
      New-Item -ItemType Directory -Force -Path "$dir\.github\workflows" | Out-Null
    }

    # build.yml
    @"
name: Build

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  build:
    uses: $templateBuild
"@ | Set-Content -Path "$dir\.github\workflows\build.yml" -NoNewline

    # release.yml
    @"
name: Release

on:
  push:
    tags: ['v*']
  workflow_dispatch:

jobs:
  release:
    uses: $templateRelease
    secrets:
      GH_PAT: `${{ secrets.GH_PAT }}
"@ | Set-Content -Path "$dir\.github\workflows\release.yml" -NoNewline

    # review-pr.yml
    @"
name: Review PR

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    uses: $templateReview
    secrets:
      GITHUB_TOKEN: `${{ secrets.GITHUB_TOKEN }}
"@ | Set-Content -Path "$dir\.github\workflows\review-pr.yml" -NoNewline

    Write-Host "  Workflows atualizados" -ForegroundColor Green
  }
  catch {
    Write-Host "  ERRO: $_" -ForegroundColor Red
  }
}
