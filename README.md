# MinusFramework

Mini ORM para Delphi com mapeamento via atributos RTTI, fluent query builders, suporte multi-banco, Unit of Work, Change Tracking e sistema de migração standalone.

[📘 Documentação Técnica](Docs/DOCUMENTACAO_TECNICA.md) — [📗 Guia do Usuário](Docs/GUIA_DO_USUARIO.md) — [📕 Roadmap](Docs/ROADMAP.md) — [📚 API Referência](Docs/API_REFERENCIA.md) — [📋 Licenciamento](LICENSE) — [🎯 Crowdfunding](Docs/ESTRATEGIA_CROWDFUNDING.md) — [📊 Comparativo de Mercado](Docs/COMPARATIVO_MERCADO.md)

## ⚖️ Licenciamento

MinusFramework adota **dual licensing** com planos por solução individual ou suite completa:

### Suites Completas

| Edição | Licença | Preço (1 dev/ano) | Preço (time ilimitado/ano) |
|--------|---------|-------------------|---------------------------|
| **Community** | [MIT](LICENSE) | **Grátis** | **Grátis** |
| **Complete Bundle** | [Comercial](Docs/LICENSE-ENTERPRISE.md) | R$ 499 | R$ 1.999 |

### Soluções Individuais (Comercial)

| Solução | Descrição | Preço (1 dev/ano) | Preço (time/ano) |
|---------|-----------|-------------------|-----------------|
| **MinusORM Pro** | ORM completo + Oracle/DB2 + suporte prioritário | R$ 199 | R$ 599 |
| **MinusMigrator Pro** | CLI + GUI + DLL + schema diff + auto-migrate | R$ 149 | R$ 449 |
| **MinusFeatureFlags Pro** | Todos providers + governança + métricas | R$ 149 | R$ 449 |
| **MinusRest Pro** | Horse middleware + integração ORM/FF | R$ 99 | R$ 299 |
| **MinusMessaging Pro** | Mensageria assíncrona multi-provider (Redis, RabbitMQ, Kafka) | R$ 149 | R$ 449 |

### Bundles com Desconto

| Bundle | Soluções Inclusas | Preço (1 dev/ano) | Economia |
|--------|-------------------|-------------------|----------|
| **ORM Bundle** | ORM Pro + Migrator Pro | R$ 299 | R$ 49 |
| **Developer Bundle** | ORM Pro + Migrator Pro + FF Pro | R$ 399 | R$ 98 |
| **Communications Bundle** | Rest Pro + Messaging Pro | R$ 199 | R$ 49 |
| **Complete Bundle** | ORM Pro + Migrator Pro + FF Pro + Rest Pro + Messaging Pro | R$ 599 | R$ 146 |

### O que vem em cada edição Community (grátis)

| Solução | Community (MIT) | Pro (Comercial) |
|---------|----------------|-----------------|
| **MinusORM** | ORM completo (SQLite, FB, PG, MySQL, MariaDB, MSSQL) | + Oracle + DB2 + suporte SLA |
| **MinusMigrator** | CLI completa (7 bancos) | + GUI + IDE Expert + auto-migrate |
| **MinusFeatureFlags** | Core engine + providers JSON/Memória | + Providers DB/REST + dashboard + governança |
| **MinusRest** | Horse middleware básico (JWT, CORS, Logger) | + Integração ORM/FF + suporte prioritário |
| **MinusMessaging** | Core + fila em memória | + Providers Redis/RabbitMQ/Kafka + Outbox + Sagas + Dashboard |

> 📋 [Compare todas as edições em detalhes →](LICENSE.md)
>
> 📊 [Veja como cada solução se compara ao mercado →](Docs/COMPARATIVO_MERCADO.md)

## Features

- **Mapeamento RTTI** — `[Tabela]`, `[Coluna]`, `[ChavePrimaria]`, `[Ignorar]`
- **Fluent Query Builders** — `TConstrutorSelecao<T>` (consultas), `TConstrutorAtualizacao<T>`, `TConstrutorExclusao<T>` + Criteria API type-safe
- **CRUD Genérico** — `TRepositorioBase<T>` com cache, soft delete, unique key, bulk, concorrência e auditoria
- **Criteria API** — `Criterio().Igual()`, `OuCriterios()`, `E()`, `Existe()`, `EmSubconsulta()`, `Nao()`
- **Unit of Work** — `TUnidadeTrabalho` com registro de novos/sujos/excluídos, commit/rollback transacional
- **Change Tracking** — `TRastreadorMudancas` com snapshot e dirty detection
- **Identity Map** — Cache de 1º nível por entidade
- **Multi-Banco** — Firebird, PostgreSQL, SQLite, MySQL via FireDAC
- **Extensions** — SoftDelete, Cache 2º nível, UniqueKey, Bulk (insert/update/delete em lote), Concorrência otimista, Shadow Properties (CriadoEm/AtualizadoEm), Auditoria (CriadoPor/AtualizadoPor + audit trail)
- **MinusMigrator** — CLI + DLL para migração versionada de schema com SchemaReaders e SQLGenerators por provider
- **Multi-tenancy** — `[Inquilino]` com filtro automático `WHERE tenant_id`
- **Health Check** — `THealthCheck` com verificação de conexão + latência
- **Retry/Circuit Breaker** — `TRetryPolicy` com exponential backoff
- **Database Seeding** — `TSeeder` com fixtures JSON
- **Pagination** — `TPaginacao` + `TResultadoPaginado<T>` built-in
- **SQL Profiler** — Log de queries com relatório Markdown
- **Scaffold** — Geração de entidades Delphi a partir do BD
- **Column Encryption** — `[Criptografado]` com XOR cipher
- **Views/Stored Procs** — Mapeamento via `[View]` e `[StoredProc]`
- **Dual Licensing** — MIT (Community) + Comercial (Enterprise)

## Projetos

| Projeto | Tipo | Descrição |
|---|---|---|
| `MinusFramework_Runtime.dpk` | BPL | Runtime package do ORM |
| `MinusFramework_Design.dpk` | BPL | Design-time package |
| `MinusMigrator_DLL.dpr` | DLL | Migrator como biblioteca stdcall |
| `MinusMigrator_CLI.dpr` | EXE | CLI do Migrator |
| `MinusMigrator_GUI.dpr` | VCL App | GUI do Migrator |
| `Test.ORM` | EXE (DUnitX) | Testes do núcleo ORM |
| `Test.Migrator` | EXE (DUnitX) | Testes do Migrator |
| `MinusMessaging_Runtime.dpk` | BPL | Runtime package de mensageria |
| `MinusDemo` | EXE | Aplicação de exemplo |

## Estrutura

```
Source/
├── Bibliotecas/                   # Código compartilhado entre projetos (canônico)
│   ├── MF.Connection.pas          # Interfaces IConexao, IComando, IResultados, etc.
│   ├── MF.Types.pas               # Enums, records, TParametrosConexao
│   ├── MF.Exceptions.pas          # Exceções base
│   ├── MF.Provider.pas            # Registry de providers
│   ├── MF.Config.pas              # TConfiguracaoORM (conexões nomeadas + cache)
│   └── Providers/                 # Implementações FireDAC
│       ├── MF.Provider.FireDAC.pas
│       └── MF.Provider.FireDAC.*.pas
├── Core/                          # Núcleo do ORM
│   ├── MF.Attributes.pas          # Atributos de mapeamento
│   ├── MF.Mapper.pas              # Mapeador RTTI IResultSet → objeto
│   ├── MF.IdGenerator.pas         # Estratégias de geração de ID
│   ├── MF.Criteria.pas            # Criteria API (ICriterio, operadores, subqueries)
│   ├── MF.QueryBuilder.pas        # SQL helpers, TConstrutorAtualizacao<T>, TConstrutorExclusao<T>
│   ├── MF.SelectBuilder.pas       # TConstrutorSelecao<T> (API unificada de SELECT)
│   ├── MF.IdentityMap.pas         # Cache de 1º nível
│   ├── MF.ChangeTracker.pas       # Snapshot + dirty checking
│   ├── MF.UnitOfWork.pas          # TUnidadeTrabalho
│   └── MF.RepositoryBase.pas      # TRepositorioBase<T> genérico
├── Extensions/
│   ├── MF.Extensions.SoftDelete.pas    # Exclusão lógica
│   ├── MF.Extensions.Cache.pas         # Cache 2º nível com TTL e regiões
│   ├── MF.Extensions.UniqueKey.pas     # Validação de chave única
│   ├── MF.Extensions.Relacionamento.pas # Injeção de conexão para lazy loading
│   ├── MF.Extensions.Bulk.pas          # Operações em lote (insert/update/delete)
│   ├── MF.Extensions.Concorrencia.pas  # Lock otimista via versão
│   ├── MF.Extensions.Sombra.pas        # Shadow properties (CriadoEm/AtualizadoEm)
│   └── MF.Extensions.Audit.pas         # Auditoria (CriadoPor/AtualizadoPor + audit trail)
├── Migrator/                     # MinusMigrator
│   ├── MF.Migrator.Types.pas
│   ├── MF.Migrator.SchemaReader.pas         # + SQLite, Firebird, PostgreSQL, MySQL, MariaDB, MSSQL, Oracle
│   ├── MF.Migrator.SQLGenerator.pas         # + SQLite, Firebird, PostgreSQL, MySQL, MariaDB, MSSQL, Oracle
│   ├── MF.Migrator.SchemaDiffer.pas
│   ├── MF.Migrator.EntityReader.pas
│   ├── MF.Migrator.Runner.pas
│   ├── MF.Migrator.Commands.pas
│   ├── MF.Migrator.Utils.pas
│   ├── MF.Migrator.Changelog.pas
│   ├── MF.Migrator.CLI.pas
│   ├── MF.Migrator.GUI.MainForm.pas
│   └── MF.Migrator.API.pas
├── Messaging/                    # MinusMessaging
│   ├── MF.Messaging.Types.pas
│   ├── MF.Messaging.Config.pas
│   ├── MF.Messaging.Serialization.pas
│   ├── MF.Messaging.Core.pas
│   ├── Reliability/
│   │   └── MF.Messaging.Reliability.pas
│   └── Providers/
│       └── MF.Messaging.Provider.InMemory.pas
```

## Quick Start

### 1. Definir Entidade

```pascal
type
  [Tabela('PRODUTO')]
  [Cache(300, 'produtos')]
  TProduto = class
  private
    [ChavePrimaria]
    [Coluna('ID')]
    FId: Integer;
    [Coluna('NOME')]
    [NotNull]
    FNome: string;
    [Coluna('PRECO_VENDA')]
    FPrecoVenda: Currency;
    [Versao('VERSAO', 1)]
    FVersao: Integer;
    [Ignorar]
    FCalculado: string;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property PrecoVenda: Currency read FPrecoVenda write FPrecoVenda;
    property Versao: Integer read FVersao write FVersao;
  end;
```

### 2. Configurar Conexão

```pascal
var
  LParams: TParametrosConexao;
begin
  LParams := TParametrosConexao.Create('FB', 'C:\dados\banco.fdb',
    'SYSDBA', 'masterkey', 'localhost', 3050);
  TConfiguracaoORM.RegistrarConexaoComParametros('default', LParams);
end;
```

### 3. CRUD Básico

```pascal
var
  LRepo: TRepositorioBase<TProduto>;
  LProduto: TProduto;
  LLista: TObjectList<TProduto>;
begin
  LRepo := TRepositorioBase<TProduto>.Create(
    TConfiguracaoORM.ConexaoPadrao);

  // Inserir
  LProduto := TProduto.Create;
  LProduto.Nome := 'Produto A';
  LProduto.PrecoVenda := 29.90;
  LRepo.Salvar(LProduto);

  // Buscar por ID
  LProduto := LRepo.BuscarPorId(1);

  // Listar todos
  LLista := LRepo.BuscarTodos;

  // Atualizar
  LProduto.Nome := 'Produto A (editado)';
  LRepo.Salvar(LProduto);

  // Excluir
  LRepo.Excluir(1);
end;
```

### 4. Consultas Fluentes com Criteria API

```pascal
// WHERE simples
var
  LLista: TObjectList<TProduto>;
begin
  LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
    .Onde(Criterio('NOME').Igual('Produto A'))
    .Onde(Criterio('PRECO_VENDA').MaiorQue(10))
    .OrdenarPor('NOME')
    .ParaLista;

  // API alternativa (GROUP BY, HAVING, ORDER BY Asc/Desc):
  LLista := TRepositorioORM<TProduto>.Select(FConexao)
    .Fields.Add('NOME').Add('PRECO_VENDA')
    .Where.Add('PRECO_VENDA', 10.0)
    .OrderBy('NOME').Asc
    .ParaLista;
end;

// OR / AND / NOT
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(OuCriterios([
    Criterio('NOME').Igual('Alpha'),
    Criterio('NOME').Igual('Gamma')
  ]))
  .ParaLista;

// EXISTS / NOT EXISTS
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Existe(
    TRepositorioORM<TItem>.Consulta(FConexao)
      .Onde(Criterio('PRODUTO_ID').EmSubconsulta(
        TRepositorioORM<TProduto>.Consulta(FConexao, ['ID']).ComoSubconsulta))
      .SQL
  ))
  .ParaLista;

// IN (subconsulta)
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Criterio('ID').EmSubconsulta(
    TRepositorioORM<TItem>.Consulta(FConexao, ['PRODUTO_ID']).SQL
  ))
  .ParaLista;

// LIKE, BETWEEN, IS NULL
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Criterio('NOME').Como('%prod%'))
  .Onde(Criterio('PRECO_VENDA').Entre(10, 100))
  .Onde(Criterio('DESCRICAO').NaoEhNulo)
  .ParaLista;
```

### 5. Unit of Work + Change Tracking

```pascal
var
  LUoW: TUnidadeTrabalho;
  LProduto1, LProduto2: TProduto;
begin
  LUoW := TUnidadeTrabalho.Create(FConexao);
  try
    LProduto1 := TProduto.Create;
    LProduto1.Nome := 'Novo';
    LUoW.RegistrarNovo(LProduto1);

    LProduto2 := LRepositorio.BuscarPorId(5);
    LProduto2.Nome := 'Editado';
    LUoW.RegistrarSujo(LProduto2);

    LUoW.RegistrarExcluido(LRepositorio.BuscarPorId(10));

    LUoW.Confirmar; // DELETE → INSERT → UPDATE em transação única
  finally
    LUoW.Free;
  end;
end;
```

## Atributos

| Atributo | Alvo | Descrição |
|---|---|---|
| `[Tabela('NOME')]` | Classe | Nome da tabela |
| `[Coluna('NOME')]` | Propriedade | Nome da coluna |
| `[ChavePrimaria]` | Propriedade | Chave primária |
| `[Ignorar]` | Propriedade | Campo transiente (não persiste) |
| `[NotNull]` | Propriedade | Validação de campo obrigatório |
| `[ReadOnly]` | Propriedade | Campo somente leitura (não incluído em INSERT/UPDATE) |
| `[Versao('coluna', 1)]` | Propriedade | Lock otimista — incrementa a cada UPDATE |
| `[Cache(TTL, 'regiao')]` | Classe | Cache 2º nível |
| `[SoftDelete('coluna', tesBooleano)]` | Classe | Exclusão lógica |
| `[ChaveUnica('grupo', ['COL1','COL2'])]` | Classe | Unique key composta |
| `[Relacionamento(trPertenceA, 'FK', 'PK')]` | Propriedade | Navigation property |
| `[ChaveEstrangeira('NOME')]` | Propriedade | Nome da FK |
| `[CriadoEm]` | Propriedade | Shadow: setado automaticamente no INSERT |
| `[AtualizadoEm]` | Propriedade | Shadow: setado automaticamente no INSERT e UPDATE |
| `[CriadoPor]` | Propriedade | Audit: setado com `UsuarioCorrente` no INSERT |
| `[AtualizadoPor]` | Propriedade | Audit: setado com `UsuarioCorrente` no INSERT e UPDATE |

## Extensions

### SoftDelete

```pascal
[Tabela('PRODUTO')]
[SoftDelete('EXCLUIDO', tesBooleano)]
TProduto = class
  [Coluna('EXCLUIDO')]
  FExcluido: Integer;
end;
```
- Consultas geram automaticamente `WHERE (EXCLUIDO IS NULL OR EXCLUIDO = 0)`
- `Excluir()` vira `UPDATE ... SET EXCLUIDO = 1 WHERE ID = :id`

### UniqueKey

```pascal
[Tabela('PRODUTO')]
[ChaveUnica('uk_nome', ['NOME'])]
TProduto = class ... end;
```
- `Salvar()` valida duplicidade antes de INSERT/UPDATE
- Suporta chaves compostas: `[ChaveUnica('uk_doc', ['CPF', 'TIPO'])]`

### Bulk

```pascal
var
  LIds: TArray<Integer>;
begin
  LIds := Repo.InserirEmLote(MinhaListaDeEntidades);
  Repo.AtualizarEmLote(MinhaLista);
  Repo.ExcluirEmLote([1, 2, 3]);
end;
```

### Concorrência

```pascal
[Versao('VERSAO', 1)]
FVersao: Integer;
```
- `UPDATE ... SET VERSAO = VERSAO + 1 WHERE ID = :id AND VERSAO = :versao`
- Se `RowsAffected = 0`, lança `EErroConcorrencia`

### Shadow Properties

```pascal
[Coluna('DATA_CRIACAO')]
[CriadoEm]
FDataCriacao: TDate;

[Coluna('DATA_ALTERACAO')]
[AtualizadoEm]
FDataAlteracao: TDate;
```
- `CriadoEm`: setado com `Now` no INSERT
- `AtualizadoEm`: setado com `Now` no INSERT e UPDATE

### Audit

```pascal
[Coluna('CRIADO_POR')]
[CriadoPor]
FCriadoPor: string;

[Coluna('ATUALIZADO_POR')]
[AtualizadoPor]
FAtualizadoPor: string;
```
- Usa `TAjudanteAuditoria.UsuarioCorrente` (threadvar)
- Audit trail: insere na tabela `auditoria`:
  `entidade, entidade_id, acao, valores_antigos, valores_novos, usuario, data_hora`

## Suporte a Banco de Dados

| Banco | Provider FireDAC | Schema Reader | SQL Generator |
|---|---|---|---|---|
| SQLite | SQLite | `SchemaReader.SQLite.pas` | `SQLGenerator.SQLite.pas` |
| Firebird | FB | `SchemaReader.Firebird.pas` | `SQLGenerator.Firebird.pas` |
| PostgreSQL | PG | `SchemaReader.PostgreSQL.pas` | `SQLGenerator.PostgreSQL.pas` |
| MySQL | MySQL | `SchemaReader.MySQL.pas` | `SQLGenerator.MySQL.pas` |
| MariaDB | MySQL | `SchemaReader.MariaDB.pas` (herda MySQL) | `SQLGenerator.MariaDB.pas` (herda MySQL) |
| MSSQL | MSSQL | `SchemaReader.MSSQL.pas` | `SQLGenerator.MSSQL.pas` |
| Oracle | Oracle | `SchemaReader.Oracle.pas` | `SQLGenerator.Oracle.pas` |

## Instalação

1. Abra `Packages\MinusFramework_Runtime.dpk` no RAD Studio
2. Compile o package
3. Adicione a BPL ao projeto consumidor
4. Adicione `Source\Bibliotecas`, `Source\Bibliotecas\Providers`, `Source\Core` e `Source\Extensions` ao search path

## MinusMigrator

CLI + GUI + DLL para migração versionada de schema:

```
MinusMigrator_CLI.exe init -c "sqlite://./app.db"
MinusMigrator_CLI.exe migrate -c "sqlite://..." -p .\migrations [--context ctx] [--dry-run]
MinusMigrator_CLI.exe status -c "sqlite://..." -p .\migrations [--format json|yaml]
MinusMigrator_CLI.exe rollback -c "sqlite://..." -p .\migrations [-n 2] [--tag nome]
MinusMigrator_CLI.exe tag "versao_1.0" -c "sqlite://..."
MinusMigrator_CLI.exe add-migration "desc" -c "sqlite://..." -e .\entities [-p .\migrations]
MinusMigrator_CLI.exe generate-models -c "sqlite://..." -o .\models [-ns MeuProjeto]
MinusMigrator_CLI.exe auto-migrate -c "sqlite://..." -e .\entities [--dry-run] [--force]
MinusMigrator_CLI.exe diff-changelog -c "sqlite://..." -e .\entities [-f xml|json]
MinusMigrator_GUI.exe    (interface gráfica)
```

Também disponível como DLL (`MinusMigrator.dll`) com exports `Migrator_Execute`, `Migrator_GetLastError`, `Migrator_Status`.

## 📊 Comparativo de Mercado

Cada solução do MinusFramework compete com ferramentas consolidadas no mercado. Veja o resumo:

| Solução | Principal Concorrente | Diferencial MinusFramework |
|---------|----------------------|---------------------------|
| **MinusORM** | TMS Aurelius ($195/dev), EntityDAC ($199/dev) | Open source (MIT) mais completo em features (cache 2º nível, soft delete, audit, shadow properties, bulk, unique key) |
| **MinusMigrator** | Flyway, Liquibase | Único migrador nativo Delphi com CLI + GUI + DLL; 7 bancos; geração de modelos; diff changelog |
| **MinusFeatureFlags** | LaunchDarkly ($200/mês), Unleash | Único SDK Delphi nativo offline; avaliação local sem latência de rede; integração com ORM |
| **MinusRest** | Horse (standalone), RAD Server ($1.999) | Middleware integrado com ORM + Feature Flags + Multi-tenancy |
| **MinusMessaging** | Redis/MQ puro, RabbitMQ.Delphi, Kafka.Delphi | Framework unificado multi-provider com retry, DLQ, outbox, sagas, circuit breaker e dashboard REST |

> 📊 [Análise competitiva detalhada →](Docs/COMPARATIVO_MERCADO.md)
