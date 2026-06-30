# Guia de Deployment

## Build dos Pacotes

### Pela IDE

1. Abrir `MinusFramework.groupproj`
2. **Build All** (Ctrl+Shift+F9)

Os `.bpl` sÃ£o gerados em `C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\`

### Pela Pipeline

```powershell
# Requer MSBuild do Delphi
MSBuild MinusFramework.groupproj /t:Build /p:Config=Release /p:Platform=Win32
```

## DistribuiÃ§Ã£o

### Runtime mÃ­nimo (ORM apenas)

Arquivos necessÃ¡rios:
- `MinusFramework_Runtime.bpl`
- `rtl.bpl` (da IDE)
- `FireDAC* .bpl` (se usar FireDAC)
- DLLs nativas: `fbclient.dll`, `libpq.dll`, `libmariadb.dll`, etc.

### AplicaÃ§Ã£o standalone (static link)

Para evitar dependÃªncia de `.bpl`, compile os projetos `.dpr` diretamente:

```
MinusORM.dll
MinusMigrator_DLL.dll
MinusMigrator_CLI.exe
MinusMigrator_GUI.exe
```

### Docker

```dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2022

COPY MinusMigrator_CLI.exe /app/
COPY MinusMigrator_DLL.dll /app/
COPY fbclient.dll /app/

ENTRYPOINT ["/app/MinusMigrator_CLI.exe"]
```

## CI/CD

```yaml
# .github/workflows/migrate.yml
on:
  push:
    branches: [main]

jobs:
  migrate:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: myapp
          POSTGRES_PASSWORD: secret

    steps:
      - uses: actions/checkout@v4
      - run: dotnet tool install -g MinusMigrator.CLI
      - run: MinusMigrator_CLI.exe migrate --connection "${{ secrets.DB_CONN }}"
```

## VariÃ¡veis de Ambiente

| VariÃ¡vel | Uso | Projeto |
|----------|-----|---------|
| `MINUSORM_TEST_FIREBIRD` | Caminho do banco de teste Firebird | Testes |
| `MINUSORM_TEST_FB_HOST` | Host Firebird de teste | Testes |
| `MINUSORM_TEST_MYSQLHOST` | Host MySQL de teste | Testes |
| `MINUSORM_TEST_PGHOST` | Host PostgreSQL de teste | Testes |
