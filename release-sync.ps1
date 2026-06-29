param(
    [Parameter(Mandatory)][string]$Version,
    [string]$Token = "",
    [switch]$DryRun = $false,
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

$Repos = @(
    "minusframework-telemetry",
    "minusframework-messaging",
    "minusframework-core",
    "minusframework-orm",
    "minusframework-migrator",
    "minusframework-featureflags",
    "minusframework-extensions",
    "minusframework-ai",
    "minusframework-cli"
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
    "minusframework-cli"          = "Cli"
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  MinusFrameWork Release Sync" -ForegroundColor Cyan
Write-Host "  Version : $Version" -ForegroundColor Cyan
Write-Host "  Branch  : $Branch" -ForegroundColor Cyan
Write-Host "  Dry-Run : $($DryRun.IsPresent)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($Version -notmatch '^v?[\d]+\.[\d]+\.[\d]+') {
    Write-Host "ERRO: Versão inválida '$Version'. Use o formato v0.1.0 ou 0.1.0" -ForegroundColor Red
    exit 1
}

$OrgUrl = "https://github.com/GabrielFerreiraMendes"
$TagName = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }

function Write-Step($Msg) {
    Write-Host "`n>>> $Msg" -ForegroundColor Yellow
}

function Invoke-Git {
    param([string]$Dir, [string[]]$GitArgs)
    if ($DryRun) {
        Write-Host "  [DRY-RUN] git -C $Dir $($GitArgs -join ' ')" -ForegroundColor DarkYellow
        return $true
    }
    $output = & {
        $ErrorActionPreference = 'SilentlyContinue'
        git -C $Dir @GitArgs
    } 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FALHA: $($output | Out-String)" -ForegroundColor Red
        return $false
    }
    return $true
}

$TagCount = 0
$ErrorCount = 0

foreach ($repo in $Repos) {
    $dest = Join-Path $Root $RepoDirs[$repo]
    $repoUrl = if ($Token) {
        "https://GabrielFerreiraMendes:$Token@github.com/GabrielFerreiraMendes/$repo.git"
    } else {
        "$OrgUrl/$repo.git"
    }

    Write-Step "[$repo] Processando..."

    if (-not (Test-Path (Join-Path $dest ".git"))) {
        Write-Host "  Repositório não clonado. Clonando..."
        if (-not $DryRun) {
            try {
                git clone $repoUrl $dest
                if ($LASTEXITCODE -ne 0) { throw "git clone falhou" }
            } catch {
                Write-Host "    FALHA ao clonar $repo : $_" -ForegroundColor Red
                $ErrorCount++
                continue
            }
        } else {
            Write-Host "  [DRY-RUN] git clone $repoUrl $dest" -ForegroundColor DarkYellow
        }
    }

    # Garantir que a origin tenha o token para fetch/push
    if ($Token -and (-not $DryRun)) {
        git -C $dest remote set-url origin $repoUrl 2>$null
    }

    if (-not (Invoke-Git -Dir $dest -GitArgs @("fetch", "origin"))) {
        $ErrorCount++; continue
    }

    if (-not (Invoke-Git -Dir $dest -GitArgs @("checkout", $Branch))) {
        $ErrorCount++; continue
    }

    $isDetached = git -C $dest symbolic-ref -q HEAD 2>$null
    if (-not $isDetached) {
        if (-not (Invoke-Git -Dir $dest -GitArgs @("reset", "--hard", "origin/$Branch"))) {
            $ErrorCount++; continue
        }
    }

    $existingTag = git -C $dest tag -l $TagName 2>$null
    if ($existingTag) {
        Write-Host "  Tag $TagName já existe em $repo. Pulando." -ForegroundColor DarkYellow
        $TagCount++
    } else {
        if (-not (Invoke-Git -Dir $dest -GitArgs @("tag", "-a", $TagName, "-m", "Release $TagName"))) {
            $ErrorCount++; continue
        }

        if (-not (Invoke-Git -Dir $dest -GitArgs @("push", "origin", $TagName))) {
            Write-Host "  AVISO: push da tag falhou (pode ser necessário token)" -ForegroundColor Yellow
        }
        $TagCount++
    }

    $currentHash = git -C $dest rev-parse HEAD
    Write-Host "  OK: $repo em $($currentHash.Substring(0,8)) com tag $TagName" -ForegroundColor Green
}

Write-Step "[meta-repo] Atualizando meta-repositório..."

if (-not $DryRun) {
    $dirtyFiles = git -C $Root status --porcelain 2>$null
    if ($dirtyFiles) {
        try {
            git -C $Root add -A 2>$null
            git -C $Root commit -m "Release $TagName" 2>$null
            Write-Host "  Meta-repo commitado." -ForegroundColor Green
        } catch {
            Write-Host "    FALHA ao commitar meta-repo: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Meta-repo limpo, sem mudanças para commitar." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  [DRY-RUN] git add -A; git commit -m 'Release $TagName'" -ForegroundColor DarkYellow
}

$metaTag = git -C $Root tag -l $TagName 2>$null
if ($metaTag) {
    Write-Host "  Tag $TagName já existe no meta-repo. Pulando." -ForegroundColor DarkYellow
} else {
    if (-not (Invoke-Git -Dir $Root -GitArgs @("tag", "-a", $TagName, "-m", "Release $TagName (meta)"))) {
        $ErrorCount++
    } else {
        Write-Host "  Meta-repo taggeado: $TagName" -ForegroundColor Green
    }
}

if (-not $DryRun) {
    Write-Step "[push] Enviando meta-repo e tags..."
    try {
        git -C $Root push origin $Branch 2>$null
        git -C $Root push origin $TagName 2>$null
    } catch {
        Write-Host "    AVISO no push: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [DRY-RUN] git push origin $Branch" -ForegroundColor DarkYellow
    Write-Host "  [DRY-RUN] git push origin $TagName" -ForegroundColor DarkYellow
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Resumo:" -ForegroundColor Cyan
Write-Host "  Tags criadas/puladas: $TagCount" -ForegroundColor Cyan
Write-Host "  Erros                : $ErrorCount" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($ErrorCount -gt 0) {
    exit 1
}
