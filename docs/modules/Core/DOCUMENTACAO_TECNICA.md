# MinusFramework â€” DocumentaÃ§Ã£o TÃ©cnica

> **VersÃ£o:** 2.1
> **Ãšltima atualizaÃ§Ã£o:** 11/Junho/2026 (Sprint 4 â€” ArrayDML)
> **Plataforma:** Windows 32/64-bit
> **Banco de dados:** Firebird, PostgreSQL, SQLite, MySQL, MariaDB, MSSQL, Oracle
> **IDE:** Delphi 11 Alexandria+
> **DependÃªncia externa:** FireDAC (RAD Studio)

---

## SumÃ¡rio

1. [VisÃ£o Geral](#1-visÃ£o-geral)
2. [Arquitetura](#2-arquitetura)
3. [Core do ORM](#3-core-do-orm)
4. [Providers (ConexÃ£o Multi-Banco)](#4-providers-conexÃ£o-multi-banco)
5. [Extensions](#5-extensions)
6. [MinusMigrator](#6-minusmigrator)
7. [DLL APIs](#7-dll-apis)
8. [Testes](#8-testes)
9. [Projetos e Build](#9-projetos-e-build)
10. [Diagrama de DependÃªncias](#10-diagrama-de-dependÃªncias)

---

## 1. VisÃ£o Geral

O **MinusFramework** Ã© um conjunto integrado de bibliotecas Delphi para desenvolvimento de aplicaÃ§Ãµes com banco de dados. Consiste em trÃªs subsistemas principais:

| Subsistema | DescriÃ§Ã£o | Projetos |
|---|---|---|
| **MinusORM** | ORM com mapeamento via atributos RTTI, Unit of Work, Change Tracking, Identity Map, Criteria API, Query Builders, RepositÃ³rio genÃ©rico | `MinusORM.dll` (DLL), packages BPL |
| **MinusMigrator** | Sistema versionado de migraÃ§Ã£o de schema com SchemaReader, SQLGenerator, Runner, CLI e GUI | `MinusMigrator_CLI.exe`, `MinusMigrator_GUI.exe`, `MinusMigrator.dll` |
| **MinusExtensions** | ExtensÃµes plugÃ¡veis (SoftDelete, Audit, Cache, Bulk, etc.) | Integradas no ORM via hook system |

### 1.1 PrÃ­ncipios de Design

- **Provider-agnostic:** Toda comunicaÃ§Ã£o com banco Ã© abstraÃ­da via interfaces (`IConexao`, `IComando`, `IResultados`, `IParametro`)
- **RTTI-first:** Mapeamento via atributos customizados (`[Tabela]`, `[Coluna]`, etc.), sem arquivos de mapeamento externos
- **ComposiÃ§Ã£o sobre heranÃ§a:** ExtensÃµes sÃ£o processadores plugÃ¡veis, nÃ£o heranÃ§a de classes base
- **Testabilidade:** Mock completo das interfaces de banco permite testes unitÃ¡rios sem banco real
- **Standalone:** CLI e DLL nÃ£o dependem do ORM para funcionar (apenas FireDAC)

---

## 2. Arquitetura

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                      APLICAÃ‡ÃƒO CONSUMIDORA                     â”‚
â”‚  (WinForms, Console, ServiÃ§o, Outra linguagem via DLL)        â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                   â”‚
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                      MINUSFRAMEWORK                           â”‚
â”‚                                                               â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚   ORM CORE          â”‚  â”‚   MINUSMIGRATOR               â”‚   â”‚
â”‚  â”‚                     â”‚  â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚   â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚   â”‚ CLI / GUI / DLL       â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TRepository   â”‚  â”‚  â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚   â”‚
â”‚  â”‚  â”‚ TUnitOfWork   â”‚  â”‚  â”‚            â”‚                   â”‚   â”‚
â”‚  â”‚  â”‚ TChangeTrackerâ”‚  â”‚  â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚   â”‚
â”‚  â”‚  â”‚ TIdentityMap  â”‚  â”‚  â”‚   â”‚ TComandosMigrador     â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TMapper       â”‚  â”‚  â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚   â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚            â”‚                   â”‚   â”‚
â”‚  â”‚          â”‚           â”‚  â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚   â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚   â”‚ TExecutorMigracao     â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TQueryBuilder  â”‚  â”‚  â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚   â”‚
â”‚  â”‚  â”‚ TSelectBuilder â”‚  â”‚  â”‚            â”‚                   â”‚   â”‚
â”‚  â”‚  â”‚ TInsertBuilder â”‚  â”‚  â”‚   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”         â”‚   â”‚
â”‚  â”‚  â”‚ TUpdateBuilder â”‚  â”‚  â”‚   â”‚                â”‚          â”‚   â”‚
â”‚  â”‚  â”‚ TDeleteBuilder â”‚  â”‚  â”‚   â–¼                â–¼          â”‚   â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚   ILeitorEsquema  IGeradorSQL  â”‚   â”‚
â”‚  â”‚          â”‚           â”‚  â”‚         â”‚                â”‚     â”‚   â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚   â”Œâ”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”  â”Œâ”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”  â”‚   â”‚
â”‚  â”‚  â”‚ TCriteria     â”‚  â”‚  â”‚   â”‚ SQLite    â”‚  â”‚ SQLite   â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TExpression   â”‚  â”‚  â”‚   â”‚ Firebird  â”‚  â”‚ Firebird â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TProcBuilder  â”‚  â”‚  â”‚   â”‚ PostgreSQLâ”‚  â”‚ PG       â”‚  â”‚   â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚   â”‚ MySQL     â”‚  â”‚ MySQL    â”‚  â”‚   â”‚
â”‚  â”‚          â”‚           â”‚  â”‚   â”‚ MariaDB   â”‚  â”‚ MariaDB  â”‚  â”‚   â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚   â”‚ MSSQL     â”‚  â”‚ MSSQL    â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TMetadataCache â”‚  â”‚  â”‚   â”‚ Oracle    â”‚  â”‚ Oracle   â”‚  â”‚   â”‚
â”‚  â”‚  â”‚ TTypeConverter â”‚  â”‚  â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚   â”‚
â”‚  â”‚  â”‚ TIdGenerator   â”‚  â”‚  â”‚                                â”‚   â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚   â”‚
â”‚  â”‚          â”‚           â”‚  â”‚  â”‚ TSchemaDiffer            â”‚   â”‚   â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚  â”‚ TEntityReader            â”‚   â”‚   â”‚
â”‚  â”‚  â”‚ EXTENSIONS    â”‚  â”‚  â”‚  â”‚ TChangelog               â”‚   â”‚   â”‚
â”‚  â”‚  â”‚ (hooks)       â”‚  â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚   â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚                                â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚             â”‚                                                   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”â”‚
â”‚  â”‚                 IConexao / IComando / IResultados           â”‚â”‚
â”‚  â”‚                       (Interfaces de AbstraÃ§Ã£o)             â”‚â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜â”‚
â”‚             â”‚                                                   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”â”‚
â”‚  â”‚              FireDAC Provider (concreto)                     â”‚â”‚
â”‚  â”‚  TConexaoFireDAC / TComandoFireDAC / TTransacaoFireDAC      â”‚â”‚
â”‚  â”‚                                                              â”‚â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚â”‚
â”‚  â”‚  â”‚ Firebird â”‚ Postgres â”‚  SQLite  â”‚  MySQL   â”‚  MSSQL   â”‚   â”‚â”‚
â”‚  â”‚  â”‚ Provider â”‚ Provider â”‚ Provider â”‚ Provider â”‚ Provider â”‚   â”‚â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 3. Core do ORM

### 3.1 Hierarchy de Interfaces de Banco

Toda comunicaÃ§Ã£o com banco passa pelas interfaces em `MF.Connection.pas`:

```
IConexao â”€â”€â”€ cria â”€â”€â”€ IComando â”€â”€â”€ executa â”€â”€â”€ IResultados
                â”‚                      â”‚
                â”‚                      â””â”€â”€ ICampo (field access)
                â””â”€â”€ ITransacao (begin/commit/rollback)
```

**ImplementaÃ§Ã£o concreta:** `TConexaoFireDAC`, `TComandoFireDAC`, `TTransacaoFireDAC` em `MF.Provider.FireDAC.pas`.

### 3.2 Registry de Providers

`TRegistroProvedores` em `MF.Provider.pas` implementa Service Locator. Cada provider (SQLite, Firebird, etc.) registra uma fÃ¡brica:

```pascal
TRegistroProvedores.Registrar('sqlite', TFabricaConexaoSQLite.Create);
```

A criaÃ§Ã£o Ã© feita via `TRegistroProvedores.CriarConexao(Params)` que instancia a conexÃ£o correta baseada no `DriverName`.

### 3.3 Mapeamento RTTI

**`MF.Attributes.pas`** define todos os atributos de mapeamento:

| Atributo | Alvo | ParÃ¢metros |
|---|---|---|
| `TabelaAttribute` | Classe | Nome da tabela |
| `ColunaAttribute` | Propriedade | Nome da coluna, tamanho mÃ¡ximo |
| `ChavePrimariaAttribute` | Propriedade | (sem parÃ¢metros) |
| `ChaveEstrangeiraAttribute` | Propriedade | Nome da FK |
| `AutoIncrementoAttribute` | Propriedade | (sem parÃ¢metros) |
| `IgnorarAttribute` | Propriedade | (sem parÃ¢metros) |
| `NotNullAttribute` | Propriedade | (sem parÃ¢metros) |
| `ReadOnlyAttribute` | Propriedade | (sem parÃ¢metros) |
| `VersaoAttribute` | Propriedade | Nome coluna, valor inicial |
| `CacheAttribute` | Classe | TTL segundos, regiÃ£o |
| `SoftDeleteAttribute` | Classe | Coluna, tipo (boolean/integer/datetime) |
| `ChaveUnicaAttribute` | Classe | Nome do grupo, array de colunas |
| `RelacionamentoAttribute` | Propriedade | Tipo (pertenceA/temUm/temMuitos), FK, PK |
| `CriadoEmAttribute` | Propriedade | (sem parÃ¢metros) |
| `AtualizadoEmAttribute` | Propriedade | (sem parÃ¢metros) |
| `CriadoPorAttribute` | Propriedade | (sem parÃ¢metros) |
| `AtualizadoPorAttribute` | Propriedade | (sem parÃ¢metros) |
| `DiscriminadorAttribute` | Classe | Nome coluna, mapeamentos |

**`MF.Mapper.pas`** â€” `TMapeador` converte `IResultados` em objetos via RTTI. Usa `TCacheMetadados` (MF.MetadataCache.pas) para evitar reflexÃ£o repetida.

**`MF.MetadataCache.pas`** â€” `TCacheMetadados` cacheia por classe:
- Nome da tabela
- Colunas mapeadas (com atributos)
- Chave primÃ¡ria
- Foreign keys
- Version info (concorrÃªncia)
- Soft-delete config

### 3.4 Query Builders

| Builder | Arquivo | PropÃ³sito |
|---|---|---|
| `TSelecaoBuilder<T>` | MF.SelectBuilder.pas | SELECT com JOIN, WHERE, ORDER BY, paginaÃ§Ã£o, GROUP BY |
| `TConstrutorInsercao<T>` | MF.InsertBuilder.pas | INSERT com auto-generated keys |
| `TAtualizacaoBuilder<T>` | MF.UpdateBuilder.pas | UPDATE com WHERE |
| `TExclusaoBuilder<T>` | MF.DeleteBuilder.pas | DELETE (ou soft-delete) |
| `TConstrutorProcedimento` | MF.ProcBuilder.pas | Stored procedures |
| `TConstrutorConsulta<T>` | MF.QueryBuilder.pas | Coordena todos os builders, executa CRUD |

**`TConstrutorConsulta<T>`** Ã© o ponto central de execuÃ§Ã£o:
1. Aplica hooks das extensions (prÃ©/pÃ³s Insert/Update/Delete/Read)
2. Gerencia Identity Map (evita duplicatas em memÃ³ria)
3. Invalida cache de 2Âº nÃ­vel em writes
4. Suporta lazy loading navigation properties

### 3.5 Criteria API

**`MF.Criteria.pas`** â€” `TCriterio` com operadores:
- `Igual`, `Diferente`, `MaiorQue`, `MenorQue`, `MaiorOuIgual`, `MenorOuIgual`
- `Como` (LIKE), `Entre` (BETWEEN), `Em` (IN), `NaoEm` (NOT IN)
- `EhNulo`, `NaoEhNulo`
- `EmSubconsulta` (IN subquery), `Existe`, `NaoExiste`

**`MF.Expression.pas`** â€” `TCondicaoCampo` fluent API:
```pascal
Campo('NOME').Igual('Joao').E(Campo('IDADE').MaiorQue(18))
```

Combinadores: `E(todos)`, `Ou(qualquer)`, `Nao`.

### 3.6 Unit of Work

**`MF.UnitOfWork.pas`** â€” `TUnidadeTrabalho`:
- `RegistrarNovo(entidade)` â€” marca INSERT
- `RegistrarSujo(entidade)` â€” marca UPDATE (dirty detection automÃ¡tico)
- `RegistrarExcluido(entidade)` â€” marca DELETE
- `Confirmar` â€” executa tudo em transaÃ§Ã£o: DELETE â†’ INSERT â†’ UPDATE (ordem otimizada)
- `Reverter` â€” descarta pendÃªncias

**`MF.ChangeTracker.pas`** â€” `TRastreadorMudancas`:
- `TirarSnapshot(objeto)` â€” salva estado atual
- `ObterCamposModificados(objeto)` â€” retorna diferenÃ§as
- Suporta rastreamento por propriedade com `oldValue/newValue`

**`MF.IdentityMap.pas`** â€” `TMapaIdentidade`:
- Cache classe/id â†’ instÃ¢ncia
- `Obter<T>(id)` â€” retorna se existir
- `Armazenar(objeto)` â€” adiciona ao cache
- `Limpar` / `LimparPorClasse`

### 3.7 Repository

**`MF.RepositoryBase.pas`** â€” `TRepositorioBase<T>`:
```pascal
Salvar(entidade): Integer      // INSERT ou UPDATE automÃ¡tico
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
Usa UoW internamente para operaÃ§Ãµes atÃ´micas.

### 3.8 Outros Componentes do Core

| Unit | Classe | PropÃ³sito |
|---|---|---|
| MF.Lazy.pas | `TLazy<T>` | Proxy para lazy loading de associaÃ§Ãµes |
| MF.IdGenerator.pas | `IGeradorId`, `TFabricaGeradorId` | EstratÃ©gia de geraÃ§Ã£o de ID por provider |
| MF.TypeConverter.pas | `ITypeConverter`, `TRegistroConversores` | ConversÃ£o de tipos Delphi â†” SQL |
| MF.Transaction.pas | `ITransacaoGerenciada` | Interface de transaÃ§Ã£o gerenciada |
| MF.Extensao.Core.pas | `IProcessador*` interfaces | Hooks de ciclo de vida para extensions |
| MF.Infra.Connection.pas | `TConexaoInfra` | Wrapper de conexÃ£o com savepoints aninhados |
| MF.DLLAPI.pas | FunÃ§Ãµes `ORM_*` | Flat C API exports (MinusORM.dll) |

---

## 4. Providers (ConexÃ£o Multi-Banco)

### 4.1 Arquitetura

`MF.Provider.FireDAC.pas` implementa as interfaces `IConexao`, `IComando`, `ITransacao`, `IResultados`, `ICampo` usando TFDConnection/TFDQuery/TFDTransaction.

Cada banco tem sua prÃ³pria fÃ¡brica que registra o driver:

| Provider | Arquivo | Driver FireDAC |
|---|---|---|
| SQLite | MF.Provider.FireDAC.SQLite.pas | SQLite |
| Firebird | MF.Provider.FireDAC.Firebird.pas | FB |
| PostgreSQL | MF.Provider.FireDAC.PostgreSQL.pas | PG |
| MySQL | MF.Provider.FireDAC.MySQL.pas | MySQL |

(Novos providers como MSSQL e Oracle usam o driver ODBC ou nativo FireDAC correspondente, registrados na mesma fÃ¡brica.)

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

### 5.1 Sistema de ExtensÃµes (Hooks)

Definido em `MF.Extensao.Core.pas`:

```pascal
IProcessadorInsercao = interface
  procedure ProcessarAntes(AEntidade: TObject; var AQuery: string; AParams: IComando);
  procedure ProcessarDepois(AEntidade: TObject; AIdGerado: TValue);
end;
```

Analogamente para Update, Delete e Read.

Extensions sÃ£o registradas em `TConfiguracaoORM.RegistrarProcessador(...)` e executadas pelo `TConstrutorConsulta<T>` em ordem.

### 5.2 ExtensÃµes Implementadas

| ExtensÃ£o | Unit | Interface | Funcionalidade |
|---|---|---|---|
| **SoftDelete** | MF.Extensions.SoftDelete.pas | `IProcessadorExclusao`, `IProcessadorLeitura` | Marca registro como excluÃ­do em vez de deletar; filtra automaticamente em consultas |
| **Audit** | MF.Extensions.Audit.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao`, `IProcessadorExclusao` | Insere na tabela `AUDITORIA` com old/new values, usuÃ¡rio, data/hora |
| **Cache** | MF.Extensions.Cache.pas | (via `ICacheProvedor`) | Cache de 2Âº nÃ­vel em memÃ³ria com TTL, regiÃµes e invalidaÃ§Ã£o automÃ¡tica |
| **Shadow** | MF.Extensions.Sombra.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao` | Seta `CriadoEm`/`AtualizadoEm`, `CriadoPor`/`AtualizadoPor` |
| **UniqueKey** | MF.Extensions.UniqueKey.pas | `IProcessadorInsercao`, `IProcessadorAtualizacao` | Valida chave Ãºnica antes de INSERT/UPDATE |
| **ConcorrÃªncia** | MF.Extensions.Concorrencia.pas | `IProcessadorAtualizacao` | Lock otimista via versÃ£o: `UPDATE ... WHERE version = :old` |
| **Bulk** | MF.Extensions.Bulk.pas | (mÃ©todos diretos no Repository) | `InserirEmLote<T>` com ArrayDML (FireDAC, 1 round-trip, 10-50x ganho); fallback para multi-INSERT com RETURNING ou transaÃ§Ã£o linha-a-linha |
| **Relacionamento** | MF.Extensions.Relacionamento.pas | (pÃ³s-carregamento) | Carregamento automÃ¡tico de navigation properties |

---

## 6. MinusMigrator

### 6.1 Arquitetura Geral

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚   CLI (MF.Migrator.CLI) / GUI (MF.Migrator.GUI.MainForm)    â”‚
â”‚   DLL (MF.Migrator.API)                                      â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                    TComandosMigrador                          â”‚
â”‚   (init, migrate, rollback, status, tag, add-migration,      â”‚
â”‚    auto-migrate, generate-models, diff-changelog)            â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                    TExecutorMigracao                          â”‚
â”‚   (control table, lock, checksums, repeatable, contexts)     â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚   ILeitorEsquema     â”‚   IGeradorSQL                         â”‚
â”‚   TLeitorEsquemaBase â”‚   TGeradorSQLBase                     â”‚
â”‚   â”œâ”€ SQLite          â”‚   â”œâ”€ SQLite                           â”‚
â”‚   â”œâ”€ Firebird        â”‚   â”œâ”€ Firebird                         â”‚
â”‚   â”œâ”€ PostgreSQL      â”‚   â”œâ”€ PostgreSQL                       â”‚
â”‚   â”œâ”€ MySQL           â”‚   â”œâ”€ MySQL                            â”‚
â”‚   â”œâ”€ MariaDB         â”‚   â”œâ”€ MariaDB                          â”‚
â”‚   â”œâ”€ MSSQL           â”‚   â”œâ”€ MSSQL                            â”‚
â”‚   â””â”€ Oracle          â”‚   â””â”€ Oracle                           â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚   TComparadorEsquema (SchemaDiffer)                          â”‚
â”‚   TLeitorEntidade (EntityReader)                              â”‚
â”‚   TSerializadorChangelog (JSON/XML)                           â”‚
â”‚   TMinusMigratorUtils (checksums, file listing)               â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 6.2 Schema Reader

`ILeitorEsquema` (MF.Migrator.SchemaReader.pas) lÃª o schema atual do banco:

```pascal
type
  ILeitorEsquema = interface
    function NomeProvedor: string;
    function LerEsquema: TEsquemaBancoDados;
  end;
```

Cada provider implementa sua prÃ³pria leitura via system views/catalog do banco:

| Provider | Fontes de Dados |
|---|---|
| SQLite | `sqlite_master`, `PRAGMA table_info`, `PRAGMA foreign_key_list` |
| Firebird | `RDB$RELATIONS`, `RDB$RELATION_FIELDS`, `RDB$INDICES`, `RDB$REF_CONSTRAINTS` |
| PostgreSQL | `information_schema.tables`, `information_schema.columns`, `pg_catalog` |
| MySQL | `INFORMATION_SCHEMA.TABLES`, `INFORMATION_SCHEMA.COLUMNS`, `INFORMATION_SCHEMA.KEY_COLUMN_USAGE` |
| MariaDB | Herda de MySQL (100% compatÃ­vel para schema reading) |
| MSSQL | `sys.tables`, `sys.columns`, `sys.indexes`, `INFORMATION_SCHEMA` |
| Oracle | `USER_TABLES`, `USER_TAB_COLUMNS`, `USER_CONSTRAINTS`, `USER_IND_COLUMNS` |

### 6.3 SQL Generator

`IGeradorSQL` produz DDL especÃ­fico por provider:

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
| Oracle | `NUMBER(10)` + ID manual | `"name"` | `VARCHAR2`, `BINARY_FLOAT`, `BINARY_DOUBLE`, `RAW(16)`, `NUMBER(1)â†’Boolean` |

### 6.4 Schema Differ

`TComparadorEsquema` (MF.Migrator.SchemaDiffer.pas) compara dois `TEsquemaBancoDados`:
- Tabelas novas/removidas
- Colunas novas/removidas/alteradas (tipo, tamanho, nullable)
- Ãndices novos/removidos
- Foreign keys novas/removidas

Produz `TArray<TAlteracaoEsquema>` com operaÃ§Ãµes de:
- `tcCriarTabela`, `tcRemoverTabela`
- `tcAdicionarColuna`, `tcRemoverColuna`, `tcAlterarColuna`
- `tcAdicionarIndice`, `tcRemoverIndice`
- `tcAdicionarChaveEstrangeira`, `tcRemoverChaveEstrangeira`
- `tcAlterarPrimaryKey`

### 6.5 Entity Reader

`TLeitorEntidade` (MF.Migrator.EntityReader.pas) lÃª arquivos `.pas` com entidades anotadas e extrai `TEsquemaBancoDados` equivalente:
- Busca atributos `[Tabela('...')]`, `[Coluna('...')]`, `[ChavePrimaria]`, etc.
- Parse textual (nÃ£o compila), funciona em qualquer .pas bem formatado
- Usado por `add-migration` e `auto-migrate`

### 6.6 Runner

`TExecutorMigracao` (MF.Migrator.Runner.pas) Ã© o motor central:

**Control Table:** `__MINUSMIGRATOR_MIGRATIONS`
- Tabela criada automaticamente no `Inicializar`
- Colunas: ID, NAME, BATCH, EXECUTED_AT, CHECKSUM, DURATION_MS

**Lock Table:** `__MINUSMIGRATOR_LOCK`
- PrevenÃ§Ã£o de concorrÃªncia entre processos
- INSERT com PK Ãºnica (falha = outro processo rodando)
- Adquirido em `migrate` e `auto-migrate`, liberado ao final

**Tag Table:** `__MINUSMIGRATOR_TAGS`
- NAME, MIGRATION_ID, CREATED_AT
- Usado para rollback-to-tag

**Fluxo de migraÃ§Ã£o:**
1. `Inicializar` â†’ cria control/lock/tag tables
2. `AdquirirLock` â†’ INSERT na lock table (se falhar, aborta)
3. `ObterPendentes` â†’ lista arquivos `.up.sql` nÃ£o executados (exclui `R__*`)
4. `ObterRepetiveisPendentes` â†’ lista `R__*.up.sql` com checksum diferente
5. `ExecutarArquivo` â†’ executa SQL, registra na control table
6. `ExecutarRepetivel` â†’ executa SQL, faz UPDATE checksum se jÃ¡ existe
7. `LiberarLock` â†’ DELETE da lock table

**Preconditions:** Suporta:
- `--precondition: tableExists(nome)`
- `--precondition: tableNotExists(nome)`
- `--precondition: columnExists(tabela, coluna)`
- `--precondition: columnNotExists(tabela, coluna)`
- `--precondition: dbms(provider)`

**Contexts:** `--context nome` filtra arquivos para subdiretÃ³rio.

**Repeatable Migrations:** Arquivos `R__*.up.sql` sÃ£o executados toda vez que o checksum muda.

**Add-Migration via diff:** Gera `.up.sql` + `.down.sql` com timestamp comparando entidades vs. banco real.

**Auto-Migrate:** Aplica diff direto no banco (sem gerar arquivos), com suporte `--dry-run` e `--force`.

**Changelog:** `TSerializadorChangelog` serializa status em JSON/XML.

### 6.7 CLI

`MF.Migrator.CLI.pas` â€” entry point `Run`:
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

`MF.Migrator.GUI.MainForm.pas` â€” `TfrmMigratorGUI`:
- Painel de conexÃ£o (connection string, path, context, entities, output, namespace, tag, description)
- StringGrid com status das migraÃ§Ãµes
- ListBox com arquivos pendentes
- BotÃµes: Connect, Status, Migrate, Rollback, Tag, Add Migration, Auto-Migrate, Generate Models, Dry-Run
- Memo de log com timestamp
- StatusBar com estado da conexÃ£o

### 6.9 Diagrama de Classes do Migrator

```
TComandosMigrador (static methods)
â”‚
â”œâ”€â”€ ExecutarInit
â”œâ”€â”€ ExecutarMigracao â† TExecutorMigracao
â”œâ”€â”€ ExecutarReverter â† TExecutorMigracao
â”œâ”€â”€ ExecutarStatus   â† TExecutorMigracao
â”œâ”€â”€ ExecutarTag      â† TExecutorMigracao
â”œâ”€â”€ ExecutarAddMigration â† ILeitorEsquema + IGeradorSQL + TComparadorEsquema
â”œâ”€â”€ ExecutarAutoMigrate  â† ILeitorEsquema + IGeradorSQL + TComparadorEsquema
â”œâ”€â”€ ExecutarGenerateModels â† ILeitorEsquema
â””â”€â”€ ExecutarDiffChangelog  â† ILeitorEsquema + IGeradorSQL + TComparadorEsquema

TExecutorMigracao
â”œâ”€â”€ Inicializar (cria tabelas)
â”œâ”€â”€ AdquirirLock / LiberarLock
â”œâ”€â”€ ObterStatus
â”œâ”€â”€ ObterPendentes / ObterRepetiveisPendentes
â”œâ”€â”€ ExecutarArquivo / ExecutarRepetivel / ExecutarPendentes
â”œâ”€â”€ RegistrarEntrada
â”œâ”€â”€ CriarTag / ObterTagID
â”œâ”€â”€ Reverter / ReverterAteTag
â””â”€â”€ VerificarPrecondicoes

ILeitorEsquema (interface, implementada por provider)
â”œâ”€â”€ TLeitorEsquemaSQLite
â”œâ”€â”€ TLeitorEsquemaFirebird
â”œâ”€â”€ TLeitorEsquemaPostgreSQL
â”œâ”€â”€ TLeitorEsquemaMySQL
â”œâ”€â”€ TLeitorEsquemaMariaDB (herda MySQL)
â”œâ”€â”€ TLeitorEsquemaMSSQL
â””â”€â”€ TLeitorEsquemaOracle

IGeradorSQL (interface, implementada por provider)
â”œâ”€â”€ TGeradorSQLSQLite
â”œâ”€â”€ TGeradorSQLFirebird
â”œâ”€â”€ TGeradorSQLPostgreSQL
â”œâ”€â”€ TGeradorSQLMySQL
â”œâ”€â”€ TGeradorSQLMariaDB (herda MySQL)
â”œâ”€â”€ TGeradorSQLMSSQL
â””â”€â”€ TGeradorSQLOracle

TComparadorEsquema
â”œâ”€â”€ Comparar â†’ TArray<TAlteracaoEsquema>
â””â”€â”€ InverterAlteracoes â†’ TArray<TAlteracaoEsquema>

TAlteracaoEsquema (record)
â”œâ”€â”€ ChangeType: tcCriarTabela, tcAdicionarColuna, ...
â”œâ”€â”€ TableName, ColumnName, NewType, OldType, ...
â””â”€â”€ IndexInfo, FKInfo

TEsquemaBancoDados (record)
â””â”€â”€ Tables: TArray<TEsquemaTabela>
    â”œâ”€â”€ Columns: TArray<TEsquemaColuna>
    â”œâ”€â”€ Indices: TArray<TEsquemaIndice>
    â””â”€â”€ ForeignKeys: TArray<TEsquemaChaveEstrangeira>
```

---

## 7. DLL APIs

### 7.1 MinusORM.dll (`MinusORM.dpr`)

Exports em `MF.DLLAPI.pas`:

```c
// Gerenciamento de conexÃ£o
int ORM_Connect(const char* connString);
int ORM_Disconnect(int connId);

// CRUD genÃ©rico
int ORM_Insert(int connId, const char* table, const char* jsonData);
int ORM_Update(int connId, const char* table, const char* jsonData, const char* whereJson);
int ORM_Delete(int connId, const char* table, const char* whereJson);
char* ORM_Select(int connId, const char* sql);

// TransaÃ§Ãµes
int ORM_BeginTransaction(int connId);
int ORM_Commit(int connId);
int ORM_Rollback(int connId);

// UtilitÃ¡rios
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
| `TTesteMapeador` | Test.ORM.Mapper.pas | UnitÃ¡rio (mock) | Mapeamento RTTI objeto â†” resultset |
| `TTesteMapaIdentidade` | Test.ORM.IdentityMap.pas | UnitÃ¡rio (mock) | Cache de 1Âº nÃ­vel |
| `TTesteRastreadorMudancas` | Test.ORM.ChangeTracker.pas | UnitÃ¡rio (mock) | Snapshot e dirty detection |
| `TTesteCriteria` | Test.ORM.Criteria.pas | UnitÃ¡rio (mock) | Criteria API e geraÃ§Ã£o SQL |
| `TTesteSelectBuilder` | Test.ORM.SelectBuilder.pas | UnitÃ¡rio (mock) | SELECT, JOIN, paginaÃ§Ã£o |
| `TTesteIdGenerator` | Test.ORM.IdGenerator.pas | UnitÃ¡rio (mock) | ID generators |
| `TTesteUnidadeTrabalhoMock` | Test.ORM.UnitOfWork.Mock.pas | UnitÃ¡rio (mock) | UoW tracking |
| `TTesteUnidadeTrabalho` | Test.ORM.UnitOfWork.pas | IntegraÃ§Ã£o (SQLite) | UoW transacional |
| `TTesteProviderBase` | Test.ORM.Provider.Base.pas | Abstrato (base) | Common CRUD test template |
| `TTesteProviderSQLite` | Test.ORM.Provider.SQLite.pas | IntegraÃ§Ã£o (SQLite) | CRUD SQLite |
| `TTesteProviderFirebird` | Test.ORM.Provider.Firebird.pas | IntegraÃ§Ã£o (Firebird) | CRUD Firebird |
| `TTesteProviderPostgreSQL` | Test.ORM.Provider.PostgreSQL.pas | IntegraÃ§Ã£o (PG) | CRUD PostgreSQL |
| `TTesteProviderMySQL` | Test.ORM.Provider.MySQL.pas | IntegraÃ§Ã£o (MySQL) | CRUD MySQL |
| `TTesteExtensions` | Test.ORM.Extensions.pas | IntegraÃ§Ã£o (SQLite) | Todas as extensions |
| `TTesteLazy` | Test.ORM.Lazy.pas | UnitÃ¡rio (mock) | Lazy loading |

### 8.2 Testes do Migrator

| Fixture | Unit | Tipo | O que testa |
|---|---|---|---|
| `TTesteSchemaReaderSQLite` | Test.Migrator.SchemaReader.pas | IntegraÃ§Ã£o (SQLite) | Leitura de schema |
| `TTesteSchemaDiffer` | Test.Migrator.SchemaDiffer.pas | UnitÃ¡rio | ComparaÃ§Ã£o de schemas |
| `TTesteSQLGenerator` | Test.Migrator.SQLGenerator.pas | UnitÃ¡rio | GeraÃ§Ã£o DDL |
| `TTesteMigratorRunner` | Test.Migrator.Runner.pas | IntegraÃ§Ã£o (SQLite) | Runner + migraÃ§Ã£o |
| `TTesteEntityReader` | Test.Migrator.EntityReader.pas | UnitÃ¡rio | Parse de .pas |

### 8.3 Mocks

`Test.ORM.Mock.pas` fornece implementaÃ§Ãµes completas de todas as interfaces de banco (`IConexao`, `IComando`, `IResultados`, `ICampo`) para testes unitÃ¡rios sem banco real.

### 8.4 ExecuÃ§Ã£o

```
Test.MinusORM.exe       â†’ testes ORM
Test.MinusMigrator.exe  â†’ testes Migrator
```

Ambiente via Docker Compose para testes cross-db (Firebird, PostgreSQL, MySQL).

---

## 9. Projetos e Build

### 9.1 Projetos

| Arquivo | Tipo | SaÃ­da | DescriÃ§Ã£o |
|---|---|---|---|
| `MinusORM.dpr` | DLL | `MinusORM.dll` | ORM como DLL com API C |
| `MinusMigrator_CLI.dpr` | Console | `MinusMigrator_CLI.exe` | CLI do migrator |
| `MinusMigrator_GUI.dpr` | VCL App | `MinusMigrator_GUI.exe` | GUI do migrator |
| `MinusMigrator_DLL.dpr` | DLL | `MinusMigrator.dll` | Migrator como DLL |
| `Test.MinusORM.dpr` | Console | `Test.MinusORM.exe` | Testes ORM |
| `Test.MinusMigrator.dpr` | Console | `Test.MinusMigrator.exe` | Testes Migrator |
| `Benchmark.MinimusORM.dpr` | Console | `Benchmark.MinimusORM.exe` | Benchmarks |
| `MinusDemo.dpr` | Console | `MinusDemo.exe` | Exemplo de uso da DLL |

### 9.2 DependÃªncias

```
MinusMigrator_CLI.exe         â”€â”€â”€ FireDAC
MinusMigrator_GUI.exe         â”€â”€â”€ FireDAC + VCL
MinusMigrator.dll             â”€â”€â”€ FireDAC
MinusORM.dll                  â”€â”€â”€ FireDAC
Test.MinusORM.exe             â”€â”€â”€ FireDAC + DUnitX
Test.MinusMigrator.exe        â”€â”€â”€ FireDAC + DUnitX
Benchmark.MinimusORM.exe      â”€â”€â”€ FireDAC
MinusDemo.exe                 â”€â”€â”€ MinusORM.dll (via LoadLibrary)
```

### 9.3 Source Dirs

```
Source/
â”œâ”€â”€ Bibliotecas/           â†’ Interfaces e registry (MF.Connection, MF.Provider, etc.)
â”‚   â””â”€â”€ Providers/         â†’ ImplementaÃ§Ãµes FireDAC
â”œâ”€â”€ Core/                  â†’ ORM Core (Mapper, QueryBuilder, UoW, etc.)
â”œâ”€â”€ Extensions/            â†’ ExtensÃµes plugÃ¡veis
â””â”€â”€ Migrator/              â†’ MinusMigrator completo
```

---

## 10. Diagrama de DependÃªncias

```
MF.Attributes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.MetadataCache
     â”‚                          â”‚
     â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
     â”‚                          â”‚
MF.Mapper â—„â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ MF.MetadataCache
     â”‚
     â”œâ”€â”€â–º MF.TypeConverter
     â”‚
MF.IdGenerator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Types
MF.Criteria â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Types
MF.Expression â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Criteria

MF.SelectBuilder â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Criteria, MF.Types
MF.InsertBuilder â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Types
MF.UpdateBuilder â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Criteria, MF.Types
MF.DeleteBuilder â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Criteria, MF.Types
MF.ProcBuilder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Types

MF.QueryBuilder â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º (todos os builders) + MF.Mapper + MF.IdentityMap
     â”‚                         + MF.ChangeTracker + MF.Extensao.Core
     â”‚
MF.RepositoryBase â”€â”€â”€â”€â”€â”€â”€â–º MF.QueryBuilder + MF.UnitOfWork

MF.UnitOfWork â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.QueryBuilder + MF.ChangeTracker + MF.IdentityMap
MF.ChangeTracker â”€â”€â”€â”€â”€â”€â”€â”€â–º MF.Mapper
MF.IdentityMap

MF.Infra.Connection â”€â”€â”€â”€â”€â–º MF.Connection (wrapping para savepoints)

MF.Extensao.Core â—„â”€â”€â”€â”€â”€â”€â”€ (interfaces que extensions implementam)
     â”‚
     â”œâ”€â”€ MF.Extensions.SoftDelete
     â”œâ”€â”€ MF.Extensions.Audit
     â”œâ”€â”€ MF.Extensions.Cache
     â”œâ”€â”€ MF.Extensions.Sombra
     â”œâ”€â”€ MF.Extensions.UniqueKey
     â”œâ”€â”€ MF.Extensions.Concorrencia
     â”œâ”€â”€ MF.Extensions.Bulk
     â””â”€â”€ MF.Extensions.Relacionamento

MF.DLLAPI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–º (tudo acima, compilado na DLL)

â”€â”€â”€ Camada do Migrador â”€â”€â”€â”€

MF.Migrator.Types
MF.Migrator.Utils

MF.Migrator.SchemaReader â—„â”€â”€â”€ MF.Connection
     â”œâ”€â”€ MF.Migrator.SchemaReader.SQLite
     â”œâ”€â”€ MF.Migrator.SchemaReader.Firebird
     â”œâ”€â”€ MF.Migrator.SchemaReader.PostgreSQL
     â”œâ”€â”€ MF.Migrator.SchemaReader.MySQL
     â”œâ”€â”€ MF.Migrator.SchemaReader.MariaDB
     â”œâ”€â”€ MF.Migrator.SchemaReader.MSSQL
     â””â”€â”€ MF.Migrator.SchemaReader.Oracle

MF.Migrator.SQLGenerator â—„â”€â”€â”€ MF.Migrator.Types
     â”œâ”€â”€ MF.Migrator.SQLGenerator.SQLite
     â”œâ”€â”€ MF.Migrator.SQLGenerator.Firebird
     â”œâ”€â”€ MF.Migrator.SQLGenerator.PostgreSQL
     â”œâ”€â”€ MF.Migrator.SQLGenerator.MySQL
     â”œâ”€â”€ MF.Migrator.SQLGenerator.MariaDB
     â”œâ”€â”€ MF.Migrator.SQLGenerator.MSSQL
     â””â”€â”€ MF.Migrator.SQLGenerator.Oracle

MF.Migrator.SchemaDiffer â—„â”€â”€â”€ MF.Migrator.Types
MF.Migrator.EntityReader  â—„â”€â”€â”€ MF.Migrator.Types
MF.Migrator.Runner        â—„â”€â”€â”€ MF.Connection + MF.Migrator.Types + MF.Migrator.Utils
MF.Migrator.Commands      â—„â”€â”€â”€ (todos acima) + MF.Migrator.SchemaDiffer + MF.Migrator.EntityReader
MF.Migrator.CLI           â—„â”€â”€â”€ MF.Migrator.Commands
MF.Migrator.GUI.MainForm  â—„â”€â”€â”€ MF.Migrator.Commands + VCL
MF.Migrator.API           â—„â”€â”€â”€ MF.Migrator.Commands
```

---

> **DocumentaÃ§Ã£o tÃ©cnica gerada em Junho de 2026.**  
> Para referÃªncia de API pÃºblica, veja `API_REFERENCIA.md`.  
> Para guia do usuÃ¡rio, veja `GUIA_DO_USUARIO.md`.
