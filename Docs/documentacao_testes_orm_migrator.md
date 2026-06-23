# Documentacao dos Testes — MinusORM e MinusMigrator

## 1. Visao Geral

Os testes utilizam **DUnitX** e estao divididos em duas suites:

| Suite | Diretorio | Executavel | Escopo |
|-------|-----------|-----------|--------|
| ORM | `Tests\ORM\` | `Test.MinusORM.exe` | Core ORM + Extensoes + Providers |
| Migrator | `Tests\Migrator\` | `Test.MinusMigrator.exe` | SchemaReader, SQLGenerator, SchemaDiffer, Runner |

Ambos sao compilados como aplicacao console (`{$APPTYPE CONSOLE}`) com saida XML via parametro `--xml-output`.

### 1.1 Arquitetura

```
Tests\
├── ORM\
│   ├── Test.MinusORM.dpr           # Entry point ORM
│   ├── Test.MinusORM.dproj
│   ├── Test.ORM.Model.Produto.pas  # Entidade modelo para testes
│   ├── Test.ORM.Model.Extensions.pas
│   ├── Test.ORM.Mapper.pas         # Testes do mapeador RTTI
│   ├── Test.ORM.ChangeTracker.pas  # Testes do ChangeTracker
│   ├── Test.ORM.IdentityMap.pas    # Testes do IdentityMap
│   ├── Test.ORM.UnitOfWork.pas     # Testes do UnitOfWork
│   ├── Test.ORM.UnitOfWork.Mock.pas
│   ├── Test.ORM.Mock.pas           # Mocks (Conexao, Comando, Resultados)
│   ├── Test.ORM.Extensions.pas     # Testes das extensoes
│   ├── Test.ORM.Provider.Base.pas  # Base para testes de provedor
│   ├── Test.ORM.Provider.SQLite.pas
│   ├── Test.ORM.Provider.Firebird.pas
│   ├── Test.ORM.Provider.PostgreSQL.pas
│   ├── Test.ORM.Provider.MySQL.pas
│   └── Benchmark.ORM.Providers.pas # Benchmark de desempenho
│
└── Migrator\
    ├── Test.MinusMigrator.dpr       # Entry point Migrator
    ├── Test.MinusMigrator.dproj
    ├── Test.Migrator.EntityReader.pas
    ├── Test.Migrator.SchemaReader.pas
    ├── Test.Migrator.SchemaDiffer.pas
    ├── Test.Migrator.SQLGenerator.pas
    └── Test.Migrator.Runner.pas
```

### 1.2 Execucao

```powershell
# Compilar
MSBuild Tests\ORM\Test.MinusORM.dproj /t:Build /p:Platform=Win32 /p:Config=Debug
MSBuild Tests\Migrator\Test.MinusMigrator.dproj /t:Build /p:Platform=Win32 /p:Config=Debug

# Executar com saida no console
Tests\ORM\Win32\Debug\TestMinusORM.exe

# Executar com saida XML (via DUnitX --xml-output)
Tests\ORM\Win32\Debug\TestMinusORM.exe --exit --xml-output:results\orm-results.xml

# Executar migrator
Tests\Migrator\Win32\Debug\TestMinusMigrator.exe --exit --xml-output:results\migrator-results.xml
```

### 1.3 Pre-requisitos

- RAD Studio 11+ com DUnitX instalado (GetIt Package Manager)
- FireDAC drivers para os provedores a serem testados
- Variaveis de ambiente para provedores externos:
  - `MinusORM_TEST_FIREBIRD` — caminho do banco Firebird
  - `MinusORM_TEST_PGHOST` — host PostgreSQL
  - `MinusORM_TEST_MYSQLHOST` — host MySQL

---

## 2. Testes ORM

### 2.1 Test.ORM.Mapper

Testa o mapeamento RTTI entre classes Delphi e tabelas/colunas do banco.

**Cenarios:**
- Mapeamento de atributos `[Tabela]` e `[Coluna]`
- Mapeamento de chave primaria com `[ChavePrimaria]`
- Ignorar propriedades com `[Ignorar]`
- Geracao de colunas para SELECT, INSERT, UPDATE

### 2.2 Test.ORM.ChangeTracker

Valida o snapshot e deteccao de dirty checking.

**Cenarios:**
- Criacao de snapshot apos carregamento
- Deteccao de alteracao em propriedade modificada
- Deteccao de multiplas alteracoes
- Ausencia de falsos positivos (propriedade inalterada)
- Suporte a propriedade ignorada (`[Ignorar]`)

### 2.3 Test.ORM.IdentityMap

Valida o cache de 1o nivel (Identity Map).

**Cenarios:**
- Armazenamento e recuperacao por tipo + ID
- Retorno de nil para entidade nao carregada
- Limpeza do mapa

### 2.4 Test.ORM.UnitOfWork

Testa o padrao Unit of Work (registro, commit, rollback).

**Cenarios:**
- Registro de nova entidade (`RegisterNew`)
- Registro de entidade modificada (`RegisterDirty`)
- Registro de entidade removida (`RegisterDeleted`)
- Commit com execucao de comandos
- Rollback com descarte de alteracoes
- Integracao com IdentityMap e ChangeTracker

### 2.5 Test.ORM.Extensions

Testa as extensoes opcionais do ORM.

**Cenarios:**
- SoftDelete (exclusao logica com filtro automatico)
- Auditoria (rastreio de criacao/alteracao)
- Cache 2o nivel
- Bulk operations
- Concorencia (optimistic locking)
- Sombra (shadow properties)

### 2.6 Test.ORM.Provider.* (Integracao)

Testes de integracao com bancos reais via FireDAC.

**Provedores:**
- **SQLite**: `:memory:` — sempre disponivel, sem setup externo
- **Firebird**: requer `MinusORM_TEST_FIREBIRD`
- **PostgreSQL**: requer `MinusORM_TEST_PGHOST`
- **MySQL**: requer `MinusORM_TEST_MYSQLHOST`

**Cenarios por provedor:**
- Conexao e autenticacao
- CRUD basico (Insert, Select, Update, Delete)
- Transacao (commit e rollback)
- Consulta com parametros
- Execucao de stored procedure (se suportado)

### 2.7 Mocks

`Test.ORM.Mock.pas` fornece implementacoes ficticias para testes sem banco real:

- `TConexaoMock` — implementa `IConexao`
- `TComandoMock` — implementa `IComando`
- `TResultadosMock` — implementa `IResultados`
- `TCampoMock` — implementa `ICampo`

---

## 3. Testes Migrator

### 3.1 Test.Migrator.EntityReader

Testa a leitura de entidades de arquivos `.pas` para extracao do esquema via regex e RTTI.

**Cenarios:**
- Leitura de atributos `[Tabela]`, `[Coluna]`, `[ChavePrimaria]`
- Mapeamento de tipos Delphi para tipos do migrador
- Ignorar propriedade com `[Ignorar]`
- Leitura de multiplas entidades

### 3.2 Test.Migrator.SchemaReader

Testa a leitura do esquema atual do banco de dados via tabelas de sistema.

**Cenarios (por provedor):**
- Leitura de tabelas existentes
- Leitura de colunas (nome, tipo, nullable, default)
- Leitura de chaves primarias
- Leitura de indices
- Leitura de chaves estrangeiras

### 3.3 Test.Migrator.SchemaDiffer

Testa a comparacao entre dois `TDatabaseSchema` (atual vs destino) e geracao da lista de mudancas.

**Cenarios:**
- Criar nova tabela
- Remover tabela inexistente no destino
- Adicionar coluna
- Remover coluna
- Alterar tipo/nullable da coluna
- Adicionar/remover indice
- Adicionar/remover chave estrangeira

### 3.4 Test.Migrator.SQLGenerator

Testa a geracao de DDL especifica por provedor.

**Cenarios (por provedor — Firebird, PostgreSQL, SQLite, MySQL):**
- `CREATE TABLE` com tipos corretos
- `ALTER TABLE ADD COLUMN`
- `ALTER TABLE DROP COLUMN`
- `ALTER TABLE ALTER COLUMN` (ou equivalente)
- `CREATE INDEX`
- `DROP INDEX`
- `ALTER TABLE ADD CONSTRAINT FK`
- `ALTER TABLE DROP CONSTRAINT FK`

### 3.5 Test.Migrator.Runner

Testa o executor de migracoes versionadas (arquivos `.up.sql` / `.down.sql`).

**Cenarios:**
- Inicializacao da tabela de controle (`_MinusMigrations`)
- Execucao de migration pendente
- Rollback de migration
- Deteccao de migration ja executada
- Checksum verification
- Listagem de status (pendentes vs executadas)

---

## 4. Benchmark

Localizado em `Tests\ORM\Benchmark.MinimusORM.dpr`, mede desempenho por provedor.

**Operacoes:** Conectar, Insert, Select by ID, Select All, Update, Delete

**Execucao:**

```powershell
# Apenas SQLite (sempre disponivel)
Benchmark.MinimusORM.exe

# Com provedores externos
set MinusORM_TEST_FIREBIRD=C:\caminho\test.fdb
set MinusORM_TEST_PGHOST=localhost
set MinusORM_TEST_MYSQLHOST=localhost
Benchmark.MinimusORM.exe
```

**Saida esperada:**
```
============================================
       BENCHMARK DE PROVIDERS
============================================

Provider        Operacao              Tempo(ms)   Iteracoes       ms/op
---------------------------------------------------------------------------
SQLite          Conectar                     15            5      3.0000
SQLite          Insert                      120          100      1.2000
SQLite          Select by ID                 45          100      0.4500
...
============================================
```

---

## 5. Script de Execucao

O projeto inclui `run-tests.ps1` para compilar e executar a suite ORM:

```powershell
.\run-tests.ps1
```

O script:
1. Compila o projeto de testes ORM via MSBuild
2. Executa o binario gerado com `--exit` e `--xml-output`
3. Exibe o resultado no console
