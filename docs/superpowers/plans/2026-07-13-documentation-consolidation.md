# Documentação Consolidada — MinusFrameWork v0.1.0

> **For agentic workers:** REQUIRED SUB-SKILL: Use dispatching-parallel-agents to implement tasks in parallel since they are independent.

**Goal:** Corrigir todas as inconsistências de documentação pós-release v0.1.0 e publicar no GitHub Pages.

**Architecture:** 4 agentes independentes (CLI+GettingStarted, Migrator+FeatureFlags, Pages+ROADMAP, Module READMEs) executando em paralelo, seguidos de build e deploy.

**Tech Stack:** Docusaurus 3.x, Markdown, TypeScript/React, Git

## Global Constraints
- Nomes de CLI: usar `MinusMigrator_CLI` (exe) e `mfc` (alias de comando)
- Tiers de licenciamento: Free (MIT), Pro (R$ 29/mês), Enterprise (R$ 69/mês)
- Pro e Enterprise estão disponíveis (remover "em breve")
- Plugin architecture `IMFPlugin` existe no CLI/Migrator v0.1.0
- Função `mmVersionCheck` existe na DLL do Migrator

---

### Grupo A: CLI + Getting Started

**Files:**
- Modify: `MinusFrameWork-Meta/docs/cli/index.md`
- Modify: `MinusFrameWork-Meta/docs/cli/commands.md`
- Modify: `MinusFrameWork-Meta/docs/cli/make-entity.md`
- Modify: `MinusFrameWork-Meta/docs/cli/new-api.md`
- Modify: `MinusFrameWork-Meta/docs/getting-started.md`

**What to change:**
- `minus.exe` → `MinusMigrator_CLI.exe` (e `mfc` como alias)
- `MinusCLI.dproj` → `MinusMigrator_CLI.dproj`
- Adicionar seção de plugin architecture (`IMFPlugin`)
- Em `getting-started.md`: corrigir referências de `MinusMigrator.exe` para `MinusMigrator_CLI.exe` e `minus` para `mfc`

### Grupo B: Migrator DLL + FeatureFlags + Modules

**Files:**
- Modify: `MinusFrameWork-Meta/docs/migrator/dll.md`
- Modify: `MinusFrameWork-Meta/docs/modules/FeatureFlags/index.md`
- Create: `MinusFrameWork-Meta/docs/modules/FeatureFlags/*` (se necessário)
- Modify: `MinusFrameWork-Meta/docs/modules/FeatureFlags/CHANGELOG.md`

**What to change:**
- Adicionar `mmVersionCheck` à tabela de funções exportadas na DLL docs
- FeatureFlags index.md: substituir placeholder por documentação real
- FeatureFlags CHANGELOG.md: corrigir encoding do título (caractere special)

### Grupo C: Pages + ROADMAP + Pricing

**Files:**
- Modify: `MinusFrameWork-Meta/docs/about.md`
- Modify: `MinusFrameWork-Meta/docs/licensing.md`
- Modify: `MinusFrameWork-Meta/ROADMAP.md`
- Modify: `MinusFrameWork-Meta/src/pages/pricing.tsx`

**What to change:**
- Remover "em breve" de Pro e Enterprise em `about.md`, `licensing.md`
- Em `pricing.tsx`: remover "(em breve)" das seções finais
- `ROADMAP.md`: atualizar comandos CLI (`new-project` → `make:entity`/`new api`), atualizar status MinusAI

### Grupo D: Module READMEs

**Files:**
- Modify: `minusframework-core/README.md`
- Modify: `minusframework-cli/README.md`
- Modify: `minusframework-ai/README.md` (se necessário)
- Modify: `MinusFrameWork-Meta/RELEASE_NOTES.md`

**What to change:**
- `core/README.md`: alinhar precificação com o meta-repo (R$ 29/mês Pro, R$ 69/mês Enterprise)
- `cli/README.md`: alinhar tiers Free/Pro/Enterprise com o modelo oficial
- `RELEASE_NOTES.md`: limpar seção inferior bagunçada, manter apenas v0.1.0 formatada
- `ai/README.md`: verificar se precisa de atualização

### Verificação Final

**Files:**
- Run: `MinusFrameWork-Meta/npm run build` no meta-repo

**What to verify:**
- Build Docusaurus sem broken links
- Verificar se as mudanças estão consistentes
