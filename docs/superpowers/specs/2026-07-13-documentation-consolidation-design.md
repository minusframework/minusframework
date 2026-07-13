# Design: Documentação Consolidada — MinusFrameWork v0.1.0

## Objetivo
Corrigir inconsistências na documentação de todos os 9 módulos + meta-repo após as releases v0.1.0, refletindo as mudanças nos commits recentes, e publicar via Docusaurus no GitHub Pages.

## Inconsistências Identificadas

1. **CLI Docs** — `minus.exe` renomeado para `MinusMigrator_CLI`; plugin architecture `IMFPlugin` não documentada
2. **Getting Started** — Referências a `MinusMigrator.exe`, `minus.exe` obsoletas
3. **Migrator DLL** — Função `mmVersionCheck` não documentada
4. **FeatureFlags** — `docs/modules/FeatureFlags/index.md` é placeholder vazio
5. **Modules dirs** — AI/, Core/, Extensions/, Messaging/, Migrator/, ORM/, Telemetry/ vazios
6. **Licensing** — `about.md`, `licensing.md`, `pricing.tsx` dizem "em breve" para tiers pagos (contradiz pricing real)
7. **ROADMAP** — Comandos CLI desatualizados; MinusAI status não reflete progresso
8. **Module READMEs** — `core/README.md` e `cli/README.md` têm precificação divergente do meta-repo

## Plano de Ação

### Grupo A — CLI + Getting Started
- Renomear `minus.exe` → `MinusMigrator_CLI` / `mfc` em todos os docs de CLI
- Adicionar seção sobre plugin architecture (`IMFPlugin`)
- Atualizar comandos `make:entity` e `new api` com nomes corretos
- Corrigir `getting-started.md` para usar `mfc`

### Grupo B — Migrator + FeatureFlags + Modules
- Adicionar `mmVersionCheck` à documentação da DLL
- Criar conteúdo real para FeatureFlags
- Preencher diretórios modules/ com content redirect ou stubs de documentação referenciando os READMEs dos módulos

### Grupo C — Pages + ROADMAP
- Remover "em breve" de Pro/Enterprise em `about.md`, `licensing.md`, `pricing.tsx`
- Atualizar `ROADMAP.md` com status real de CLI e MinusAI

### Grupo D — READMEs dos módulos
- Alinhar `core/README.md` pricing tiers com o meta-repo (R$ 29/mês Pro, R$ 69/mês Enterprise)
- Alinhar `cli/README.md` tiers com o modelo oficial Free/Pro/Enterprise

## Entrega
- Build Docusaurus via `npm run build`
- Publicação no GitHub Pages via CI/CD
