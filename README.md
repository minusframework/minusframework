<p align="center">
  <img src="static/img/logo.svg" alt="MinusFrameWork Logo" width="160" />
</p>

<h1 align="center">MinusFrameWork</h1>

<p align="center">
  Framework Delphi moderno, modular e corporativo — ORM, Migrator, Mensageria, Feature Flags, Telemetria e IA
</p>

<p align="center">
  <a href="https://github.com/GabrielFerreiraMendes/minusframework/actions/workflows/ci.yml"><img src="https://github.com/GabrielFerreiraMendes/minusframework/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://gabrielferreiramendes.github.io/minusframework/"><img src="https://img.shields.io/badge/docs-online-blue" alt="Docs" /></a>
  <a href="https://github.com/GabrielFerreiraMendes/minusframework/blob/main/LICENSE"><img src="https://img.shields.io/badge/licen%C3%A7a-MIT%20%7C%20Pro%20%7C%20Enterprise-blue" alt="License" /></a>
</p>

---

## Sobre

**MinusFrameWork** é um framework Delphi focado em produtividade corporativa, seguindo princípios de Clean Architecture, SOLID e Object Calisthenics. Oferece uma suíte modular de componentes que vão do ORM à inteligência artificial, com licenciamento flexível (Free/Pro/Enterprise).

Este repositório é o **meta-repositório oficial**, contendo a documentação, site, CI/CD, instalador, scripts de automação e arquivos de licenciamento.

## Documentação

A documentação completa está disponível em:

- 🌐 **Site publicado**: [gabrielferreiramendes.github.io/minusframework](https://gabrielferreiramendes.github.io/minusframework/)
- 📖 **Docs locais**: `./docs/` (formato Docusaurus)

### Desenvolvimento local

```bash
npm ci
npm start
```

Acesse `http://localhost:3000/minusframework/`. Para build de produção:

```bash
npm run build
npx docusaurus serve
```

## Módulos

| Módulo | Categoria | Licença | Descrição |
|--------|-----------|---------|-----------|
| MinusORM | ORM | Free | ORM com RTTI, queries fluentes, Unit of Work e Change Tracking |
| MinusMigrator | Migrator | Free | Migração versionada de schema via CLI, GUI e DLL |
| MinusCLI | CLI | Free | Scaffolding de entidades, APIs e projetos |
| MinusFeatureFlags | Feature Flags | Pro | Feature flags com rollout percentual, A/B testing, SSE e REST API |
| MinusMessaging | Mensageria | Pro | Message bus multi-provider com retry, circuit breaker, sagas e outbox |
| MinusExtensions | Extensões | Pro | Integrações prontas para Horse, JWT e bibliotecas de terceiros |
| MinusTelemetry | Telemetria | Enterprise | Tracing e logging estruturado no padrão OpenTelemetry |
| MinusAI | Inteligência Artificial | Enterprise | Agentes inteligentes e servidor MCP para Delphi |

## Estrutura do repositório

```
MinusFrameWork-Meta/
├── docs/              # Documentação (Docusaurus)
├── src/               # Código-fonte do site (React)
├── i18n/              # Traduções (pt-BR, en)
├── static/            # Assets estáticos (imagens, 404, robots)
├── .github/workflows/ # CI/CD (docs, wiki, release)
├── site/              # Site do instalador
├── AI/                # Módulo de IA
├── Cli/               # Módulo CLI
├── Core/              # Núcleo do framework
├── FeatureFlags/      # Módulo de feature flags
├── Messaging/         # Módulo de mensageria
├── Migrator/          # Módulo de migração
├── ORM/               # Módulo ORM
├── Telemetry/         # Módulo de telemetria
├── Extensions/        # Extensões para terceiros
├── Installer/         # Instalador Inno Setup
├── license-server/    # Servidor de licenciamento
├── .superpowers/      # Planos e specs de design
└── scripts *.ps1      # Scripts de automação (release, CI, wiki)
```

## Planos e licenciamento

| Plano | Acesso | Preço |
|-------|--------|-------|
| **Free** | ORM, Migrator, CLI | MIT — gratuito |
| **Pro** | + Feature Flags, Messaging, Extensions | R$ 29/mês ou R$ 197/ano |
| **Enterprise** | + Telemetria, AI | R$ 69/mês ou R$ 497/ano |

🔒 **Licenciamento**: Consulte [LICENSE](./LICENSE) e [LICENSE-SERVER.md](./LICENSE-SERVER.md) para detalhes completos.

## CI/CD

O pipeline automatiza:

- **Build**: documentação Docusaurus (pt-BR + en)
- **Preview**: deploy em subdiretório para revisão em pull requests
- **Wiki**: sincronização automática do wiki do repositório
- **Release**: versionamento e sincronização entre submódulos

## Desenvolvimento

### Pré-requisitos

- Node.js >= 20
- Delphi (para os módulos do framework)
- Git LFS (para assets grandes)

### Scripts disponíveis

| Comando | Descrição |
|---------|-----------|
| `npm start` | Inicia servidor de desenvolvimento Docusaurus |
| `npm run build` | Build de produção do site |
| `npm run serve` | Serve o build localmente |
| `./release.ps1` | Script de release automatizada |
| `./ci-setup.ps1` | Configuração de CI local |
| `./deploy-wiki.ps1` | Deploy do wiki para GitHub |

## Contribuição

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Commit suas mudanças: `git commit -m "feat: descrição concisa"`
4. Push: `git push origin feature/minha-feature`
5. Abra um Pull Request

Veja o [guia de contribuição](https://gabrielferreiramendes.github.io/minusframework/docs/getting-started) para mais detalhes.

---

<p align="center">
  <sub>© 2026 Gabriel Ferreira Mendes. Free modules sob licença MIT. Módulos Pro e Enterprise sob licença comercial.</sub>
</p>
