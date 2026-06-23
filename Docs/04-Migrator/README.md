# MinusMigrator — Migração de Schema de Banco de Dados

**Projetos:**
- `MinusMigrator_DLL.dproj` — DLL com API C-compatible
- `MinusMigrator_CLI.dproj` — CLI (console)
- `MinusMigrator_GUI.dproj` — GUI (VCL Forms)

**Diretório:** `Source\Migrator\`

Sistema completo de migração de schema com suporte a múltiplos bancos, changelog em JSON/XML/YAML, scaffolding, lint e diff.

---

## Fluxo de Trabalho

```
Entidades Delphi  ──→  LeitorEntidade  ──→  Esquema (modelo)
                                                │
Banco de Dados  ──→  LeitorEsquema  ──→  Esquema (real)
                                                │
                                          Comparador
                                                │
                                          Alterações
                                                │
                                          Gerador SQL
                                                │
                                          Executor
```

---

## CLI — Comandos

```
MinusMigrator_CLI.exe <comando> [opções]
```

### `init`
Inicializa o diretório de migrações.
```
MinusMigrator_CLI.exe init --connection "FB://localhost:3050/minha_db?user=SYSDBA&password=masterkey"
```

### `add-migration`
Cria um novo arquivo de migração baseado na diferença entre entidades e banco.
```
MinusMigrator_CLI.exe add-migration "AdicionarTabelaClientes"
```

### `migrate`
Executa migrações pendentes.
```
MinusMigrator_CLI.exe migrate --connection "FB://..."
```

### `rollback`
Reverte a última migração.
```
MinusMigrator_CLI.exe rollback

# Reverter N migrações
MinusMigrator_CLI.exe rollback --steps 3
```

### `status`
Exibe o estado atual das migrações.
```
MinusMigrator_CLI.exe status --connection "FB://..."
```

### `auto-migrate`
Sincroniza o banco com as entidades automaticamente (sem arquivos de migração).
```
MinusMigrator_CLI.exe auto-migrate --connection "FB://..."
```

### `generate-models`
Gera classes Delphi a partir do schema do banco.
```
MinusMigrator_CLI.exe generate-models --connection "FB://..." --output "..\Source\Models"
```

### `diff-changelog`
Gera um changelog comparando entidades com banco.
```
MinusMigrator_CLI.exe diff-changelog --connection "FB://..."
```

### `changelog-apply`
Aplica um changelog (formato Liquibase).
```
MinusMigrator_CLI.exe changelog-apply --file "changelog.xml"
```

### `snapshot`
Captura um snapshot do schema atual.
```
MinusMigrator_CLI.exe snapshot --connection "FB://..." --output "snapshot.json"
```

### `diff-snapshots`
Compara dois snapshots.
```
MinusMigrator_CLI.exe diff-snapshots --before "v1.json" --after "v2.json"
```

### `lint`
Valida o schema contra boas práticas.
```
MinusMigrator_CLI.exe lint --connection "FB://..."
```

### `tag`
Adiciona uma tag ao histórico de migrações.
```
MinusMigrator_CLI.exe tag "v1.0.0"
```

### `diff-databases`
Compara schemas de dois bancos diferentes.
```
MinusMigrator_CLI.exe diff-databases --source "FB://..." --target "PG://..."
```

---

## Conexão (string format)

```
<driver>://<host>:<port>/<database>?user=<user>&password=<pass>
```

| Driver | Banco | Exemplo |
|--------|-------|---------|
| `FB` | Firebird | `FB://localhost:3050/C:\db.fdb?user=SYSDBA&password=masterkey` |
| `SQLite` | SQLite | `SQLite:///C:\db.sqlite` |
| `PG` | PostgreSQL | `PG://localhost:5433/minusorm_test?user=postgres&password=postgres` |
| `MySQL` | MySQL | `MySQL://localhost:3307/minusorm_test?user=root&password=root` |
| `MariaDB` | MariaDB | `MariaDB://localhost:3308/minusorm_test?user=root&password=root` |

---

## Tabelas de Controle

### `__MINUSMIGRATOR_MIGRATIONS`
Registra todas as migrações executadas:
- `ID` (identity)
- `Nome` — nome da migração
- `AplicadaEm` — timestamp
- `Checksum` — hash do conteúdo
- `Tipo` — `migrate` ou `rollback`
- `Tag` — tag opcional

### `__MINUSMIGRATOR_LOCK`
Lock de migração (impede execução concorrente):
- `Locked` — 0/1
- `LockedBy` — hostname
- `LockedAt` — timestamp

---

## Changelog

Serialização do histórico de alterações em múltiplos formatos.

### JSON

```json
{
  "databaseChangeLog": [
    {
      "changes": [
        {
          "tipo": "satCriarTabela",
          "nomeTabela": "PRODUTOS",
          "colunas": [
            { "nome": "ID_PRODUTO", "tipo": "INTEGER", "chavePrimaria": true },
            { "nome": "NOME", "tipo": "VARCHAR(100)" }
          ]
        }
      ]
    }
  ]
}
```

### XML (Liquibase-style)

```xml
<databaseChangeLog>
  <changeSet author="dev" id="1">
    <createTable tableName="PRODUTOS">
      <column name="ID_PRODUTO" type="INTEGER" autoIncrement="true">
        <constraints primaryKey="true"/>
      </column>
      <column name="NOME" type="VARCHAR(100)"/>
    </createTable>
  </changeSet>
</databaseChangeLog>
```

---

## Schema Linter

Validações realizadas pelo `lint`:

| Regra | Descrição |
|-------|-----------|
| `PK_MISSING` | Tabela sem chave primária |
| `FK_MISSING` | Coluna sufixada com `_ID` sem FK correspondente |
| `NAME_CONVENTION` | Nome fora do padrão (snake_case) |
| `TYPE_SUGGESTION` | Tipo de dado sub-ótimo |
| `NULLABLE_PK` | PK anulável |

---

## DLL API (C-compatible)

A DLL `MinusMigrator.dll` exporta funções para uso de qualquer linguagem:

```c
int mmInit(const char* connectionString, const char* migrationsDir);
int mmMigrate();
int mmRollback(int steps);
int mmStatus();
int mmAddMigration(const char* name);
int mmAutoMigrate();
int mmDiffChangelog(const char* entityDir, const char* outputFile);
int mmApplyChangelog(const char* changelogFile);
int mmSnapshot(const char* outputFile);
int mmDiffSnapshots(const char* before, const char* after, const char* output);
int mmGenerateModels(const char* outputDir);
int mmDiffDatabases(const char* source, const char* target, const char* output);
int mLint();
int mTag(const char* tagName);
int mmVersion();
int mmPing();
```

---

## GUI

O `MinusMigrator_GUI.exe` fornece uma interface visual VCL para:

- Gerenciar conexões
- Visualizar status das migrações
- Executar/desfazer migrações
- Visualizar diff de schema
- Editar changelog
- Scaffolding visual

---

## Tipos de Schema

| Tipo | Descrição |
|------|-----------|
| `TTipoDadoMigrador` | Enum de tipos: `tmChar`, `tmVarchar`, `tmInteger`, `tmBigInt`, `tmDecimal`, `tmDate`, `tmTimestamp`, `tmBlob`, `tmBoolean`, etc. |
| `TEsquemaColuna` | Coluna: nome, tipo, tamanho, nullable, default, PK, FK |
| `TEsquemaIndice` | Índice: nome, colunas, único |
| `TEsquemaChaveEstrangeira` | FK: colunas, tabela referenciada, colunas referenciadas |
| `TEsquemaTabela` | Tabela: nome, colunas, índices, FKs |
| `TEsquemaBancoDados` | Banco: conjunto de tabelas |
| `TAlteracaoEsquema` | Change: tipo (`satCriarTabela`, `satAdicionarColuna`, etc.), detalhes |
| `TChangeset` | Changelog entry: autor, descrição, alterações |

---

## Schema Readers por Banco

| Unit | Banco |
|------|-------|
| `MF.Migrator.SchemaReader.SQLite.pas` | SQLite |
| `MF.Migrator.SchemaReader.Firebird.pas` | Firebird |
| `MF.Migrator.SchemaReader.PostgreSQL.pas` | PostgreSQL |
| `MF.Migrator.SchemaReader.MySQL.pas` | MySQL |
| `MF.Migrator.SchemaReader.MariaDB.pas` | MariaDB |
| `MF.Migrator.SchemaReader.MSSQL.pas` | SQL Server |
| `MF.Migrator.SchemaReader.Oracle.pas` | Oracle |
| `MF.Migrator.SchemaReader.DB2.pas` | IBM DB2 |

## SQL Generators por Banco

| Unit | Banco |
|------|-------|
| `MF.Migrator.SQLGenerator.SQLite.pas` | SQLite |
| `MF.Migrator.SQLGenerator.Firebird.pas` | Firebird |
| `MF.Migrator.SQLGenerator.PostgreSQL.pas` | PostgreSQL |
| `MF.Migrator.SQLGenerator.MySQL.pas` | MySQL |
| `MF.Migrator.SQLGenerator.MariaDB.pas` | MariaDB |
| `MF.Migrator.SQLGenerator.MSSQL.pas` | SQL Server |
| `MF.Migrator.SQLGenerator.Oracle.pas` | Oracle |
| `MF.Migrator.SQLGenerator.DB2.pas` | IBM DB2 |
