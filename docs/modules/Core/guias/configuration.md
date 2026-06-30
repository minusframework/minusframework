# Guia de ConfiguraÃ§Ã£o

## String de ConexÃ£o

Formato: `<driver>://[user[:pass]@]<host>[:port]/<database>[?param=value]`

### Exemplos por Banco

```pascal
// SQLite (arquivo)
'SQLite:///C:/Dados/app.db'
'SQLite:///:memory:'  // banco em memÃ³ria

// Firebird
'FB://localhost:3050/C:/Dados/DB.FDB?user=SYSDBA&password=masterkey'

// PostgreSQL
'PG://localhost:5433/minusorm_test?user=postgres&password=postgres'

// MySQL
'MySQL://localhost:3307/minusorm_test?user=root&password=root'

// MariaDB
'MariaDB://localhost:3308/minusorm_test?user=root&password=root'
```

## ConfiguraÃ§Ã£o ProgramÃ¡tica

```pascal
uses
  MF.Config,
  MF.ConnectionPool;

// ConfiguraÃ§Ã£o bÃ¡sica
TConfiguracaoORM.Configurar('SQLite:///C:/db.sqlite');

// Pool de conexÃµes
var LPool: TConfiguracaoPool;
LPool.MinSize := 2;
LPool.MaxSize := 10;
LPool.TimeoutMs := 30000;
TConfiguracaoORM.ConfiguracaoPool := LPool;

// Cache
TConfiguracaoORM.CacheAtivo := True;

// AutoMapper
TConfiguracaoORM.AutoMapear(TAutoMapeamento.Create(ncSnakeCase));

// Soft Delete global
TConfiguracaoORM.SoftDeleteAtivo := True;

// Auditoria
TAjudanteAuditoria.Ativo := True;
TAjudanteAuditoria.UsuarioAtual := 'sistema';
```

## Feature Flags

```pascal
// Registrar provider
TConfiguracaoORM.FeatureFlags.Provedor :=
  TProviderJSON.Create('flags.json');

// Verificar
if TConfiguracaoORM.FeatureFlags.Habilitada('nova-funcionalidade') then ...
```

## Multi-Tenancy

```pascal
TContextoInquilino.Atual.AtribuirInquilino(42);
```

## Docker (Ambiente de Desenvolvimento)

```powershell
# Subir bancos
docker compose up -d

# Verificar status
docker compose ps

# Parar
docker compose down
```
