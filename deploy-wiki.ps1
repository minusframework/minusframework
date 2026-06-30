param([string]$Token)

$ErrorActionPreference = "Stop"
$WikiUrl = "https://github.com/GabrielFerreiraMendes/minusframework-meta.wiki"

Write-Host "MinusFrameWork - Wiki Deploy" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Verificando se o wiki existe..." -ForegroundColor Gray
$wikiExists = git -c credential.helper=manager ls-remote "https://github.com/GabrielFerreiraMendes/minusframework-meta.wiki.git" 2>$null
if (-not $wikiExists) {
    Write-Host "2. Acesse no navegador para criar o wiki:" -ForegroundColor Yellow
    Write-Host "   $WikiUrl" -ForegroundColor White
    Write-Host "   (Clique em 'Create the first page')"
    Write-Host ""
    Write-Host "3. Depois execute novamente: .\deploy-wiki.ps1 -Token `"seu_pat`"" -ForegroundColor Yellow
    if (-not $Token) { exit 1 }
}

$WikiPages = @{
    "Home"             = "# Welcome to the MinusFrameWork Wiki`n`nMinusFrameWork is a modern Delphi framework for building enterprise applications.`n`n## Modules`n`n- **[Core](Core)** - Base framework (attributes, config, connection pool, exceptions)`n- **[ORM](ORM)** - Object-Relational Mapping with FireDAC`n- **[Migrator](Migrator)** - Database migration management`n- **[Messaging](Messaging)** - Async messaging and event bus`n- **[Telemetry](Telemetry)** - Application monitoring and metrics`n- **[FeatureFlags](FeatureFlags)** - Feature flag management`n- **[Extensions](Extensions)** - Additional utilities and helpers`n- **[AI](AI)** - MCP Server for AI-assisted development`n- **[CLI](CLI)** - Command-line scaffolding tool`n`n## Quick Links`n`n- [Getting Started](Getting-Started)`n- [Architecture Overview](Architecture)`n- [Contributing](Contributing)`n- [License](https://github.com/GabrielFerreiraMendes/minusframework-meta/blob/main/LICENSE)"
    "_Sidebar"         = "- [Home](Home)`n- [Getting Started](Getting-Started)`n- **Modules**`n  - [Core](Core)`n  - [ORM](ORM)`n  - [Migrator](Migrator)`n  - [Messaging](Messaging)`n  - [Telemetry](Telemetry)`n  - [FeatureFlags](FeatureFlags)`n  - [Extensions](Extensions)`n  - [AI](AI)`n  - [CLI](CLI)`n- [Architecture](Architecture)`n- [Contributing](Contributing)"
    "_Footer"          = "**MinusFrameWork** - [Repository](https://github.com/GabrielFerreiraMendes/minusframework-meta)"
    "Getting-Started"  = "# Getting Started`n`n## Prerequisites`n`n- Delphi 11 or later`n- FireDAC (included with Delphi)`n- Git with LFS support`n`n## Installation`n`nClone the meta-repository and initialize all submodules:`n`n````powershell`ngit clone https://github.com/GabrielFerreiraMendes/minusframework-meta.git`ncd minusframework-meta`ngit submodule update --init --recursive`n````"
    "Core"             = "# Core Module`n`nBase framework providing foundational components: MF.Attributes, MF.Config, MF.Connection, MF.ConnectionPool, MF.Exceptions, MF.Provider, MF.Mapper, MF.MetadataCache, MF.QueryBuilder, MF.RepositoryBase, MF.SelectBuilder, MF.UnitOfWork, MF.CommandExecutor."
    "ORM"              = "# ORM Module`n`nObject-Relational Mapping with FireDAC. Features attribute-based mapping, generic repository, CRUD operations, automatic SQL generation."
    "Migrator"         = "# Migrator Module`n`nDatabase migration management with versioned migrations, rollback support, CLI interface."
    "Messaging"        = "# Messaging Module`n`nAsync messaging and event bus for Delphi applications with pub/sub, multiple transport backends."
    "Telemetry"        = "# Telemetry Module`n`nApplication monitoring and metrics collection: performance metrics, error tracking, custom metrics."
    "FeatureFlags"     = "# FeatureFlags Module`n`nFeature flag management for toggling functionality. Supports boolean/percentage flags, multi-provider, audit logging, license tiers (Free/Pro/Enterprise)."
    "Extensions"       = "# Extensions Module`n`nAdditional utilities and helpers: extended data types, helper functions, utility classes."
    "AI"               = "# AI Module`n`nMCP Server for AI-assisted development with FireDAC database integration. Tools: executar_consulta, gerar_entidade, listar_tabelas, explicar_codigo, criar_migracao."
    "CLI"              = "# CLI Module`n`nCommand-line scaffolding tool. Commands: make:entity, new:api, new:module."
    "Architecture"     = "# Architecture Overview`n`nMeta-repository with 9 submodules: Core, ORM, Migrator, Messaging, Telemetry, FeatureFlags, Extensions, AI, CLI."
    "Contributing"     = "# Contributing`n`nClone with submodules, follow Conventional Commits (feat:, fix:, docs:, refactor:, test:, chore:), submit PRs from feature branches."
}

$tmpBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
$tmpDir = Join-Path $tmpBase "minusframework-wiki-deploy"
if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

Push-Location $tmpDir
git init 2>$null | Out-Null

foreach ($page in $WikiPages.Keys) {
    Set-Content -Path "$page.md" -Value $WikiPages[$page] -NoNewline
}

git add -A 2>$null
git commit --allow-empty -m "docs: initial wiki setup" 2>$null | Out-Null

git branch -M main 2>$null | Out-Null

$repoUrl = "https://GabrielFerreiraMendes:${Token}@github.com/GabrielFerreiraMendes/minusframework-meta.wiki.git"
git remote add origin $repoUrl 2>$null
git push -u origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nWiki deployed successfully!" -ForegroundColor Green
    Write-Host "Acesse: $WikiUrl" -ForegroundColor Cyan
} else {
    Write-Host "`nFalha ao fazer push." -ForegroundColor Red
    Write-Host "Verifique se o wiki foi criado em: $WikiUrl" -ForegroundColor Yellow
}

Pop-Location
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue