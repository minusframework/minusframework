# MinusMigrator

Sistema completo de migraÃ§Ã£o de schema de banco de dados para Delphi.

## Projetos

| Projeto | Tipo | DescriÃ§Ã£o |
|---|---|---|
| `MinusMigrator_DLL.dproj` | DLL | API C-compatible |
| `MinusMigrator_CLI.dproj` | EXE | CLI (console) |
| `MinusMigrator_GUI.dproj` | VCL App | GUI (VCL Forms) |
| `Test.MinusMigrator.dproj` | EXE (DUnitX) | Testes unitÃ¡rios |

## Uso

```
MinusMigrator_CLI.exe init -c "sqlite://./app.db"
MinusMigrator_CLI.exe migrate -c "sqlite://..." -p .\migrations
MinusMigrator_CLI.exe status -c "sqlite://..." -p .\migrations
MinusMigrator_CLI.exe rollback -c "sqlite://..." -p .\migrations
```

## DocumentaÃ§Ã£o

- [Roadmap](Docs/ROADMAP.md)
- [Changelog](Docs/CHANGELOG.md)
- [DocumentaÃ§Ã£o tÃ©cnica](Docs/README.md)
- [Guia de migration workflow](Docs/migration-workflow.md)
- [Arquitetura](Docs/MINUSMIGRATOR_ARQUITETURA.md)
