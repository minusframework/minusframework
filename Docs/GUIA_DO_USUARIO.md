# MinusFramework — Guia do Usuário

> **Versão:** 2.0
> **Última atualização:** Junho de 2026
> **Licença:** MIT (framework) / Commercial (se aplicável)

---

## Sumário

1. [O que é o MinusFramework](#1-o-que-é-o-minusframework)
2. [Instalação](#2-instalação)
3. [Primeiros Passos](#3-primeiros-passos)
4. [Mapeamento de Entidades](#4-mapeamento-de-entidades)
5. [Repositório e CRUD](#5-repositório-e-crud)
6. [Consultas com Criteria API](#6-consultas-com-criteria-api)
7. [Unit of Work](#7-unit-of-work)
8. [Extensions](#8-extensions)
9. [MinusMessaging](#9-minusmessaging)
10. [MinusMigrator](#10-minusmigrator)
11. [Suporte Multi-Banco](#11-suporte-multi-banco)
12. [Referência Rápida de Atributos](#12-referência-rápida-de-atributos)
13. [Solução de Problemas](#13-solução-de-problemas)

---

## 1. O que é o MinusFramework

O **MinusFramework** é um conjunto de bibliotecas Delphi para desenvolvimento de aplicações com banco de dados. Ele oferece:

- **ORM completo** com mapeamento via atributos RTTI
- **Unit of Work** com change tracking e identity map
- **Criteria API** type-safe para consultas fluentes
- **7 providers de banco** (SQLite, Firebird, PostgreSQL, MySQL, MariaDB, MSSQL, Oracle)
- **Sistema de migração versionada** (CLI, GUI e DLL)
- **Extensões plugáveis** (soft-delete, auditoria, cache, bulk, concorrência, etc.)
- **Duas DLLs** com API C para consumo de qualquer linguagem

### Público-alvo

- Desenvolvedores Delphi que querem uma ORM leve sem dependências pesadas
- Equipes que precisam de migração de banco versionada (tipo Liquibase/Flyway)
- Projetos que precisam de suporte multi-banco sem mudar código
- Aplicações que expõem API de banco para outras linguagens via DLL

### O que NÃO é

- Não é um framework de aplicação (não tem MVC, MVVM, etc.)
- Não substitui o FireDAC como camada de acesso — usa FireDAC por baixo
- Não é um ORM com LINQ ou expression trees como C# Entity Framework

---

## 2. Instalação

### 2.1 Via Packages BPL (Runtime + Design)

1. Abra o RAD Studio
2. Abra os arquivos `.dpk` na pasta `Packages\`
3. Compile o Runtime Package primeiro
4. Depois compile o Design Package
5. Adicione ao Search Path do seu projeto:
   - `Source\Bibliotecas`
   - `Source\Bibliotecas\Providers`
   - `Source\Core`
   - `Source\Extensions`
   - `Source\Migrator`

### 2.2 Via DLL

Copie `MinusORM.dll` e/ou `MinusMigrator.dll` para a pasta do seu executável e use `LoadLibrary` + `GetProcAddress`. Consulte o projeto `MinusDemo.dpr` para exemplo completo.

### 2.3 Via Source (modo mais simples)

Adicione os paths acima ao Search Path do seu projeto. Inclua a unit `MF` (facade) para ter tudo disponível:

```pascal
uses
  MF;  // importa todo o ORM
```

### 2.4 Requisitos

- RAD Studio 11 Alexandria+
- FireDAC (já incluso no RAD Studio)
- drivers FireDAC para os bancos que for usar

---

## 3. Primeiros Passos

### 3.1 Exemplo Mínimo

```pascal
program Minimo;

uses
  MF;

var
  LRepo: TRepositorioBase<TProduto>;
  LProduto: TProduto;
  LParams: TParametrosConexao;
begin
  // 1. Configurar conexão
  LParams := TParametrosConexao.Create(
    'sqlite', 'C:\dados\app.db', '', '', '', 0);
  TConfiguracaoORM.RegistrarConexaoComParametros('default', LParams);

  // 2. Criar repositório
  LRepo := TRepositorioBase<TProduto>.Create(
    TConfiguracaoORM.ConexaoPadrao);

  try
    // 3. Inserir
    LProduto := TProduto.Create;
    LProduto.Nome := 'Produto Exemplo';
    LProduto.Preco := 99.90;
    LRepo.Salvar(LProduto);

    // 4. Buscar
    LProduto := LRepo.BuscarPorId(1);
    WriteLn(LProduto.Nome);

    // 5. Listar
    for LProduto in LRepo.BuscarTodos do
      WriteLn(LProduto.Id, ': ', LProduto.Nome);
  finally
    LRepo.Free;
  end;
end.
```

### 3.2 Configuração de Conexão

**Registrar conexão nomeada:**
```pascal
TConfiguracaoORM.RegistrarConexaoComParametros('nome_da_conexao', LParams);
```

**Usar conexão padrão:**
```pascal
TConfiguracaoORM.DefinirConexaoPadrao('nome_da_conexao');
```

**Connection string URI (para migrator):**
```
sqlite://C:\dados\app.db
firebird://localhost:3050/C:/dados/banco.fdb?user=SYSDBA&password=masterkey
postgresql://localhost:5432/mydb?user=postgres&password=123
mysql://localhost:3306/mydb?user=root&password=123
mssql://localhost:1433/mydb?user=sa&password=123
oracle://localhost:1521/XEPDB1?user=system&password=123
mariadb://localhost:3306/mydb?user=root&password=123
```

---

## 4. Mapeamento de Entidades

### 4.1 Entidade Simples

```pascal
type
  [Tabela('CLIENTES')]
  TCliente = class
  private
    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('ID')]
    FId: Integer;

    [Coluna('NOME', 100)]
    [NotNull]
    FNome: string;

    [Coluna('EMAIL')]
    FEmail: string;

    [Coluna('DATA_CADASTRO')]
    FDataCadastro: TDate;

    [Ignorar]
    FTempCalculado: string;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property DataCadastro: TDate read FDataCadastro write FDataCadastro;
  end;
```

### 4.2 Tipos Suportados

| Tipo Delphi | Mapeamento SQL |
|---|---|
| `Integer` | `INTEGER` |
| `Int64` | `BIGINT` |
| `string` | `VARCHAR(n)` ou `TEXT` |
| `Double` / `Single` | `DOUBLE PRECISION` / `FLOAT` |
| `Currency` | `DECIMAL(18,4)` ou `NUMERIC` |
| `TDate` | `DATE` |
| `TDateTime` | `TIMESTAMP` |
| `TTime` | `TIME` |
| `Boolean` | `INTEGER` / `BOOLEAN` |
| `TBytes` | `BLOB` / `BYTEA` |
| `TValue` | (dinâmico) |

### 4.3 Chave Primária Composta

```pascal
type
  [Tabela('ITENS_PEDIDO')]
  TItemPedido = class
  private
    [ChavePrimaria]
    [Coluna('PEDIDO_ID')]
    FPedidoId: Integer;

    [ChavePrimaria]
    [Coluna('PRODUTO_ID')]
    FProdutoId: Integer;
  end;
```

### 4.4 Herança TPH (Table per Hierarchy)

```pascal
type
  [Tabela('PESSOAS')]
  [Discriminador('TIPO', ['F', TPessoaFisica], ['J', TPessoaJuridica])]
  TPessoa = class
    [Coluna('TIPO')]
    FTipo: string;
  end;

  TPessoaFisica = class(TPessoa)
    [Coluna('CPF')]
    FCPF: string;
  end;

  TPessoaJuridica = class(TPessoa)
    [Coluna('CNPJ')]
    FCNPJ: string;
  end;
```

### 4.5 Relacionamentos (Navigation Properties)

```pascal
type
  [Tabela('PEDIDOS')]
  TPedido = class
  private
    [ChavePrimaria]
    [Coluna('ID')]
    FId: Integer;

    // FK para o cliente
    [ChaveEstrangeira('CLIENTE_ID')]
    [Coluna('CLIENTE_ID')]
    FClienteId: Integer;

    // Propriedade de navegação
    [Relacionamento(trPertenceA, 'CLIENTE_ID', 'ID')]
    FCliente: TCliente;
  public
    property Cliente: TCliente read FCliente write FCliente;
  end;
```

---

## 5. Repositório e CRUD

### 5.1 Operações Básicas

```pascal
var
  LRepo: TRepositorioBase<TCliente>;
  LCliente: TCliente;
  LLista: TObjectList<TCliente>;
begin
  LRepo := TRepositorioBase<TCliente>.Create(FConexao);
  try
    // INSERT
    LCliente := TCliente.Create;
    LCliente.Nome := 'João Silva';
    LRepo.Salvar(LCliente);

    // UPDATE (alterar e salvar de novo)
    LCliente.Nome := 'João Silva (editado)';
    LRepo.Salvar(LCliente);

    // Buscar por ID
    LCliente := LRepo.BuscarPorId(1);

    // Buscar todos
    LLista := LRepo.BuscarTodos;

    // Excluir
    LRepo.Excluir(1);
    // ou: LRepo.Excluir(LCliente);

    // Verificar existência
    if LRepo.Existe(1) then
      WriteLn('Cliente existe');
  finally
    LRepo.Free;
  end;
end;
```

### 5.2 Bulk Operations

O framework seleciona automaticamente a melhor estratégia:

| Estratégia | Quando? | Performance |
|------------|---------|-------------|
| **ArrayDML** (FireDAC) | GUIDs e sequences (IDs pré-gerados) | 🚀 1 round-trip |
| **Multi-INSERT + RETURNING** | Identity/AutoIncrement | Moderado |
| **Transação linha-a-linha** | Fallback (ADO ou sem suporte) | Linha por linha |

```pascal
// Inserir em lote (retorna IDs gerados)
var LIds := LRepo.InserirEmLote(ListaDeClientes);
// Com FireDAC + GUID: 1.000 inserts em 1 round-trip!

// Atualizar em lote
LRepo.AtualizarEmLote(ListaDeClientes);

// Excluir em lote
LRepo.ExcluirEmLote([1, 2, 3, 4, 5]);
```

---

## 6. Consultas com Criteria API

### 6.1 Consultas Simples

```pascal
// Clientes com nome específico
var LLista := LRepo.Consulta
  .Onde(Criterio('NOME').Igual('João Silva'))
  .ParaLista;

// Preço maior que 100
LLista := LRepo.Consulta
  .Onde(Criterio('PRECO').MaiorQue(100))
  .ParaLista;

// LIKE
LLista := LRepo.Consulta
  .Onde(Criterio('NOME').Como('%Silva%'))
  .ParaLista;

// BETWEEN
LLista := LRepo.Consulta
  .Onde(Criterio('DATA').Entre(Date1, Date2))
  .ParaLista;

// IN
LLista := LRepo.Consulta
  .Onde(Criterio('ID').Em([1, 2, 3]))
  .ParaLista;

// IS NULL
LLista := LRepo.Consulta
  .Onde(Criterio('EMAIL').EhNulo)
  .ParaLista;
```

### 6.2 Combinações Lógicas

```pascal
// OR: nome = 'Alpha' OU nome = 'Gamma'
LLista := LRepo.Consulta
  .Onde(OuCriterios([
    Criterio('NOME').Igual('Alpha'),
    Criterio('NOME').Igual('Gamma')
  ]))
  .ParaLista;

// AND + OR combinados
LLista := LRepo.Consulta
  .Onde(Criterio('ATIVO').Igual(True))
  .Onde(OuCriterios([
    Criterio('TIPO').Igual('A'),
    Criterio('TIPO').Igual('B')
  ]))
  .ParaLista;

// NOT
LLista := LRepo.Consulta
  .Onde(Nao(Criterio('STATUS').Igual('CANCELADO')))
  .ParaLista;
```

### 6.3 Subconsultas

```pascal
// EXISTS
LLista := LRepo.Consulta
  .Onde(Existe(
    TRepositorioBase<TItem>.Create(FConexao)
      .Consulta
      .Onde(Criterio('PEDIDO_ID').EmSubconsulta(
        LRepo.Consulta.Campo('ID').ComoSubconsulta))
      .SQL
  ))
  .ParaLista;

// IN (subconsulta)
LLista := LRepo.Consulta
  .Onde(Criterio('ID').EmSubconsulta(
    TRepositorioBase<TItem>.Create(FConexao)
      .BuscarSQL('SELECT DISTINCT PEDIDO_ID FROM ITENS')
  ))
  .ParaLista;
```

### 6.4 Ordenação, Paginação e Projeção

```pascal
// Ordenação
LLista := LRepo.Consulta
  .Onde(Criterio('ATIVO').Igual(True))
  .OrdenarPor('NOME')
  .ParaLista;

// Ordenação descendente
LLista := LRepo.Consulta
  .OrdenarPor('DATA')
  .Desc
  .ParaLista;

// Paginação
LLista := LRepo.Consulta
  .Onde(Criterio('ATIVO').Igual(True))
  .Pular(10)   // OFFSET
  .Pegar(10)   // LIMIT
  .ParaLista;

// Projeção DTO
type
  TClienteDTO = class
    Nome: string;
    Email: string;
  end;

var LDTOs: TObjectList<TClienteDTO>;
begin
  LDTOs := LRepo.Consulta
    .Projetar<TClienteDTO>;
end;
```

### 6.5 Fluent Expression API (Alternativa)

```pascal
LLista := LRepo.Consulta
  .Onde(
    Campo('NOME').Igual('João')
      .E(Campo('IDADE').MaiorQue(18))
      .E(
        Campo('TIPO').Igual('A')
          .Ou(Campo('TIPO').Igual('B'))
      )
  )
  .ParaLista;
```

---

## 7. Unit of Work

### 7.1 Uso Básico

```pascal
var
  LUoW: TUnidadeTrabalho;
  LCliente1, LCliente2: TCliente;
  LRepo: TRepositorioBase<TCliente>;
begin
  LRepo := TRepositorioBase<TCliente>.Create(FConexao);
  LUoW := TUnidadeTrabalho.Create(FConexao);
  try
    // Novo cliente
    LCliente1 := TCliente.Create;
    LCliente1.Nome := 'Novo Cliente';
    LUoW.RegistrarNovo(LCliente1);

    // Cliente existente modificado
    LCliente2 := LRepo.BuscarPorId(5);
    LCliente2.Nome := 'Nome Alterado';
    LUoW.RegistrarSujo(LCliente2);

    // Cliente a excluir
    LUoW.RegistrarExcluido(LRepo.BuscarPorId(10));

    // Executa tudo em UMA transação
    LUoW.Confirmar;
  finally
    LUoW.Free;
    LRepo.Free;
  end;
end;
```

### 7.2 Change Tracking (Rastreamento Automático)

O `TRastreadorMudancas` detecta automaticamente campos alterados:

```pascal
LUoW := TUnidadeTrabalho.Create(FConexao);
try
  LCliente := LRepo.BuscarPorId(1);   // snapshot automático
  LCliente.Nome := 'Novo Nome';        // tracker detecta mudança

  // RegistrarSujo detecta que só NOME foi alterado
  // e gera UPDATE apenas com coluna NOME
  LUoW.RegistrarSujo(LCliente);
  LUoW.Confirmar;
finally
  LUoW.Free;
end;
```

### 7.3 Transações Manuais

```pascal
FConexao.IniciarTransacao;
try
  LRepo.Salvar(Cliente1);
  LRepo.Salvar(Cliente2);
  FConexao.Confirmar;
except
  FConexao.Reverter;
  raise;
end;
```

---

## 8. Extensions

### 8.1 SoftDelete

```pascal
[Tabela('PRODUTOS')]
[SoftDelete('EXCLUIDO', tesBooleano)]
TProduto = class
  [Coluna('EXCLUIDO')]
  FExcluido: Boolean;
end;

// Uso: Excluir vira UPDATE SET EXCLUIDO=1
// Consultas automaticamente filtram WHERE (EXCLUIDO IS NULL OR EXCLUIDO=0)
// Para incluir excluídos: LRepo.IncluirExcluidos(true).BuscarTodos
```

### 8.2 Auditoria

```pascal
[Tabela('CLIENTES')]
TCliente = class
  [Coluna('CRIADO_POR')]
  [CriadoPor]
  FCriadoPor: string;

  [Coluna('CRIADO_EM')]
  [CriadoEm]
  FCriadoEm: TDateTime;

  [Coluna('ATUALIZADO_POR')]
  [AtualizadoPor]
  FAtualizadoPor: string;

  [Coluna('ATUALIZADO_EM')]
  [AtualizadoEm]
  FAtualizadoEm: TDateTime;
end;

// Configurar usuário corrente
TAjudanteAuditoria.UsuarioCorrente := 'joao@email.com';

// Audit trail automático na tabela AUDITORIA
// (entidade, entidade_id, acao, valores_antigos, valores_novos, usuario, data_hora)
```

### 8.3 Cache de Segundo Nível

```pascal
[Tabela('PRODUTOS')]
[Cache(300, 'produtos')]  // 300 segundos de TTL, região 'produtos'
TProduto = class ... end;

// Cache é automaticamente invalidado em INSERT/UPDATE/DELETE
// Cache por consulta também é suportado:
LRepo.Cache(60).BuscarPorId(1);  // cache por 60s
```

### 8.4 Unique Key

```pascal
[Tabela('CLIENTES')]
[ChaveUnica('uk_cpf', ['CPF'])]
TCliente = class
  [Coluna('CPF')]
  FCPF: string;
end;

// Lança EErroUniqueKey se duplicado ao salvar
// Suporta chaves compostas: [ChaveUnica('uk_doc', ['CPF', 'TIPO'])]
```

### 8.5 Concorrência Otimista

```pascal
[Tabela('PRODUTOS')]
TProduto = class
  [Versao('VERSAO', 1)]
  FVersao: Integer;
end;

// UPDATE gera: SET VERSAO = VERSAO + 1 WHERE ID = :id AND VERSAO = :old_versao
// Se 0 linhas afetadas → lança EErroConcorrencia
```

### 8.6 Shadow Properties

```pascal
[Coluna('DATA_CRIACAO')]
[CriadoEm]
FDataCriacao: TDateTime;

[Coluna('DATA_ALTERACAO')]
[AtualizadoEm]
FDataAlteracao: TDateTime;
```

### 8.7 Bulk Operations (ArrayDML)

```pascal
// INSERT em lote (retorna IDs gerados)
// Com FireDAC: usa ArrayDML automático para 10-50x de ganho
var LIds := LRepo.InserirEmLote(ListaDeProdutos);

// UPDATE em lote
LRepo.AtualizarEmLote(ListaDeProdutos);

// DELETE em lote
LRepo.ExcluirEmLote([1, 2, 3]);
```

> **Nota de performance:** Quando o provider suporta ArrayDML (FireDAC) e as PKs são
> pré-geradas (GUIDs, sequences), `InserirEmLote` executa 1.000+ inserts em um único
> round-trip ao banco. Para identity/autoincrement, usa multi-INSERT com RETURNING.

### 8.8 Lazy Loading

```pascal
type
  [Tabela('PEDIDOS')]
  TPedido = class
    [Relacionamento(trTemMuitos, 'PEDIDO_ID', 'ID')]
    FItens: TLazy<TObjectList<TItemPedido>>;
  public
    property Itens: TLazy<TObjectList<TItemPedido>> read FItens;
  end;

// Uso: automaticamente carrega os itens na primeira leitura
var LItens := Pedido.Itens.Valor;  // primeira vez faz SELECT

// Carregamento explícito (eager):
TRepositorioBase<TPedido>.Create(FConexao)
  .Incluir(p => p.Cliente)
  .Incluir(p => p.Itens)
  .BuscarPorId(10);
```

---

## 9. MinusMessaging

O **MinusMessaging** é o subsistema de mensageria assíncrona do MinusFramework. Ele oferece:

- **Filas** — publish/consume com retry e DLQ
- **Pub/Sub** — tópicos com múltiplos assinantes
- **Provedores plugáveis** — InMemory (padrão), Redis, RabbitMQ
- **Serialização** — JSON e binária
- **Outbox pattern** — entrega confiável via banco de dados
- **21 testes unitários** DUnitX

### 9.1 Instalação

Adicione ao Search Path do seu projeto:

- `Source\Messaging`
- `Source\Messaging\Reliability`
- `Source\Messaging\Providers`

Compile o package `Packages\MinusMessaging_Runtime.dpk`.

### 9.2 Exemplo Rápido

```pascal
uses
  MF.Messaging.Core,
  MF.Messaging.Provider.InMemory;

var
  LBus: TMessageBus;
begin
  LBus := TMessageBus.Create;
  try
    LBus.RegistrarProvider('memoria', TProvedorMemoria.Create, True);
    LBus.Publicar('minha.fila', TValue.From('Olá Mundo!'));
  finally
    LBus.Free;
  end;
end;
```

### 9.3 Documentação Completa

Consulte o guia dedicado em [`Docs/GUIA_MENSAGERIA.md`](GUIA_MENSAGERIA.md) para detalhes de todos os recursos: filas, Pub/Sub, serialização, DLQ, Outbox e provedores Redis/RabbitMQ.

---

## 10. MinusMigrator

### 10.1 Modo CLI

```
MinusMigrator_CLI.exe init -c "sqlite://C:\dados\app.db"
MinusMigrator_CLI.exe migrate -c "sqlite://C:\dados\app.db" -p .\migrations
MinusMigrator_CLI.exe status -c "sqlite://C:\dados\app.db" -p .\migrations
MinusMigrator_CLI.exe rollback -c "sqlite://C:\dados\app.db" -p .\migrations -n 2
MinusMigrator_CLI.exe tag "versao_1.0" -c "sqlite://C:\dados\app.db"
MinusMigrator_CLI.exe rollback -c "sqlite://C:\dados\app.db" --tag versao_1.0
MinusMigrator_CLI.exe add-migration "cria_tabela_clientes" -c "sqlite://C:\dados\app.db" -e .\entities
MinusMigrator_CLI.exe generate-models -c "sqlite://C:\dados\app.db" -o .\models -ns MeuProjeto.Model
MinusMigrator_CLI.exe auto-migrate -c "sqlite://C:\dados\app.db" -e .\entities --dry-run
MinusMigrator_CLI.exe auto-migrate -c "sqlite://C:\dados\app.db" -e .\entities --force
MinusMigrator_CLI.exe status -c "sqlite://C:\dados\app.db" --format json
```

### 10.2 Modo GUI

Execute `MinusMigrator_GUI.exe` para usar a interface gráfica:
1. Preencha a connection string
2. Clique **Connect**
3. Use os botões para Status, Migrate, Rollback, Tag, Add Migration, Auto-Migrate, Generate Models

### 10.3 Modo DLL

```c
// De C#, Python, Node.js, etc.
#include <windows.h>

typedef int (*Migrator_Execute)(const char* cmd, const char* conn, const char* path, int dryRun);
typedef char* (*Migrator_Status)();

HMODULE hDll = LoadLibrary("MinusMigrator.dll");
Migrator_Execute fnExec = (Migrator_Execute)GetProcAddress(hDll, "Migrator_Execute");

fnExec("migrate", "sqlite://C:\\dados\\app.db", ".\\migrations", 0);
```

### 10.4 Estrutura de Migrations

```
migrations\
├── 20260601120000_descricao.up.sql    ← SQL de upgrade
├── 20260601120000_descricao.down.sql  ← SQL de downgrade
├── 20260602150000_outra.up.sql
├── 20260602150000_outra.down.sql
├── R__funcoes.up.sql                  ← Repeatable (executa sempre que mudar)
└── R__views.up.sql
```

### 10.5 Preconditions

Adicione no início do arquivo `.sql`:

```sql
--precondition: tableNotExists(CLIENTES)
CREATE TABLE CLIENTES (
  ID    INTEGER PRIMARY KEY,
  NOME  VARCHAR(100) NOT NULL
);

--precondition: dbms(postgresql)
--precondition: columnNotExists(PEDIDOS, STATUS)
ALTER TABLE PEDIDOS ADD COLUMN STATUS VARCHAR(20);
```

Preconditions disponíveis: `tableExists`, `tableNotExists`, `columnExists`, `columnNotExists`, `dbms`.

### 9.6 Contexts

Organize migrations em subdiretórios:

```
migrations\
├── vendas\
│   ├── 20260601120000_cria_pedidos.up.sql
│   └── ...
├── financeiro\
│   ├── 20260601130000_cria_lancamentos.up.sql
│   └── ...
```

Execute apenas um contexto:

```
MinusMigrator_CLI.exe migrate -c "sqlite://..." -p .\migrations --context vendas
```

### 9.7 Auto-Migrate (Desenvolvimento Rápido)

Compara entidades (.pas) com o banco real e aplica mudanças automaticamente:

```
MinusMigrator_CLI.exe auto-migrate -c "sqlite://..." -e .\entities
```

Opções:
- `--dry-run`: mostra o que seria feito sem executar
- `--force`: executa sem confirmação (CI/CD)

---

## 10. Suporte Multi-Banco

O MinusFramework suporta 7 bancos com o mesmo código:

| Banco | Status | Observações |
|---|---|---|
| SQLite | ✅ Completo | Ideal para testes e apps desktop simples |
| Firebird | ✅ Completo | Suporte a generators, blob, procedures |
| PostgreSQL | ✅ Completo | Suporte a schemas, serial, boolean nativo |
| MySQL | ✅ Completo | InnoDB, charset UTF-8 |
| MariaDB | ✅ Completo | 100% compatível MySQL |
| MSSQL | ✅ Completo | IDENTITY, NVARCHAR, esquemas |
| Oracle | ✅ Completo | Sequences, VARCHAR2, NUMBER |
| DB2 | ⬜ Planejado | Futuro |

Para trocar de banco, mude apenas a connection string:

```pascal
// Tudo igual, só muda a string
LParams := TParametrosConexao.Parse('postgresql://...');
```

---

## 11. Referência Rápida de Atributos

| Atributo | Uso | Descrição |
|---|---|---|
| `[Tabela('NOME')]` | Classe | Nome da tabela no banco |
| `[Coluna('NOME')]` | Propriedade | Nome da coluna no banco |
| `[Coluna('NOME', 100)]` | Propriedade | Coluna com tamanho máximo |
| `[ChavePrimaria]` | Propriedade | Campo de chave primária |
| `[AutoIncremento]` | Propriedade | Geração automática de ID |
| `[ChaveEstrangeira('FK')]` | Propriedade | Nome da foreign key |
| `[Ignorar]` | Propriedade | Campo não persistido |
| `[NotNull]` | Propriedade | Valida campo obrigatório |
| `[ReadOnly]` | Propriedade | Campo somente leitura |
| `[Versao('COL', 1)]` | Propriedade | Lock otimista |
| `[Cache(300, 'regiao')]` | Classe | Cache 2º nível (TTL em segundos) |
| `[SoftDelete('COL', tesBooleano)]` | Classe | Exclusão lógica |
| `[ChaveUnica('nome', ['C1','C2'])]` | Classe | Unique key composta |
| `[Relacionamento(trPertenceA, 'FK', 'PK')]` | Propriedade | Navigation property |
| `[CriadoEm]` | Propriedade | Shadow property: setado no INSERT |
| `[AtualizadoEm]` | Propriedade | Shadow property: setado no INSERT/UPDATE |
| `[CriadoPor]` | Propriedade | Audit: setado no INSERT |
| `[AtualizadoPor]` | Propriedade | Audit: setado no INSERT/UPDATE |
| `[Discriminador('COL', ['V',TClasse])]` | Classe | Herança TPH |

---

## 12. Solução de Problemas

### 12.1 Erro: "Provider não encontrado"

Verifique se a unit do provider está incluída no uses do projeto:
```pascal
uses
  MF.Provider.FireDAC.SQLite,   // para SQLite
  MF.Provider.FireDAC.Firebird,  // para Firebird
  MF.Provider.FireDAC.PostgreSQL, // para PostgreSQL
  MF.Provider.FireDAC.MySQL;     // para MySQL
```

### 12.2 Erro: "Duplicate key value" no UniqueKey

Significa que já existe um registro com o mesmo valor da chave única. Use try..except com `EErroUniqueKey`.

### 12.3 Erro: "Concorrência" no Update

Outro usuário alterou o registro antes de você. Re-leia o registro e tente novamente.

### 12.4 Connection string não funciona

Use o formato URI:
```
driver://host:porta/database?user=...&password=...
```
Para SQLite: `sqlite://C:\caminho\para\arquivo.db`

### 12.5 Migration não aparece como pendente

Verifique:
1. O arquivo está na pasta de migrations correta
2. O nome do arquivo começa com timestamp (ex: `20260601120000_`)
3. Não é um arquivo `R__*` (repeatable) — esses aparecem separados
4. Já foi executado? Cheque a tabela `__MINUSMIGRATOR_MIGRATIONS`

---

> Para documentação técnica detalhada, veja `DOCUMENTACAO_TECNICA.md`.  
> Para referência completa da API pública, veja `API_REFERENCIA.md`.  
> Para roadmap e plano de evolução, veja `ROADMAP.md`.
