# Changelog â€” MinusFramework Core

All notable changes to MinusFramework Core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-06-06

### Added
- Initial project structure with ORM core, extensions, migrator, and test projects
- RTTI attribute mapping (`[Tabela]`, `[Coluna]`, `[ChavePrimaria]`, etc.)
- Fluent query builders (`TConstrutorSelecao<T>`, `TConstrutorAtualizacao<T>`)
- Criteria API with type-safe operators
- Unit of Work with change tracking
- Identity Map (L1 cache)
- Multi-provider support (SQLite, Firebird, PostgreSQL, MySQL)
- Extensions: SoftDelete, Cache, UniqueKey, Bulk, Concurrency, Shadow Properties, Audit

### Fixed
- SQL injection in subqueries
- Deadlock in connection pool
- threadvar leak in TConexaoInfra
- Race condition in TRegistroProcessadores
- RTTI per-setter allocation in TProxyGerador

### Changed
- Migrated from `threadvar` to TDictionary for thread-safe connection management
- Replaced `TRttiContext.Create` with cached `TCacheMetadados.RttiContext`
- Added topological sort for UnitOfWork commit order

## [0.3.0] - 2026-06-27

### Refactoring Sprint 7 â€” SRP em TComandoPersistencia (God Class)
- Extraiu 4 interfaces de serviÃ§o: `IOrdenadorDependencias`, `IPropagadorFK`, `IVersionadorEntidade`, `IAjudanteChaveEntidade`
- Criou `MF.ServicosComando.pas` com implementaÃ§Ãµes padrÃ£o (`TOrdenadorDependencias`, `TPropagadorFK`, `TVersionadorEntidade`, `TAjudanteChaveEntidade`) + `TServicosComando` record
- `TComandoPersistencia.Inserir`: removeu 6 procedimentos aninhados, substituÃ­dos por delegaÃ§Ã£o aos serviÃ§os
- `TComandoPersistencia.Atualizar`/`Excluir`: `VincularIdChave` (duplicado 3x) e `DefinirVersaoEntidade` (duplicado 2x) eliminados via serviÃ§os
- ReduÃ§Ã£o de ~80 linhas com lÃ³gica duplicada removida
- Arquivos: `MF.ServicosComando.pas` (nova), `MF.CommandExecutor.pas`

### Refactoring Sprint 8 â€” SRP em MF.QueryBuilder
- `MF.Extensions.SoftDelete` movido de `interface uses` para `implementation uses` (remoÃ§Ã£o de dependÃªncia de extensÃ£o no core)
- `TConstrutorExclusao<T>`: criou `FExclusaoLogica`, `DeveUsarExclusaoLogica` (virtual) e `GerarSQLExclusaoLogica` (virtual), isolando a dependÃªncia de SoftDelete
- `GerarSQL` agora usa `FExclusaoLogica` em vez de chamar `TAjudanteSoftDelete` diretamente
- Arquivo: `MF.QueryBuilder.pas`

### Refactoring Sprint 9 â€” ReduÃ§Ã£o de acoplamento em MF.Mapper
- Criou 3 interfaces de serviÃ§o: `ILeitorValorCampo`, `IMapeadorNullable`, `IMapeadorConversor`
- `TLeitorValorCampoPadrao` (type-dispatch unificado), `TMapeadorNullablePadrao` (nullable records), `TMapeadorConversorPadrao` (TypeConverters)
- `MapearPropriedade` reduzido de ~140 para ~30 linhas (delegaÃ§Ã£o)
- `MapearDTO` ~55 â†’ ~25 linhas, `MapearPlan`/`MapearListaPlan` nullable blocks substituÃ­dos por serviÃ§o
- `LerValorIndice` removido (substituÃ­do por `TLeitorValorCampoPadrao`)
- EliminaÃ§Ã£o de ~120 linhas de type-dispatch duplicado (5 ocorrÃªncias)
- Arquivo: `MF.Mapper.pas`

### Refactoring Sprint 10 â€” SeparaÃ§Ã£o SQL/Metadata em MF.MetadataCache
- Criou `TSQLCompilado` (record) e `TCompiladorSQLMeta.Compilar` (static)
- Construtor `TMetaEntidade.Create` reduzido de ~195 para ~50 linhas (RTTI scanning + hook + delegaÃ§Ã£o ao compilador)
- SQL generation movida de inline no construtor para `TCompiladorSQLMeta.Compilar`
- Arquivo: `MF.MetadataCache.pas`

### Refactoring Sprint 11 â€” Service Locator para DI em MF.Config
- Criou `MF.ServicosConfig.pas` com interfaces `IGerenciadorConexoes`, `IGerenciadorPools` e implementaÃ§Ãµes padrÃ£o
- `TConfiguracaoORM` refatorado para delegar a `TServicosConfig` internamente
- Adicionado `TConfiguracaoORM.Configurar(AServicos)` para injeÃ§Ã£o em testes
- Todas as 68 referÃªncias externas mantÃªm compatibilidade: API pÃºblica inalterada
- Arquivos: `MF.ServicosConfig.pas` (nova), `MF.Config.pas`

## [0.2.0] - 2026-06-26

### Refactoring Sprint 1 â€” SRP em TUnidadeTrabalho
- Extraiu `ProcessarExclusoes`, `ProcessarInsercoes`, `ProcessarAtualizacoes` do mÃ©todo `Confirmar`
- Reduziu indentaÃ§Ã£o de 3 nÃ­veis para 1 nÃ­vel (Object Calisthenics)
- TransaÃ§Ã£o (`IniciarTransacao`/`Confirmar`/`Reverter`) mantida no mÃ©todo principal
- Arquivo: `MF.UnitOfWork.pas`

### Refactoring Sprint 2 â€” InjeÃ§Ã£o de DependÃªncia em TRepositorioBase
- Criou interfaces `IGeradorConsultaSQL` e `IProcessadorEventosORM` com implementaÃ§Ãµes padrÃ£o
- Adicionou construtor de 4 parÃ¢metros para injeÃ§Ã£o
- Extraiu `ExecutarInsercao`/`ExecutarAtualizacao` como `protected virtual`
- `Salvar` refatorado sem ELSE (early return com `Exit`)
- Arquivo: `MF.RepositoryBase.pas`

### Refactoring Sprint 3 â€” ComposiÃ§Ã£o via Strategy (Bulk/Async)
- Criou `TRepositorioBulkImpl<T>` e `TRepositorioAsyncImpl<T>` como classes de composiÃ§Ã£o
- `TRepositorioBase<T>` delega `IRepositorioBulk<T>` e `IRepositorioAsync<T>` via propriedades `implements`
- Removidas ~90 linhas de implementaÃ§Ã£o direta de bulk/async da classe base
- Arquivo: `MF.RepositoryBase.pas`

### Refactoring Sprint 4 â€” Criteria API Type-Safe
- Adicionou overload `Onde(const AExpr: TExprOnde<T>)` para expressÃµes lambda com RTTI
- Adicionou `TPropriedadeEntidade` + `Propriedade()` para overloads de `OrdenarPor`/`AgruparPor`
- Criou `TEntidadeCriterios<T>` com mÃ©todos `Coluna()` e `Campo()` para resoluÃ§Ã£o automÃ¡tica de colunas
- 5 novos testes DUnitX para as novas overloads
- Arquivos: `MF.SelectBuilder.pas`, `Test.ORM.SelectBuilder.pas`

### Refactoring Sprint 6 â€” EliminaÃ§Ã£o de DependÃªncias EstÃ¡ticas no Executor
- Criou interfaces `ICloneador`, `IProcessadorEventos`, `IProfilerORM` em nova unit `MF.ServicosExecutor.pas`
- Criou implementaÃ§Ãµes padrÃ£o que delegam para os estÃ¡ticos originais (`TCloneadorPadrao`, `TProcessadorEventosPadrao`, `TProfilerORMPadrao`)
- Modificou `TExecutorConsultaPadrao<T>` para aceitar `TServicosExecutor` opcional com fallback automÃ¡tico
- Executor 100% mockÃ¡vel em testes: todas as chamadas a `TClonador`, `TRegistroProcessadores` e `TProfiler` agora passam por interfaces injetÃ¡veis
- 2 novos testes DUnitX para injeÃ§Ã£o de servicos
- Arquivos: `MF.ServicosExecutor.pas`, `MF.SelectBuilder.pas`, `Test.ORM.SelectBuilder.pas`

### Refactoring Sprint 5 â€” SeparaÃ§Ã£o Builder/Executor
- Criou `IExecutorConsulta<T>` e `TExecutorConsultaPadrao<T>` para execuÃ§Ã£o de queries
- Criou `TContextoExecucao<T>` como contrato imutÃ¡vel entre builder e executor
- Moveu ~120 linhas de cache, includes, profiling e mapeamento do builder para o executor
- `TConstrutorSelecao<T>` aceita executor injetÃ¡vel via construtor opcional
- Extraiu helpers standalone `ExecVincularParametros` e `ExecAplicarIncludes`
- Arquivo: `MF.SelectBuilder.pas`
