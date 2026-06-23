# MinusMigrator — Arquitetura

> **Projeto:** MinusMigrator
> **Propósito:** CLI standalone para controle versionado de schema de banco de dados
> **Dependência externa:** FireDAC (apenas para conexão com banco)
> **Dependência de conceito:** Atributos do MinusORM (via parse textual)

---

## Sumário

1. [Visão Geral](#1-visão-geral)
2. [CLI Layer](#2-cli-layer)
3. [Schema Reader](#3-schema-reader)
4. [Entity Reader](#4-entity-reader)
5. [Schema Differ](#5-schema-differ)
6. [SQL Generator](#6-sql-generator)
7. [Migration Runner](#7-migration-runner)
8. [Estrutura de Diretórios](#8-estrutura-de-diretórios)

---

## 1. Visão Geral

```
┌─────────────────────────────────────────────────────────┐
│                   MinusMigrator CLI                      │
│                     (minusmigrator.exe)                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │               CLI Layer                           │   │
│  │  add-migration │ migrate │ status │ rollback     │   │
│  │  generate-models │ init │ --help                 │   │
│  └──────────┬───────────────┬───────────────────────┘   │
│             │               │                           │
│     ┌───────▼───────┐ ┌────▼────────┐                  │
│     │  Command       │ │  Schema     │                  │
│     │  Handlers      │ │  Reader     │                  │
│     └───────┬───────┘ └────┬────────┘                  │
│             │              │                            │
│     ┌───────▼──────────────▼────────┐                  │
│     │        Schema Differ          │                  │
│     │  Entities Schema  vs  DB Schema                 │
│     └───────┬───────────────────────┘                  │
│             │                                          │
│     ┌───────▼───────────────────────┐                  │
│     │        SQL Generator          │                  │
│     │  Provider-aware DDL gerado    │                  │
│     └───────┬───────────────────────┘                  │
│             │                                          │
│     ┌───────▼───────────────────────┐                  │
│     │     Migration Runner          │                  │
│     │  Executa .sql, controla versão                  │
│     └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. CLI Layer

### Comandos

| Comando | Sintaxe | Descrição |
|---|---|---|
| `init` | `minusmigrator init -c "firebird://..."` | Cria tabela `__MINUSMIGRATOR_MIGRATIONS` |
| `add-migration` | `minusmigrator add-migration "Nome" -p Models/ -c "firebird://..."` | Gera `.up.sql` + `.down.sql` |
| `migrate` | `minusmigrator migrate -c "firebird://..." [--dry-run] [-v]` | Executa pendentes |
| `rollback` | `minusmigrator rollback -c "firebird://..." [-n 3]` | Reverte N migrations |
| `status` | `minusmigrator status -c "firebird://..."` | Lista migrações com status |
| `generate-models` | `minusmigrator generate-models -c "firebird://..." -o Models/` | Gera classes .pas |
| `help` | `minusmigrator --help` | Ajuda |

### Formatos de Connection String

```
firebird://localhost:3050/C:/data/db.fdb?user=SYSDBA&password=masterkey
postgresql://localhost:5432/mydb?user=postgres&password=123
sqlite://C:/data/db.sqlite
mysql://localhost:3306/mydb?user=root&password=123
```

---

## 3. Schema Reader

Lê a estrutura atual do banco e monta `TDatabaseSchema`.

### Hierarquia de Classes

```
TDatabaseSchema
└── TTableSchema (1..n)
    ├── FName: string
    ├── FColumns: TObjectList<TColumnSchema>
    │   └── TColumnSchema
    │       ├── FName: string
    │       ├── FDataType: TMigratorDataType
    │       ├── FLength: Integer
    │       ├── FPrecision: Integer
    │       ├── FScale: Integer
    │       ├── FNotNull: Boolean
    │       ├── FDefaultValue: string
    │       ├── FAutoIncrement: Boolean
    │       └── FIsPrimaryKey: Boolean
    ├── FPrimaryKey: TIndexSchema
    ├── FIndexes: TObjectList<TIndexSchema>
    │   └── TIndexSchema
    │       ├── FName: string
    │       ├── FColumns: TArray<string>
    │       └── FUnique: Boolean
    └── FForeignKeys: TObjectList<TForeignKeySchema>
        └── TForeignKeySchema
            ├── FName: string
            ├── FColumns: TArray<string>
            ├── FReferencedTable: string
            ├── FReferencedColumns: TArray<string>
            └── FOnDelete: string
```

### TMigratorDataType

```pascal
TMigratorDataType = (
  mdVarchar, mdChar,
  mdInteger, mdSmallInt, mdBigInt,
  mdNumeric, mdDecimal,
  mdFloat, mdDouble,
  mdDate, mdTime, mdTimestamp,
  mdBlob, mdBlobText,
  mdBoolean,
  mdBinary, mdVarBinary,
  mdGuid,
  mdJSON,
  mdArray,
  mdUnknown
);
```

### Implementações

| Provider | Classe | Fontes de Dados |
|---|---|---|
| Firebird | `TSchemaReaderFirebird` | `RDB$RELATIONS`, `RDB$RELATION_FIELDS`, `RDB$FIELDS`, `RDB$INDICES`, `RDB$INDEX_SEGMENTS`, `RDB$REFENTIAL_CONSTRAINTS` |
| PostgreSQL | `TSchemaReaderPostgreSQL` | `information_schema.tables`, `information_schema.columns`, `pg_indexes`, `pg_constraint` |
| SQLite | `TSchemaReaderSQLite` | `sqlite_master`, `PRAGMA table_info`, `PRAGMA index_list`, `PRAGMA foreign_key_list` |
| MySQL | `TSchemaReaderMySQL` | `information_schema.tables`, `information_schema.columns`, `information_schema.key_column_usage`, `information_schema.table_constraints` |

### Exemplo — Schema Reader Firebird

```sql
-- Tabelas
SELECT RDB$RELATION_NAME FROM RDB$RELATIONS
WHERE RDB$SYSTEM_FLAG = 0 AND RDB$RELATION_TYPE = 0
ORDER BY RDB$RELATION_NAME;

-- Colunas
SELECT
  RF.RDB$FIELD_NAME,
  F.RDB$FIELD_TYPE,
  F.RDB$FIELD_LENGTH,
  F.RDB$FIELD_PRECISION,
  F.RDB$FIELD_SCALE,
  RF.RDB$NULL_FLAG,
  RF.RDB$DEFAULT_VALUE,
  RF.RDB$FIELD_POSITION
FROM RDB$RELATION_FIELDS RF
JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = RF.RDB$FIELD_SOURCE
WHERE RF.RDB$RELATION_NAME = :TABELA
ORDER BY RF.RDB$FIELD_POSITION;

-- Primary Key
SELECT
  RC.RDB$CONSTRAINT_NAME,
  ISG.RDB$FIELD_NAME
FROM RDB$RELATION_CONSTRAINTS RC
JOIN RDB$INDICES S ON S.RDB$INDEX_NAME = RC.RDB$INDEX_NAME
JOIN RDB$INDEX_SEGMENTS ISG ON ISG.RDB$INDEX_NAME = S.RDB$INDEX_NAME
WHERE RC.RDB$CONSTRAINT_TYPE = 'PRIMARY KEY'
  AND RC.RDB$RELATION_NAME = :TABELA;

-- Foreign Keys
SELECT
  RC.RDB$CONSTRAINT_NAME,
  ISG.RDB$FIELD_NAME,
  RC2.RDB$RELATION_NAME AS REF_TABLE,
  ISG2.RDB$FIELD_NAME AS REF_FIELD
FROM RDB$RELATION_CONSTRAINTS RC
JOIN RDB$REFENTIAL_CONSTRAINTS REF
  ON REF.RDB$CONSTRAINT_NAME = RC.RDB$CONSTRAINT_NAME
JOIN RDB$RELATION_CONSTRAINTS RC2
  ON RC2.RDB$CONSTRAINT_NAME = REF.RDB$CONST_NAME_UQ
JOIN RDB$INDICES S ON S.RDB$INDEX_NAME = RC.RDB$INDEX_NAME
JOIN RDB$INDEX_SEGMENTS ISG ON ISG.RDB$INDEX_NAME = S.RDB$INDEX_NAME
JOIN RDB$INDICES S2 ON S2.RDB$INDEX_NAME = RC2.RDB$INDEX_NAME
JOIN RDB$INDEX_SEGMENTS ISG2 ON ISG2.RDB$INDEX_NAME = S2.RDB$INDEX_NAME
WHERE RC.RDB$CONSTRAINT_TYPE = 'FOREIGN KEY'
  AND RC.RDB$RELATION_NAME = :TABELA;

-- Indexes (não-PK)
SELECT
  S.RDB$INDEX_NAME,
  S.RDB$UNIQUE_FLAG,
  ISG.RDB$FIELD_NAME
FROM RDB$INDICES S
JOIN RDB$INDEX_SEGMENTS ISG ON ISG.RDB$INDEX_NAME = S.RDB$INDEX_NAME
WHERE S.RDB$RELATION_NAME = :TABELA
  AND S.RDB$INDEX_NAME NOT IN (
    SELECT RDB$INDEX_NAME FROM RDB$RELATION_CONSTRAINTS
    WHERE RDB$RELATION_NAME = :TABELA AND RDB$CONSTRAINT_TYPE = 'PRIMARY KEY'
  );
```

---

## 4. Entity Reader

Lê classes Delphi com atributos MinusORM e monta `TDatabaseSchema` equivalente.

### Modo 1 — Parse Superficial (Recomendado)

Escaneia arquivos `.pas` com regex, sem compilar:

```pascal
TEntityReader = class
  class function ReadFromPath(const APath: string): TDatabaseSchema;
  class function ParseFile(const AFileName: string): TArray<TEntitySchema>;
end;
```

**Regex patterns buscados:**

```
\[Tabela\('(.+)'\)\]        → Nome da tabela
\[Coluna\('(.+)'\)\]        → Nome da coluna
\[Chave\]                   → Chave primária
\[Ignorar\]                 → Ignorar
class\s+(\w+)\s*=\s*class   → Nome da classe
property\s+(\w+)\s*:\s*(\w+) → Propriedade e tipo
```

**Mapeamento de tipos Delphi → TMigratorDataType:**

| Tipo Delphi | TMigratorDataType |
|---|---|
| `Integer` | `mdInteger` |
| `Int64` | `mdBigInt` |
| `string` | `mdVarchar` (length do atributo ou 255) |
| `Currency` | `mdNumeric(15,2)` |
| `Double` | `mdDouble` |
| `TDate` | `mdDate` |
| `TDateTime` | `mdTimestamp` |
| `TTime` | `mdTime` |
| `Boolean` | `mdChar(1)` ou `mdBoolean` |
| `TBytes` | `mdBlob` |
| `TStream` | `mdBlob` |

### Modo 2 — RTTI Real (Opcional)

Compila as units em DLL temporária e usa `TRttiContext`:
- Mais preciso (herança, interfaces, tipos complexos)
- Requer o compilador Delphi instalado
- Usado apenas quando disponível

---

## 5. Schema Differ

Compara dois `TDatabaseSchema` (entidades vs banco) e gera operações.

### Tipos de Mudança

```pascal
TSchemaChangeType = (
  sctCreateTable,
  sctDropTable,
  sctAddColumn,
  sctDropColumn,
  sctAlterColumn,
  sctAddIndex,
  sctDropIndex,
  sctAddForeignKey,
  sctDropForeignKey
);
```

### Algoritmo

```
function Diff(ASchemaA, ASchemaB: TDatabaseSchema): TArray<TSchemaChange>;

1. TABELAS NOVAS (em A, não em B)
   → sctCreateTable para cada

2. TABELAS REMOVIDAS (em B, não em A)
   → sctDropTable para cada

3. TABELAS COMUNS (existem em ambos)
   for each TableName:
     a. COLUNAS NOVAS (em A.Table, não em B.Table)
        → sctAddColumn
     b. COLUNAS REMOVIDAS (em B.Table, não em A.Table)
        → sctDropColumn
     c. COLUNAS ALTERADAS (mesmo nome, tipo/tamanho diferente)
        → sctAlterColumn
     d. ÍNDICES NOVOS → sctAddIndex
     e. ÍNDICES REMOVIDOS → sctDropIndex
     f. FKs NOVAS → sctAddForeignKey
     g. FKs REMOVIDAS → sctDropForeignKey

4. ORDENAÇÃO FINAL:
   - CREATE TABLE primeiro (necessário para FK)
   - ADD COLUMN
   - ALTER COLUMN
   - ADD INDEX
   - ADD FOREIGN KEY
   - DROP FOREIGN KEY
   - DROP INDEX
   - DROP COLUMN
   - DROP TABLE por último
```

---

## 6. SQL Generator

Converte `TArray<TSchemaChange>` em scripts SQL DDL.

### Interface

```pascal
ISQLGenerator = interface
  function GenerateCreateTable(const ATable: TTableSchema): TArray<string>;
  function GenerateDropTable(const ATableName: string): string;
  function GenerateAddColumn(const ATableName: string; const AColumn: TColumnSchema): string;
  function GenerateDropColumn(const ATableName, AColumnName: string): string;
  function GenerateAlterColumn(const ATableName: string;
    const ANewColumn, AOldColumn: TColumnSchema): string;
  function GenerateAddIndex(const ATableName: string; const AIndex: TIndexSchema): string;
  function GenerateDropIndex(const ATableName, AIndexName: string): string;
  function GenerateAddFK(const ATableName: string; const AFK: TForeignKeySchema): string;
  function GenerateDropFK(const ATableName, AFKName: string): string;
  function MapDataType(const ADataType: TMigratorDataType;
    ALength, APrecision, AScale: Integer): string;
  function StringifyChanges(const AChanges: TArray<TSchemaChange>): TArray<string>;
  function ProviderName: string;
end;
```

### Provider-aware DDL Examples

| Operação | Firebird | PostgreSQL | SQLite | MySQL |
|---|---|---|---|---|
| Auto PK | `INTEGER` + `GEN_ID` trigger | `SERIAL PRIMARY KEY` | `INTEGER PRIMARY KEY AUTOINCREMENT` | `INTEGER AUTO_INCREMENT PRIMARY KEY` |
| String | `VARCHAR(n)` | `VARCHAR(n)` | `TEXT` | `VARCHAR(n)` |
| Decimal | `NUMERIC(p,s)` | `NUMERIC(p,s)` | `REAL` | `DECIMAL(p,s)` |
| Date/time | `TIMESTAMP` | `TIMESTAMP` | `TEXT` (ISO) | `DATETIME` |
| Blob | `BLOB SUB_TYPE 0` | `BYTEA` | `BLOB` | `BLOB` |
| Add column | `ALTER TABLE t ADD COLUMN c tipo` | `ALTER TABLE t ADD COLUMN c tipo` | `ALTER TABLE t ADD COLUMN c tipo` | `ALTER TABLE t ADD COLUMN c tipo` |
| Alter column | `ALTER TABLE t ALTER COLUMN c TYPE tipo` | `ALTER TABLE t ALTER COLUMN c TYPE tipo` | Recria tabela | `ALTER TABLE t MODIFY COLUMN c tipo` |
| Drop column | `ALTER TABLE t DROP c` | `ALTER TABLE t DROP COLUMN c` | Recria tabela | `ALTER TABLE t DROP COLUMN c` |

---

## 7. Migration Runner

### Estrutura

```pascal
TMigrationRunner = class
  FConnection: TFDConnection;
  FMigrationsPath: string;
  FTabelaControle: string;  // __MINUSMIGRATOR_MIGRATIONS

  procedure Init;
  function GetStatus: TArray<TMigrationEntry>;
  function GetPending: TArray<string>;
  procedure ExecutePending(ADryRun: Boolean = False);
  procedure ExecuteFile(const AFileName: string; ADryRun: Boolean);
  procedure Rollback(ASteps: Integer = 1);
end;

TMigrationEntry = record
  ID: Integer;
  Name: string;
  Batch: Integer;
  ExecutedAt: TDateTime;
  Checksum: string;
  Status: (msPending, msExecuted, msFailed);
  DurationMs: Integer;
end;
```

### Tabela de Controle

```sql
CREATE TABLE __MINUSMIGRATOR_MIGRATIONS (
  ID          INTEGER       NOT NULL PRIMARY KEY,
  NAME        VARCHAR(255)  NOT NULL UNIQUE,
  BATCH       INTEGER       NOT NULL,
  EXECUTED_AT TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  CHECKSUM    VARCHAR(64),
  DURATION_MS INTEGER DEFAULT 0
);
```

### Nomenclatura de Arquivos

```
migrations/
├── 20260529_120000_AdicionarEmailProdutor.up.sql
├── 20260529_120000_AdicionarEmailProdutor.down.sql
├── 20260615_083000_CriarTabelaCategoria.up.sql
├── 20260615_083000_CriarTabelaCategoria.down.sql
└── ...

Formato: YYYYMMDD_HHMMSS_NomeDescritivo.{up|down}.sql
```

### Fluxo de Execução

```
migrate:
  1. Lê arquivos .up.sql da pasta, ordena por nome
  2. Lê tabela __MINUSMIGRATOR_MIGRATIONS → listas executadas
  3. Para cada arquivo não executado:
     a. Calcula MD5 checksum
     b. Executa conteúdo em transação
     c. Registra na tabela de controle
     d. Se falha, rollback da transação + aborta

rollback N:
  1. Lê últimos N registros da tabela (ordenados por ID DESC)
  2. Para cada um (em ordem reversa):
     a. Localiza .down.sql correspondente
     b. Executa
     c. Remove da tabela de controle
```

---

## 8. Estrutura de Diretórios

```
MinusMigrator/
├── Packages/
│   ├── MinusMigrator_Runtime.dpk    → BPL do núcleo
│   └── MinusMigrator_CLI.dpk        → CLI standalone
├── Source/
│   ├── MinusMigrator.CLI.pas        → Entry point, arg parser
│   ├── MinusMigrator.Commands.pas   → Handlers de cada comando
│   ├── MinusMigrator.Types.pas      → Enums, records, TDatabaseSchema
│   ├── MinusMigrator.SchemaReader.pas → Interface + base
│   ├── MinusMigrator.SchemaReader.Firebird.pas
│   ├── MinusMigrator.SchemaReader.PostgreSQL.pas
│   ├── MinusMigrator.SchemaReader.SQLite.pas
│   ├── MinusMigrator.SchemaReader.MySQL.pas
│   ├── MinusMigrator.EntityReader.pas → Lê .pas com atributos
│   ├── MinusMigrator.SchemaDiffer.pas → Comparação de schemas
│   ├── MinusMigrator.SQLGenerator.pas → Interface + base
│   ├── MinusMigrator.SQLGenerator.Firebird.pas
│   ├── MinusMigrator.SQLGenerator.PostgreSQL.pas
│   ├── MinusMigrator.SQLGenerator.SQLite.pas
│   ├── MinusMigrator.SQLGenerator.MySQL.pas
│   ├── MinusMigrator.Runner.pas     → Execução + rollback
│   ├── MinusMigrator.Config.pas     → Config de conexão
│   └── MinusMigrator.Utils.pas      → Helpers (hash, validação)
├── Tests/
│   ├── Test.Migrator.SchemaDiffer.pas
│   ├── Test.Migrator.SQLGenerator.pas
│   ├── Test.Migrator.Runner.pas
│   ├── Test.Migrator.SchemaReader.pas
│   └── Test.Migrator.EntityReader.pas
├── Samples/
│   └── models/
├── docker-compose.yml   → Firebird + PostgreSQL + MySQL para testes
└── README.md
```
