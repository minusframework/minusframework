# Standalone DLLs

Duas DLLs com API C-compatible para uso de qualquer linguagem (C#, Python, C++, etc.).

---

## MinusORM.dll

### Uso

```c
// C
HMODULE h = LoadLibrary("MinusORM.dll");

typedef int (*ORM_ConnectFn)(const char* connStr);
ORM_ConnectFn ORM_Connect = (ORM_ConnectFn)GetProcAddress(h, "ORM_Connect");

int result = ORM_Connect("FB://localhost:3050/minha_db?user=SYSDBA&password=masterkey");
```

```python
# Python
import ctypes

orm = ctypes.CDLL("MinusORM.dll")
orm.ORM_Connect(b"SQLite:///C:/dados.db")
```

### API Exportada

```c
int ORM_Connect(const char* connectionString);
int ORM_Execute(const char* sql);
void* ORM_Open(const char* sql);
void ORM_Close(void* resultSet);
int ORM_Next(void* resultSet);
const char* ORM_FieldAsString(void* resultSet, int index);
int ORM_FieldAsInteger(void* resultSet, int index);
double ORM_FieldAsFloat(void* resultSet, int index);
int ORM_StartTransaction();
int ORM_Commit();
int ORM_Rollback();
int ORM_Ping();
```

### Retorno

Todas as funções retornam `0` para sucesso ou código de erro:

| Código | Constante | Descrição |
|--------|-----------|-----------|
| `0` | `ORM_OK` | Sucesso |
| `-1` | `ORM_ERRO_CONEXAO` | Falha de conexão |
| `-2` | `ORM_ERRO_EXECUCAO` | Erro na execução SQL |
| `-3` | `ORM_ERRO_PARAMETRO` | Parâmetro inválido |
| `-4` | `ORM_NAO_CONECTADO` | Não conectado |

Último erro: `const char* ORM_GetLastError();`

---

## MinusMigrator.dll

### Uso

```c
HMODULE h = LoadLibrary("MinusMigrator.dll");

typedef int (*mmInitFn)(const char* connStr, const char* dir);
mmInitFn mmInit = (mmInitFn)GetProcAddress(h, "mmInit");

mmInit("FB://localhost:3050/db", "C:\\Migrations");
```

### API Exportada

```c
int mmInit(const char* connectionString, const char* migrationsDir);
int mmMigrate();
int mmRollback(int steps);
int mmStatus(int* total, int* pending, int* executed);
int mmAddMigration(const char* name);
int mmAutoMigrate();
int mmDiffChangelog(const char* entityDir, const char* outputFile);
int mmApplyChangelog(const char* changelogFile);
int mmSnapshot(const char* outputFile);
int mmDiffSnapshots(const char* before, const char* after, const char* output);
int mmGenerateModels(const char* outputDir);
int mmDiffDatabases(const char* source, const char* target, const char* output);
int mmLint(int* warnings, int* errors);
int mmTag(const char* tagName);
int mmVersion(char* buffer, int bufferSize);
int mmPing();
```

### Pipeline CI/CD

```yaml
# GitHub Actions example
jobs:
  migrate:
    runs-on: windows-latest
    steps:
      - run: MinusMigrator_CLI.exe init --connection "${{ secrets.DB_CONN }}"
      - run: MinusMigrator_CLI.exe migrate --connection "${{ secrets.DB_CONN }}"
```
