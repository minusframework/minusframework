# Visão Geral da Arquitetura

## Camadas

```
+----------------------------------------------------+
|                Aplicação do Usuário                  |
|  (Console, VCL, Horse API, DLL host)                |
+----------------------------------------------------+
|       MinusFramework_Design  |  MinusMessaging_Design |
|       (IDE integration)      |  (IDE integration)      |
+------------------------------+------------------------+
|  MinusFramework_Runtime (ORAM + Foundation + Ext)     |
|  MinusORM.dll (C-accessible API)                      |
+----------------------------------------------------+
|  MinusMigrator (DLL + CLI + GUI)                      |
+----------------------------------------------------+
|  MinusMessaging_Runtime (Message Bus, Patterns)       |
+----------------------------------------------------+
|  MinusTelemetry_Runtime (Tracing, Logging, Metrics)    |
+----------------------------------------------------+
```

## Princípios de Design

1. **Programação para interfaces** — Todo o ORM trabalha com interfaces (`IConexao`, `IComando`, `IRepositorioBase<T>`), nunca com classes concretas.
2. **Provedores plugáveis** — `TRegistroProvedores` permite adicionar novos bancos sem modificar o núcleo.
3. **Extensões por hook** — `TRegistroProcessadores` expõe pontos de extensão para insert, update, delete, validação e cache.
4. **Atributos sobre configuração** — Mapeamento declarativo via atributos RTTI.
5. **Composição sobre herança** — Repositórios usam composição com Identity Map, Change Tracker e Metadata Cache.
6. **Resiliência por padrão** — Connection pooling, retry com backoff, circuit breaker, outbox pattern.

## Fluxo de uma operação de Save

```pascal
TRepositorioBase<T>.Salvar(Entidade)
  |
  +-> TCacheMetadados (obter metadados compilados)
  +-> TRastreadorMudancas.CapturarInstantaneo (antes)
  +-> TProcessadoresInsercao/Atualizacao (hooks)
  |     +-> TAjudanteSombra (CriadoEm, AtualizadoEm)
  |     +-> TAjudanteAuditoria (log de auditoria)
  |     +-> TAjudanteConcorrencia (versão)
  |     +-> TCriptografiaColuna (encrypt)
  +-> TMapaIdentidade.Adicionar
  +-> TComandoPersistencia.Executar (INSERT/UPDATE)
  +-> TRastreadorMudancas.AceitarMudancas
  +-> TAjudanteCache.Atualizar
  +-> TTelemetry (span: DB <Entidade>.Salvar)
```

## Diagrama de Dependências (Source)

```
Source\
  Bibliotecas\          (sem dependências internas)
    MF.Types.pas
    MF.Connection.pas
    MF.Provider.pas
    MF.Config.pas
    MF.Attributes.pas
    MF.Exceptions.pas
    MF.ConnectionPool.pas
    Providers\*.pas      (implements IFabricaConexao)

  Core\                  (depende de Bibliotecas)
    MF.MetadataCache.pas
    MF.Mapper.pas
    MF.IdGenerator.pas
    MF.QueryBuilder.pas
    MF.Criteria.pas
    MF.SelectBuilder.pas
    MF.InsertBuilder.pas
    MF.UpdateBuilder.pas
    MF.DeleteBuilder.pas
    MF.RepositoryBase.pas
    MF.IdentityMap.pas
    MF.ChangeTracker.pas
    MF.UnitOfWork.pas
    MF.Validation.pas
    MF.Lazy.pas
    MF.Nullable.pas
    MF.Profiler.pas
    MF.Expression.pas
    MF.CompiledQuery.pas
    MF.Pagination.pas
    MF.Infra.Connection.pas

  Extensions\            (depende de Core)
    MF.Extensions.JSON.pas
    MF.Extensions.AutoMapper.pas
    MF.Extensions.Horse.pas
    MF.Extensions.SoftDelete.pas
    MF.Extensions.MultiTenancy.pas
    MF.Extensions.Audit.pas
    MF.Extensions.Encryption.pas
    MF.Extensions.Bulk.pas
    MF.Extensions.Async.pas
    MF.Extensions.Cache.pas
    MF.Extensions.GlobalFilters.pas
    MF.Extensions.Concorrencia.pas
    MF.Extensions.Sombra.pas
    MF.Extensions.DataSet.pas
    MF.Extensions.Relacionamento.pas
    MF.Extensions.Profiler.pas
    MF.Extensions.Telemetry.ORM.pas

  Telemetry\             (independente)
    MF.Telemetry.pas
    MF.Telemetry.Logger.pas
    MF.Telemetry.Exporter.pas

  Messaging\             (depende de Telemetry)
    MF.Messaging.Types.pas
    MF.Messaging.Config.pas
    MF.Messaging.Core.pas
    MF.Messaging.Reliability.pas
    Providers\*.pas
    Patterns\*.pas
    Monitor\*.pas

  FeatureFlags\          (independente)
    MF.FeatureFlags.Types.pas
    MF.FeatureFlags.Provider.pas
    MF.FeatureFlags.Metrics.pas
    MF.FeatureFlags.Audit.pas
    MF.FeatureFlags.Webhook.pas
    MF.FeatureFlags.SSE.pas
    MF.FeatureFlags.SDK.pas

  Migrator\              (depende de Bibliotecas + Core)
    MF.Migrator.Types.pas
    MF.Migrator.EntityReader.pas
    MF.Migrator.SchemaReader.pas
    MF.Migrator.SchemaReader.*.pas
    MF.Migrator.SchemaDiffer.pas
    MF.Migrator.SQLGenerator.pas
    MF.Migrator.SQLGenerator.*.pas
    MF.Migrator.Runner.pas
    MF.Migrator.Commands.pas
    MF.Migrator.CLI.pas
    MF.Migrator.Changelog.pas
```
