# MinusFramework

Mini ORM para Delphi com mapeamento via atributos RTTI, fluent query builders, suporte multi-banco, Unit of Work, Change Tracking e sistema de migraÃ§Ã£o standalone.

[ðŸ“˜ DocumentaÃ§Ã£o TÃ©cnica](Docs/DOCUMENTACAO_TECNICA.md) â€” [ðŸ“— Guia do UsuÃ¡rio](Docs/GUIA_DO_USUARIO.md) â€” [ðŸ“• Roadmap](Docs/ROADMAP.md) â€” [ðŸ“š API ReferÃªncia](Docs/API_REFERENCIA.md) â€” [ðŸ“‹ Licenciamento](LICENSE) â€” [ðŸŽ¯ Crowdfunding](Docs/ESTRATEGIA_CROWDFUNDING.md) â€” [ðŸ“Š Comparativo de Mercado](Docs/COMPARATIVO_MERCADO.md)

## âš–ï¸ Licenciamento

MinusFramework adota **dual licensing** com planos por soluÃ§Ã£o individual ou suite completa:

### Suites Completas

| EdiÃ§Ã£o | LicenÃ§a | PreÃ§o (1 dev/ano) | PreÃ§o (time ilimitado/ano) |
|--------|---------|-------------------|---------------------------|
| **Community** | [MIT](LICENSE) | **GrÃ¡tis** | **GrÃ¡tis** |
| **Complete Bundle** | [Comercial](Docs/LICENSE-ENTERPRISE.md) | R$ 499 | R$ 1.999 |

### SoluÃ§Ãµes Individuais (Comercial)

| SoluÃ§Ã£o | DescriÃ§Ã£o | PreÃ§o (1 dev/ano) | PreÃ§o (time/ano) |
|---------|-----------|-------------------|-----------------|
| **MinusORM Pro** | ORM completo + Oracle/DB2 + suporte prioritÃ¡rio | R$ 199 | R$ 599 |
| **MinusMigrator Pro** | CLI + GUI + DLL + schema diff + auto-migrate | R$ 149 | R$ 449 |
| **MinusFeatureFlags Pro** | Todos providers + governanÃ§a + mÃ©tricas | R$ 149 | R$ 449 |
| **MinusRest Pro** | Horse middleware + integraÃ§Ã£o ORM/FF | R$ 99 | R$ 299 |
| **MinusMessaging Pro** | Mensageria assÃ­ncrona multi-provider (Redis, RabbitMQ, Kafka) | R$ 149 | R$ 449 |

### Bundles com Desconto

| Bundle | SoluÃ§Ãµes Inclusas | PreÃ§o (1 dev/ano) | Economia |
|--------|-------------------|-------------------|----------|
| **ORM Bundle** | ORM Pro + Migrator Pro | R$ 299 | R$ 49 |
| **Developer Bundle** | ORM Pro + Migrator Pro + FF Pro | R$ 399 | R$ 98 |
| **Communications Bundle** | Rest Pro + Messaging Pro | R$ 199 | R$ 49 |
| **Complete Bundle** | ORM Pro + Migrator Pro + FF Pro + Rest Pro + Messaging Pro | R$ 599 | R$ 146 |

### O que vem em cada ediÃ§Ã£o Community (grÃ¡tis)

| SoluÃ§Ã£o | Community (MIT) | Pro (Comercial) |
|---------|----------------|-----------------|
| **MinusORM** | ORM completo (SQLite, FB, PG, MySQL, MariaDB, MSSQL) | + Oracle + DB2 + suporte SLA |
| **MinusMigrator** | CLI completa (7 bancos) | + GUI + IDE Expert + auto-migrate |
| **MinusFeatureFlags** | Core engine + providers JSON/MemÃ³ria | + Providers DB/REST + dashboard + governanÃ§a |
| **MinusRest** | Horse middleware bÃ¡sico (JWT, CORS, Logger) | + IntegraÃ§Ã£o ORM/FF + suporte prioritÃ¡rio |
| **MinusMessaging** | Core + fila em memÃ³ria | + Providers Redis/RabbitMQ/Kafka + Outbox + Sagas + Dashboard |

> ðŸ“‹ [Compare todas as ediÃ§Ãµes em detalhes â†’](LICENSE.md)
>
> ðŸ“Š [Veja como cada soluÃ§Ã£o se compara ao mercado â†’](Docs/COMPARATIVO_MERCADO.md)

## Features

- **Mapeamento RTTI** â€” `[Tabela]`, `[Coluna]`, `[ChavePrimaria]`, `[Ignorar]`
- **Fluent Query Builders** â€” `TConstrutorSelecao<T>` (consultas), `TConstrutorAtualizacao<T>`, `TConstrutorExclusao<T>` + Criteria API type-safe
- **CRUD GenÃ©rico** â€” `TRepositorioBase<T>` com cache, soft delete, unique key, bulk, concorrÃªncia e auditoria
- **Criteria API** â€” `Criterio().Igual()`, `OuCriterios()`, `E()`, `Existe()`, `EmSubconsulta()`, `Nao()`
- **Unit of Work** â€” `TUnidadeTrabalho` com registro de novos/sujos/excluÃ­dos, commit/rollback transacional
- **Change Tracking** â€” `TRastreadorMudancas` com snapshot e dirty detection
- **Identity Map** â€” Cache de 1Âº nÃ­vel por entidade
- **Multi-Banco** â€” Firebird, PostgreSQL, SQLite, MySQL via FireDAC
- **Extensions** â€” SoftDelete, Cache 2Âº nÃ­vel, UniqueKey, Bulk (insert/update/delete em lote), ConcorrÃªncia otimista, Shadow Properties (CriadoEm/AtualizadoEm), Auditoria (CriadoPor/AtualizadoPor + audit trail)
- **MinusMigrator** â€” CLI + DLL para migraÃ§Ã£o versionada de schema com SchemaReaders e SQLGenerators por provider
- **Multi-tenancy** â€” `[Inquilino]` com filtro automÃ¡tico `WHERE tenant_id`
- **Health Check** â€” `THealthCheck` com verificaÃ§Ã£o de conexÃ£o + latÃªncia
- **Retry/Circuit Breaker** â€” `TRetryPolicy` com exponential backoff
- **Database Seeding** â€” `TSeeder` com fixtures JSON
- **Pagination** â€” `TPaginacao` + `TResultadoPaginado<T>` built-in
- **SQL Profiler** â€” Log de queries com relatÃ³rio Markdown
- **Scaffold** â€” GeraÃ§Ã£o de entidades Delphi a partir do BD
- **Column Encryption** â€” `[Criptografado]` com XOR cipher
- **Views/Stored Procs** â€” Mapeamento via `[View]` e `[StoredProc]`
- **Dual Licensing** â€” MIT (Community) + Comercial (Enterprise)

## Projetos

| Projeto | Tipo | DescriÃ§Ã£o |
|---|---|---|
| `MinusFramework_Runtime.dpk` | BPL | Runtime package do ORM |
| `MinusFramework_Design.dpk` | BPL | Design-time package |

## Estrutura

```
Source/
â”œâ”€â”€ Bibliotecas/                   # CÃ³digo compartilhado entre projetos (canÃ´nico)
â”‚   â”œâ”€â”€ MF.Connection.pas          # Interfaces IConexao, IComando, IResultados, etc.
â”‚   â”œâ”€â”€ MF.Types.pas               # Enums, records, TParametrosConexao
â”‚   â”œâ”€â”€ MF.Exceptions.pas          # ExceÃ§Ãµes base
â”‚   â”œâ”€â”€ MF.Provider.pas            # Registry de providers
â”‚   â”œâ”€â”€ MF.Config.pas              # TConfiguracaoORM (conexÃµes nomeadas + cache)
â”‚   â””â”€â”€ Providers/                 # ImplementaÃ§Ãµes FireDAC
â”‚       â”œâ”€â”€ MF.Provider.FireDAC.pas
â”‚       â””â”€â”€ MF.Provider.FireDAC.*.pas
â”œâ”€â”€ Core/                          # NÃºcleo do ORM
â”‚   â”œâ”€â”€ MF.Attributes.pas          # Atributos de mapeamento
â”‚   â”œâ”€â”€ MF.Mapper.pas              # Mapeador RTTI IResultSet â†’ objeto
â”‚   â”œâ”€â”€ MF.IdGenerator.pas         # EstratÃ©gias de geraÃ§Ã£o de ID
â”‚   â”œâ”€â”€ MF.Criteria.pas            # Criteria API (ICriterio, operadores, subqueries)
â”‚   â”œâ”€â”€ MF.QueryBuilder.pas        # SQL helpers, TConstrutorAtualizacao<T>, TConstrutorExclusao<T>
â”‚   â”œâ”€â”€ MF.SelectBuilder.pas       # TConstrutorSelecao<T> (API unificada de SELECT)
â”‚   â”œâ”€â”€ MF.IdentityMap.pas         # Cache de 1Âº nÃ­vel
â”‚   â”œâ”€â”€ MF.ChangeTracker.pas       # Snapshot + dirty checking
â”‚   â”œâ”€â”€ MF.UnitOfWork.pas          # TUnidadeTrabalho
â”‚   â””â”€â”€ MF.RepositoryBase.pas      # TRepositorioBase<T> genÃ©rico
â”œâ”€â”€ Extensions/
â”‚   â”œâ”€â”€ MF.Extensions.SoftDelete.pas    # ExclusÃ£o lÃ³gica
â”‚   â”œâ”€â”€ MF.Extensions.Cache.pas         # Cache 2Âº nÃ­vel com TTL e regiÃµes
â”‚   â”œâ”€â”€ MF.Extensions.UniqueKey.pas     # ValidaÃ§Ã£o de chave Ãºnica
â”‚   â”œâ”€â”€ MF.Extensions.Relacionamento.pas # InjeÃ§Ã£o de conexÃ£o para lazy loading
â”‚   â”œâ”€â”€ MF.Extensions.Bulk.pas          # OperaÃ§Ãµes em lote (insert/update/delete)
â”‚   â”œâ”€â”€ MF.Extensions.Concorrencia.pas  # Lock otimista via versÃ£o
â”‚   â”œâ”€â”€ MF.Extensions.Sombra.pas        # Shadow properties (CriadoEm/AtualizadoEm)
â”‚   â””â”€â”€ MF.Extensions.Audit.pas         # Auditoria (CriadoPor/AtualizadoPor + audit trail)
â””â”€â”€ Packages/                      # BPL packages
    â”œâ”€â”€ MinusFramework_Runtime.dpk
    â””â”€â”€ MinusFramework_Design.dpk
```

## Quick Start

### 1. Definir Entidade

```pascal
type
  [Tabela('PRODUTO')]
  [Cache(300, 'produtos')]
  TProduto = class
  private
    [ChavePrimaria]
    [Coluna('ID')]
    FId: Integer;
    [Coluna('NOME')]
    [NotNull]
    FNome: string;
    [Coluna('PRECO_VENDA')]
    FPrecoVenda: Currency;
    [Versao('VERSAO', 1)]
    FVersao: Integer;
    [Ignorar]
    FCalculado: string;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property PrecoVenda: Currency read FPrecoVenda write FPrecoVenda;
    property Versao: Integer read FVersao write FVersao;
  end;
```

### 2. Configurar ConexÃ£o

```pascal
var
  LParams: TParametrosConexao;
begin
  LParams := TParametrosConexao.Create('FB', 'C:\dados\banco.fdb',
    'SYSDBA', 'masterkey', 'localhost', 3050);
  TConfiguracaoORM.RegistrarConexaoComParametros('default', LParams);
end;
```

### 3. CRUD BÃ¡sico

```pascal
var
  LRepo: TRepositorioBase<TProduto>;
  LProduto: TProduto;
  LLista: TObjectList<TProduto>;
begin
  LRepo := TRepositorioBase<TProduto>.Create(
    TConfiguracaoORM.ConexaoPadrao);

  // Inserir
  LProduto := TProduto.Create;
  LProduto.Nome := 'Produto A';
  LProduto.PrecoVenda := 29.90;
  LRepo.Salvar(LProduto);

  // Buscar por ID
  LProduto := LRepo.BuscarPorId(1);

  // Listar todos
  LLista := LRepo.BuscarTodos;

  // Atualizar
  LProduto.Nome := 'Produto A (editado)';
  LRepo.Salvar(LProduto);

  // Excluir
  LRepo.Excluir(1);
end;
```

### 4. Consultas Fluentes com Criteria API

```pascal
// WHERE simples
var
  LLista: TObjectList<TProduto>;
begin
  LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
    .Onde(Criterio('NOME').Igual('Produto A'))
    .Onde(Criterio('PRECO_VENDA').MaiorQue(10))
    .OrdenarPor('NOME')
    .ParaLista;

  // API alternativa (GROUP BY, HAVING, ORDER BY Asc/Desc):
  LLista := TRepositorioORM<TProduto>.Select(FConexao)
    .Fields.Add('NOME').Add('PRECO_VENDA')
    .Where.Add('PRECO_VENDA', 10.0)
    .OrderBy('NOME').Asc
    .ParaLista;
end;

// OR / AND / NOT
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(OuCriterios([
    Criterio('NOME').Igual('Alpha'),
    Criterio('NOME').Igual('Gamma')
  ]))
  .ParaLista;

// EXISTS / NOT EXISTS
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Existe(
    TRepositorioORM<TItem>.Consulta(FConexao)
      .Onde(Criterio('PRODUTO_ID').EmSubconsulta(
        TRepositorioORM<TProduto>.Consulta(FConexao, ['ID']).ComoSubconsulta))
      .SQL
  ))
  .ParaLista;

// IN (subconsulta)
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Criterio('ID').EmSubconsulta(
    TRepositorioORM<TItem>.Consulta(FConexao, ['PRODUTO_ID']).SQL
  ))
  .ParaLista;

// LIKE, BETWEEN, IS NULL
LLista := TRepositorioORM<TProduto>.Consulta(FConexao)
  .Onde(Criterio('NOME').Como('%prod%'))
  .Onde(Criterio('PRECO_VENDA').Entre(10, 100))
  .Onde(Criterio('DESCRICAO').NaoEhNulo)
  .ParaLista;
```

### 5. Unit of Work + Change Tracking

```pascal
var
  LUoW: TUnidadeTrabalho;
  LProduto1, LProduto2: TProduto;
begin
  LUoW := TUnidadeTrabalho.Create(FConexao);
  try
    LProduto1 := TProduto.Create;
    LProduto1.Nome := 'Novo';
    LUoW.RegistrarNovo(LProduto1);

    LProduto2 := LRepositorio.BuscarPorId(5);
    LProduto2.Nome := 'Editado';
    LUoW.RegistrarSujo(LProduto2);

    LUoW.RegistrarExcluido(LRepositorio.BuscarPorId(10));

    LUoW.Confirmar; // DELETE â†’ INSERT â†’ UPDATE em transaÃ§Ã£o Ãºnica
  finally
    LUoW.Free;
  end;
end;
```

## Atributos

| Atributo | Alvo | DescriÃ§Ã£o |
|---|---|---|
| `[Tabela('NOME')]` | Classe | Nome da tabela |
| `[Coluna('NOME')]` | Propriedade | Nome da coluna |
| `[ChavePrimaria]` | Propriedade | Chave primÃ¡ria |
| `[Ignorar]` | Propriedade | Campo transiente (nÃ£o persiste) |
| `[NotNull]` | Propriedade | ValidaÃ§Ã£o de campo obrigatÃ³rio |
| `[ReadOnly]` | Propriedade | Campo somente leitura (nÃ£o incluÃ­do em INSERT/UPDATE) |
| `[Versao('coluna', 1)]` | Propriedade | Lock otimista â€” incrementa a cada UPDATE |
| `[Cache(TTL, 'regiao')]` | Classe | Cache 2Âº nÃ­vel |
| `[SoftDelete('coluna', tesBooleano)]` | Classe | ExclusÃ£o lÃ³gica |
| `[ChaveUnica('grupo', ['COL1','COL2'])]` | Classe | Unique key composta |
| `[Relacionamento(trPertenceA, 'FK', 'PK')]` | Propriedade | Navigation property |
| `[ChaveEstrangeira('NOME')]` | Propriedade | Nome da FK |
| `[CriadoEm]` | Propriedade | Shadow: setado automaticamente no INSERT |
| `[AtualizadoEm]` | Propriedade | Shadow: setado automaticamente no INSERT e UPDATE |
| `[CriadoPor]` | Propriedade | Audit: setado com `UsuarioCorrente` no INSERT |
| `[AtualizadoPor]` | Propriedade | Audit: setado com `UsuarioCorrente` no INSERT e UPDATE |

## Extensions

### SoftDelete

```pascal
[Tabela('PRODUTO')]
[SoftDelete('EXCLUIDO', tesBooleano)]
TProduto = class
  [Coluna('EXCLUIDO')]
  FExcluido: Integer;
end;
```
- Consultas geram automaticamente `WHERE (EXCLUIDO IS NULL OR EXCLUIDO = 0)`
- `Excluir()` vira `UPDATE ... SET EXCLUIDO = 1 WHERE ID = :id`

### UniqueKey

```pascal
[Tabela('PRODUTO')]
[ChaveUnica('uk_nome', ['NOME'])]
TProduto = class ... end;
```
- `Salvar()` valida duplicidade antes de INSERT/UPDATE
- Suporta chaves compostas: `[ChaveUnica('uk_doc', ['CPF', 'TIPO'])]`

### Bulk

```pascal
var
  LIds: TArray<Integer>;
begin
  LIds := Repo.InserirEmLote(MinhaListaDeEntidades);
  Repo.AtualizarEmLote(MinhaLista);
  Repo.ExcluirEmLote([1, 2, 3]);
end;
```

### ConcorrÃªncia

```pascal
[Versao('VERSAO', 1)]
FVersao: Integer;
```
- `UPDATE ... SET VERSAO = VERSAO + 1 WHERE ID = :id AND VERSAO = :versao`
- Se `RowsAffected = 0`, lanÃ§a `EErroConcorrencia`

### Shadow Properties

```pascal
[Coluna('DATA_CRIACAO')]
[CriadoEm]
FDataCriacao: TDate;

[Coluna('DATA_ALTERACAO')]
[AtualizadoEm]
FDataAlteracao: TDate;
```
- `CriadoEm`: setado com `Now` no INSERT
- `AtualizadoEm`: setado com `Now` no INSERT e UPDATE

### Audit

```pascal
[Coluna('CRIADO_POR')]
[CriadoPor]
FCriadoPor: string;

[Coluna('ATUALIZADO_POR')]
[AtualizadoPor]
FAtualizadoPor: string;
```
- Usa `TAjudanteAuditoria.UsuarioCorrente` (threadvar)
- Audit trail: insere na tabela `auditoria`:
  `entidade, entidade_id, acao, valores_antigos, valores_novos, usuario, data_hora`

## Suporte a Banco de Dados (compartilhado via submodule deps)

| Banco | Provider FireDAC | Schema Reader | SQL Generator |
|---|---|---|---|---|
| SQLite | SQLite | `SchemaReader.SQLite.pas` | `SQLGenerator.SQLite.pas` |
| Firebird | FB | `SchemaReader.Firebird.pas` | `SQLGenerator.Firebird.pas` |
| PostgreSQL | PG | `SchemaReader.PostgreSQL.pas` | `SQLGenerator.PostgreSQL.pas` |
| MySQL | MySQL | `SchemaReader.MySQL.pas` | `SQLGenerator.MySQL.pas` |
| MariaDB | MySQL | `SchemaReader.MariaDB.pas` (herda MySQL) | `SQLGenerator.MariaDB.pas` (herda MySQL) |
| MSSQL | MSSQL | `SchemaReader.MSSQL.pas` | `SQLGenerator.MSSQL.pas` |
| Oracle | Oracle | `SchemaReader.Oracle.pas` | `SQLGenerator.Oracle.pas` |

## InstalaÃ§Ã£o

1. Abra `Packages\MinusFramework_Runtime.dpk` no RAD Studio
2. Compile o package
3. Adicione a BPL ao projeto consumidor
4. Adicione `Source\Bibliotecas`, `Source\Bibliotecas\Providers`, `Source\Core` e `Source\Extensions` ao search path

## RepositÃ³rios Relacionados

| RepositÃ³rio | DescriÃ§Ã£o |
|---|---|
| [minusframework-orm](https://github.com/GabrielFerreiraMendes/minusframework-orm) | MinusORM DLL standalone |
| [minusframework-migrator](https://github.com/GabrielFerreiraMendes/minusframework-migrator) | MigraÃ§Ã£o de schema |
| [minusframework-messaging](https://github.com/GabrielFerreiraMendes/minusframework-messaging) | Message bus multi-provider |
| [minusframework-telemetry](https://github.com/GabrielFerreiraMendes/minusframework-telemetry) | Observabilidade e tracing |
| [minusframework-featureflags](https://github.com/GabrielFerreiraMendes/minusframework-featureflags) | Feature flags e A/B testing |
| [minusframework-extensions](https://github.com/GabrielFerreiraMendes/minusframework-extensions) | Horse, JWT e outras extensÃµes |
| [minusframework-meta](https://github.com/GabrielFerreiraMendes/minusframework-meta) | Meta-repo com todos os mÃ³dulos + instalador |

## ðŸ“Š Comparativo de Mercado

Cada soluÃ§Ã£o do MinusFramework compete com ferramentas consolidadas no mercado. Veja o resumo:

| SoluÃ§Ã£o | Principal Concorrente | Diferencial MinusFramework |
|---------|----------------------|---------------------------|
| **MinusORM** | TMS Aurelius ($195/dev), EntityDAC ($199/dev) | Open source (MIT) mais completo em features (cache 2Âº nÃ­vel, soft delete, audit, shadow properties, bulk, unique key) |
| **MinusMigrator** | Flyway, Liquibase | Ãšnico migrador nativo Delphi com CLI + GUI + DLL; 7 bancos; geraÃ§Ã£o de modelos; diff changelog |
| **MinusFeatureFlags** | LaunchDarkly ($200/mÃªs), Unleash | Ãšnico SDK Delphi nativo offline; avaliaÃ§Ã£o local sem latÃªncia de rede; integraÃ§Ã£o com ORM |
| **MinusRest** | Horse (standalone), RAD Server ($1.999) | Middleware integrado com ORM + Feature Flags + Multi-tenancy |
| **MinusMessaging** | Redis/MQ puro, RabbitMQ.Delphi, Kafka.Delphi | Framework unificado multi-provider com retry, DLQ, outbox, sagas, circuit breaker e dashboard REST |

> ðŸ“Š [AnÃ¡lise competitiva detalhada â†’](Docs/COMPARATIVO_MERCADO.md)
