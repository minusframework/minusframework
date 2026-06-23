# Fluxo de Migração

## Inicialização

```powershell
MinusMigrator_CLI.exe init --connection "FB://localhost:3050/minha_db?user=SYSDBA&password=masterkey"
```

Cria:
- Diretório `Migrations\`
- Arquivo `Migrations\__init__.sql` (DDL da tabela de controle)
- Tabelas `__MINUSMIGRATOR_MIGRATIONS` e `__MINUSMIGRATOR_LOCK` no banco

## Adicionar Migração

```powershell
# O migrador compara suas entidades Delphi com o schema atual do banco
# e gera um arquivo .sql com as diferenças

MinusMigrator_CLI.exe add-migration "AdicionarTabelaClientes"

# Resultado: Migrations\20260621_1923_AdicionarTabelaClientes.sql
```

## Executar Migrações

```powershell
# Executa todas as migrações pendentes
MinusMigrator_CLI.exe migrate

# Com dry-run (não altera o banco)
MinusMigrator_CLI.exe migrate --dry-run
```

## Reverter

```powershell
# Reverter última migração
MinusMigrator_CLI.exe rollback

# Reverter 3 migrações
MinusMigrator_CLI.exe rollback --steps 3
```

## Status

```powershell
MinusMigrator_CLI.exe status
```

Exemplo de saída:
```
Migrações: 5 total, 2 pendentes, 3 executadas
Última execução: 2026-06-21 19:23:45

PENDENTES:
  [ ] 20260621_1923_AdicionarTabelaClientes
  [ ] 20260621_1930_AdicionarColunaEmail

EXECUTADAS:
  [x] 20260601_1000_Init
  [x] 20260610_1200_CriarTabelaUsuarios
  [x] 20260615_1400_CriarTabelaProdutos
```

## Auto-Migrate

Sincronização automática entre entidades e banco (sem arquivos de migração).

```powershell
# Útil em desenvolvimento
MinusMigrator_CLI.exe auto-migrate
```

## Tags

```powershell
# Marcar ponto no histórico
MinusMigrator_CLI.exe tag "v1.0.0"
MinusMigrator_CLI.exe tag "v1.1.0"

# Rollback até uma tag
MinusMigrator_CLI.exe rollback --tag "v1.0.0"
```

## Lint

```powershell
MinusMigrator_CLI.exe lint

# Exemplo de saída:
# WARNING: Tabela "PRODUTOS" sem chave primária
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
