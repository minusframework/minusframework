# MinusMigrator â€” Roadmap

> **Ãšltima atualizaÃ§Ã£o:** Junho/2026

## MinusMigrator Fase 1 (ConcluÃ­da)

- `TDatabaseSchema` + SchemaReader Firebird/PostgreSQL/SQLite/MySQL
- SchemaDiffer (algoritmo de comparaÃ§Ã£o)
- SQLGenerator para todos os providers
- Runner + CLI (init, migrate, rollback, status)
- EntityReader (parse de .pas com atributos)
- Auto-migrate com confirmaÃ§Ã£o
- Testes com Docker

## MinusMigrator Fase 2 (ConcluÃ­da)

| Tarefa | Status |
|---|---|
| Lock de tabela de controle (`__MINUSMIGRATOR_LOCK`) | OK |
| Add-migration via diff (gera `.up.sql` + `.down.sql` versionados) | OK |
| Changelog JSON/YAML/XML (input + output) | OK |
| Repeatable migrations (runOnChange: `R__*.up.sql`) | OK |
| Tag command + rollback-to-tag | OK |
| CI/CD mode: `--force` no auto-migrate | OK |
| Preconditions (`tableExists`, `columnNotExists`, `dbms`, etc.) | OK |
| Contexts (`--context <nome>` filtra subdiretÃ³rio) | OK |
| Generate-models (reverse engineering .pas do BD) | OK |
| Track auto-migrate na tabela de controle | OK |
| Provider MSSQL (SchemaReader + SQLGenerator) | OK |
| Dry run (`--dry-run`) | OK |
| SQL Lint/Validation (`minusmigrator lint`) | OK |
| Diff entre 2 bancos (`minusmigrator diff-bancos`) | OK |
| Rollback seletivo por changeset ID | OK |
| Changesets reorganizÃ¡veis (YAML/JSON/XML input) | OK |

## MinusMigrator Fase 3 (Planejado)

- Oracle / DB2 providers
- DLL API com exports C-compatible
- GUI / IDE Expert para RAD Studio
- REST API (`POST /migrate`, `GET /status`, etc.)
- Changelog XML/Liquibase-compatÃ­vel
- diff-changelog + diff com snapshot
- GetIt Package + MSBuild Task
- BPL Design/Runtime
