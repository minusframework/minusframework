# MinusORM — Mapeamento Objeto-Relacional

**Pacote:** MinusFramework_Runtime  
**Diretório:** `Source\Core\`

ORM completo com suporte a mapeamento por atributos, repositórios genéricos, Unit of Work, criteria API, lazy loading, cache e mais.

---

## Arquitetura do Core

```
Entity (atributos)
    |
    v
TMetaEntidade (metadados refletidos e compilados)
    |
    v
IRepositorioBase<T> → TRepositorioBase<T>
    |                    |
    |              + Identity Map
    |              + Change Tracker
    |              + Extension Hooks
    |
    +-- TUnidadeTrabalho (Unit of Work)
    |
    +-- TConstrutorSelecao<T> (fluent query)
    |
    +-- TMapeador (result set → objeto)
```

---

## Entidades

Toda entidade é uma classe com atributos de mapeamento.

```pascal
type
  [Tabela('PRODUTOS')]
  TProduto = class
  private
    FId: Integer;
    FNome: string;
    FPreco: Currency;
    FAtivo: Boolean;
  public
    [ChavePrimaria(eiIdentidade)]
    [Coluna('ID_PRODUTO')]
    property Id: Integer read FId write FId;

    [Coluna('NOME')]
    property Nome: string read FNome write FNome;

    [Coluna('PRECO')]
    property Preco: Currency read FPreco write FPreco;

    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;
  end;
```

### Atributos disponíveis

| Atributo | Descrição |
|----------|-----------|
| `Tabela('nome')` | Nome da tabela |
| `Coluna('nome')` | Nome da coluna |
| `ChavePrimaria(eiIdentidade)` | Chave primária com estratégia |
| `Ignorar` | Ignora a propriedade |
| `SoftDelete` | Habilita soft delete na classe |
| `Cache(TTL)` | Cache com TTL em segundos |
| `Versao` | Controle de concorrência |
| `CriadoEm`, `AtualizadoEm` | Timestamps automáticos |
| `CriadoPor`, `AtualizadoPor` | Auditoria |
| `ChaveUnica` | Unique constraint |
| `TamanhoMinimo(n)`, `TamanhoMaximo(n)` | Validação |
| `Obrigatorio` | Campo obrigatório |
| `Email` | Validação de email |
| `ExpressaoRegular('pattern')` | Validação por regex |
| `TPHEntidade` / `Discriminador` | Herança TPH |

### Estratégias de ID

| Estratégia | Descrição | Bancos |
|------------|-----------|--------|
| `eiIdentidade` | Auto-incremento nativo | MySQL, MariaDB, SQLite, MSSQL, PostgreSQL |
| `eiSequencia` | Sequence/Generator | Firebird, PostgreSQL, Oracle |
| `eiGUID` | GUID gerado em memória | Todos |
| `eiManual` | Atribuição manual | Todos |

---

## Repositórios

### `IRepositorioBase<T>` — CRUD básico

```pascal
var
  LRepo: IRepositorioBase<TProduto>;
begin
  LRepo := TRepositorioBase<TProduto>.Create(FConexao);

  // Inserir
  LProduto := TProduto.Create;
  LProduto.Nome := 'Novo Produto';
  LProduto.Preco := 99.90;
  LRepo.Salvar(LProduto);

  // Buscar por ID
  LProduto := LRepo.BuscarPorId(1);

  // Buscar todos
  LProdutos := LRepo.BuscarTodos;

  // Atualizar
  LProduto.Nome := 'Atualizado';
  LRepo.Salvar(LProduto);

  // Excluir
  LRepo.Excluir(LProduto.Id);

  // Iteração
  LRepo.ParaCada(
    procedure(AProduto: TProduto)
    begin
      WriteLn(AProduto.Nome);
    end);
end;
```

### `IRepositorioBulk<T>` — Operações em lote

```pascal
// Inserir múltiplos registros em lote
LRepo.InserirEmLote(LListaProdutos);
```

### `IRepositorioAsync<T>` — Operações assíncronas

```pascal
// Streaming assíncrono
LRepo.ParaCadaAsync(MeuCallback);
```

---

## Criteria API

Filtros fortemente tipados usando `TCriterioCampo<T>` e operadores.

```pascal
var
  LProdutos: TObjectList<TProduto>;
begin
  LProdutos := TRepositorioORM<TProduto>
    .Consulta(FConexao)
    .Onde(Criterio('NOME').Igual('Produto Teste'))
    .ParaLista;
end;
```

### Operadores disponíveis

| Método | SQL Gerado |
|--------|------------|
| `.Igual(valor)` | `= ?` |
| `.Diferente(valor)` | `<> ?` |
| `.MaiorQue(valor)` | `> ?` |
| `.MenorQue(valor)` | `< ?` |
| `.MaiorOuIgual(valor)` | `>= ?` |
| `.MenorOuIgual(valor)` | `<= ?` |
| `.Como(valor)` | `LIKE ?` |
| `.Entre(v1, v2)` | `BETWEEN ? AND ?` |
| `.Em(valores)` | `IN (?, ?, ...)` |
| `.EhNulo` | `IS NULL` |
| `.NaoEhNulo` | `IS NOT NULL` |

### Combinação

```pascal
// AND
.Onde(Criterio('NOME').Igual('Carro'))
.Onde(Criterio('PRECO').MaiorQue(35000))

// OR
.Onde(OuCriterios([
  Criterio('NOME').Igual('Alpha'),
  Criterio('NOME').Igual('Gamma')
]))

// NOT
.Onde(Nao(Criterio('NOME').Igual('Excluir')))

// Subconsulta
.Onde(Existe(TConstrutorSelecao<TFoo>...))
```

### Expressões tipadas (`TCriterioCampo<T>`)

```pascal
type
  TProduto = class
    [Coluna('PRECO')]
    property Preco: Currency read FPreco write FPreco;
  end;

// Uso com operadores sobrecarregados
var
  LCampo: TCriterioCampo<TProduto>;
begin
  LCampo := CriterioCampo<TProduto>('PRECO');

  // Usando operadores Delphi
  if LCampo > 100 then ...
  if LCampo = 50 then ...

  // Métodos fluentes
  LCampo.Entre(10, 100);
  LCampo.Em([10, 20, 30]);
end;
```

---

## Fluent Query Builders

### SelectBuilder (`TConstrutorSelecao<T>`)

```pascal
TRepositorioORM<TProduto>
  .Consulta(FConexao)
  .Onde(Criterio('ATIVO').Igual(True))
  .OrdenarPor('NOME', oaAsc)
  .Pular(10)
  .Pegar(20)
  .ParaLista;
```

**Métodos:** `Onde`, `Juncao`, `Include`, `AgruparPor`, `Tendo`, `OrdenarPor`, `Pular`, `Pegar`, `SQL`, `Executar`, `ExecutarLista`, `ParaCada`, `Paginar`

### InsertBuilder

```pascal
TConstrutorInsercao.Create(FConexao)
  .Values.Add('NOME', 'Produto X')
  .Values.Add('PRECO', 49.90)
  .Executar;
```

### UpdateBuilder

```pascal
TAtualizacaoBuilder.Create(FConexao)
  .Values.Add('NOME', 'Produto Y')
  .Values.Add('PRECO', 59.90)
  .Where.Add(Criterio('ID').Igual(1))
  .Executar;
```

### DeleteBuilder

```pascal
TExclusaoBuilder.Create(FConexao)
  .Where(Criterio('ID').Igual(1))
  .Executar;
```

---

## Unit of Work

Gerencia transações e tracking de entidades.

```pascal
var
  LUoW: TUnidadeTrabalho;
begin
  LUoW := TUnidadeTrabalho.Create(FConexao);
  try
    LUoW.RegistrarNovo(LProduto1);
    LUoW.RegistrarNovo(LProduto2);
    LUoW.RegistrarSujo(LProdutoExistente);
    LUoW.RegistrarExcluido(LProdutoRemover);

    LUoW.Confirmar;  // Commit + flush
  except
    LUoW.Reverter;
    raise;
  end;
end;
```

**Event hooks:** `OnBeforeSave`, `OnAfterSave`, `OnRegistrarOutbox`

---

## Compiled Queries

SQL gerado uma única vez, execução com parâmetros vinculados.

```pascal
var
  LQuery: TCompiledQuery<TProduto>;
begin
  LQuery := TCompiledQuery<TProduto>.Create(
    FConexao,
    'SELECT * FROM PRODUTOS WHERE PRECO > :PrecoMin'
  );
  LQuery.DefinirParametro('PrecoMin', 50.0);
  LResultados := LQuery.ExecutarLista;
end;
```

**Métodos:** `Compilar`, `DefinirParametro`, `DefinirId`, `Executar`, `ExecutarUm`, `ExecutarLista`

---

## Lazy Loading

```pascal
type
  TPedido = class
  private
    FItens: TLazy<TObjectList<TItemPedido>>;
  public
    [Ignorar]
    property Itens: TLazy<TObjectList<TItemPedido>> read FItens;
  end;

// Os itens são carregados apenas quando acessados
if Assigned(Pedido.Itens.Valor) then
  for var LItem in Pedido.Itens.Valor do
    ...
```

---

## Paginação

```pascal
var
  LResultado: TResultadoPaginado<TProduto>;
begin
  LResultado := TRepositorioORM<TProduto>
    .Consulta(FConexao)
    .Paginar(1, 20);  // página 1, 20 itens por página

  WriteLn(LResultado.TotalItens);    // total no banco
  WriteLn(LResultado.TotalPaginas);  // total de páginas
  WriteLn(LResultado.Itens.Count);   // itens na página
end;
```

---

## Validação

Validação por atributos.

```pascal
type
  TUsuario = class
  private
    FEmail: string;
  public
    [Obrigatorio]
    [TamanhoMinimo(3)]
    [TamanhoMaximo(100)]
    property Nome: string read FNome write FNome;

    [Obrigatorio]
    [Email]
    property Email: string read FEmail write FEmail;
  end;

// Validar
LResultado := TValidador.Validar(LUsuario);
if not LResultado.Valido then
  for var LErro in LResultado.Erros do
    WriteLn(LErro.Mensagem);
```

---

## SQL Profiler

```pascal
// Ativar profiling
TProfiler.Ativo := True;

// ... executar queries ...

// Relatório
WriteLn(TProfiler.Relatorio);

// Últimas N queries
var LQuery := TProfiler.Ultimas(10);

// Queries lentas (>100ms)
var LLentas := TProfiler.Lentas;
```

---

## Cache

```pascal
// Configurar cache
TConfiguracaoORM.CacheAtivo := True;
TConfiguracaoORM.ObterCache.Definir(TMeuCacheProvider.Create);

// Cache por entidade
[Cache(60)]  // 60 segundos de TTL
TProduto = class
  ...
end;
```

---

## Metadata Cache

O ORM reflete os metadados das entidades (atributos, colunas, SQLs) uma única vez e compila as queries.

```pascal
// Acesso direto ao cache de metadados
var
  LMeta: TMetaEntidade;
begin
  LMeta := TCacheMetadados.GetInstance.MetaEntidades[TProduto];
  WriteLn(LMeta.NomeTabela);
  WriteLn(LMeta.SQLSelectTodos);
end;
```
