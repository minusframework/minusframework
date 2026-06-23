# MinusFramework — Documentação Técnica

> **Versão:** 2.1
> **Última atualização:** 11/Junho/2026 (Sprint 4 — ArrayDML)
> **Plataforma:** Windows 32/64-bit
> **Banco de dados:** Firebird, PostgreSQL, SQLite, MySQL, MariaDB, MSSQL, Oracle
> **IDE:** Delphi 11 Alexandria+
> **Dependência externa:** FireDAC (RAD Studio)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura](#2-arquitetura)
3. [Core do ORM](#3-core-do-orm)
4. [Providers (Conexão Multi-Banco)](#4-providers-conexão-multi-banco)
5. [Extensions](#5-extensions)
6. [MinusMigrator](#6-minusmigrator)
7. [DLL APIs](#7-dll-apis)
8. [Testes](#8-testes)
9. [Projetos e Build](#9-projetos-e-build)
10. [Diagrama de Dependências](#10-diagrama-de-dependências)

---

## 1. Visão Geral

O **MinusFramework** é um conjunto integrado de bibliotecas Delphi para desenvolvimento de aplicações com banco de dados. Consiste em três subsistemas principais:

| Subsistema | Descrição | Projetos |
|---|---|---|
| **MinusORM** | ORM com mapeamento via atributos RTTI, Unit of Work, Change Tracking, Identity Map, Criteria API, Query Builders, Repositório genérico | `MinusORM.dll` (DLL), packages BPL |
| **MinusMigrator** | Sistema versionado de migração de schema com SchemaReader, SQLGenerator, Runner, CLI e GUI | `MinusMigrator_CLI.exe`, `MinusMigrator_GUI.exe`, `MinusMigrator.dll` |
| **MinusExtensions** | Extensões plugáveis (SoftDelete, Audit, Cache, Bulk, etc.) | Integradas no ORM via hook system |

### 1.1 Príncipios de Design

- **Provider-agnostic:** Toda comunicação com banco é abstraída via interfaces (`IConexao`, `IComando`, `IResultados`, `IParametro`)
- **RTTI-first:** Mapeamento via atributos customizados (`[Tabela]`, `[Coluna]`, etc.), sem arquivos de mapeamento externos
- **Composição sobre herança:** Extensões são processadores plugáveis, não herança de classes base
- **Testabilidade:** Mock completo das interfaces de banco permite testes unitários sem banco real
- **Standalone:** CLI e DLL não dependem do ORM para funcionar (apenas FireDAC)

---

## 2. Arquitetura

```
┌──────────────────────────────────────────────────────────────┐
│                      APLICAÇÃO CONSUMIDORA                     │
│  (WinForms, Console, Serviço, Outra linguagem via DLL)        │
└──────────────────┬───────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────┐
│                      MINUSFRAMEWORK                           │
│                                                               │
│  ┌─────────────────────┐  ┌──────────────────────────────┐   │
│  │   ORM CORE          │  │   MINUSMIGRATOR               │   │
│  │                     │  │   ┌────────────────────────┐  │   │
│  │  ┌───────────────┐  │  │   │ CLI / GUI / DLL       │  │   │
│  │  │ TRepository   │  │  │   └────────┬───────────────┘  │   │
│  │  │ TUnitOfWork   │  │  │            │                   │   │
│  │  │ TChangeTracker│  │  │   ┌────────▼───────────────┐  │   │
│  │  │ TIdentityMap  │  │  │   │ TComandosMigrador     │  │   │
│  │  │ TMapper       │  │  │   └────────┬───────────────┘  │   │
│  │  └───────┬───────┘  │  │            │                   │   │
│  │          │           │  │   ┌────────▼───────────────┐  │   │
│  │  ┌───────▼───────┐  │  │   │ TExecutorMigracao     │  │   │
│  │  │ TQueryBuilder  │  │  │   └────────┬───────────────┘  │   │
│  │  │ TSelectBuilder │  │  │            │                   │   │
│  │  │ TInsertBuilder │  │  │   ┌────────┴────────┐         │   │
│  │  │ TUpdateBuilder │  │  │   │                │          │   │
│  │  │ TDeleteBuilder │  │  │   ▼                ▼          │   │
│  │  └───────┬───────┘  │  │   ILeitorEsquema  IGeradorSQL  │   │
│  │          │           │  │         │                │     │   │
│  │  ┌───────▼───────┐  │  │   ┌─────┴─────┐  ┌───────┴──┐  │   │
│  │  │ TCriteria     │  │  │   │ SQLite    │  │ SQLite   │  │   │
│  │  │ TExpression   │  │  │   │ Firebird  │  │ Firebird │  │   │
│  │  │ TProcBuilder  │  │  │   │ PostgreSQL│  │ PG       │  │   │
│  │  └───────┬───────┘  │  │   │ MySQL     │  │ MySQL    │  │   │
│  │          │           │  │   │ MariaDB   │  │ MariaDB  │  │   │
│  │  ┌───────▼───────┐  │  │   │ MSSQL     │  │ MSSQL    │  │   │
│  │  │ TMetadataCache │  │  │   │ Oracle    │  │ Oracle   │  │   │
│  │  │ TTypeConverter │  │  │   └───────────┘  └──────────┘  │   │
│  │  │ TIdGenerator   │  │  │                                │   │
│  │  └───────┬───────┘  │  │  ┌──────────────────────────┐   │   │
│  │          │           │  │  │ TSchemaDiffer            │   │   │
│  │  ┌───────▼───────┐  │  │  │ TEntityReader            │   │   │
│  │  │ EXTENSIONS    │  │  │  │ TChangelog               │   │   │
│  │  │ (hooks)       │  │  │  └──────────────────────────┘   │   │
│  │  └───────────────┘  │  │                                │   │
│  └──────────┬──────────┘  └────────────────────────────────┘   │
│             │                                                   │
│  ┌──────────▼──────────────────────────────────────────────────┐│
│  │                 IConexao / IComando / IResultados           ││
│  │                       (Interfaces de Abstração)             ││
│  └──────────┬──────────────────────────────────────────────────┘│
│             │                                                   │
│  ┌──────────▼──────────────────────────────────────────────────┐│
│  │              FireDAC Provider (concreto)                     ││
│  │  TConexaoFireDAC / TComandoFireDAC / TTransacaoFireDAC      ││
│  │                                                              ││
│  │  ┌──────────┬──────────┬──────────┬──────────┬──────────┐   ││
│  │  │ Firebird │ Postgres │  SQLite  │  MySQL   │  MSSQL   │   ││
│  │  │ Provider │ Provider │ Provider │ Provider │ Provider │   ││
│  │  └──────────┴──────────┴──────────┴──────────┴──────────┘   ││
│  └──────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Core do ORM

### 3.1 Hierarchy de Interfaces de Banco

Toda comunicação com banco passa pelas interfaces em `MF.Connection.pas`:

```
IConexao ─── cria ─── IComando ─── executa ─── IResultados
                │                      │
                │                      └── ICampo (field access)
                └── ITransacao (begin/commit/rollback)
```

**Implementação concreta:** `TConexaoFireDAC`, `TComandoFireDAC`, `TTransacaoFireDAC` em `MF.Provider.FireDAC.pas`.

### 3.2 Registry de Providers

`TRegistroProvedores` em `MF.Provider.pas` implementa Service Locator. Cada provider (SQLite, Firebird, etc.) registra uma fábrica:

```pascal
TRegistroProvedores.Registrar('sqlite', TFabricaConexaoSQLite.Create);
```

A criação é feita via `TRegistroProvedores.CriarConexao(Params)` que instancia a conexão correta baseada no `DriverName`.

### 3.3 Mapeamento RTTI

**`MF.Attributes.pas`** define todos os atributos de mapeamento:

| Atributo | Alvo | Parâmetros |
|---|---|---|
| `TabelaAttribute` | Classe | Nome da tabela |
| `ColunaAttribute` | Propriedade | Nome da coluna, tamanho máximo |
| `ChavePrimariaAttribute` | Propriedade | (sem parâmetros) |
| `ChaveEstrangeiraAttribute` | Propriedade | Nome da FK |
| `AutoIncrementoAttribute` | Propriedade | (sem parâmetros) |
| `IgnorarAttribute` | Propriedade | (sem parâmetros) |
| `NotNullAttribute` | Propriedade | (sem parâmetros) |
| `ReadOnlyAttribute` | Propriedade | (sem parâmetros) |
| `VersaoAttribute` | Propriedade | Nome coluna, valor inicial |
| `CacheAttribute` | Classe | TTL segundos, região |
| `SoftDeleteAttribute` | Classe | Coluna, tipo (boolean/integer/datetime) |
| `ChaveUnicaAttribute` | Classe | Nome do grupo, array de colunas |
| `RelacionamentoAttribute` | Propriedade | Tipo (pertenceA/temUm/temMuitos), FK, PK |
| `CriadoEmAttribute` | Propriedade | (sem parâmetros) |
| `AtualizadoEmAttribute` | Propriedade | (sem parâmetros) |
| `CriadoPorAttribute` | Propriedade | (sem parâmetros) |
| `AtualizadoPorAttribute` | Propriedade | (sem parâmetros) |
| `DiscriminadorAttribute` | Classe | Nome coluna, mapeamentos |

**`MF.Mapper.pas`** — `TMapeador` converte `IResultados` em objetos via RTTI. Usa `TCacheMetadados` (MF.MetadataCache.pas) para evitar reflexão repetida.

**`MF.MetadataCache.pas`** — `TCacheMetadados` cacheia por classe:
- Nome da tabela
- Colunas mapeadas (com atributos)
- Chave primária
- Foreign keys
- Version info (concorrência)
- Soft-delete config

### 3.4 Query Builders

| Builder | Arquivo | Propósito |
|---|---|---|
| `TSelecaoBuilder<T>` | MF.SelectBuilder.pas | SELECT com JOIN, WHERE, ORDER BY, paginação, GROUP BY |
| `TConstrutorInsercao<T>` | MF.InsertBuilder.pas | INSERT com auto-generated keys |
| `TAtualizacaoBuilder<T>` | MF.UpdateBuilder.pas | UPDATE com WHERE |
| `TExclusaoBuilder<T>` | MF.DeleteBuilder.pas | DELETE (ou soft-delete) |
| `TConstrutorProcedimento` | MF.ProcBuilder.pas | Stored procedures |
| `TConstrutorConsulta<T>` | MF.QueryBuilder.pas | Coordena todos os builders, executa CRUD |

**`TConstrutorConsulta<T>`** é o ponto central de execução:
1. Aplica hooks das extensions (pré/pós Insert/Update/Delete/Read)
2. Gerencia Identity Map (evita duplicatas em memória)
3. Invalida cache de 2º nível em writes
4. Suporta lazy loading navigation properties

### 3.5 Criteria API

**`MF.Criteria.pas`** — `TCriterio` com operadores:
- `Igual`, `Diferente`, `MaiorQue`, `MenorQue`, `MaiorOuIgual`, `MenorOuIgual`
- `Como` (LIKE), `Entre` (BETWEEN), `Em` (IN), `NaoEm` (NOT IN)
- `EhNulo`, `NaoEhNulo`
- `EmSubconsulta` (IN subquery), `Existe`, `NaoExiste`

**`MF.Expression.pas`** — `TCondicaoCampo` fluent API:
```pascal
Campo('NOME').Igual('Joao').E(Campo('IDADE').MaiorQue(18))
```

Combinadores: `E(todos)`, `Ou(qualquer)`, `Nao`.

### 3.6 Unit of Work

**`MF.UnitOfWork.pas`** — `TUnidadeTrabalho`:
- `RegistrarNovo(entidade)` — marca INSERT
- `RegistrarSujo(entidade)` — marca UPDATE (dirty detection automático)
- `RegistrarExcluido(entidade)` — marca DELETE
- `Confirmar` — executa tudo em transação: DELETE → INSERT → UPDATE (ordem otimizada)
- `Reverter` — descarta pendências

**`MF.ChangeTracker.pas`** — `TRastreadorMudancas`:
- `TirarSnapshot(objeto)` — salva estado atual
- `ObterCamposModificados(objeto)` — retorna diferenças
- Suporta rastreamento por propriedade com `oldValue/newValue`

**`MF.IdentityMap.pas`** — `TMapaIdentidade`:
- Cache classe/id → instância
- `Obter<T>(id)` — retorna se existir
- `Armazenar(objeto)` — adiciona ao cache
- `Limpar` / `LimparPorClasse`

### 3.7 Repository

**`MF.RepositoryBase.pas`** — `TRepositorioBase<T>`:
```pascal
Salvar(entidade): Integer      // INSERT ou UPDATE automático
BuscarPorId(id): T
BuscarTodos: TObjectList<T>
Excluir(id)
Excluir(entidade)
Consulta: TSelecaoBuilder<T>   // Criteria API
Select: TSelecaoBuilder<T>     // Fluent Select Builder
InserirEmLote(lista): TArray<Integer>
AtualizarEmLote(lista)
ExcluirEmLote(ids)
```
Usa UoW internamente para operações atômicas.

### 3.8 Outros Componentes do Core

| Unit | Classe | Propósito |
|---|---|---|
| MF.Lazy.pas | `TLazy<T>` | Proxy para lazy loading de associações |
| MF.IdGenerator.pas | `IGeradorId`, `TFabricaGeradorId` | Estratégia de geração de ID por provider |
| MF.TypeConverter.pas | `ITypeConverter`, `TRegistroConversores` | Conversão de tipos Delphi ↔ SQL |
| MF.Transaction.pas | `ITransacaoGerenciada` | Interface de transação gerenciada |
| MF.Extensao.Core.pas | `IProcessador*` interfaces | Hooks de ciclo de vida para extensions |
| MF.Infra.Connection.pas | `TConexaoInfra` | Wrapper de conexão com savepoints aninhados |
| MF.DLLAPI.pas | Funções `ORM_*` | Flat C API exports (MinusORM.dll) |

---

## 4. Providers (Conexão Multi-Banco)

### 4.1 Arquitetura

`MF.Provider.FireDAC.pas` implementa as interfaces `IConexao`, `IComando`, `ITransacao`, `IResultados`, `ICampo` usando TFDConnection/TFDQuery/TFDTransaction.

Cada banco tem sua própria fábrica que registra o driver:

| Provider | Arquivo | Driver FireDAC |
|---|---|---|
| SQLite | MF.Provider.FireDAC.SQLite.pas | SQLite |
| Firebird | MF.Provider.FireDAC.Firebird.pas | FB |
| PostgreSQL | MF.Provider.FireDAC.PostgreSQL.pas | PG |
| MySQL | MF.Provider.FireDAC.MySQL.pas | MySQL |

(Novos providers como MSSQL e Oracle usam o driver ODBC ou nativo FireDAC correspondente, registrados na mesma fábrica.)

### 4.2 Connection String URI

Formato padronizado:

```
<driver>://<host>:<porta>/<database|service>?user=<user>&password=<pass>&params...
```

Exemplos:
```
sqlite://C:\dados\app.db
firebird://localhost:3050/C:/dados/banco.fdb?user=SYSDBA&password=masterkey
postgresql://localhost:5432/mydb?user=postgres&password=123
mysql://localhost:3306/mydb?user=root&password=123
mssql://localhost:1433/mydb?user=sa&password=123
oracle://localhost:1521/XEPDB1?user=system&password=123
mariadb://localhost:3307/mydb?user=root&password=123
```

---

## 5. Extensions

### 5.1 Sistema de Extensões (Hooks)

Definido em `MF.Extensao.Core.pas`:

```pascal
IProcessadorInsercao = interface
  procedure ProcessarAntes(AEntidade: TObject; var AQuery: string; AParams: IComando);
  procedure ProcessarDepois(AEntidade: TObject; AIdGerado: TValue);
end;
```

Analogamente para Update, Delete e Read.

Extensions são registradas em `TConfiguracaoORM.RegistrarProcessador(...)` e executadas pelo `TConstrutorConsulta<T>` em ordem.

### 5.2 Extensões Implementadas

| Extensão | Unit | Interface | Funcionalidade |
|---|---|---|---|
| **SoftDelete** | MF.Extensions.SoftDelete.pas | `IProcessadorExclusao`, `IProcessadorLeitura` | Marca registro como excluído em vez de deletar; filtra automaticamente em consultas |
| **Audit** | MF.Extensions.Audit.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao`, `IProcessadorExclusao` | Insere na tabela `AUDITORIA` com old/new values, usuário, data/hora |
| **Cache** | MF.Extensions.Cache.pas | (via `ICacheProvedor`) | Cache de 2º nível em memória com TTL, regiões e invalidação automática |
| **Shadow** | MF.Extensions.Sombra.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao` | Seta `CriadoEm`/`AtualizadoEm`, `CriadoPor`/`AtualizadoPor` |
| **UniqueKey** | MF.Extensions.UniqueKey.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao` | Valida chave única antes de INSERT/UPDATE |
| **Concorrência** | MF.Extensions.Concorrencia.pas | `IProcessadorAtualizacao` | Lock otimista via versão: `UPDATE ... WHERE version = :old` |
| **Bulk** | MF.Extensions.Bulk.pas | (métodos diretos no Repository) | `InserirEmLote<T>` com ArrayDML (FireDAC, 1 round-trip, 10-50x ganho); fallback para multi-INSERT com RETURNING ou transação linha-a-linha |
| **Relacionamento** | MF.Extensions.Relacionamento.pas | (pós-carregamento) | Carregamento automático de navigation properties |

---

## 6. MinusMigrator

### 6.1 Arquitetura Geral

```
┌──────────────────────────────────────────────────────────────┐
│   CLI (MF.Migrator.CLI) / GUI (MF.Migrator.GUI.MainForm)    │
│   DLL (MF.Migrator.API)                                      │
├──────────────────────────────────────────────────────────────┤
│                    TComandosMigrador                          │
│   (init, migrate, rollback, status, tag, add-migration,      │
│    auto-migrate, generate-models, diff-changelog)            │
├──────────────────────────────────────────────────────────────┤
│                    TExecutorMigracao                          │
│   (control table, lock, checksums, repeatable, contexts)     │
├──────────────────────┬───────────────────────────────────────┤
│   ILeitorEsquema     │   IGeradorSQL                         │
│   TLeitorEsquemaBase │   TGeradorSQLBase                     │
│   ├─ SQLite          │   ├─ SQLite                           │
│   ├─ Firebird        │   ├─ Firebird                         │
│   ├─ PostgreSQL      │   ├─ PostgreSQL                       │
│   ├─ MySQL           │   ├─ MySQL                            │
│   ├─ MariaDB         │   ├─ MariaDB                          │
│   ├─ MSSQL           │   ├─ MSSQL                            │
│   └─ Oracle          │   └─ Oracle                           │
├──────────────────────┴───────────────────────────────────────┤
│   TComparadorEsquema (SchemaDiffer)                          │
│   TLeitorEntidade (EntityReader)                              │
│   TSerializadorChangelog (JSON/XML)                           │
│   TMinusMigratorUtils (checksums, file listing)               │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 Schema Reader

`ILeitorEsquema` (MF.Migrator.SchemaReader.pas) lê o schema atual do banco:

```pascal
type
  ILeitorEsquema = interface
    function NomeProvedor: string;
    function LerEsquema: TEsquemaBancoDados;
  end;
```

Cada provider implementa sua própria leitura via system views/catalog do banco:

| Provider | Fontes de Dados |
|---|---|
| SQLite | `sqlite_master`, `PRAGMA table_info`, `PRAGMA foreign_key_list` |
| Firebird | `RDB$RELATIONS`, `RDB$RELATION_FIELDS`, `RDB$INDICES`, `RDB$REF_CONSTRAINTS` |
| PostgreSQL | `information_schema.tables`, `information_schema.columns`, `pg_catalog` |
| MySQL | `INFORMATION_SCHEMA.TABLES`, `INFORMATION_SCHEMA.COLUMNS`, `INFORMATION_SCHEMA.KEY_COLUMN_USAGE` |
| MariaDB | Herda de MySQL (100% compatível para schema reading) |
| MSSQL | `sys.tables`, `sys.columns`, `sys.indexes`, `INFORMATION_SCHEMA` |
| Oracle | `USER_TABLES`, `USER_TAB_COLUMNS`, `USER_CONSTRAINTS`, `USER_IND_COLUMNS` |

### 6.3 SQL Generator

`IGeradorSQL` produz DDL específico por provider:

```pascal
type
  IGeradorSQL = interface
    function NomeProvedor: string;
    function GerarCriarTabela(const Tabela: TEsquemaTabela): string;
    function GerarAlterarTabela(const Alteracao: TAlteracaoEsquema): TArray<string>;
    function GerarDropTabela(const Nome: string): string;
    function TipoColunaSQL(const Coluna: TEsquemaColuna): string;
  end;
```

Particularidades de cada provider:

| Provider | Auto-increment | Quoting | Tipos especiais |
|---|---|---|---|
| SQLite | `AUTOINCREMENT` | Sem quotes | `TEXT` para strings, recreates table em ALTER |
| Firebird | Generator + Trigger | Sem quotes | `BLOB SUB_TYPE TEXT`, GENERATOR |
| PostgreSQL | `SERIAL`/`BIGSERIAL` | `"name"` | `TEXT`, `BOOLEAN`, `TIMESTAMPTZ` |
| MySQL/MariaDB | `AUTO_INCREMENT` | `` `name` `` | `ENGINE=InnoDB`, `CHARSET=utf8` |
| MSSQL | `IDENTITY(1,1)` | `[name]` | `NVARCHAR`, `DATETIME2`, `DROP COLUMN`, `ALTER COLUMN` |
| Oracle | `NUMBER(10)` + ID manual | `"name"` | `VARCHAR2`, `BINARY_FLOAT`, `BINARY_DOUBLE`, `RAW(16)`, `NUMBER(1)→Boolean` |

### 6.4 Schema Differ

`TComparadorEsquema` (MF.Migrator.SchemaDiffer.pas) compara dois `TEsquemaBancoDados`:
- Tabelas novas/removidas
- Colunas novas/removidas/alteradas (tipo, tamanho, nullable)
- Índices novos/removidos
- Foreign keys novas/removidas

Produz `TArray<TAlteracaoEsquema>` com operações de:
- `tcCriarTabela`, `tcRemoverTabela`
- `tcAdicionarColuna`, `tcRemoverColuna`, `tcAlterarColuna`
- `tcAdicionarIndice`, `tcRemoverIndice`
- `tcAdicionarChaveEstrangeira`, `tcRemoverChaveEstrangeira`
- `tcAlterarPrimaryKey`

### 6.5 Entity Reader

`TLeitorEntidade` (MF.Migrator.EntityReader.pas) lê arquivos `.pas` com entidades anotadas e extrai `TEsquemaBancoDados` equivalente:
- Busca atributos `[Tabela('...')]`, `[Coluna('...')]`, `[ChavePrimaria]`, etc.
- Parse textual (não compila), funciona em qualquer .pas bem formatado
- Usado por `add-migration` e `auto-migrate`

### 6.6 Runner

`TExecutorMigracao` (MF.Migrator.Runner.pas) é o motor central:

**Control Table:** `__MINUSMIGRATOR_MIGRATIONS`
- Tabela criada automaticamente no `Inicializar`
- Colunas: ID, NAME, BATCH, EXECUTED_AT, CHECKSUM, DURATION_MS

**Lock Table:** `__MINUSMIGRATOR_LOCK`
- Prevenção de concorrência entre processos
- INSERT com PK única (falha = outro processo rodando)
- Adquirido em `migrate` e `auto-migrate`, liberado ao final

**Tag Table:** `__MINUSMIGRATOR_TAGS`
- NAME, MIGRATION_ID, CREATED_AT
- Usado para rollback-to-tag

**Fluxo de migração:**
1. `Inicializar` → cria control/lock/tag tables
2. `AdquirirLock` → INSERT na lock table (se falhar, aborta)
3. `ObterPendentes` → lista arquivos `.up.sql` não executados (exclui `R__*`)
4. `ObterRepetiveisPendentes` → lista `R__*.up.sql` com checksum diferente
5. `ExecutarArquivo` → executa SQL, registra na control table
6. `ExecutarRepetivel` → executa SQL, faz UPDATE checksum se já existe
7. `LiberarLock` → DELETE da lock table

**Preconditions:** Suporta:
- `--precondition: tableExists(nome)`
- `--precondition: tableNotExists(nome)`
- `--precondition: columnExists(tabela, coluna)`
- `--precondition: columnNotExists(tabela, coluna)`
- `--precondition: dbms(provider)`

**Contexts:** `--context nome` filtra arquivos para subdiretório.

**Repeatable Migrations:** Arquivos `R__*.up.sql` são executados toda vez que o checksum muda.

**Add-Migration via diff:** Gera `.up.sql` + `.down.sql` com timestamp comparando entidades vs. banco real.

**Auto-Migrate:** Aplica diff direto no banco (sem gerar arquivos), com suporte `--dry-run` e `--force`.

**Changelog:** `TSerializadorChangelog` serializa status em JSON/XML.

### 6.7 CLI

`MF.Migrator.CLI.pas` — entry point `Run`:
```
minusmigrator init -c <conn>
minusmigrator migrate -c <conn> -p <path> [--context <ctx>] [--dry-run]
minusmigrator rollback -c <conn> -p <path> [-n <steps>] [--tag <name>]
minusmigrator status -c <conn> -p <path> [--format json|yaml]
minusmigrator tag <nome> -c <conn>
minusmigrator add-migration <desc> -c <conn> -e <entities> [-p <path>]
minusmigrator generate-models -c <conn> -o <output> [-ns <namespace>]
minusmigrator auto-migrate -c <conn> -e <entities> [--dry-run] [--force]
minusmigrator diff-changelog -c <conn> -e <entities> [-f xml|json]
minusmigrator --help
```

### 6.8 GUI

`MF.Migrator.GUI.MainForm.pas` — `TfrmMigratorGUI`:
- Painel de conexão (connection string, path, context, entities, output, namespace, tag, description)
- StringGrid com status das migrações
- ListBox com arquivos pendentes
- Botões: Connect, Status, Migrate, Rollback, Tag, Add Migration, Auto-Migrate, Generate Models, Dry-Run
- Memo de log com timestamp
- StatusBar com estado da conexão

### 6.9 Diagrama de Classes do Migrator

```
TComandosMigrador (static methods)
│
├── ExecutarInit
├── ExecutarMigracao ← TExecutorMigracao
├── ExecutarReverter ← TExecutorMigracao
├── ExecutarStatus   ← TExecutorMigracao
├── ExecutarTag      ← TExecutorMigracao
├── ExecutarAddMigration ← ILeitorEsquema + IGeradorSQL + TComparadorEsquema
├── ExecutarAutoMigrate  ← ILeitorEsquema + IGeradorSQL + TComparadorEsquema
├── ExecutarGenerateModels ← ILeitorEsquema
└── ExecutarDiffChangelog  ← ILeitorEsquema + IGeradorSQL + TComparadorEsquema

TExecutorMigracao
├── Inicializar (cria tabelas)
├── AdquirirLock / LiberarLock
├── ObterStatus
├── ObterPendentes / ObterRepetiveisPendentes
├── ExecutarArquivo / ExecutarRepetivel / ExecutarPendentes
├── RegistrarEntrada
├── CriarTag / ObterTagID
├── Reverter / ReverterAteTag
└── VerificarPrecondicoes

ILeitorEsquema (interface, implementada por provider)
├── TLeitorEsquemaSQLite
├── TLeitorEsquemaFirebird
├── TLeitorEsquemaPostgreSQL
├── TLeitorEsquemaMySQL
├── TLeitorEsquemaMariaDB (herda MySQL)
├── TLeitorEsquemaMSSQL
└── TLeitorEsquemaOracle

IGeradorSQL (interface, implementada por provider)
├── TGeradorSQLSQLite
├── TGeradorSQLFirebird
├── TGeradorSQLPostgreSQL
├── TGeradorSQLMySQL
├── TGeradorSQLMariaDB (herda MySQL)
├── TGeradorSQLMSSQL
└── TGeradorSQLOracle

TComparadorEsquema
├── Comparar → TArray<TAlteracaoEsquema>
└── InverterAlteracoes → TArray<TAlteracaoEsquema>

TAlteracaoEsquema (record)
├── ChangeType: tcCriarTabela, tcAdicionarColuna, ...
├── TableName, ColumnName, NewType, OldType, ...
└── IndexInfo, FKInfo

TEsquemaBancoDados (record)
└── Tables: TArray<TEsquemaTabela>
    ├── Columns: TArray<TEsquemaColuna>
    ├── Indices: TArray<TEsquemaIndice>
    └── ForeignKeys: TArray<TEsquemaChaveEstrangeira>
```

---

## 7. DLL APIs

### 7.1 MinusORM.dll (`MinusORM.dpr`)

Exports em `MF.DLLAPI.pas`:

```c
// Gerenciamento de conexão
int ORM_Connect(const char* connString);
int ORM_Disconnect(int connId);

// CRUD genérico
int ORM_Insert(int connId, const char* table, const char* jsonData);
int ORM_Update(int connId, const char* table, const char* jsonData, const char* whereJson);
int ORM_Delete(int connId, const char* table, const char* whereJson);
char* ORM_Select(int connId, const char* sql);

// Transações
int ORM_BeginTransaction(int connId);
int ORM_Commit(int connId);
int ORM_Rollback(int connId);

// Utilitários
void ORM_FreeString(char* str);
char* ORM_LastError();
```

### 7.2 MinusMigrator.dll (`MinusMigrator_DLL.dpr`)

Exports em `MF.Migrator.API.pas`:

```c
int Migrator_Execute(const char* command, const char* connection, const char* path, int dryRun);
char* Migrator_GetLastError();
char* Migrator_Status();
```

---

## 8. Testes

### 8.1 Testes do ORM

| Fixture | Unit | Tipo | O que testa |
|---|---|---|---|
| `TTesteMapeador` | Test.ORM.Mapper.pas | Unitário (mock) | Mapeamento RTTI objeto ↔ resultset |
| `TTesteMapaIdentidade` | Test.ORM.IdentityMap.pas | Unitário (mock) | Cache de 1º nível |
| `TTesteRastreadorMudancas` | Test.ORM.ChangeTracker.pas | Unitário (mock) | Snapshot e dirty detection |
| `TTesteCriteria` | Test.ORM.Criteria.pas | Unitário (mock) | Criteria API e geração SQL |
| `TTesteSelectBuilder` | Test.ORM.SelectBuilder.pas | Unitário (mock) | SELECT, JOIN, paginação |
| `TTesteIdGenerator` | Test.ORM.IdGenerator.pas | Unitário (mock) | ID generators |
| `TTesteUnidadeTrabalhoMock` | Test.ORM.UnitOfWork.Mock.pas | Unitário (mock) | UoW tracking |
| `TTesteUnidadeTrabalho` | Test.ORM.UnitOfWork.pas | Integração (SQLite) | UoW transacional |
| `TTesteProviderBase` | Test.ORM.Provider.Base.pas | Abstrato (base) | Common CRUD test template |
| `TTesteProviderSQLite` | Test.ORM.Provider.SQLite.pas | Integração (SQLite) | CRUD SQLite |
| `TTesteProviderFirebird` | Test.ORM.Provider.Firebird.pas | Integração (Firebird) | CRUD Firebird |
| `TTesteProviderPostgreSQL` | Test.ORM.Provider.PostgreSQL.pas | Integração (PG) | CRUD PostgreSQL |
| `TTesteProviderMySQL` | Test.ORM.Provider.MySQL.pas | Integração (MySQL) | CRUD MySQL |
| `TTesteExtensions` | Test.ORM.Extensions.pas | Integração (SQLite) | Todas as extensions |
| `TTesteLazy` | Test.ORM.Lazy.pas | Unitário (mock) | Lazy loading |

### 8.2 Testes do Migrator

| Fixture | Unit | Tipo | O que testa |
|---|---|---|---|
| `TTesteSchemaReaderSQLite` | Test.Migrator.SchemaReader.pas | Integração (SQLite) | Leitura de schema |
| `TTesteSchemaDiffer` | Test.Migrator.SchemaDiffer.pas | Unitário | Comparação de schemas |
| `TTesteSQLGenerator` | Test.Migrator.SQLGenerator.pas | Unitário | Geração DDL |
| `TTesteMigratorRunner` | Test.Migrator.Runner.pas | Integração (SQLite) | Runner + migração |
| `TTesteEntityReader` | Test.Migrator.EntityReader.pas | Unitário | Parse de .pas |

### 8.3 Mocks

`Test.ORM.Mock.pas` fornece implementações completas de todas as interfaces de banco (`IConexao`, `IComando`, `IResultados`, `ICampo`) para testes unitários sem banco real.

### 8.4 Execução

```
Test.MinusORM.exe       → testes ORM
Test.MinusMigrator.exe  → testes Migrator
```

Ambiente via Docker Compose para testes cross-db (Firebird, PostgreSQL, MySQL).

---

## 9. Projetos e Build

### 9.1 Projetos

| Arquivo | Tipo | Saída | Descrição |
|---|---|---|---|
| `MinusORM.dpr` | DLL | `MinusORM.dll` | ORM como DLL com API C |
| `MinusMigrator_CLI.dpr` | Console | `MinusMigrator_CLI.exe` | CLI do migrator |
| `MinusMigrator_GUI.dpr` | VCL App | `MinusMigrator_GUI.exe` | GUI do migrator |
| `MinusMigrator_DLL.dpr` | DLL | `MinusMigrator.dll` | Migrator como DLL |
| `Test.MinusORM.dpr` | Console | `Test.MinusORM.exe` | Testes ORM |
| `Test.MinusMigrator.dpr` | Console | `Test.MinusMigrator.exe` | Testes Migrator |
| `Benchmark.MinimusORM.dpr` | Console | `Benchmark.MinimusORM.exe` | Benchmarks |
| `MinusDemo.dpr` | Console | `MinusDemo.exe` | Exemplo de uso da DLL |

### 9.2 Dependências

```
MinusMigrator_CLI.exe         ─── FireDAC
MinusMigrator_GUI.exe         ─── FireDAC + VCL
MinusMigrator.dll             ─── FireDAC
MinusORM.dll                  ─── FireDAC
Test.MinusORM.exe             ─── FireDAC + DUnitX
Test.MinusMigrator.exe        ─── FireDAC + DUnitX
Benchmark.MinimusORM.exe      ─── FireDAC
MinusDemo.exe                 ─── MinusORM.dll (via LoadLibrary)
```

### 9.3 Source Dirs

```
Source/
├── Bibliotecas/           → Interfaces e registry (MF.Connection, MF.Provider, etc.)
│   └── Providers/         → Implementações FireDAC
├── Core/                  → ORM Core (Mapper, QueryBuilder, UoW, etc.)
├── Extensions/            → Extensões plugáveis
└── Migrator/              → MinusMigrator completo
```

---

## 10. Diagrama de Dependências

```
MF.Attributes ──────────► MF.MetadataCache
     │                          │
     ├──────────────────────────┤
     │                          │
MF.Mapper ◄──────────── MF.MetadataCache
     │
     ├──► MF.TypeConverter
     │
MF.IdGenerator ──────────► MF.Types
MF.Criteria ─────────────► MF.Types
MF.Expression ───────────► MF.Criteria

MF.SelectBuilder ────────► MF.Criteria, MF.Types
MF.InsertBuilder ────────► MF.Types
MF.UpdateBuilder ────────► MF.Criteria, MF.Types
MF.DeleteBuilder ────────► MF.Criteria, MF.Types
MF.ProcBuilder ──────────► MF.Types

MF.QueryBuilder ─────────► (todos os builders) + MF.Mapper + MF.IdentityMap
     │                         + MF.ChangeTracker + MF.Extensao.Core
     │
MF.RepositoryBase ───────► MF.QueryBuilder + MF.UnitOfWork

MF.UnitOfWork ───────────► MF.QueryBuilder + MF.ChangeTracker + MF.IdentityMap
MF.ChangeTracker ────────► MF.Mapper
MF.IdentityMap

MF.Infra.Connection ─────► MF.Connection (wrapping para savepoints)

MF.Extensao.Core ◄─────── (interfaces que extensions implementam)
     │
     ├── MF.Extensions.SoftDelete
     ├── MF.Extensions.Audit
     ├── MF.Extensions.Cache
     ├── MF.Extensions.Sombra
     ├── MF.Extensions.UniqueKey
     ├── MF.Extensions.Concorrencia
     ├── MF.Extensions.Bulk
     └── MF.Extensions.Relacionamento

MF.DLLAPI ───────────────► (tudo acima, compilado na DLL)

─── Camada do Migrador ────

MF.Migrator.Types
MF.Migrator.Utils

MF.Migrator.SchemaReader ◄─── MF.Connection
     ├── MF.Migrator.SchemaReader.SQLite
     ├── MF.Migrator.SchemaReader.Firebird
     ├── MF.Migrator.SchemaReader.PostgreSQL
     ├── MF.Migrator.SchemaReader.MySQL
     ├── MF.Migrator.SchemaReader.MariaDB
     ├── MF.Migrator.SchemaReader.MSSQL
     └── MF.Migrator.SchemaReader.Oracle

MF.Migrator.SQLGenerator ◄─── MF.Migrator.Types
     ├── MF.Migrator.SQLGenerator.SQLite
     ├── MF.Migrator.SQLGenerator.Firebird
     ├── MF.Migrator.SQLGenerator.PostgreSQL
     ├── MF.Migrator.SQLGenerator.MySQL
     ├── MF.Migrator.SQLGenerator.MariaDB
     ├── MF.Migrator.SQLGenerator.MSSQL
     └── MF.Migrator.SQLGenerator.Oracle

MF.Migrator.SchemaDiffer ◄─── MF.Migrator.Types
MF.Migrator.EntityReader  ◄─── MF.Migrator.Types
MF.Migrator.Runner        ◄─── MF.Connection + MF.Migrator.Types + MF.Migrator.Utils
MF.Migrator.Commands      ◄─── (todos acima) + MF.Migrator.SchemaDiffer + MF.Migrator.EntityReader
MF.Migrator.CLI           ◄─── MF.Migrator.Commands
MF.Migrator.GUI.MainForm  ◄─── MF.Migrator.Commands + VCL
MF.Migrator.API           ◄─── MF.Migrator.Commands
```

---

> **Documentação técnica gerada em Junho de 2026.**  
> Para referência de API pública, veja `API_REFERENCIA.md`.  
> Para guia do usuário, veja `GUIA_DO_USUARIO.md`.
