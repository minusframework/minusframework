---
title: "Sobre o MinusFrameWork"
---

# Sobre o MinusFrameWork

## Missão

> Fornecer um ecossistema coeso de bibliotecas Delphi que acelerem o desenvolvimento de aplicações corporativas — sem sacrificar performance, testabilidade ou boas práticas de engenharia de software.

## História

O MinusFrameWork nasceu da necessidade de um framework Delphi **moderno, modular e bem testado** que pudesse competir com ecossistemas como Spring Boot (Java), NestJS (Node) e Entity Framework (.NET).

Diferente de frameworks monolíticos, o MinusFrameWork é dividido em **módulos independentes** — cada um versionado e publicado separadamente — permitindo que equipes adotem apenas o que precisam.

## Arquitetura

O framework segue princípios de:

- **Clean Architecture** — separação clara entre domínio, infraestrutura e apresentação
- **SOLID** — interfaces segregadas, inversão de dependência, responsabilidade única
- **Object Calisthenics** — métodos curtos, baixa complexidade ciclomática

## Repositórios

| Módulo | Repositório | Descrição |
|--------|-------------|-----------|
| **Meta** (docs, CI/CD) | [minusframework](https://github.com/GabrielFerreiraMendes/minusframework) | Orquestração, instalador e documentação |
| **Core** | [minusframework-core](https://github.com/GabrielFerreiraMendes/minusframework-core) | Núcleo compartilhado (conexão, atributos, tipos) |
| **ORM** | [minusframework-orm](https://github.com/GabrielFerreiraMendes/minusframework-orm) | Repositório genérico, queries, mapeamento |
| **Migrator** | [minusframework-migrator](https://github.com/GabrielFerreiraMendes/minusframework-migrator) | Migração versionada de schema |
| **Messaging** | [minusframework-messaging](https://github.com/GabrielFerreiraMendes/minusframework-messaging) | Message bus, sagas, outbox |
| **Feature Flags** | [minusframework-featureflags](https://github.com/GabrielFerreiraMendes/minusframework-featureflags) | Feature toggles, SSE, REST API |
| **Extensions** | [minusframework-extensions](https://github.com/GabrielFerreiraMendes/minusframework-extensions) | Integrações Horse, JWT |
| **Telemetry** | [minusframework-telemetry](https://github.com/GabrielFerreiraMendes/minusframework-telemetry) | Tracing e logging estruturado |
| **AI** | [minusframework-ai](https://github.com/GabrielFerreiraMendes/minusframework-ai) | MCP Server e agentes inteligentes |
| **CLI** | [minusframework-cli](https://github.com/GabrielFerreiraMendes/minusframework-cli) | CLI de scaffolding |

## Autores

Desenvolvido por **Gabriel Ferreira Mendes** e contribuidores da comunidade.

## Licença

O MinusFrameWork é distribuído em três tiers:

- **Free** (MIT) — ORM SQLite, Migrator, CLI
- **Pro** (Comercial) — Multi-banco, Messaging, Feature Flags, Extensions. Licença perpétua + 12 meses de suporte e atualizações.
- **Enterprise** (Comercial) — Pro + Telemetria, AI, suporte prioritário. Licença perpétua + 12 meses de suporte e atualizações.

Consulte [Licenciamento](licensing.md) e [Planos](/pricing) para detalhes.
