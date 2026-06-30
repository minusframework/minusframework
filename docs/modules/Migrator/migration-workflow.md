# Fluxo de MigraÃ§Ã£o

## InicializaÃ§Ã£o

```powershell
MinusMigrator_CLI.exe init --connection "FB://localhost:3050/minha_db?user=SYSDBA&password=masterkey"
```

Cria:
- DiretÃ³rio `Migrations\`
- Arquivo `Migrations\__init__.sql` (DDL da tabela de controle)
- Tabelas `__MINUSMIGRATOR_MIGRATIONS` e `__MINUSMIGRATOR_LOCK` no banco

## Adicionar MigraÃ§Ã£o

```powershell
# O migrador compara suas entidades Delphi com o schema atual do banco
# e gera um arquivo .sql com as diferenÃ§as

MinusMigrator_CLI.exe add-migration "AdicionarTabelaClientes"

# Resultado: Migrations\20260621_1923_AdicionarTabelaClientes.sql
```

## Executar MigraÃ§Ãµes

```powershell
# Executa todas as migraÃ§Ãµes pendentes
MinusMigrator_CLI.exe migrate

# Com dry-run (nÃ£o altera o banco)
MinusMigrator_CLI.exe migrate --dry-run
```

## Reverter

```powershell
# Reverter Ãºltima migraÃ§Ã£o
MinusMigrator_CLI.exe rollback

# Reverter 3 migraÃ§Ãµes
MinusMigrator_CLI.exe rollback --steps 3
```

## Status

```powershell
MinusMigrator_CLI.exe status
```

Exemplo de saÃ­da:
```
MigraÃ§Ãµes: 5 total, 2 pendentes, 3 executadas
Ãšltima execuÃ§Ã£o: 2026-06-21 19:23:45

PENDENTES:
  [ ] 20260621_1923_AdicionarTabelaClientes
  [ ] 20260621_1930_AdicionarColunaEmail

EXECUTADAS:
  [x] 20260601_1000_Init
  [x] 20260610_1200_CriarTabelaUsuarios
  [x] 20260615_1400_CriarTabelaProdutos
```

## Auto-Migrate

SincronizaÃ§Ã£o automÃ¡tica entre entidades e banco (sem arquivos de migraÃ§Ã£o).

```powershell
# Ãštil em desenvolvimento
MinusMigrator_CLI.exe auto-migrate
```

## Tags

```powershell
# Marcar ponto no histÃ³rico
MinusMigrator_CLI.exe tag "v1.0.0"
MinusMigrator_CLI.exe tag "v1.1.0"

# Rollback atÃ© uma tag
MinusMigrator_CLI.exe rollback --tag "v1.0.0"
```

## Lint

```powershell
MinusMigrator_CLI.exe lint

# Exemplo de saÃ­da:
# WARNING: Tabela "PRODUTOS" sem chave primÃ¡ria
# WARNING: Coluna "CLIENTE_ID" sem FK correspondente
# ERROR: Tabela "CLIENTES" nome inconsistente (esperado: "CLIENTE")
```

## Snapshot

```powershell
# Capturar schema atual
MinusMigrator_CLI.exe snapshot --output "schema.json"

# Comparar dois momentos
MinusMigrator_CLI.exe diff-snapshots --before "schema-v1.json" --after "schema-v2.json"
```

## Generate Models

Gera classes Delphi a partir do banco existente:

```powershell
MinusMigrator_CLI.exe generate-models
  --connection "FB://localhost:3050/minha_db?user=SYSDBA&password=masterkey"
  --output "..\Source\Models"
  --namespace "MeuProjeto.Model"
```
