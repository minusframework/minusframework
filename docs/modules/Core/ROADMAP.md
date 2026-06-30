# MinusFramework Core â€” Roadmap

> **InÃ­cio:** Junho de 2026
> **Ãšltima atualizaÃ§Ã£o:** Junho/2026

## Estado Atual

| Sprint | Foco | Status |
|---|---|---|
| Sprint 1 | CorreÃ§Ãµes crÃ­ticas (deadlock, SQL injection, IdentityMap) | ConcluÃ­do |
| Sprint 2 | OtimizaÃ§Ãµes de performance (RTTI cache, Ã­ndices O(1)) | ConcluÃ­do |
| Sprint 3 | EvoluÃ§Ã£o arquitetural (PKs universais, contexto ORM) | ConcluÃ­do |
| Sprint 4 | Features avanÃ§adas (ArrayDML, Criteria type-safe, Pool) | ConcluÃ­do |
| Sprint 5 | InovaÃ§Ã£o cross-language (Proxy, CompiledQuery, Async) | ConcluÃ­do |
| Sprint 6 | Qualidade interna + gaps (Thread safety, RTTI, TDataSet, RAII) | ConcluÃ­do |
| Sprint 7 | MinusMessaging Fase 0 | ConcluÃ­do |
| Sprint 8 | Hardening arquitetural (thread safety, seguranÃ§a, design gaps) | Parcial |

## Refactoring Sprints â€” Acoplamento e CoesÃ£o

Sprints focados em reduzir acoplamento e aumentar coesÃ£o (SRP/ISP) sem quebrar API pÃºblica.

| Sprint | Foco | Unidades | Status |
|---|---|---|---|
| R-1 | Extrair responsabilidades do `TUnidadeTrabalho.Confirmar` (3 mÃ©todos, 1 nÃ­vel de indentaÃ§Ã£o) | `MF.UnitOfWork.pas` | ConcluÃ­do |
| R-2 | InjeÃ§Ã£o de dependÃªncia em `TRepositorioBase` (IGeradorConsultaSQL, IProcessadorEventosORM) | `MF.RepositoryBase.pas` | ConcluÃ­do |
| R-3 | Composition over inheritance para Bulk/Async (TRepositorioBulkImpl, TRepositorioAsyncImpl) | `MF.RepositoryBase.pas` | ConcluÃ­do |
| R-4 | EliminaÃ§Ã£o de magic strings na Criteria API (TExprOnde<T>, TEntidadeCriterios<T>, Propriedade()) | `MF.SelectBuilder.pas` | ConcluÃ­do |
| R-5 | SeparaÃ§Ã£o Builder/Executor (IExecutorConsulta<T>, TContextoExecucao<T>) | `MF.SelectBuilder.pas` | ConcluÃ­do |
| R-6 | EliminaÃ§Ã£o de dependÃªncias estÃ¡ticas no executor (ICloneador, IProcessadorEventos, IProfilerORM) | `MF.ServicosExecutor.pas`, `MF.SelectBuilder.pas` | ConcluÃ­do |
| R-7 | SRP em TComandoPersistencia (God Class) â€” extraÃ§Ã£o de 4 interfaces + `MF.ServicosComando.pas` | `MF.ServicosComando.pas`, `MF.CommandExecutor.pas` | ConcluÃ­do |
| R-8 | SRP em MF.QueryBuilder â€” SoftDelete isolado em virtual methods, removido de `interface uses` | `MF.QueryBuilder.pas` | ConcluÃ­do |
| R-9 | ReduÃ§Ã£o de acoplamento em MF.Mapper â€” `ILeitorValorCampo`, `IMapeadorNullable`, `IMapeadorConversor` | `MF.Mapper.pas` | ConcluÃ­do |
| R-10 | SeparaÃ§Ã£o SQL/Metadata em MF.MetadataCache â€” `TCompiladorSQLMeta` + `TSQLCompilado` | `MF.MetadataCache.pas` | ConcluÃ­do |
| R-11 | Service Locator para DI em MF.Config â€” `IGerenciadorConexoes`, `IGerenciadorPools` + `MF.ServicosConfig.pas` | `MF.ServicosConfig.pas`, `MF.Config.pas` | ConcluÃ­do |

## ORM Features Competitivas

- Cascade persist (UoW percorre grafo automaticamente)
- DTO projection (`Projetar<TDTO>` na chain do SelectBuilder)
- Fluent where tipado (`TCond<T>.Campo('Nome')` com RTTI + lambdas)
- Identity Map (class var no Mapper, UoW seta automaticamente)
- Value Objects (`ITypeConverter` + `TipoConverterAttribute`)
- HeranÃ§a TPH (`DiscriminadorAttribute` + `ResolverClasse`)
- SQL Injection fix (subconsultas com parÃ¢metros nomeados)
- Limit/Offset parametrizado (`:_offset`, `:_limit`, `:_limit_end`)

## Features de ProduÃ§Ã£o

- Multi-tenancy (`[Inquilino]` + `TContextoInquilino` com filtro automÃ¡tico)
- Health Check + Retry (`THealthCheck.Executar` + `TRetryPolicy` com exponential backoff)
- Database Seeding (`TSeeder` com fixtures JSON)
- Pagination built-in (`TPaginacao` + `TResultadoPaginado<T>`)
- SQL Profiler (`TProfiler` com log de queries, relatÃ³rio Markdown)
- Scaffold DB to Entidades (`TScaffold` gera .pas via INFORMATION_SCHEMA)
- Column Encryption (`[Criptografado]` + `TCriptografiaColuna`)
- Views + Stored Procs (`[View]`, `[StoredProc]` + `TMapeadorView`)
- Dual Licensing (MIT Community + Comercial Enterprise)
- LicenÃ§a HMAC-SHA256 (`TLicenciamento` com derivaÃ§Ã£o PBKDF2-like)
- Companions Python (`minus-yaml.py`, `minus-report.py`, `minus-graph.py`)

## Melhorias de Qualidade Interna

- Thread safety (`TMonitor` adicionado ao MF.Config, MF.TypeConverter)
- RTTI caching completo (`TCacheMetadados.RttiContext`)
- ValidaÃ§Ã£o por atributos (`[Obrigatorio]`, `[TamanhoMinimo]`, etc.)
- TTransactionScope (RAII) com auto-rollback no destructor
- Async/await (`SalvarAsync`, `BuscarPorIdAsync`, `ExcluirAsync`)
- Logging/Audit hooks (`TRastreadorMudancas.OnMudanca`)
- Exception handling (`EExcecaoORM` com aliases em inglÃªs)
- DependÃªncias circulares eliminadas

## Sprint 8 â€” Hardening

### S8-01 CorreÃ§Ãµes CrÃ­ticas
- Fix `threadvar` global em `TConexaoInfra`
- Fix race condition em `TRegistroProcessadores.Registrar`
- Fix RTTI por setter no `TProxyGerador`
- Topological sort no `TUnidadeTrabalho.Confirmar`

### S8-02 SeguranÃ§a e Licenciamento
- RevisÃ£o criptogrÃ¡fica do `TLicenciamento` (migrar para RSA real)
- Separar `TFeatureFlags` em dois mÃ³dulos (SRP)

### S8-03 Design e Usabilidade
- `SELECT DISTINCT` no `TConstrutorSelecao<T>`
- `IEspecificacao<T>` â€” Specification Pattern
- `IValidadorEntidade<T>` injetÃ¡vel
- Imutabilidade pÃ³s-construÃ§Ã£o de `TMetaEntidade`
- Suporte a PKs compostas e `Int64`
- `IQueryInterceptor` â€” pipeline de middlewares
- MÃ©tricas de pool de conexÃ£o integradas ao MinusTelemetry

## InovaÃ§Ãµes EstratÃ©gicas

- Source Generator completo (expandir `TProxyGerador`)
- `TQueryPlan` â€” EXPLAIN/ANALYZE integrado
- Domain Events tipados via `TChangeSet<T>`
- `TMinusSchema` â€” validaÃ§Ã£o de schema em healthcheck
- `MinusFixture` com Contract-Based Fixtures
- Aproveitar recursos do Delphi 12 Athens

## Fases Anteriores (ConcluÃ­das)

### Fase 0 â€” Isolamento do MinusORM
`IConnection`, `ICommand`, `IResultSet`, `IParam`, `IField`, exceÃ§Ãµes, provider registry, FireDAC implementation, BPL packages

### Fase 1.4 â€” Criteria API
`TCriteriaOperator`, `TCriteria<T>`, integraÃ§Ã£o com `TQueryBuilder<T>`, subqueries, geraÃ§Ã£o provider-aware de SQL

### Fase 1.1+1.2 â€” UoW + Change Tracking
`TIdentityMap`, `TChangeTracker`, `TUnitOfWork`, paginaÃ§Ã£o provider-aware, lock otimista

### Extensions
SoftDelete, Audit Log, Cache 2Âº nÃ­vel, Shadow Properties, ConcorrÃªncia, Bulk Operations, Navigation Properties

### Fase 2 â€” Providers Multi-Banco
SQLite (in-memory), PostgreSQL, MySQL, testes cross-db com Docker Compose, benchmarks

### Providers Adicionais
Oracle, DB2, MariaDB

## Produtos Derivados (Planejado)

- MinusOutbox â€” Transactional Outbox Pattern
- MinusQuery â€” Tradutor OData/GraphQL
- MinusFixture â€” Motor de geraÃ§Ã£o de dados para testes
- MinusHealth Dashboard â€” Painel de monitoramento
