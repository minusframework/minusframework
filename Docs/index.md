# MinusFrameWork

**ORM completo, message bus, telemetria, feature flags e migrador de banco de dados para Delphi.**

---

## Projetos

| Projeto | Tipo | Descrição |
|---------|------|-----------|
| [MinusFramework_Runtime](02-ORM/README.md) | Package (`.dpk`) | Núcleo do ORM, foundation libraries, extensions |
| [MinusFramework_Design](08-DesignPackage/README.md) | Package (`.dpk`) | Expert e registro de componentes na IDE |
| [MinusTelemetry_Runtime](05-Telemetry/README.md) | Package (`.dpk`) | Tracing, logging e métricas (OpenTelemetry-style) |
| [MinusMessaging_Runtime](06-Messaging/README.md) | Package (`.dpk`) | Message bus, providers, sagas, circuit breaker |
| [MinusORM](09-StandaloneDLLs/README.md) | DLL | ORM exportado como C-accessible DLL |
| [MinusMigrator](04-Migrator/README.md) | DLL + CLI + GUI | Migração de schema de banco de dados |
| [MinusFeatureFlags](07-FeatureFlags/README.md) | EXE + API | Sistema de feature flags com REST API |

## Dependência entre pacotes

```
MinusTelemetry_Runtime
  +-- MinusMessaging_Runtime
  +-- MinusFramework_Runtime
        +-- MinusFramework_Design
        +-- MinusORM.dll
        +-- MinusMigrator (DLL + CLI + GUI)
```

## Primeiros passos

- [Comece por aqui](guias/quickstart.md)
- [Configuração](guias/configuration.md)
- [Exemplo básico de CRUD](exemplos/basic-crud.md)

## Arquitetura

O framework é dividido em camadas:

| Camada | Descrição |
|--------|-----------|
| **Foundation** (`Source\Bibliotecas`) | Tipos, conexão, provedores, pool, exceções |
| **ORM Core** (`Source\Core`) | Mapeamento, repositórios, criteria, Unit of Work |
| **Extensions** (`Source\Extensions`) | JSON, Horse, soft delete, multitenancy, audit |
| **Telemetry** (`Source\Telemetry`) | Tracing distribuído, logging estruturado |
| **Messaging** (`Source\Messaging`) | Message bus, filas, padrões de resiliência |
| **FeatureFlags** (`Source\FeatureFlags`) | Feature flags, rollout, A/B testing |
| **Migrator** (`Source\Migrator`) | Migração de schema, changelog, scaffolding |
