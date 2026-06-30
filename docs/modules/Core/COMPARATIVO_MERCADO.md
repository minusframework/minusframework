# Comparativo de Mercado â€” MinusFramework

> AnÃ¡lise detalhada de cada soluÃ§Ã£o do pacote MinusFramework frente Ã s alternativas disponÃ­veis no mercado.

---

## SumÃ¡rio

1. [MinusORM](#1-minusorm)
2. [MinusMigrator](#2-minusmigrator)
3. [MinusFeatureFlags](#3-minusfeatureflags)
4. [MinusRest](#4-minusrest)
5. [MinusExtensions](#5-minusextensions)
6. [Tabela Resumo](#6-tabela-resumo)

---

## 1. MinusORM

### Concorrentes Diretos

| CaracterÃ­stica | MinusORM | TMS Aurelius | EntityDAC | DORM | mORMot |
|---|---|---|---|---|---|
| **LicenÃ§a** | MIT (Community) / Comercial | Comercial (~$195/dev) | Comercial (~$199/dev) | LGPL (abandonado) | GPL / Comercial |
| **PreÃ§o (1 dev)** | GrÃ¡tis (Community) / R$199 (Pro) | ~$195 | ~$199 | GrÃ¡tis | GrÃ¡tis (GPL) |
| **CÃ³digo aberto** | âœ… Sim | âŒ NÃ£o | âŒ NÃ£o | âœ… Sim | âœ… Sim |
| **Multi-banco** | 7 bancos (SQLite, FB, PG, MySQL, MariaDB, MSSQL, Oracle) | 5 bancos | 7 bancos | 2 bancos (FB, SQLite) | Multi (via SQLite3, Jet, etc.) |
| **Mapeamento RTTI** | Atributos `[Tabela]`, `[Coluna]`, `[ChavePrimaria]` | Atributos | Atributos | Atributos | CÃ³digo ou RTTI |
| **Fluent Query Builder** | âœ… `TConstrutorSelecao<T>` + Criteria API | âœ… LINQ-like | âœ… LINQ-like | âŒ Parcial | âŒ SQL direto |
| **Unit of Work** | âœ… `TUnidadeTrabalho` com change tracking | âœ… | âœ… | âŒ | âŒ |
| **Change Tracking** | âœ… Snapshot + dirty detection | âœ… | âŒ | âŒ | âŒ |
| **Identity Map** | âœ… Cache 1Âº nÃ­vel | âœ… | âœ… | âŒ | âŒ |
| **Cache 2Âº nÃ­vel** | âœ… TTL + regiÃµes | âŒ | âŒ | âŒ | âŒ |
| **Soft Delete** | âœ… `[SoftDelete]` | âœ… | âŒ | âŒ | âŒ |
| **Unique Key** | âœ… `[ChaveUnica]` | âŒ | âŒ | âŒ | âŒ |
| **Bulk Operations** | âœ… Insert/Update/Delete em lote | âŒ | âŒ | âŒ | âŒ |
| **Shadow Properties** | âœ… `[CriadoEm]`, `[AtualizadoEm]` | âŒ | âŒ | âŒ | âŒ |
| **Auditoria** | âœ… `[CriadoPor]`, `[AtualizadoPor]` + audit trail | âŒ | âŒ | âŒ | âŒ |
| **ConcorrÃªncia Otimista** | âœ… `[Versao]` | âœ… | âŒ | âŒ | âŒ |
| **Encryption** | âœ… `[Criptografado]` (XOR) | âŒ | âŒ | âŒ | âŒ |
| **Multi-tenancy** | âœ… `[Inquilino]` com filtro automÃ¡tico | âŒ | âŒ | âŒ | âŒ |
| **Navigation Properties** | âœ… `[Relacionamento]` + lazy loading | âœ… | âœ… | âŒ | âŒ |
| **Views / Stored Procs** | âœ… `[View]`, `[StoredProc]` | âœ… | âœ… | âŒ | âœ… |
| **Health Check** | âœ… `THealthCheck` built-in | âŒ | âŒ | âŒ | âŒ |
| **Retry / Circuit Breaker** | âœ… `TRetryPolicy` | âŒ | âŒ | âŒ | âŒ |
| **SQL Profiler** | âœ… Log + relatÃ³rio Markdown | âŒ | âŒ | âŒ | âŒ |
| **Database Seeding** | âœ… `TSeeder` com fixtures JSON | âŒ | âŒ | âŒ | âŒ |
| **Scaffold** | âœ… GeraÃ§Ã£o de entidades do BD | âœ… | âœ… | âŒ | âŒ |
| **PaginaÃ§Ã£o** | âœ… `TPaginacao` + `TResultadoPaginado<T>` | âŒ | âŒ | âŒ | âŒ |
| **Suporte a Brasil/PT-BR** | âœ… DocumentaÃ§Ã£o PT-BR, desenvolvedor brasileiro | âŒ (InglÃªs) | âŒ (InglÃªs) | âŒ (InglÃªs) | âŒ (InglÃªs) |
| **Suporte Community** | GitHub Issues/Discussions | FÃ³rum | FÃ³rum | N/A | GitHub |
| **Suporte Enterprise** | Email 8h SLA + WhatsApp | Email 48h | Email 48h | N/A | Comercial |

### Quando escolher cada um

| CenÃ¡rio | RecomendaÃ§Ã£o |
|---|---|
| Projeto pessoal / acadÃªmico / startup sem orÃ§amento | **MinusORM Community** (grÃ¡tis, MIT) |
| Empresa brasileira que precisa de suporte em PT-BR | **MinusORM** (documentaÃ§Ã£o e suporte em portuguÃªs) |
| Precisa de Oracle + SLA + garantia jurÃ­dica | **MinusORM Enterprise** (R$199/dev/ano) |
| Precisa de .NET Framework (WinForms, WPF) | **TMS Aurelius** (ecossistema .NET da TMS) |
| Precisa de suporte oficial da Embarcadero | **EntityDAC** (mesma empresa do FireDAC) |
| Quer cÃ³digo aberto e nÃ£o se importa com faltas de features | **DORM** (abandonado, mas funcional) |
| Performance mÃ¡xima em servidor Linux sem Windows | **mORMot** (nÃ£o usa FireDAC, SQL direto) |

---

## 2. MinusMigrator

### Concorrentes Diretos

| CaracterÃ­stica | MinusMigrator | Flyway | Liquibase | DBMigration (Delphi) | Alembic |
|---|---|---|---|---|---|
| **LicenÃ§a** | MIT (Community) / Comercial | Open Source + EdiÃ§Ãµes Pagas | Open Source + EdiÃ§Ãµes Pagas | Comercial | Apache 2.0 |
| **PreÃ§o** | GrÃ¡tis (CLI) / R$149 (Pro) | GrÃ¡tis (Community) / $1k+ (Enterprise) | GrÃ¡tis (Community) / $999+ (Pro) | ~$99 | GrÃ¡tis |
| **Linguagem nativa** | **Delphi** (nativo) | Java | Java | Delphi | Python |
| **CLI** | âœ… `MinusMigrator_CLI.exe` | âœ… CLI | âœ… CLI | âŒ | âœ… CLI |
| **DLL para consumo externo** | âœ… stdcall exports | âŒ | âŒ | âŒ | âŒ |
| **GUI** | âœ… `MinusMigrator_GUI.exe` | âŒ (sÃ³ CLI) | âŒ (sÃ³ CLI) | âŒ | âŒ |
| **Multi-banco** | 7 bancos (SQLite, FB, PG, MySQL, MariaDB, MSSQL, Oracle) | 15+ (via JDBC) | 15+ (via JDBC) | 3 bancos | Via SQLAlchemy |
| **Versionamento** | âœ… Migrations numeradas + tags + contexto | âœ… | âœ… | âœ… | âœ… |
| **Auto-migrate** | âœ… Gera migrations das entidades | âŒ | âŒ | âŒ | âœ… (autogenerate) |
| **Diff changelog** | âœ… Compara schema atual vs entidades | âŒ | âœ… (diff) | âŒ | âŒ |
| **Dry-run** | âœ… `--dry-run` | âœ… | âœ… | âŒ | âœ… |
| **Rollback** | âœ… `rollback -n N` ou `--tag` | âœ… | âœ… | âŒ | âœ… |
| **Generate models** | âœ… Gera classes Delphi do BD | âŒ | âŒ | âŒ | âŒ |
| **Status** | âœ… `status --format json\|yaml` | âœ… | âœ… | âŒ | âœ… |
| **Tagging** | âœ… `tag "nome"` em migrations | âœ… | âœ… | âŒ | âŒ |
| **Context isolation** | âœ… `--context ctx` (mÃºltiplos tenants) | âŒ | âŒ | âŒ | âŒ |
| **Schema Readers** | âœ… Individual por banco | âŒ | âŒ | âŒ | âŒ |
| **SQL Generators** | âœ… SQL por provider | âŒ | âŒ | âŒ | âŒ |
| **Zero dependÃªncia externa** | âœ… SÃ³ precisa do FireDAC | âŒ (JDBC) | âŒ (JDBC) | âœ… | âŒ (Python) |
| **Suporte PT-BR** | âœ… | âŒ | âŒ | âŒ | âŒ |
| **IDE nativa Delphi** | âœ… Packages BPL, integraÃ§Ã£o RAD Studio | âŒ | âŒ | âŒ | âŒ |

### Quando escolher cada um

| CenÃ¡rio | RecomendaÃ§Ã£o |
|---|---|
| Projeto Delphi que precisa de migraÃ§Ã£o versionada | **MinusMigrator** (nativo, zero setup) |
| Precisa embarcar migrator em DLL para outra linguagem | **MinusMigrator** (Ãºnico com exports stdcall) |
| Equipe multi-linguagem (Java, .NET, Node) | **Flyway** ou **Liquibase** |
| Projeto puramente Python | **Alembic** |
| Precisa de integraÃ§Ã£o com RAD Studio IDE | **MinusMigrator** (Ãºnica opÃ§Ã£o nativa) |
| OrÃ§amento zero | **MinusMigrator Community** (CLI grÃ¡tis) |

---

## 3. MinusFeatureFlags

### Concorrentes Diretos

| CaracterÃ­stica | MinusFeatureFlags | LaunchDarkly | Unleash | Flagsmith | ConfigCat |
|---|---|---|---|---|---|
| **LicenÃ§a** | MIT (Community) / Comercial | SaaS proprietÃ¡rio | BSL 1.1 / SaaS | BSD 3-Clause / SaaS | SaaS proprietÃ¡rio |
| **PreÃ§o** | GrÃ¡tis (Core) / R$149 (Pro/dev) | $200/mÃªs+ (10 seats) | GrÃ¡tis (self-host) / $80/mÃªs+ | GrÃ¡tis (self-host) / $99/mÃªs+ | GrÃ¡tis (10 flags) / $5.99/mÃªs+ |
| **Modelo** | **On-premise** (embarcado) | SaaS | SaaS / Self-host | SaaS / Self-host | SaaS |
| **SDK Delphi nativo** | âœ… `TFeatureFlags` | âŒ | âŒ (REST genÃ©rico) | âŒ (REST genÃ©rico) | âŒ (REST genÃ©rico) |
| **Providers** | MemÃ³ria, JSON, Database, REST | API prÃ³pria | API prÃ³pria | API prÃ³pria | API prÃ³pria |
| **Targeting** | 6 tipos (global, %, usuÃ¡rio, grupo, atributo, agendado) | âœ… | âœ… | âœ… | âœ… |
| **A/B Testing** | âœ… Hash global + segmentado por regra | âœ… | âœ… | âœ… | âŒ |
| **Prerequisite flags** | âœ… `DependeDe` | âœ… | âœ… | âŒ | âŒ |
| **Multi-environment** | âœ… | âœ… | âœ… | âœ… | âœ… |
| **Audit log** | âœ… Tabela `feature_flag_audit` | âœ… | âœ… | âœ… | âœ… |
| **MÃ©tricas** | âœ… Buffer + persistÃªncia SQL | âœ… | âœ… | âœ… | âœ… |
| **Web Dashboard** | Em roadmap (Vue/Svelte) | âœ… | âœ… | âœ… | âœ… |
| **SDK Remoto** | Em roadmap | âœ… | âœ… | âœ… | âœ… |
| **Batch evaluation** | Em roadmap | âœ… | âœ… | âŒ | âŒ |
| **SSE Streaming** | Em roadmap | âœ… | âŒ | âŒ | âŒ |
| **RBAC** | Em roadmap | âœ… | âœ… | âœ… | âœ… |
| **Funciona offline/sem internet** | âœ… **Completo** (embarcado na app) | âŒ (requer SaaS) | âŒ (requer servidor) | âŒ (requer servidor) | âŒ (requer servidor) |
| **Zero latÃªncia de rede** | âœ… (avaliaÃ§Ã£o local em ms) | âŒ (latÃªncia HTTP) | âŒ (latÃªncia HTTP) | âŒ (latÃªncia HTTP) | âŒ (latÃªncia HTTP) |
| **IntegraÃ§Ã£o com MinusORM** | âœ… Providers Database e MemÃ³ria jÃ¡ conectados | âŒ | âŒ | âŒ | âŒ |

### Quando escolher cada um

| CenÃ¡rio | RecomendaÃ§Ã£o |
|---|---|
| AplicaÃ§Ã£o Delphi desktop sem internet | **MinusFeatureFlags** (Ãºnica opÃ§Ã£o nativa offline) |
| Sistema crÃ­tico onde latÃªncia de rede Ã© inaceitÃ¡vel | **MinusFeatureFlags** (avaliaÃ§Ã£o local em microssegundos) |
| Empresa que jÃ¡ usa MinusORM | **MinusFeatureFlags** (integraÃ§Ã£o nativa com ORM) |
| Precisa de dashboard web sofisticado HOJE | **LaunchDarkly** ou **Unleash** |
| Equipe multi-linguagem com feature flags centralizadas | **Unleash** ou **Flagsmith** |
| OrÃ§amento zero, precisa de feature flags simples | **MinusFeatureFlags Community** (providers JSON/MemÃ³ria) |

---

## 4. MinusRest

### Concorrentes Diretos

| CaracterÃ­stica | MinusRest (Horse Extensions) | Horse (standalone) | Delphi MVC Framework | DataSnap | RAD Server |
|---|---|---|---|---|---|
| **LicenÃ§a** | MIT (Community) | MIT | MIT | Comercial (Embarcadero) | Comercial (Embarcadero) |
| **PreÃ§o** | GrÃ¡tis (Community) / R$99 (Pro) | GrÃ¡tis | GrÃ¡tis | Incluso no RAD Studio | $1.999+ |
| **Middleware JWT** | âœ… Horse JWT | âŒ (terceiros) | âœ… | âŒ | âŒ |
| **Middleware CORS** | âœ… Horse Cors | âŒ (terceiros) | âœ… | âŒ | âŒ |
| **Middleware Logger** | âœ… Lumberjack Logger | âŒ (terceiros) | âœ… | âŒ | âŒ |
| **JSON Serialization** | âœ… Jhonson (Horse JSON) | âŒ (terceiros) | âŒ | âŒ | âŒ |
| **IntegraÃ§Ã£o com MinusORM** | âœ… Providers nativos | âŒ | âŒ | âŒ | âŒ |
| **Feature Flags via REST** | âœ… MinusFeatureFlags API | âŒ | âŒ | âŒ | âŒ |
| **Multi-tenancy** | âœ… Filtro automÃ¡tico `tenant_id` | âŒ | âŒ | âŒ | âŒ |
| **Pacote completo** | âœ… ORM + REST + FF + Migrator | âŒ (sÃ³ web) | âŒ (sÃ³ web) | âŒ (sÃ³ REST) | âŒ (sÃ³ REST) |
| **DocumentaÃ§Ã£o PT-BR** | âœ… | âŒ | âŒ | âŒ | âŒ |

### Quando escolher cada um

| CenÃ¡rio | RecomendaÃ§Ã£o |
|---|---|
| API REST Delphi simples e rÃ¡pida | **Horse** (leve, MIT, standalone) |
| API REST + ORM + Feature Flags + Migrator | **MinusRest completo** (ecossistema integrado) |
| Precisa de suporte oficial Embarcadero | **RAD Server** ou **DataSnap** |
| Precisa de multi-tier com chamadas remotas | **DataSnap** |

---

## 5. MinusExtensions

### ExtensÃµes vs Alternativas Isoladas

| ExtensÃ£o | MinusFramework | Alternativa Isolada | Vantagem MF |
|---|---|---|---|
| **Soft Delete** | `[SoftDelete('coluna', tesBooleano)]` | ImplementaÃ§Ã£o manual | Declarativo, automÃ¡tico em todas as queries |
| **Cache 2Âº nÃ­vel** | `[Cache(TTL, 'regiao')]` | Redis / Memcached | Zero dependÃªncia externa, TTL por regiÃ£o |
| **Unique Key** | `[ChaveUnica('grupo', ['COL1','COL2'])]` | ValidaÃ§Ã£o manual no SQL | Declarativo, composto, automÃ¡tico |
| **Bulk Operations** | `InserirEmLote`, `AtualizarEmLote`, `ExcluirEmLote` | FireDAC Array DML | API unificada, independente de banco |
| **Shadow Properties** | `[CriadoEm]`, `[AtualizadoEm]` | Triggers no banco | Sem trigger, sem permissÃ£o extra |
| **Audit Trail** | `[CriadoPor]`, `[AtualizadoPor]` + tabela `auditoria` | Triggers + tabela de log | Rastreia quem, quando, valores anteriores/novos |
| **Multi-tenancy** | `[Inquilino]` com filtro automÃ¡tico | Manual `WHERE tenant_id` | Declarativo, sem risco de esquecer o filtro |
| **Encryption** | `[Criptografado]` (XOR) | Criptografia manual na app | Transparente, desserializa automÃ¡tico |
| **ConcorrÃªncia** | `[Versao]` com lock otimista | Manual `WHERE ... AND versao = :v` | AutomÃ¡tico, exception tipada |
| **Health Check** | `THealthCheck` built-in | ImplementaÃ§Ã£o manual | JÃ¡ integrado com ORM, mÃ©tricas de latÃªncia |
| **Retry / Circuit Breaker** | `TRetryPolicy` com exponential backoff | Polly (.NET) / ImplementaÃ§Ã£o manual | PolÃ­tica configurÃ¡vel, integrada |
| **SQL Profiler** | Log + relatÃ³rio Markdown | Ferramentas externas | Gera relatÃ³rio formatado, integrado |
| **Seeding** | `TSeeder` com fixtures JSON | Scripts SQL manuais | Dados de teste tipados, reutilizÃ¡veis |
| **PaginaÃ§Ã£o** | `TPaginacao` + `TResultadoPaginado<T>` | Manual `LIMIT/OFFSET` | API consistente, retorno padronizado |

---

## 6. MinusMessaging

> Sistema de mensageria assÃ­ncrona multi-provider com suporte a filas, pub/sub, retry, DLQ, outbox, sagas e circuit breaker.

### Concorrentes Diretos

| CaracterÃ­stica | MinusMessaging | Redis (raw) | RabbitMQ (raw) | Kafka (raw) | MQTT (raw) |
|---|---|---|---|---|---|
| **LicenÃ§a** | MIT (Community) / Comercial | BSD | MPL 2.0 | Apache 2.0 | MIT |
| **PreÃ§o** | GrÃ¡tis (Community) / R$149 (Pro) | GrÃ¡tis | GrÃ¡tis | GrÃ¡tis | GrÃ¡tis |
| **SDK Delphi nativo** | âœ… Nativo | âœ… `delphiredis` | âœ… `RabbitMQ.Delphi` | âš  `librdkafka` binding | âœ… `TMQTTClient` |
| **Multi-provider** | âœ… Mesma API para todos | âŒ SÃ³ Redis | âŒ SÃ³ RabbitMQ | âŒ SÃ³ Kafka | âŒ SÃ³ MQTT |
| **Retry + Backoff** | âœ… Built-in (fixo, exp, jitter) | âŒ Manual | âŒ Manual | âŒ Manual | âŒ Manual |
| **DLQ automÃ¡tica** | âœ… `TGerenciadorDLQ` | âŒ ZSET manual | âœ… DLX nativa | âŒ Manual | âŒ Manual |
| **Outbox pattern** | âœ… IntegraÃ§Ã£o MinusORM | âŒ | âŒ | âŒ | âŒ |
| **Saga (coreografia)** | âœ… Fase 2 | âŒ | âŒ | âŒ | âŒ |
| **Saga (orquestraÃ§Ã£o)** | âœ… Fase 2 | âŒ | âŒ | âŒ | âŒ |
| **Circuit Breaker** | âœ… `TCirtuitBreaker` integrado | âŒ | âŒ | âŒ | âŒ |
| **IdempotÃªncia** | âœ… Fase 1 | âŒ Manual | âŒ Manual | âŒ Manual | âŒ Manual |
| **Dashboard REST** | âœ… Fase 2 (Horse) | âŒ | âŒ RabbitMQ UI (Java) | âŒ Kafka UI (Java) | âŒ |
| **RPC sÃ­ncrono** | âœ… Fase 2 (CorrelationId) | âŒ | âœ… | âŒ | âŒ |
| **Streaming SSE** | âœ… Fase 3 | âŒ | âŒ | âŒ | âŒ |
| **Tracer distribuÃ­do** | âœ… Fase 3 (W3C Trace Context) | âŒ | âŒ | âŒ | âŒ |
| **DocumentaÃ§Ã£o PT-BR** | âœ… | âŒ | âŒ | âŒ | âŒ |

### Quando escolher cada um

| CenÃ¡rio | RecomendaÃ§Ã£o |
|---|---|
| Mensageria simples em memÃ³ria (testes/dev) | **MinusMessaging Community** (InMemory, grÃ¡tis) |
| Precisa de Redis pub/sub + filas | **MinusMessaging Pro** (API unificada + Redis) |
| Precisa de RabbitMQ com DLQ nativa | **MinusMessaging Pro** (RabbitMQ + DLX) |
| Precisa de Kafka para eventos em larga escala | **MinusMessaging Pro** (Kafka + consumer groups) |
| Precisa de outbox pattern + ORM | **MinusORM + MinusMessaging** (integraÃ§Ã£o nativa) |
| Precisa de dashboard REST + sagas | **MinusMessaging Pro** (Horse + Sagas) |
| Quer um Ãºnico provider especÃ­fico | Redis/RabbitMQ/Kafka puro (menos complexidade) |
| Equipe grande, precisa de tracing distribuÃ­do | **MinusMessaging Pro** (W3C Trace Context + OpenTelemetry) |

---

## 7. Tabela Resumo

### PreÃ§os no Mercado (por desenvolvedor, anual)

| SoluÃ§Ã£o | MinusFramework Community | MinusFramework Pro | Concorrente Mais Barato | Concorrente Mais Caro |
|---|---|---|---|---|
| **ORM** | **GrÃ¡tis** âœ… | R$199 | TMS Aurelius ~$195 | EntityDAC ~$199 |
| **Migrator** | **GrÃ¡tis** âœ… (CLI) | R$149 | DBMigration ~$99 | Liquibase Pro $999+ |
| **Feature Flags** | **GrÃ¡tis** âœ… (Core) | R$149 | Unleash Open Source (grÃ¡tis) | LaunchDarkly $200/mÃªs |
| **REST API** | **GrÃ¡tis** âœ… | R$99 | Horse (grÃ¡tis) | RAD Server $1.999 |
| **Messaging** | **GrÃ¡tis** âœ… (Core + MemÃ³ria) | R$149 | Redis (grÃ¡tis, sem SDK Delphi) | Kafka (grÃ¡tis, sem SDK Delphi) |
| **Suite Completa** | **GrÃ¡tis** âœ… | **R$599** | N/A (nenhum concorrente oferece suite integrada) | N/A |

### Matriz de DecisÃ£o

| Perfil | Plano Recomendado | Custo |
|---|---|---|
| Estudante / hobby | **Community** | **GrÃ¡tis** |
| Startup (1 dev, orÃ§amento zero) | **Community** | **GrÃ¡tis** |
| Freelancer (1 dev, precisa de Oracle) | **ORM Pro + Migrator Pro** | R$348/ano (~R$29/mÃªs) |
| Empresa pequena (1 dev, tudo incluso) | **Complete Bundle (1 dev)** | R$499/ano (~R$42/mÃªs) |
| Equipe (5 devs, tudo incluso) | **Enterprise Suite (time)** | R$1.999/ano (~R$167/mÃªs) |
| Empresa grande (10+ devs, SLA urgente) | **Enterprise Suite** | R$1.999/ano |
| Precisa sÃ³ de migraÃ§Ã£o | **Migrator Community** | **GrÃ¡tis** |
| Precisa sÃ³ de feature flags | **FeatureFlags Community** | **GrÃ¡tis** |
| Precisa de mensageria assÃ­ncrona | **Messaging Community** | **GrÃ¡tis** |

---

> **DÃºvidas sobre qual plano escolher?** Abra uma [issue](https://github.com/GabrielFerreiraMendes/MinusFramework/issues) ou envie email para `comercial@minusframework.com.br`.
>
> *Documento atualizado em Junho de 2026.*
