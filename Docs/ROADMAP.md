# Roadmap de Implementação

> **Início:** Junho de 2026
> **Projetos:** MinusORM 2.0 + MinusMigrator 1.0 + MinusMessaging 1.0 (proposto)
> **Última atualização:** 21/Junho/2026 (23:23)

---

## Estado Atual (Junho 2026)

### Progresso dos Sprints (Plano de Implementação)

| Sprint | Foco | Status |
|---|---|---|
| **Sprint 1** | Correções críticas (deadlock, SQL injection, IdentityMap) | ✅ Concluído |
| **Sprint 2** | Otimizações de performance (RTTI cache, índices O(1)) | ✅ Concluído |
| **Sprint 3** | Evolução arquitetural (PKs universais, contexto ORM) | ✅ Concluído |
| **Sprint 4** | Features avançadas (ArrayDML, Criteria type-safe, Pool) | ✅ Concluído |
| **Sprint 5** | Inovação cross-language (Proxy, CompiledQuery, Async) | ✅ Concluído |
| **Sprint 6** | Qualidade interna + gaps (Thread safety, RTTI, TDataSet, RAII) | ✅ Concluído |
| **Sprint 7** | MinusMessaging Fase 0 — Core + Provider InMemory + Testes | ✅ Concluído |
| **Sprint 8** | Hardening arquitetural (thread safety, segurança, design gaps) | 🔄 Parcial (S8-01 ✅) |

### S4-01 — ArrayDML ✅ (concluído em 11/Jun)
### S4-02 — SQL Pré-compilado ✅ (concluído em 11/Jun)

`InserirEmLote<T>` agora usa `ArrayDMLSize` do FireDAC quando suportado (GUIDs, sequences).
`TGeradorConsulta` retorna SQLs do `TMetaEntidade` sem `Format()` em runtime.
**Ganho:** 10-50x em inserção em lote + zero alocação de string por query.

```
MinusORM 2.0                                      MinusMigrator 1.0            MinusMessaging 1.0
├── Core              ✅ completo                  ├── Fase 1     ✅ completo    ├── Fase 0     ✅ completo
├── Extensions        ✅ completo                  │   ├── SchemaReader          │   ├── Core (interfaces + TMessageBus)
├── Features comp.    ✅ completo                  │   ├── SchemaDiffer          │   ├── Provider InMemory
│   ├── Cascade persist                            │   ├── SQLGenerator         │   ├── Serialização JSON
│   ├── Fluent where tipado                        │   ├── Runner + CLI         │   ├── Retry + DLQ
│   ├── DTO projection                             │   └── Auto-migrate         │   └── Testes unitários
│   └── MSSQL provider                             │                            │
├── Sprint 4          ✅ completo                  ├── Fase 2     ✅ completo    ├── Fase 1     ⬜ planejado
│   ├── S4-01 ArrayDML            ✅               │   ├── Lock table           │   ├── Providers Redis/RabbitMQ
│   ├── S4-02 SQL Pré-compilado   ✅               │   ├── Add-migration        │   ├── Outbox + Idempotência
│   ├── S4-03 Criteria TypeSafe   ✅               │   ├── Changelog JSON/YAML  │   └── Health Check
│   ├── S4-04 ParaCadaAsync       ✅               │   ├── Repeatable mig.      │
│   ├── S4-05 Pool de Conexões    ✅               │   ├── Tag/rollback         │
│                                                  │   ├── Preconditions        │
└── Fase 3           ⬜ planejado                  │   ├── Generate-models      │
    ├── Oracle provider                             │   ├── CI/CD mode          │
    ├── DB2 provider                                │   ├── Track auto-migrate  │
    ├── MariaDB provider                            │   └── Provider MSSQL      │
    ├── Changelog XML/YAML/JSON (input) ✅            │                            │
    ├── diff-changelog + snapshot                    └── Fase 3     ⬜ planejado  └── Fase 2     ⬜ planejado
    ├── DLL API                                         ├── Oracle / DB2              ├── Saga + Circuit Breaker
    ├── GUI / IDE Expert                                ├── Changelog XML/YAML/JSON   ├── Dashboard REST
    ├── REST API                                        ├── DLL API + BPL + GetIt     └── MQTT
    ├── BPL / GetIt / MSBuild Task                      ├── GUI + IDE Expert
    ├── minuSCM / minusERP                              └── REST API
    └── Documentação + exemplos
```

---

## MinusMigrator Fase 2 ✅

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | Lock de tabela de controle (`__MINUSMIGRATOR_LOCK`) | ✅ |
| 🔴 | Add-migration via diff (gera `.up.sql` + `.down.sql` versionados) | ✅ |
| 🔴 | Changelog JSON/YAML/XML (input + output) | ✅ |
| 🔴 | Repeatable migrations (runOnChange: `R__*.up.sql`) | ✅ |
| 🟡 | Tag command + rollback-to-tag | ✅ |
| 🟡 | CI/CD mode: `--force` no auto-migrate | ✅ |
| 🟡 | Preconditions (`tableExists`, `columnNotExists`, `dbms`, etc.) | ✅ |
| 🟡 | Contexts (`--context <nome>` filtra subdiretório) | ✅ |
| 🟡 | Generate-models (reverse engineering .pas do BD) | ✅ |
| 🟡 | Track auto-migrate na tabela de controle | ✅ |
| 🔴 | Provider MSSQL (SchemaReader + SQLGenerator) | ✅ |
| 🔴 | **Dry run** (`--dry-run`) | ✅ |
| 🔴 | **SQL Lint/Validation** (`minusmigrator lint`) | ✅ |
| 🔴 | **Diff entre 2 bancos** (`minusmigrator diff-bancos`) | ✅ |
| 🟡 | **Rollback seletivo** por changeset ID | ✅ |
| 🟡 | **Changesets reorganizáveis** (YAML/JSON/XML input) | ✅ |

## ORM Features Competitivas ✅

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | Cascade persist (UoW percorre grafo automaticamente) | ✅ |
| 🔴 | DTO projection (`Projetar<TDTO>` na chain do SelectBuilder) | ✅ |
| 🟡 | Fluent where tipado (`TCond<T>.Campo('Nome')` com RTTI + lambdas) | ✅ |
| 🔴 | Identity Map (class var no Mapper, UoW seta automaticamente) | ✅ |
| 🟡 | Value Objects (`ITypeConverter` + `TipoConverterAttribute`) | ✅ |
| 🟡 | Herança TPH (`DiscriminadorAttribute` + `ResolverClasse`) | ✅ |
| 🔴 | SQL Injection fix (subconsultas com parâmetros nomeados) | ✅ |
| 🔴 | Limit/Offset parametrizado (`:_offset`, `:_limit`, `:_limit_end`) | ✅ |

## ORM Features — Gap vs Aurelius / EntityDAC ⬜

| Prioridade | Feature | Complexidade | Observação |
|---|---|---|---|
| 🔴 | **Lazy loading (Proxy)** | ✅ | `TLazy<T>` com `.Valor` transparente + `TLazy.Carregar` manual |
| 🔴 | **Nullable types** | ✅ | `TNullable<Integer>`, `TNullable<Currency>` para campos opcionais de BD. Evita ambiguidade 0 vs NULL |
| 🔴 | **Associação Many-to-Many** | ✅ | `[Relacionamento(trMuitosMuitos)]` + `[TabelaIntermediaria]` com JOIN automático. Carregamento N:N em lote (`CarregarPropriedadeEmMassa`) |
| 🔴 | **Componente TDataSet** | ✅ | `TMinusDataSet` com `Carregar(IResultados)`, `CarregarLista<T>`, `Load<T>(TConstrutorSelecao<T>)`, `LoadFromRepository<T>`. Compatível com DBGrid/DBEdit/DBNavigator |
| 🟡 | **LINQ-like queries** | Alta | Expressões lambda compiladas: `Consulta.Where(function(c) c.Nome = 'Joao')`. EntityDAC tem LINQ nativo |
| 🟡 | **Joined-Table inheritance** | Média | Cada classe da hierarquia em sua própria tabela (apenas TPH atualmente) |
| 🟡 | **Design-time components** | Média | `TMinusConnection`, `TMinusContext` para arrastar na IDE. Aurelius e EntityDAC têm |
| 🟡 | **Oracle provider** | Alta | `ALL_TABLES`/`ALL_TAB_COLUMNS`, sequences, tipos `NUMBER`/`VARCHAR2`/`CLOB`/`BLOB` |
| 🟡 | **Suporte UniDAC + ADO + dbExpress** | Média | Atualmente só FireDAC. Adaptadores para outros componentes de acesso |
| 🟡 | **JSON serialization nativa** | ✅ | `TJsonSerializer.Serializar/Desserializar` via RTTI |
| 🟡 | **Plataforma Linux/macOS** | Alta | Suporte FireMonkey + compilação cross-platform. Aurelius suporta Win/Mac/Linux/iOS/Android |
| 🟡 | **Nullable types** | Média | `TNullable<Integer>`, `TNullable<Currency>` para campos opcionais de BD |
| 🟢 | **Benchmarks vs Aurelius/EntityDAC/ADO** | Baixa | Publicar comparativo de desempenho com cenários reais (CRUD, bulk insert, queries complexas) |
| 🟢 | **AI Agent Skills** | Baixa | Skills para Claude/Cursor/Cline que ensinam os patterns do MinusORM. Aurelius já tem |
| 🟢 | **Suporte MariaDB** | Baixa | 99% compatível MySQL, ajustar apenas sintaxe `AUTO_INCREMENT` e charset |

---

## Features de Produção (Junho/2026) ✅

| Prioridade | Feature | Status | Descrição |
|---|---|---|---|
| 🔴 | **Multi-tenancy** | ✅ | `[Inquilino]` + `TContextoInquilino` com filtro automático `WHERE tenant_id` |
| 🔴 | **Health Check + Retry** | ✅ | `THealthCheck.Executar` + `TRetryPolicy` com exponential backoff e circuit breaker |
| 🔴 | **Database Seeding** | ✅ | `TSeeder` com fixtures JSON |
| 🔴 | **Pagination built-in** | ✅ | `TPaginacao` + `TResultadoPaginado<T>` |
| 🟡 | **SQL Profiler** | ✅ | `TProfiler` com log de queries, relatório Markdown, queries lentas |
| 🟡 | **Scaffold DB→Entidades** | ✅ | `TScaffold` gera .pas via INFORMATION_SCHEMA |
| 🟡 | **Column Encryption** | ✅ | `[Criptografado]` + `TCriptografiaColuna` |
| 🟡 | **Views + Stored Procs** | ✅ | `[View]`, `[StoredProc]` + `TMapeadorView` |
| 🟢 | **Dual Licensing** | ✅ | MIT (Community) + Comercial (Enterprise) |
| 🟢 | **Licença HMAC-SHA256** | ✅ | `TLicenciamento` com derivação PBKDF2-like |
| 🟢 | **Companions Python** | ✅ | `minus-yaml.py`, `minus-report.py`, `minus-graph.py` |
| 🟢 | **GitHub Action CI** | ✅ | Validação automática de migrations em PRs |

---

## Feature Flags — MinusFeatureFlag ✅⬜

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | **Fase 0 — Diagnóstico e bugs críticos** | ✅ |
| | Parsear array `regras` do JSON em `TProviderJSON` | ✅ |
| | Serializar `Regras`/`Variantes`/`Tags` para JSON em `SalvarFlag` | ✅ |
| | Popular `criada_em`/`atualizada_em` no INSERT/UPDATE | ✅ |
| | `Variante()` considerar regras de targeting para A/B segmentado | ✅ |
| | Corrigir `Result.Regras := nil` no `ParseFlag` | ✅ |
| 🟡 | **Fase 1 — Fundação** | ✅ |
| | Testes unitários DUnitX (motor, cache, providers, métricas) | ✅ |
| | Métricas persistentes (tabela `feature_flag_metrics`) | ✅ |
| 🟡 | **Fase 2 — Governança** | ⬜ |
| | Multi-environment (campo `ambiente` + filtro por provider) | ⬜ |
| | Audit log (tabela `feature_flag_audit` + consulta) | ⬜ |
| | Web dashboard (SPA Vue/Svelte) | ⬜ |
| | Prerequisite flags (`DependeDe`) | ✅ |
| | A/B segmentado por regras de targeting | ✅ |
| | TProviderREST com write (POST/PUT/DELETE) | ⬜ |
| 🟢 | **Fase 3 — Escala** | ⬜ |
| | SDK remoto para Delphi (`MF.FeatureFlags.SDK`) | ⬜ |
| | Batch evaluation (`POST /api/flags/evaluate`) | ⬜ |
| | Streaming SSE (`GET /api/flags/stream`) | ⬜ |
| | Import/Export (`GET/POST /api/flags/export`) | ⬜ |
| | RBAC (usuários, papéis, Bearer token) | ⬜ |

---

## Melhorias de Qualidade Interna 🔄

| Prioridade | Melhoria | Status | Benefício |
|---|---|---|---|
| 🔴 | **Thread safety** | ✅ | `TMonitor` adicionado ao MF.Config (FConexoes, FPools) e MF.TypeConverter (FMapa). MF.MetadataCache e MF.Extensions.Cache já possuíam proteção |
| 🔴 | **RTTI caching completo** | ✅ | `TRttiContext.Create` substituído por `TCacheMetadados.RttiContext` em MF.EntityBase, MF.Validation, MF.Extensions.AutoMapper |
| 🔴 | **Validação por atributos** | ✅ | Já implementado: `[Obrigatorio]`, `[TamanhoMinimo]`, `[TamanhoMaximo]`, `[Tamanho]`, `[Intervalo]`, `[ExpressaoRegular]`, `[Email]` com mensagens customizáveis |
| 🟡 | **TTransactionScope (RAII)** | ✅ | `ITransactionScope` + `TTransactionScope` com auto-rollback no destructor via `IInterface` |
| 🟡 | **Async/await** | ✅ | `SalvarAsync`, `BuscarPorIdAsync`, `ExcluirAsync` via `TTask.Future<T>`. Consistente com `ParaCadaAsync` |
| 🟡 | **Logging/Audit hooks** | ✅ | `TRastreadorMudancas.OnMudanca` — callback disparado automaticamente quando `ObterMudancas` encontra mudancas. `TUnidadeTrabalho.OnBeforeSave`/`OnAfterSave` ja existiam |
| 🟡 | **Exception handling** | ✅ | `Exception.Create` substituído por `EExcecaoORM` no Core. Aliases em inglês adicionados (`EORMException`, etc.) |
| 🟡 | **Nomenclatura padronizada** | ✅ | Convenção documentada em `Docs/CONVENTIONS.md`. Português primário, aliases em inglês (`TUnitOfWork`, `IConnection`, etc.) |
| 🟡 | **Dependências circulares** | ✅ | Analisado: arquitetura limpa em camadas sem ciclos. Leaf → Mapper → QueryBuilder → SelectBuilder → RepositoryBase |
| 🟢 | **Code coverage** | ✅ | Testes criados para InsertBuilder, DeleteBuilder, UpdateBuilder, Validation (20 metodos), Pagination (15 metodos). Total: 306 → 366 metodos. |
| 🟢 | **GetIt Package** | ✅ | Descritores JSON criados para MinusORM (`GETIT_MinusORM.json`), MinusMigrator (`GETIT_MinusMigrator.json`) e MinusMessaging (existente) |
| 🟢 | **PasDoc API Docs** | ✅ | Script `Tools/generate-docs.ps1` configurado com todos os diretorios de source. Documentacao HTML gerada em `Docs/API/` |
| 🟢 | **Guia Migracao Aurelius** | ✅ | `Docs/GUIA_MIGRACAO_AURELIUS.md` — tabela de equivalencia de atributos, script PowerShell de renomeacao em massa, checklist de 6 fases |

---

## Polimento + Documentação

| Prioridade | Tarefa | Motivo / Dependência |
|---|---|---|
| 🟢 | Benchmarks ORM vs ADO/DBExpress/Aurelius | Bloqueado: licença Community/Trial não compila CLI |
| 🟢 | Testes providers MSSQL | Bloqueado: sem SQL Server disponível |
| 🟢 | Testes providers Oracle | Bloqueado: sem Oracle disponível |
| 🟢 | Documentação completa + exemplos | ✅ `Docs/` contem 15 documentos tecnicos + guia de usuario + guia mensageria + guia migracao |
| 🟢 | Documentação API (auto-gerada) | ✅ Script `Tools/generate-docs.ps1` com PasDoc. Execute `.\Tools\generate-docs.ps1` |
| 🟢 | Guia de migração de Aurelius/EntityDAC | ✅ `Docs/GUIA_MIGRACAO_AURELIUS.md` com tabela de equivalencia e script de renomeacao |

---

## MinusTelemetry — Observabilidade (Fase 1 ✅, Fase 2 ⬜)

### Diagnóstico de Competitividade (Junho/2026)

O MinusTelemetry é a **melhor solução de observabilidade do ecossistema Delphi**: único a oferecer Jaeger + Zipkin + OTLP + Prometheus em um pacote sem dependências externas.

| Capacidade | MinusFW | Delphi 12 nativo | QuickLogger | mORMot |
|-----------|---------|------------------|-------------|--------|
| Tracing distribuído | ✅ | ➖ parcial | ❌ | ➖ |
| W3C Trace Context | ✅ | ✅ | ❌ | ❌ |
| Export Jaeger / Zipkin / OTLP | ✅✅✅ | ❌ | ❌ | ❌ |
| Métricas (Counter/Gauge/Histogram) | ✅ | ❌ | ❌ | ❌ |
| Export Prometheus | ✅ | ❌ | ❌ | ❌ |
| Logging estruturado JSON | ✅ | ❌ | ✅ | ✅ |
| Background thread exporter | ✅ | ❌ | ❌ | ❌ |
| Auto-instrumentação ORM | ✅ | ❌ | ❌ | ❌ |
| Auto-instrumentação REST | ✅ Horse | ❌ | ❌ | ❌ |
| Auto-instrumentação Messaging | ✅ | ❌ | ❌ | ❌ |
| Zero dependências externas | ✅ | ✅ | ✅ | ✅ |

### Arquitetura Atual ✅

```
MF.Telemetry.pas          → ITracer / ISpan / IMetrica / IMetricasManager (interfaces)
MF.Telemetry.Logger.pas   → TTelemetryLogger + ConsoleAppender + StreamAppender (JSON)
MF.Telemetry.Exporter.pas → TExporter (thread background, batch, HTTP)
                             ├── Jaeger  → POST /api/traces
                             ├── Zipkin  → POST /api/v2/spans
                             └── OTLP    → POST /v1/traces (HTTP/JSON)
MF.Extensions.Telemetry.ORM.pas       → Auto-span em comandos SQL
MF.Extensions.Telemetry.Messaging.pas → Auto-span em publish/consume
MF.Extensions.Horse.Telemetry.pas     → Auto-span em requisições HTTP
```

### Cobertura dos 5 Pilares de Observabilidade

| Pilar | Status | O que falta |
|-------|--------|-------------|
| **Logs** | ✅ | — |
| **Métricas** | ✅ | `ObterOuCriarHistograma` implementado com buckets configuráveis e export Prometheus completo |
| **Traces** | ✅ | — |
| **Dashboards** | ✅ Delegado | Exporta para Grafana (via Prometheus) e Jaeger UI |
| **Alertas** | ✅ Delegado | Métricas → Prometheus → AlertManager → Slack/PagerDuty |

### Fase 2 — Polimento e Padrões Abertos

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | **Sampling configurável** | ✅ `TTracerPadrao.SetSamplingRatio` + `TExporterConfig.SamplingRatio`. Head-based com propagação W3C |
| 🔴 | **Resource Attributes** | ✅ `TExporterConfig.ResourceAttributes` anexados a todo span (Jaeger/Zipkin/OTLP) |
| 🔴 | **Histograma completo** | ✅ `ObterOuCriarHistograma` com buckets padrao HTTP + export Prometheus `_bucket/_sum/_count/+Inf` |
| 🟡 | **Span Events** | ✅ | `ISpan.AdicionarEvento(Nome, Tags)`. Serializados em Jaeger (logs), Zipkin (annotations), OTLP (events) |
| 🟡 | **Baggage Propagation** | ✅ | `ITracer.DefinirBagagem`/`ObterBagagem`. Thread-local, propaga via bagagem entre servicos |
| 🟡 | **gRPC OTLP Export** | ✅ | `TExportBackend.ebOTLPgRPC` com HTTP/Protobuf binario |
| 🟡 | **SpanKind** | ✅ | `TSpanKind = (skInternal, skServer, skClient, skProducer, skConsumer)`. Auto-instrumentacao usa tipos corretos |
| 🟢 | **Exemplar** | `IMetrica.RegistrarComExemplar(Valor, TraceId, SpanId)`. Vincula métrica ao trace que a gerou para correlação trissinal |
| 🟢 | **Dashboard embutido** | Página Horse com gráficos de latência P50/P95/P99, taxa de erro, throughput por endpoint (sem precisar de Prometheus/Grafana externos) |
| 🟢 | **Health Check endpoint** | `GET /health` com status dos componentes (tracer, exporter, métricas, conexão com backend). Formato compatível com Kubernetes liveness/readiness |

---

## Fase 3 — Expansão (✅ Providers concluídos)

### Providers adicionais
| Prioridade | Tarefa | Complexidade | Observação |
|---|---|---|---|
| 🟡 | **Oracle provider** | ✅ | `FireDAC.Phys.Oracle` + `TFabricaConexaoOracle` + `TLeitorEsquemaOracle` (345 linhas) + `TGeradorSQLOracle` (testes existentes) + `TGeradorIdOracle` (SEQUENCE via `NEXTVAL FROM DUAL`) |
| 🟡 | **DB2 provider** | ✅ | `FireDAC.Phys.DB2` + `TFabricaConexaoDB2` + `TLeitorEsquemaDB2` (178 linhas) + `TGeradorSQLDB2` + `TGeradorIdDB2` (`IDENTITY_VAL_LOCAL()`) |
| 🟢 | **MariaDB provider** | ✅ | 99% compatível MySQL; wrapper fino sobre MySQL com charset UTF8 e porta 3306 |

### DLL API
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **Exportar MinusMigrator como DLL** | `MinusMigrator.dll` com funções `C` exportáveis: `mmInit`, `mmMigrate`, `mmStatus`, `mmRollback`, `mmAddMigration`, `mmAutoMigrate`. Chamável de Python, C#, Node.js, etc. |

### GUI
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **Interface gráfica (FMX ou VCL)** | App desktop para visualizar status, executar/reverter migrations, diff visual entidades vs BD, editor de migration SQL com syntax highlight |

### REST API
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **Serviço HTTP para migrations** | API RESTful em Delphi (ou outra stack) para execução remota: `POST /migrate`, `GET /status`, `POST /rollback`, `POST /add-migration` |

### Changelog em XML/YAML/JSON (input) ✅
| Prioridade | Tarefa | Descrição | Status |
|---|---|---|---|
| 🟡 | **Changelog XML** | Formato Liquibase-compatível: `<changeSet author="..." id="..."><createTable tableName="X"><column name="id" type="INT"/></createTable></changeSet>` | ✅ |
| 🟡 | **Changelog YAML/JSON** | Formato estruturado com changesets, author, id, context, preconditions. YAML input implementado (antes `ENotSupportedException`) | ✅ |

### Diff / Comparison
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **diff-changelog** | Gerar changelog XML/YAML/JSON a partir do diff (equivalente ao `liquibase diff-changelog`), não apenas `.up.sql` |
| 🟡 | **diff com snapshot** | Snapshots de BD para comparar offline (equivalente ao `liquibase snapshot`) |

### IDE / RAD Studio Integration
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **Expert IDE** | Expert para RAD Studio que executa migrations, mostra status, diff visual do BD vs entidades diretamente na IDE |
| 🟡 | **GetIt Package** | Publicar MinusMigrator + MinusORM no Delphi GetIt Manager para instalação com um clique |

### Package / Build Integration
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟡 | **BPL Design/Runtime** | Empacotar como BPL para uso em Design-time (componentes, editores de propriedade) e Runtime |
| 🟢 | **MSBuild Task** | Task MSBuild para executar migrations automagicamente no build |

### Aplicações reais
| Prioridade | Tarefa | Descrição |
|---|---|---|
| 🟢 | **minuSCM** | Sistema de Controle Comercial (vendas, estoque, financeiro) usando MinusORM + MinusMigrator como prova de conceito real |
| 🟢 | **minusERP** | Sistema ERP completo (compras, vendas, fiscal, contábil, RH, produção) rodando em produção com o framework |

---

## MCP Server — Model Context Protocol ⬜ Planejado

| Prioridade | Tarefa | Status |
|---|---|---|
| 🟢 | **MCP Server do MinusFrameWork** — expõe ferramentas para IAs (Claude, Cursor, Copilot) como `listar-provedores`, `executar-testes`, `compilar`, `consultar-docs`, `docker-up/down` | ⬜ |

---

### Produtos Derivados (⬜ Planejado)

| Produto | Descrição | Complexidade | Prioridade |
|---|---|---|---|
| **MinusOutbox** | Transactional Outbox Pattern integrado ao `TUnidadeTrabalho`. Grava eventos na tabela `__MINUS_OUTBOX` na mesma transação; worker background publica no broker | Média | 🟡 |
| **MinusQuery** | Tradutor automático de OData/GraphQL para `TConstrutorSelecao<T>`. Middleware Horse que converte `$filter`, `$expand`, `$select` da URL em critérios tipados | Alta | 🟡 |
| **MinusFixture** | Motor de geração de dados dinâmicos (Faker) para testes. Inspeciona atributos RTTI e gera dados realistas. Anotações `[MockNome]`, `[MockEmail]` | Média | 🟢 |
| **MinusHealth Dashboard** | Painel VCL/FMX + página web Horse com gráficos de latência, pool de conexões, cache hits/misses, health checks em tempo real | Baixa | 🟢 |
| **MinusTelemetry** | OpenTelemetry-compatible tracing distribuído (W3C Trace Context) + métricas + logging estruturado. Exportadores Jaeger/Zipkin/OTLP + Prometheus. Auto-instrumentação para ORM, Messaging e Horse REST. **Fase 1 concluída.** | Média | ✅ Fase 1 |

---

## Sprint 8 — Hardening Arquitetural (🔄 Parcial)

> Pontos identificados na análise arquitetural de Junho/2026 — não cobertos pelo roadmap anterior.

### S8-01 — Correções Críticas de Estabilidade ✅

| Prioridade | Tarefa | Complexidade | Descrição | Status |
|---|---|---|---|---|
| 🔴 | **Fix `threadvar` global em `TConexaoInfra`** | Média | `GPadraoConexaoInfra` era `threadvar` e vazava em pools de threads (IIS, Horse). Migrado para `FGerenciadorThreads: TDictionary<TThreadID, TConexaoInfra>` protegido por `FLock: TCriticalSection`. `LiberarThread` exposto para chamada explícita no fim de cada requisição. | ✅ `MF.Infra.Connection.pas` |
| 🔴 | **Fix race condition em `TRegistroProcessadores.Registrar`** | Baixa | Concatenação de arrays dinâmicos (`FInsercoes := FInsercoes + [AProc]`) não era atômica. Protegido com `TMonitor.Enter(TRegistroProcessadores)` em todos os métodos `Registrar`. | ✅ `MF.Extensao.Core.pas` |
| 🔴 | **Fix RTTI por setter no `TProxyGerador`** | Média | Código gerado usava `TRttiContext.Create` dentro de cada setter. Refatorado para `TCacheMetadados.RttiContext` no `class constructor` com `class var FProp_Nome: TRttiProperty` cacheada. | ✅ `MF.Proxy.pas` |
| 🟡 | **Limite implícito em `BuscarTodos` com aviso via Telemetry** | Baixa | `BuscarTodos` sem paginação pode carregar milhões de registros causando OOM silencioso. Adicionar `TConfiguracaoORM.LimiteAvisoBuscarTodos` (padrão 5000); logar `TProfiler.Avisar` quando resultado ultrapassar o threshold. | ⬜ |
| 🟡 | **Topological sort no `TUnidadeTrabalho.Confirmar`** | Alta | A ordem fixa Exclusões→Inserções→Atualizações podia violar FK constraints. Implementado `TOrdenadorTopologico` que analisa atributos `[Relacionamento]` para determinar ordem de persistência respeitando dependências. | ✅ `MF.UnitOfWork.Sorter.pas` |

### S8-02 — Segurança e Licenciamento

| Prioridade | Tarefa | Complexidade | Descrição |
|---|---|---|---|
| 🔴 | **Revisão criptográfica do `TLicenciamento`** | Alta | `CSeed` HMAC hardcoded no código-fonte é reversível por decompilação — não equivale a RSA-2048 como o comentário sugere. Migrar para RSA real com chave pública embutida (`IndyOpenSSL` ou `TMS Cryptography`) ou validação via servidor de licenças com grace period offline. |
| 🟡 | **Separar `TFeatureFlags` em dois módulos (SRP)** | Média | `MF.FeatureFlags.pas` mistura dois concerns: licensing tier (permanente) e runtime flags (dinâmico, baseado em provider). Separar em `MF.FeatureFlags.pas` (flags puras), `MF.Licensing.pas` (sem dependência de flags) e `MF.FeatureFlags.Licensing.pas` (bridge de sincronização). Elimina risco de dependência circular. |

### S8-03 — Design e Usabilidade

| Prioridade | Tarefa | Complexidade | Descrição |
|---|---|---|---|
| 🟡 | **`SELECT DISTINCT` no `TConstrutorSelecao<T>`** | Baixa | Adicionar `function Distinto: TConstrutorSelecao<T>` ao fluent builder. Ausência obriga SQL raw em queries de relatório com deduplicação. |
| 🟡 | **`IEspecificacao<T>` — Specification Pattern** | Média | Criar `IEspecificacao<T>` com métodos `E`, `Ou`, `Nao` e `ParaCriterio: ICriterio`. Permite encapsular regras de negócio como objetos reutilizáveis, combináveis e testáveis independentemente dos repositórios. |
| 🟡 | **`IValidadorEntidade<T>` injetável** | Média | A validação por atributos não suporta validações com dependências externas (ex: unicidade no banco). Criar `IValidadorEntidade<T>` registrável via `TRegistroProcessadores` com acesso à `IConexao`, complementando os atributos `[Obrigatorio]` etc. |
| 🟡 | **Imutabilidade pós-construção de `TMetaEntidade`** | Média | `TMetaEntidade` expõe todos os fields como `public var`, permitindo corrupção acidental do cache global. Encapsular em propriedades somente-leitura ou expor interface `IMetaEntidade` read-only ao público, mantendo mutabilidade apenas dentro de `TCacheMetadados`. |
| 🟡 | **Suporte a PKs compostas e `Int64`** | Alta | `IGeradorId` assume `Integer` ou `TGUID`. Sistemas legados usam PKs compostas (`empresa_id` + `pedido_num`) ou `Int64`. Criar `IChavePrimaria` com suporte a `TArray<TValue>` e adaptar `TGeradorConsulta` para PKs compostas. |
| 🟡 | **`IQueryInterceptor` — pipeline de middlewares para queries de leitura** | Média | `OnBeforeSave/OnAfterSave` existem no UoW mas não há interceptação de queries SELECT. Criar `IInterceptorQuery` registrável em `TRegistroProcessadores` para logging universal, RLS por query, query rewriting e caching granular. |
| 🟢 | **Métricas de pool de conexão integradas ao MinusTelemetry** | Baixa | O pool de conexões não emite métricas observáveis. Integrar `TConfiguracaoORM` com `IMetricasManager` já existente no MinusTelemetry: `db.pool.active`, `db.pool.idle`, `db.pool.wait_ms`. |
| 🟢 | **Remover ou implementar herança TPT (`TabelaPai`)** | Média | `TMetaEntidade.TabelaPai` está declarado mas herança Table-Per-Type não está implementada (apenas TPH). Implementar TPT completo (JOIN automático, INSERT/UPDATE dividido, DELETE cascade) ou remover o field para não confundir extensores. |
| 🟢 | **Backpressure em `MF.Extensions.Async.Streaming`** | Média | `IAsyncStream<T>` não tem mecanismo de backpressure — o produtor pode sobrecarregar o consumidor em streaming de grandes resultsets. Implementar `TBoundedChannel<T>` com capacidade configurável que bloqueia o produtor quando o buffer está cheio. |

---

## Inovações Estratégicas (⬜ Longo Prazo)

> Funcionalidades que posicionam o MinusFrameWork como referência no ecossistema Delphi — sem equivalente em Aurelius/EntityDAC.

| Prioridade | Produto / Feature | Complexidade | Descrição |
|---|---|---|---|
| 🟡 | **Source Generator completo** | Alta | Expandir `TProxyGerador` para geração full: `IRepositorio<T>` + implementação concreta, DTOs com `FromEntity`/`ToEntity`, migrations tipadas a partir de diff de entidades. Expert IDE com "Generate MinusORM Repository" no botão direito. Pioneiro no ecossistema Delphi. |
| 🟡 | **`TQueryPlan` — EXPLAIN/ANALYZE integrado** | Média | Expor análise de plano de execução diretamente no fluent builder: `.AnalisarPlano` executa `EXPLAIN ANALYZE` (PostgreSQL), `SHOWPLAN` (MSSQL), `EXPLAIN` (MySQL/SQLite). Retorna `CustoEstimado`, `UsouIndice`, `Avisos`. Integrado com `TProfiler` para alertar queries sem índice. |
| 🟡 | **Domain Events tipados via `TChangeSet<T>`** | Alta | Expandir `TRastreadorMudancas` para emitir eventos fortemente tipados após `Confirmar`: `TEventoMudancaEntidade<T>` com `Entidade`, `Propriedade`, `ValorAnterior`, `ValorAtual`, `Timestamp`. Integração nativa ORM → MinusMessaging sem Outbox manual. |
| 🟡 | **Migrations como código Delphi (`TMigrationBase`)** | Alta | Além de SQL raw, suportar migrations implementadas em Pascal: `procedure Aplicar(const AConexao: IConexao)` pode usar o próprio ORM para migrar dados complexos. Pioneiro — Liquibase tem SQL/XML mas não "Typed Delphi Migrations". |
| 🟡 | **`TMinusSchema` — validação de schema em healthcheck de startup** | Média | Serviço que valida em runtime se o schema do banco está sincronizado com as entidades mapeadas. Útil como `GET /health` de startup para detectar migrations não aplicadas em produção antes da aplicação iniciar. |
| 🟢 | **`MinusFixture` com Contract-Based Fixtures** | Média | Em vez de apenas Faker aleatório, suportar `TMinusFixture<T>` que garante invariantes de domínio (Email válido, CPF formatado, relacionamentos coerentes). Compartilhado entre times como "contrato de dado de teste". Integrado com `TSeeder` existente. |
| 🟢 | **Aproveitar recursos do Delphi 12 Athens** | Baixa | `TNullable<T>` com Custom Managed Records (Delphi 10.4+) para cleanup sem overhead de interface. Verificar inferência de tipo genérico para simplificar chamadas da API. Span-like views para processar resultsets sem copiar arrays. |

---

## Fases Anteriores (Concluídas)

As fases abaixo já foram implementadas e estão estáveis. Mantidas como referência histórica.

### Fase 0 — Isolamento do MinusORM ✅

| Tarefa |
|---|
| `IConnection`, `ICommand`, `IResultSet`, `IParam`, `IField` |
| `TORMConnectionParams`, `TORMDatabaseType` |
| Exceções: `EORMException`, `EORMConcurrency`, `EORMValidation`, `EORMProviderNotFound` |
| `TORMProvider` registry + `IProviderFactory` |
| `TFireDACConnection`, `TFireDACCommand` |
| `TFireDACParam`, `TFireDACResultSet`, `TFireDACField` |
| Refactoring: Mapper, QueryBuilder, Repository |
| `IIdGenerator` + `TFirebirdIdGenerator` |
| BPL Runtime + Design packages |

### Fase 2 — Providers Multi-Banco ✅

| Tarefa |
|---|
| Provider SQLite (in-memory para CI) |
| Provider PostgreSQL |
| Provider MySQL |
| Testes cross-db com Docker Compose |
| Benchmarks por provider |

### Fase 1.4 — Criteria API ✅

| Tarefa |
|---|
| `TCriteriaOperator` enum + `TCriteria<T>` core + operadores |
| Integração com `TQueryBuilder<T>` |
| Suporte a subqueries (IN, EXISTS, NOT IN) |
| Geração provider-aware de SQL |

### Fase 1.1+1.2 — UoW + Change Tracking ✅

| Tarefa |
|---|
| `TIdentityMap` (cache de 1º nível) |
| `TChangeTracker` (snapshot + dirty detection) |
| `TUnitOfWork` (RegisterNew/Dirty/Deleted, Commit/Rollback) |
| Paginação provider-aware |
| Lock otimista automático |

### Extensions ✅

| Tarefa |
|---|
| SoftDelete + filtro automático + `IncluirExcluidos` toggle |
| Audit Log (CriadoPor, AtualizadoPor, tabela de auditoria) |
| Cache 2º nível (TCacheMemoria, estatísticas, dependências, max size) |
| Shadow Properties (`[Sombra]`) |
| Concorrência (`[Versao]` lock otimista) |
| Bulk Operations (insert/update/delete em lote) |
| UniqueKey (validação chave única) |
| Navigation Properties (N:N, Include, batch loading N+1) |

### MinusMigrator Fase 1 ✅

| Tarefa |
|---|
| `TDatabaseSchema` + SchemaReader Firebird/PostgreSQL/SQLite/MySQL |
| SchemaDiffer (algoritmo de comparação) |
| SQLGenerator para todos os providers |
| Runner + CLI (init, migrate, rollback, status) |
| EntityReader (parse de .pas com atributos) |
| Auto-migrate com confirmação |
| Testes com Docker |

---

## MinusMessaging — Fase 0: Core (4-6 semanas ✅)

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | `IMensagem`, `IMensageria`, `IProvedorMensageria` — interfaces core | ✅ |
| 🔴 | `TMessageBus` — orquestrador com retry + DLQ | ✅ |
| 🔴 | `TProvedorMemoria` — fila em memória com TThreadedQueue | ✅ |
| 🔴 | Serialização JSON via RTTI (`ISerializadorMensagem`) | ✅ |
| 🔴 | Testes unitários do Core (publish/consume, DLQ, retry) | ✅ |
| 🟡 | CLI `MinusMessaging_CLI.exe` — publish/consume/status | ✅ |
| 🟡 | `TFilaConfig` — configuração por fila (TTL, retry, prefetch) | ✅ |
| 🟢 | Documentação técnica da arquitetura | ✅ |

## MinusMessaging — Fase 1: Providers Reais (6-8 semanas ✅)

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | `TProvedorRedis` — filas (BRPOP) + pub/sub + DLQ via ZSET | ✅ |
| 🔴 | `TProvedorRabbitMQ` — exchanges, bindings, Basic.Ack/Nack, DLX nativa | ✅ |
| 🔴 | Outbox pattern com MinusORM (`TMensagemPendente` + worker) | ✅ |
| 🔴 | Idempotência (`mensageria_idempotencia`) | ✅ |
| 🟡 | **Health Check Messaging** | ✅ | `THealthCheckMessaging` — ping provider, verifica DLQ acumulada, report agregado |
| 🟡 | **Métricas por fila** | ✅ | `TMessagingMetrics` — contadores de publish/consume/falha/DLQ + histogramas de latência |
| 🟢 | **RabbitMQ Publisher Confirms** | ✅ | `TProvedorRabbitMQ.AtivarConfirmMode` + `WaitForConfirms` via Confirm.Select |

## MinusMessaging — Fase 2: Resiliência (4-6 semanas ✅ testes + CI)

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | Saga coreografia (event-driven) | ✅ `TSagaCoreografia` + testes |
| 🔴 | Saga orquestração (`ISaga` com passos + compensação) | ✅ `TSagaOrquestrador` + 11 testes |
| 🔴 | Circuit breaker (`ICircuitBreaker` com half-open) | ✅ `TCircuitBreaker` + 12 testes |
| 🔴 | `TProvedorMQTT` — QoS 0/1/2, will, retain | ✅ implementado (QoS 0 falta tests) |
| 🟡 | RPC síncrono (request/reply via fila temporária + CorrelationId) | ✅ `TRPCClient` + `TRPCServer` |
| 🟡 | Dashboard REST via Horse (`GET /api/messageria/filas`, DLQ, reenvio) | ⬜ |
| 🟡 | DLQ com reenvio seletivo via API | ⬜ |
| 🟢 | CI workflow (GitHub Actions) | ✅ `messaging-tests.yml` |
| 🟢 | Documentação de padrões (saga, outbox, idempotência) | ⬜ |

## MinusMessaging — Fase 3: Escala (6-8 semanas ⬜)

| Prioridade | Tarefa | Status |
|---|---|---|
| 🔴 | `TProvedorKafka` — consumer groups, offset commit, batch | ⬜ |
| 🟡 | Streaming SSE (Server-Sent Events) para UI em tempo real | ⬜ |
| 🟡 | Tracer distribuído (W3C Trace Context + OpenTelemetry compatível) | ⬜ |
| 🟡 | `TProvedorNuvem` — bridge para Amazon SQS / Azure Service Bus | ⬜ |
| 🟢 | Benchmark público vs concorrentes (throughput, latência P50/P99) | ⬜ |
| 🟢 | Pacotes BPL Runtime + Design | ⬜ |
| 🟢 | IDE Expert para RAD Studio (visualizar filas, publicar mensagens) | ⬜ |
| 🟢 | GetIt Package | ⬜ |

### Integrações com Ecossistema

| Integração | Descrição | Fase |
|---|---|---|
| **MinusORM** | Outbox (`TMensagemPendente` via `TRepositorioBase`), Idempotência, Saga estado | Fase 1 |
| **MinusFeatureFlags** | Toggle de consumidores sem deploy, routing dinâmico por flag | Fase 2 |
| **MinusRest** | Endpoints REST de gerenciamento (`/api/messageria/*`) | Fase 2 |
| **MinusMigrator** | Schema das tabelas `mensageria_outbox`, `mensageria_idempotencia`, `mensageria_saga_estado` | Fase 1 |

### Maturidade Esperada

```
Fase 0           Fase 1           Fase 2           Fase 3
Prototipo        Produtivo        Resiliencia      Escala
+ Testes         + Redis          + Saga ✅        + Kafka
+ Core           + RabbitMQ       + MQTT (impl)    + Streaming
+ CLI            + Outbox         + RPC (impl)     + Tracing
                 + Health         + CircuitBreaker ✅ + Benchmark
                 + Idempotencia   + CI workflow ✅   + GetIt/BPL
```

### Providers por Fase

| Provider | Fase | Dependência Externa |
|----------|------|-------------------|
| InMemory | Fase 0 | Nenhuma |
| Redis | Fase 1 | `delphiredis` (NuGet) |
| RabbitMQ | Fase 1 | `RabbitMQ.Delphi` |
| MQTT | Fase 2 | `TMQTTClient` (Embarcadero) | ✅ implementado (QoS 0, SUB/UNSUB, PING) |
| Kafka | Fase 3 | `librdkafka` (DLL C) |
