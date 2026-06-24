# MinusFrameWork

**ORM completo, message bus, telemetria, feature flags e migrador de banco de dados para Delphi.**

---

## Módulos

| Módulo | Repositório | Descrição |
|--------|-------------|-----------|
| **Core** | `minusframework-core` | Foundation libraries, ORM Core, Extensions, Design packages |
| **ORM** | `minusframework-orm` | DLL standalone do ORM com API C-compatible |
| **Telemetry** | `minusframework-telemetry` | Tracing, logging e métricas (OpenTelemetry-style) |
| **Messaging** | `minusframework-messaging` | Message bus, providers, sagas, circuit breaker |
| **Migrator** | `minusframework-migrator` | Migração de schema de banco de dados |
| **FeatureFlags** | `minusframework-featureflags` | Sistema de feature flags com REST API |
| **Extensions** | `minusframework-extensions` | Wrappers para Horse, JWT e bibliotecas de terceiros |

## Primeiros passos

- [Comece por aqui — Core](Core/Docs/guias/quickstart.md)
- [Configuração](Core/Docs/guias/configuration.md)
- [Exemplo básico de CRUD](Core/Docs/exemplos/basic-crud.md)

## Licenciamento

- [MIT](LICENSE) para Community Edition
- [Comercial / Enterprise](Core/Docs/LICENSE-ENTERPRISE.md)

## Repositório Meta

Este repositório contém todos os módulos como submodules, além do instalador (`Installer/`) e documentação comum.
