# MinusMigrator â€” Arquitetura

> **Projeto:** MinusMigrator
> **PropÃ³sito:** CLI standalone para controle versionado de schema de banco de dados
> **DependÃªncia externa:** FireDAC (apenas para conexÃ£o com banco)
> **DependÃªncia de conceito:** Atributos do MinusORM (via parse textual)

---

## SumÃ¡rio

1. [VisÃ£o Geral](#1-visÃ£o-geral)
2. [CLI Layer](#2-cli-layer)
3. [Schema Reader](#3-schema-reader)
4. [Entity Reader](#4-entity-reader)
5. [Schema Differ](#5-schema-differ)
6. [SQL Generator](#6-sql-generator)
7. [Migration Runner](#7-migration-runner)
8. [Estrutura de DiretÃ³rios](#8-estrutura-de-diretÃ³rios)

---

## 1. VisÃ£o Geral

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                   MinusMigrator CLI                      â”‚
â”‚                     (minusmigrator.exe)                  â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                                                         â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚               CLI Layer                           â”‚   â”‚
â”‚  â”‚  add-migration â”‚ migrate â”‚ status â”‚ rollback     â”‚   â”‚
â”‚  â”‚  generate-models â”‚ init â”‚ --help                 â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚             â”‚               â”‚                           â”‚
â”‚     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â” â”Œâ”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”                  â”‚
â”‚     â”‚  Command       â”‚ â”‚  Schema     â”‚                  â”‚
â”‚     â”‚  Handlers      â”‚ â”‚  Reader     â”‚                  â”‚
â”‚     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”˜ â””â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”˜                  â”‚
â”‚             â”‚              â”‚                            â”‚
â”‚     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”                  â”‚
â”‚     â”‚        Schema Differ          â”‚                  â”‚
â”‚     â”‚  Entities Schema  vs  DB Schema                 â”‚
â”‚     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                  â”‚
â”‚             â”‚                                          â”‚
â”‚     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                  â”‚
â”‚     â”‚        SQL Generator          â”‚                  â”‚
â”‚     â”‚  Provider-aware DDL gerado    â”‚                  â”‚
â”‚     â””â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜                  â”‚
â”‚             â”‚                                          â”‚
â”‚     â”Œâ”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”                  â”‚
â”‚     â”‚     Migration Runner          â”‚                  â”‚
â”‚     â”‚  Executa .sql, controla versÃ£o                  â”‚
â”‚     â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 2. CLI Layer

### Comandos

| Comando | Sintaxe | DescriÃ§Ã£o |
|---|---|---|
| `init` | `minusmigrator init -c "firebird://..."` | Cria tabela `__MINUSMIGRATOR_MIGRATIONS` |
| `add-migration` | `minusmigrator add-migration "Nome" -p Models/ -c "firebird://..."` | Gera `.up.sql` + `.down.sql` |
| `migrate` | `minusmigrator migrate -c "firebird://..." [--dry-run] [-v]` | Executa pendentes |
| `rollback` | `minusmigrator rollback -c "firebird://..." [-n 3]` | Reverte N migrations |
| `status` | `minusmigrator status -c "firebird://..."` | Lista migraÃ§Ãµes com status |
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

LÃª a estrutura atual do banco e monta `TDatabaseSchema`.

### Hierarquia de Classes

```
TDatabaseSchema
â””â”€â”€ TTableSchema (1..n)
    â”œâ”€â”€ FName: string
    â”œâ”€â”€ FColumns: TObjectList<TColumnSchema>
    â”‚   â””â”€â”€ TColumnSchema
    â”‚       â”œâ”€â”€ FName: string
    â”‚       â”œâ”€â”€ FDataType: TMigratorDataType
    â”‚       â”œâ”€â”€ FLength: Integer
    â”‚       â”œâ”€â”€ FPrecision: Integer
    â”‚       â”œâ”€â”€ FScale: Integer
    â”‚       â”œâ”€â”€ FNotNull: Boolean
    â”‚       â”œâ”€â”€ FDefaultValue: string
    â”‚       â”œâ”€â”€ FAutoIncrement: Boolean
    â”‚       â””â”€â”€ FIsPrimaryKey: Boolean
    â”œâ”€â”€ FPrimaryKey: TIndexSchema
    â”œâ”€â”€ FIndexes: TObjectList<TIndexSchema>
    â”‚   â””â”€â”€ TIndexSchema
    â”‚       â”œâ”€â”€ FName: string
    â”‚       â”œâ”€â”€ FColumns: TArray<string>
    â”‚       â””â”€â”€ FUnique: Boolean
    â””â”€â”€ FForeignKeys: TObjectList<TForeignKeySchema>
        â””â”€â”€ TForeignKeySchema
            â”œâ”€â”€ FName: string
            â”œâ”€â”€ FColumns: TArray<string>
            â”œâ”€â”€ FReferencedTable: string
            â”œâ”€â”€ FReferencedColumns: TArray<string>
            â””â”€â”€ FOnDelete: string
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

### ImplementaÃ§Ãµes

| Provider | Classe | Fontes de Dados |
|---|---|---|
| Firebird | `TSchemaReaderFirebird` | `RDB$RELATIONS`, `RDB$RELATION_FIELDS`, `RDB$FIELDS`, `RDB$INDICES`, `RDB$INDEX_SEGMENTS`, `RDB$REFENTIAL_CONSTRAINTS` |
| PostgreSQL | `TSchemaReaderPostgreSQL` | `information_schema.tables`, `information_schema.columns`, `pg_indexes`, `pg_constraint` |
| SQLite | `TSchemaReaderSQLite` | `sqlite_master`, `PRAGMA table_info`, `PRAGMA index_list`, `PRAGMA foreign_key_list` |
| MySQL | `TSchemaReaderMySQL` | `information_schema.tables`, `information_schema.columns`, `information_schema.key_column_usage`, `information_schema.table_constraints` |

### Exemplo â€” Schema Reader Firebird

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

-- Indexes (nÃ£o-PK)
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

LÃª classes Delphi com atributos MinusORM e monta `TDatabaseSchema` equivalente.

### Modo 1 â€” Parse Superficial (Recomendado)

Escaneia arquivos `.pas` com regex, sem compilar:

```pascal
TEntityReader = class
  class function ReadFromPath(const APath: string): TDatabaseSchema;
  class function ParseFile(const AFileName: string): TArray<TEntitySchema>;
end;
```

**Regex patterns buscados:**

```
\[Tabela\('(.+)'\)\]        â†’ Nome da tabela
\[Coluna\('(.+)'\)\]        â†’ Nome da coluna
\[Chave\]                   â†’ Chave primÃ¡ria
\[Ignorar\]                 â†’ Ignorar
class\s+(\w+)\s*=\s*class   â†’ Nome da classe
property\s+(\w+)\s*:\s*(\w+) â†’ Propriedade e tipo
```

**Mapeamento de tipos Delphi â†’ TMigratorDataType:**

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

### Modo 2 â€” RTTI Real (Opcional)

Compila as units em DLL temporÃ¡ria e usa `TRttiContext`:
- Mais preciso (heranÃ§a, interfaces, tipos complexos)
- Requer o compilador Delphi instalado
- Usado apenas quando disponÃ­vel

---

## 5. Schema Differ

Compara dois `TDatabaseSchema` (entidades vs banco) e gera operaÃ§Ãµes.

### Tipos de MudanÃ§a

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

1. TABELAS NOVAS (em A, nÃ£o em B)
   â†’ sctCreateTable para cada

2. TABELAS REMOVIDAS (em B, nÃ£o em A)
   â†’ sctDropTable para cada

3. TABELAS COMUNS (existem em ambos)
   for each TableName:
     a. COLUNAS NOVAS (em A.Table, nÃ£o em B.Table)
        â†’ sctAddColumn
     b. COLUNAS REMOVIDAS (em B.Table, nÃ£o em A.Table)
        â†’ sctDropColumn
     c. COLUNAS ALTERADAS (mesmo nome, tipo/tamanho diferente)
        â†’ sctAlterColumn
     d. ÃNDICES NOVOS â†’ sctAddIndex
     e. ÃNDICES REMOVIDOS â†’ sctDropIndex
     f. FKs NOVAS â†’ sctAddForeignKey
     g. FKs REMOVIDAS â†’ sctDropForeignKey

4. ORDENAÃ‡ÃƒO FINAL:
   - CREATE TABLE primeiro (necessÃ¡rio para FK)
   - ADD COLUMN
   - ALTER COLUMN
   - ADD INDEX
   - ADD FOREIGN KEY
   - DROP FOREIGN KEY
   - DROP INDEX
   - DROP COLUMN
   - DROP TABLE por Ãºltimo
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

| OperaÃ§Ã£o | Firebird | PostgreSQL | SQLite | MySQL |
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
â”œâ”€â”€ 20260529_120000_AdicionarEmailProdutor.up.sql
â”œâ”€â”€ 20260529_120000_AdicionarEmailProdutor.down.sql
â”œâ”€â”€ 20260615_083000_CriarTabelaCategoria.up.sql
â”œâ”€â”€ 20260615_083000_CriarTabelaCategoria.down.sql
â””â”€â”€ ...

Formato: YYYYMMDD_HHMMSS_NomeDescritivo.{up|down}.sql
```

### Fluxo de ExecuÃ§Ã£o

```
migrate:
  1. LÃª arquivos .up.sql da pasta, ordena por nome
  2. LÃª tabela __MINUSMIGRATOR_MIGRATIONS â†’ listas executadas
  3. Para cada arquivo nÃ£o executado:
     a. Calcula MD5 checksum
     b. Executa conteÃºdo em transaÃ§Ã£o
     c. Registra na tabela de controle
     d. Se falha, rollback da transaÃ§Ã£o + aborta

rollback N:
  1. LÃª Ãºltimos N registros da tabela (ordenados por ID DESC)
  2. Para cada um (em ordem reversa):
     a. Localiza .down.sql correspondente
     b. Executa
     c. Remove da tabela de controle
```

---

## 8. Estrutura de DiretÃ³rios

```
MinusMigrator/
â”œâ”€â”€ Packages/
â”‚   â”œâ”€â”€ MinusMigrator_Runtime.dpk    â†’ BPL do nÃºcleo
â”‚   â””â”€â”€ MinusMigrator_CLI.dpk        â†’ CLI standalone
â”œâ”€â”€ Source/
â”‚   â”œâ”€â”€ MinusMigrator.CLI.pas        â†’ Entry point, arg parser
â”‚   â”œâ”€â”€ MinusMigrator.Commands.pas   â†’ Handlers de cada comando
â”‚   â”œâ”€â”€ MinusMigrator.Types.pas      â†’ Enums, records, TDatabaseSchema
â”‚   â”œâ”€â”€ MinusMigrator.SchemaReader.pas â†’ Interface + base
â”‚   â”œâ”€â”€ MinusMigrator.SchemaReader.Firebird.pas
â”‚   â”œâ”€â”€ MinusMigrator.SchemaReader.PostgreSQL.pas
â”‚   â”œâ”€â”€ MinusMigrator.SchemaReader.SQLite.pas
â”‚   â”œâ”€â”€ MinusMigrator.SchemaReader.MySQL.pas
â”‚   â”œâ”€â”€ MinusMigrator.EntityReader.pas â†’ LÃª .pas com atributos
â”‚   â”œâ”€â”€ MinusMigrator.SchemaDiffer.pas â†’ ComparaÃ§Ã£o de schemas
â”‚   â”œâ”€â”€ MinusMigrator.SQLGenerator.pas â†’ Interface + base
â”‚   â”œâ”€â”€ MinusMigrator.SQLGenerator.Firebird.pas
â”‚   â”œâ”€â”€ MinusMigrator.SQLGenerator.PostgreSQL.pas
â”‚   â”œâ”€â”€ MinusMigrator.SQLGenerator.SQLite.pas
â”‚   â”œâ”€â”€ MinusMigrator.SQLGenerator.MySQL.pas
â”‚   â”œâ”€â”€ MinusMigrator.Runner.pas     â†’ ExecuÃ§Ã£o + rollback
â”‚   â”œâ”€â”€ MinusMigrator.Config.pas     â†’ Config de conexÃ£o
â”‚   â””â”€â”€ MinusMigrator.Utils.pas      â†’ Helpers (hash, validaÃ§Ã£o)
â”œâ”€â”€ Tests/
â”‚   â”œâ”€â”€ Test.Migrator.SchemaDiffer.pas
â”‚   â”œâ”€â”€ Test.Migrator.SQLGenerator.pas
â”‚   â”œâ”€â”€ Test.Migrator.Runner.pas
â”‚   â”œâ”€â”€ Test.Migrator.SchemaReader.pas
â”‚   â””â”€â”€ Test.Migrator.EntityReader.pas
â”œâ”€â”€ Samples/
â”‚   â””â”€â”€ models/
â”œâ”€â”€ docker-compose.yml   â†’ Firebird + PostgreSQL + MySQL para testes
â””â”€â”€ README.md
```
