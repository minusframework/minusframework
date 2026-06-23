# Testes

## Projetos de Teste

| Projeto | Framework | O que testa |
|---------|-----------|-------------|
| `Test.MinusORM` | DUnitX | ORM core, providers, criteria, query builders |
| `Test.MinusMigrator` | DUnitX | Schema readers, SQL generators, differ, runner |
| `Test.MinusMessaging` | DUnitX | Message bus, providers, patterns |
| `Test.MinusFeatureFlags` | DUnitX | Flag evaluation, providers, SDK |

## Executar Testes

### Pela IDE

1. Abrir o `.dproj` de teste
2. **Run → Run** (F9)

### Pelo PowerShell

```powershell
# ORM
.\Tests\ORM\Win32\Debug\Test.MinusORM.exe

# Migrator
.\Tests\Migrator\Win32\Debug\Test.MinusMigrator.exe
```

### Com Docker (bancos externos)

```powershell
# Subir bancos
docker compose up -d

# Executar ORM tests (todos os 302 passam)
.\Tests\ORM\Win32\Debug\Test.MinusORM.exe
```

## Estrutura

```
Tests\
  ORM\             -> 302 testes (242 unitários + 60 integração)
    Test.ORM.*.pas
  Migrator\        -> Testes do migrator
    Test.Migrator.*.pas
  Messaging\
    Test.Messaging.*.pas
  FeatureFlags\
    Test.FeatureFlags.*.pas
```

## Resultados

Os testes geram XML de resultado em `TestResults\`:

- `Tests\ORM\TestResults\orm_test_results.xml`
- `Tests\Migrator\TestResults\migrator_test_results.xml`
