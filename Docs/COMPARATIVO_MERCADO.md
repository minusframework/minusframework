# Comparativo de Mercado — MinusFramework

> Análise detalhada de cada solução do pacote MinusFramework frente às alternativas disponíveis no mercado.

---

## Sumário

1. [MinusORM](#1-minusorm)
2. [MinusMigrator](#2-minusmigrator)
3. [MinusFeatureFlags](#3-minusfeatureflags)
4. [MinusRest](#4-minusrest)
5. [MinusExtensions](#5-minusextensions)
6. [Tabela Resumo](#6-tabela-resumo)

---

## 1. MinusORM

### Concorrentes Diretos

| Característica | MinusORM | TMS Aurelius | EntityDAC | DORM | mORMot |
|---|---|---|---|---|---|
| **Licença** | MIT (Community) / Comercial | Comercial (~$195/dev) | Comercial (~$199/dev) | LGPL (abandonado) | GPL / Comercial |
| **Preço (1 dev)** | Grátis (Community) / R$199 (Pro) | ~$195 | ~$199 | Grátis | Grátis (GPL) |
| **Código aberto** | ✅ Sim | ❌ Não | ❌ Não | ✅ Sim | ✅ Sim |
| **Multi-banco** | 7 bancos (SQLite, FB, PG, MySQL, MariaDB, MSSQL, Oracle) | 5 bancos | 7 bancos | 2 bancos (FB, SQLite) | Multi (via SQLite3, Jet, etc.) |
| **Mapeamento RTTI** | Atributos `[Tabela]`, `[Coluna]`, `[ChavePrimaria]` | Atributos | Atributos | Atributos | Código ou RTTI |
| **Fluent Query Builder** | ✅ `TConstrutorSelecao<T>` + Criteria API | ✅ LINQ-like | ✅ LINQ-like | ❌ Parcial | ❌ SQL direto |
| **Unit of Work** | ✅ `TUnidadeTrabalho` com change tracking | ✅ | ✅ | ❌ | ❌ |
| **Change Tracking** | ✅ Snapshot + dirty detection | ✅ | ❌ | ❌ | ❌ |
| **Identity Map** | ✅ Cache 1º nível | ✅ | ✅ | ❌ | ❌ |
| **Cache 2º nível** | ✅ TTL + regiões | ❌ | ❌ | ❌ | ❌ |
| **Soft Delete** | ✅ `[SoftDelete]` | ✅ | ❌ | ❌ | ❌ |
| **Unique Key** | ✅ `[ChaveUnica]` | ❌ | ❌ | ❌ | ❌ |
| **Bulk Operations** | ✅ Insert/Update/Delete em lote | ❌ | ❌ | ❌ | ❌ |
| **Shadow Properties** | ✅ `[CriadoEm]`, `[AtualizadoEm]` | ❌ | ❌ | ❌ | ❌ |
| **Auditoria** | ✅ `[CriadoPor]`, `[AtualizadoPor]` + audit trail | ❌ | ❌ | ❌ | ❌ |
| **Concorrência Otimista** | ✅ `[Versao]` | ✅ | ❌ | ❌ | ❌ |
| **Encryption** | ✅ `[Criptografado]` (XOR) | ❌ | ❌ | ❌ | ❌ |
| **Multi-tenancy** | ✅ `[Inquilino]` com filtro automático | ❌ | ❌ | ❌ | ❌ |
| **Navigation Properties** | ✅ `[Relacionamento]` + lazy loading | ✅ | ✅ | ❌ | ❌ |
| **Views / Stored Procs** | ✅ `[View]`, `[StoredProc]` | ✅ | ✅ | ❌ | ✅ |
| **Health Check** | ✅ `THealthCheck` built-in | ❌ | ❌ | ❌ | ❌ |
| **Retry / Circuit Breaker** | ✅ `TRetryPolicy` | ❌ | ❌ | ❌ | ❌ |
| **SQL Profiler** | ✅ Log + relatório Markdown | ❌ | ❌ | ❌ | ❌ |
| **Database Seeding** | ✅ `TSeeder` com fixtures JSON | ❌ | ❌ | ❌ | ❌ |
| **Scaffold** | ✅ Geração de entidades do BD | ✅ | ✅ | ❌ | ❌ |
| **Paginação** | ✅ `TPaginacao` + `TResultadoPaginado<T>` | ❌ | ❌ | ❌ | ❌ |
| **Suporte a Brasil/PT-BR** | ✅ Documentação PT-BR, desenvolvedor brasileiro | ❌ (Inglês) | ❌ (Inglês) | ❌ (Inglês) | ❌ (Inglês) |
| **Suporte Community** | GitHub Issues/Discussions | Fórum | Fórum | N/A | GitHub |
| **Suporte Enterprise** | Email 8h SLA + WhatsApp | Email 48h | Email 48h | N/A | Comercial |

### Quando escolher cada um

| Cenário | Recomendação |
|---|---|
| Projeto pessoal / acadêmico / startup sem orçamento | **MinusORM Community** (grátis, MIT) |
| Empresa brasileira que precisa de suporte em PT-BR | **MinusORM** (documentação e suporte em português) |
| Precisa de Oracle + SLA + garantia jurídica | **MinusORM Enterprise** (R$199/dev/ano) |
| Precisa de .NET Framework (WinForms, WPF) | **TMS Aurelius** (ecossistema .NET da TMS) |
| Precisa de suporte oficial da Embarcadero | **EntityDAC** (mesma empresa do FireDAC) |
| Quer código aberto e não se importa com faltas de features | **DORM** (abandonado, mas funcional) |
| Performance máxima em servidor Linux sem Windows | **mORMot** (não usa FireDAC, SQL direto) |

---

## 2. MinusMigrator

### Concorrentes Diretos

| Característica | MinusMigrator | Flyway | Liquibase | DBMigration (Delphi) | Alembic |
|---|---|---|---|---|---|
| **Licença** | MIT (Community) / Comercial | Open Source + Edições Pagas | Open Source + Edições Pagas | Comercial | Apache 2.0 |
| **Preço** | Grátis (CLI) / R$149 (Pro) | Grátis (Community) / $1k+ (Enterprise) | Grátis (Community) / $999+ (Pro) | ~$99 | Grátis |
| **Linguagem nativa** | **Delphi** (nativo) | Java | Java | Delphi | Python |
| **CLI** | ✅ `MinusMigrator_CLI.exe` | ✅ CLI | ✅ CLI | ❌ | ✅ CLI |
| **DLL para consumo externo** | ✅ stdcall exports | ❌ | ❌ | ❌ | ❌ |
| **GUI** | ✅ `MinusMigrator_GUI.exe` | ❌ (só CLI) | ❌ (só CLI) | ❌ | ❌ |
| **Multi-banco** | 7 bancos (SQLite, FB, PG, MySQL, MariaDB, MSSQL, Oracle) | 15+ (via JDBC) | 15+ (via JDBC) | 3 bancos | Via SQLAlchemy |
| **Versionamento** | ✅ Migrations numeradas + tags + contexto | ✅ | ✅ | ✅ | ✅ |
| **Auto-migrate** | ✅ Gera migrations das entidades | ❌ | ❌ | ❌ | ✅ (autogenerate) |
| **Diff changelog** | ✅ Compara schema atual vs entidades | ❌ | ✅ (diff) | ❌ | ❌ |
| **Dry-run** | ✅ `--dry-run` | ✅ | ✅ | ❌ | ✅ |
| **Rollback** | ✅ `rollback -n N` ou `--tag` | ✅ | ✅ | ❌ | ✅ |
| **Generate models** | ✅ Gera classes Delphi do BD | ❌ | ❌ | ❌ | ❌ |
| **Status** | ✅ `status --format json\|yaml` | ✅ | ✅ | ❌ | ✅ |
| **Tagging** | ✅ `tag "nome"` em migrations | ✅ | ✅ | ❌ | ❌ |
| **Context isolation** | ✅ `--context ctx` (múltiplos tenants) | ❌ | ❌ | ❌ | ❌ |
| **Schema Readers** | ✅ Individual por banco | ❌ | ❌ | ❌ | ❌ |
| **SQL Generators** | ✅ SQL por provider | ❌ | ❌ | ❌ | ❌ |
| **Zero dependência externa** | ✅ Só precisa do FireDAC | ❌ (JDBC) | ❌ (JDBC) | ✅ | ❌ (Python) |
| **Suporte PT-BR** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **IDE nativa Delphi** | ✅ Packages BPL, integração RAD Studio | ❌ | ❌ | ❌ | ❌ |

### Quando escolher cada um

| Cenário | Recomendação |
|---|---|
| Projeto Delphi que precisa de migração versionada | **MinusMigrator** (nativo, zero setup) |
| Precisa embarcar migrator em DLL para outra linguagem | **MinusMigrator** (único com exports stdcall) |
| Equipe multi-linguagem (Java, .NET, Node) | **Flyway** ou **Liquibase** |
| Projeto puramente Python | **Alembic** |
| Precisa de integração com RAD Studio IDE | **MinusMigrator** (única opção nativa) |
| Orçamento zero | **MinusMigrator Community** (CLI grátis) |

---

## 3. MinusFeatureFlags

### Concorrentes Diretos

| Característica | MinusFeatureFlags | LaunchDarkly | Unleash | Flagsmith | ConfigCat |
|---|---|---|---|---|---|
| **Licença** | MIT (Community) / Comercial | SaaS proprietário | BSL 1.1 / SaaS | BSD 3-Clause / SaaS | SaaS proprietário |
| **Preço** | Grátis (Core) / R$149 (Pro/dev) | $200/mês+ (10 seats) | Grátis (self-host) / $80/mês+ | Grátis (self-host) / $99/mês+ | Grátis (10 flags) / $5.99/mês+ |
| **Modelo** | **On-premise** (embarcado) | SaaS | SaaS / Self-host | SaaS / Self-host | SaaS |
| **SDK Delphi nativo** | ✅ `TFeatureFlags` | ❌ | ❌ (REST genérico) | ❌ (REST genérico) | ❌ (REST genérico) |
| **Providers** | Memória, JSON, Database, REST | API própria | API própria | API própria | API própria |
| **Targeting** | 6 tipos (global, %, usuário, grupo, atributo, agendado) | ✅ | ✅ | ✅ | ✅ |
| **A/B Testing** | ✅ Hash global + segmentado por regra | ✅ | ✅ | ✅ | ❌ |
| **Prerequisite flags** | ✅ `DependeDe` | ✅ | ✅ | ❌ | ❌ |
| **Multi-environment** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Audit log** | ✅ Tabela `feature_flag_audit` | ✅ | ✅ | ✅ | ✅ |
| **Métricas** | ✅ Buffer + persistência SQL | ✅ | ✅ | ✅ | ✅ |
| **Web Dashboard** | Em roadmap (Vue/Svelte) | ✅ | ✅ | ✅ | ✅ |
| **SDK Remoto** | Em roadmap | ✅ | ✅ | ✅ | ✅ |
| **Batch evaluation** | Em roadmap | ✅ | ✅ | ❌ | ❌ |
| **SSE Streaming** | Em roadmap | ✅ | ❌ | ❌ | ❌ |
| **RBAC** | Em roadmap | ✅ | ✅ | ✅ | ✅ |
| **Funciona offline/sem internet** | ✅ **Completo** (embarcado na app) | ❌ (requer SaaS) | ❌ (requer servidor) | ❌ (requer servidor) | ❌ (requer servidor) |
| **Zero latência de rede** | ✅ (avaliação local em ms) | ❌ (latência HTTP) | ❌ (latência HTTP) | ❌ (latência HTTP) | ❌ (latência HTTP) |
| **Integração com MinusORM** | ✅ Providers Database e Memória já conectados | ❌ | ❌ | ❌ | ❌ |

### Quando escolher cada um

| Cenário | Recomendação |
|---|---|
| Aplicação Delphi desktop sem internet | **MinusFeatureFlags** (única opção nativa offline) |
| Sistema crítico onde latência de rede é inaceitável | **MinusFeatureFlags** (avaliação local em microssegundos) |
| Empresa que já usa MinusORM | **MinusFeatureFlags** (integração nativa com ORM) |
| Precisa de dashboard web sofisticado HOJE | **LaunchDarkly** ou **Unleash** |
| Equipe multi-linguagem com feature flags centralizadas | **Unleash** ou **Flagsmith** |
| Orçamento zero, precisa de feature flags simples | **MinusFeatureFlags Community** (providers JSON/Memória) |

---

## 4. MinusRest

### Concorrentes Diretos

| Característica | MinusRest (Horse Extensions) | Horse (standalone) | Delphi MVC Framework | DataSnap | RAD Server |
|---|---|---|---|---|---|
| **Licença** | MIT (Community) | MIT | MIT | Comercial (Embarcadero) | Comercial (Embarcadero) |
| **Preço** | Grátis (Community) / R$99 (Pro) | Grátis | Grátis | Incluso no RAD Studio | $1.999+ |
| **Middleware JWT** | ✅ Horse JWT | ❌ (terceiros) | ✅ | ❌ | ❌ |
| **Middleware CORS** | ✅ Horse Cors | ❌ (terceiros) | ✅ | ❌ | ❌ |
| **Middleware Logger** | ✅ Lumberjack Logger | ❌ (terceiros) | ✅ | ❌ | ❌ |
| **JSON Serialization** | ✅ Jhonson (Horse JSON) | ❌ (terceiros) | ❌ | ❌ | ❌ |
| **Integração com MinusORM** | ✅ Providers nativos | ❌ | ❌ | ❌ | ❌ |
| **Feature Flags via REST** | ✅ MinusFeatureFlags API | ❌ | ❌ | ❌ | ❌ |
| **Multi-tenancy** | ✅ Filtro automático `tenant_id` | ❌ | ❌ | ❌ | ❌ |
| **Pacote completo** | ✅ ORM + REST + FF + Migrator | ❌ (só web) | ❌ (só web) | ❌ (só REST) | ❌ (só REST) |
| **Documentação PT-BR** | ✅ | ❌ | ❌ | ❌ | ❌ |

### Quando escolher cada um

| Cenário | Recomendação |
|---|---|
| API REST Delphi simples e rápida | **Horse** (leve, MIT, standalone) |
| API REST + ORM + Feature Flags + Migrator | **MinusRest completo** (ecossistema integrado) |
| Precisa de suporte oficial Embarcadero | **RAD Server** ou **DataSnap** |
| Precisa de multi-tier com chamadas remotas | **DataSnap** |

---

## 5. MinusExtensions

### Extensões vs Alternativas Isoladas

| Extensão | MinusFramework | Alternativa Isolada | Vantagem MF |
|---|---|---|---|
| **Soft Delete** | `[SoftDelete('coluna', tesBooleano)]` | Implementação manual | Declarativo, automático em todas as queries |
| **Cache 2º nível** | `[Cache(TTL, 'regiao')]` | Redis / Memcached | Zero dependência externa, TTL por região |
| **Unique Key** | `[ChaveUnica('grupo', ['COL1','COL2'])]` | Validação manual no SQL | Declarativo, composto, automático |
| **Bulk Operations** | `InserirEmLote`, `AtualizarEmLote`, `ExcluirEmLote` | FireDAC Array DML | API unificada, independente de banco |
| **Shadow Properties** | `[CriadoEm]`, `[AtualizadoEm]` | Triggers no banco | Sem trigger, sem permissão extra |
| **Audit Trail** | `[CriadoPor]`, `[AtualizadoPor]` + tabela `auditoria` | Triggers + tabela de log | Rastreia quem, quando, valores anteriores/novos |
| **Multi-tenancy** | `[Inquilino]` com filtro automático | Manual `WHERE tenant_id` | Declarativo, sem risco de esquecer o filtro |
| **Encryption** | `[Criptografado]` (XOR) | Criptografia manual na app | Transparente, desserializa automático |
| **Concorrência** | `[Versao]` com lock otimista | Manual `WHERE ... AND versao = :v` | Automático, exception tipada |
| **Health Check** | `THealthCheck` built-in | Implementação manual | Já integrado com ORM, métricas de latência |
| **Retry / Circuit Breaker** | `TRetryPolicy` com exponential backoff | Polly (.NET) / Implementação manual | Política configurável, integrada |
| **SQL Profiler** | Log + relatório Markdown | Ferramentas externas | Gera relatório formatado, integrado |
| **Seeding** | `TSeeder` com fixtures JSON | Scripts SQL manuais | Dados de teste tipados, reutilizáveis |
| **Paginação** | `TPaginacao` + `TResultadoPaginado<T>` | Manual `LIMIT/OFFSET` | API consistente, retorno padronizado |

---

## 6. MinusMessaging

> Sistema de mensageria assíncrona multi-provider com suporte a filas, pub/sub, retry, DLQ, outbox, sagas e circuit breaker.

### Concorrentes Diretos

| Característica | MinusMessaging | Redis (raw) | RabbitMQ (raw) | Kafka (raw) | MQTT (raw) |
|---|---|---|---|---|---|
| **Licença** | MIT (Community) / Comercial | BSD | MPL 2.0 | Apache 2.0 | MIT |
| **Preço** | Grátis (Community) / R$149 (Pro) | Grátis | Grátis | Grátis | Grátis |
| **SDK Delphi nativo** | ✅ Nativo | ✅ `delphiredis` | ✅ `RabbitMQ.Delphi` | ⚠ `librdkafka` binding | ✅ `TMQTTClient` |
| **Multi-provider** | ✅ Mesma API para todos | ❌ Só Redis | ❌ Só RabbitMQ | ❌ Só Kafka | ❌ Só MQTT |
| **Retry + Backoff** | ✅ Built-in (fixo, exp, jitter) | ❌ Manual | ❌ Manual | ❌ Manual | ❌ Manual |
| **DLQ automática** | ✅ `TGerenciadorDLQ` | ❌ ZSET manual | ✅ DLX nativa | ❌ Manual | ❌ Manual |
| **Outbox pattern** | ✅ Integração MinusORM | ❌ | ❌ | ❌ | ❌ |
| **Saga (coreografia)** | ✅ Fase 2 | ❌ | ❌ | ❌ | ❌ |
| **Saga (orquestração)** | ✅ Fase 2 | ❌ | ❌ | ❌ | ❌ |
| **Circuit Breaker** | ✅ `TCirtuitBreaker` integrado | ❌ | ❌ | ❌ | ❌ |
| **Idempotência** | ✅ Fase 1 | ❌ Manual | ❌ Manual | ❌ Manual | ❌ Manual |
| **Dashboard REST** | ✅ Fase 2 (Horse) | ❌ | ❌ RabbitMQ UI (Java) | ❌ Kafka UI (Java) | ❌ |
| **RPC síncrono** | ✅ Fase 2 (CorrelationId) | ❌ | ✅ | ❌ | ❌ |
| **Streaming SSE** | ✅ Fase 3 | ❌ | ❌ | ❌ | ❌ |
| **Tracer distribuído** | ✅ Fase 3 (W3C Trace Context) | ❌ | ❌ | ❌ | ❌ |
| **Documentação PT-BR** | ✅ | ❌ | ❌ | ❌ | ❌ |

### Quando escolher cada um

| Cenário | Recomendação |
|---|---|
| Mensageria simples em memória (testes/dev) | **MinusMessaging Community** (InMemory, grátis) |
| Precisa de Redis pub/sub + filas | **MinusMessaging Pro** (API unificada + Redis) |
| Precisa de RabbitMQ com DLQ nativa | **MinusMessaging Pro** (RabbitMQ + DLX) |
| Precisa de Kafka para eventos em larga escala | **MinusMessaging Pro** (Kafka + consumer groups) |
| Precisa de outbox pattern + ORM | **MinusORM + MinusMessaging** (integração nativa) |
| Precisa de dashboard REST + sagas | **MinusMessaging Pro** (Horse + Sagas) |
| Quer um único provider específico | Redis/RabbitMQ/Kafka puro (menos complexidade) |
| Equipe grande, precisa de tracing distribuído | **MinusMessaging Pro** (W3C Trace Context + OpenTelemetry) |

---

## 7. Tabela Resumo

### Preços no Mercado (por desenvolvedor, anual)

| Solução | MinusFramework Community | MinusFramework Pro | Concorrente Mais Barato | Concorrente Mais Caro |
|---|---|---|---|---|
| **ORM** | **Grátis** ✅ | R$199 | TMS Aurelius ~$195 | EntityDAC ~$199 |
| **Migrator** | **Grátis** ✅ (CLI) | R$149 | DBMigration ~$99 | Liquibase Pro $999+ |
| **Feature Flags** | **Grátis** ✅ (Core) | R$149 | Unleash Open Source (grátis) | LaunchDarkly $200/mês |
| **REST API** | **Grátis** ✅ | R$99 | Horse (grátis) | RAD Server $1.999 |
| **Messaging** | **Grátis** ✅ (Core + Memória) | R$149 | Redis (grátis, sem SDK Delphi) | Kafka (grátis, sem SDK Delphi) |
| **Suite Completa** | **Grátis** ✅ | **R$599** | N/A (nenhum concorrente oferece suite integrada) | N/A |

### Matriz de Decisão

| Perfil | Plano Recomendado | Custo |
|---|---|---|
| Estudante / hobby | **Community** | **Grátis** |
| Startup (1 dev, orçamento zero) | **Community** | **Grátis** |
| Freelancer (1 dev, precisa de Oracle) | **ORM Pro + Migrator Pro** | R$348/ano (~R$29/mês) |
| Empresa pequena (1 dev, tudo incluso) | **Complete Bundle (1 dev)** | R$499/ano (~R$42/mês) |
| Equipe (5 devs, tudo incluso) | **Enterprise Suite (time)** | R$1.999/ano (~R$167/mês) |
| Empresa grande (10+ devs, SLA urgente) | **Enterprise Suite** | R$1.999/ano |
| Precisa só de migração | **Migrator Community** | **Grátis** |
| Precisa só de feature flags | **FeatureFlags Community** | **Grátis** |
| Precisa de mensageria assíncrona | **Messaging Community** | **Grátis** |

---

> **Dúvidas sobre qual plano escolher?** Abra uma [issue](https://github.com/GabrielFerreiraMendes/MinusFramework/issues) ou envie email para `comercial@minusframework.com.br`.
>
> *Documento atualizado em Junho de 2026.*
