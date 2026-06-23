# Extensions

**Pacote:** MinusFramework_Runtime  
**Diretório:** `Source\Extensions\`

Módulos opcionais que estendem o ORM com funcionalidades como serialização JSON, REST API, soft delete, multitenancy, auditoria e mais.

---

## JSON (`MF.Extensions.JSON.pas`)

Serialização e deserialização de entidades para JSON.

```pascal
// Objeto para JSON
LJson := TJsonORM.Serializar(LProduto);
// Resultado: {"Id":1,"Nome":"Produto X","Preco":99.9}

// JSON para objeto
LProduto := TJsonORM.Desserializar<TProduto>(LJson);
```

---

## AutoMapper (`MF.Extensions.AutoMapper.pas`)

Mapeamento automático de classes para tabelas por convenção de nomes.

```pascal
// Registrar convenção global
TConfiguracaoORM.AutoMapear(TAutoMapeamento.Create);

// Convenções disponíveis
TAutoMapeamento.Create(TConvencaoNomes.ncSnakeCase);
// PascalCase "NomeProduto" → snake_case "nome_produto"

TAutoMapeamento.Create(TConvencaoNomes.ncUpperSnakeCase);
// → "NOME_PRODUTO"

TAutoMapeamento.Create(TConvencaoNomes.ncLowerSnakeCase);
// → "nome_produto"
```

---

## Horse REST API (`MF.Extensions.Horse.pas`)

Gera automaticamente endpoints REST para qualquer entidade.

```csharp
// 1. Registrar middleware ORM no Horse
uses MF.Extensions.Horse;

// 2. Auto-registrar rotas para uma entidade
TMinusORMRouter.Registrar<TProduto>;

// Rotas geradas automaticamente:
// GET    /produto         → listar todos
// GET    /produto/:id     → buscar por ID
// POST   /produto         → inserir
// PUT    /produto/:id     → atualizar
// DELETE /produto/:id     → excluir

// Com paginação e filtro
// GET /produto?pagina=1&tamanho=20&sort=nome&order=asc
```

### JWT Authentication (`MF.Extensions.Horse.JWT.pas`)

```pascal
// Proteger rotas com JWT
uses MF.Extensions.Horse.JWT;

TMinusORMRouter
  .Registrar<TProduto>
  .ComAutenticacao(TSegredoJWT.Create('minha-chave-secreta'));
```

---

## Soft Delete (`MF.Extensions.SoftDelete.pas`)

Exclusão lógica — registros são marcados como inativos em vez de removidos.

```pascal
type
  [Tabela('PRODUTOS')]
  [SoftDelete]  // Habilita soft delete
  TProduto = class
  private
    FAtivo: Boolean;
  public
    [Coluna('ATIVO')]
    property Ativo: Boolean read FAtivo write FAtivo;
  end;

// Excluir logicamente
LRepo.Excluir(1);  // Gera UPDATE SET ATIVO = 0 WHERE ID = 1

// Buscar inclui filtro automático
LRepo.BuscarTodos;  // Gera ... WHERE ATIVO = 1
```

### Configuração avançada

```pascal
// Coluna e valores customizados
[SoftDelete('EXCLUIDO', 1, 0)]
TProduto = class ...;

// Com data de exclusão
[SoftDelete('DELETED_AT', TSoftDeleteType.sdtDateTime)]
TProduto = class ...;
```

---

## Multi-Tenancy (`MF.Extensions.MultiTenancy.pas`)

Isolamento de dados por inquilino.

```pascal
type
  [Tabela('PRODUTOS')]
  [Inquilino('ID_INQUILINO')]
  TProduto = class
  private
    FInquilinoId: Integer;
  public
    [Coluna('ID_INQUILINO')]
    property InquilinoId: Integer read FInquilinoId write FInquilinoId;
  end;

// Definir inquilino atual
TContextoInquilino.Atual.AtribuirInquilino(42);

// Todas as queries incluem automaticamente:
// WHERE ID_INQUILINO = 42
```

---

## Auditoria (`MF.Extensions.Audit.pas`)

Registra automaticamente todas as operações de insert/update/delete em uma tabela de auditoria.

```pascal
// Configurar
TAjudanteAuditoria.Ativo := True;
TAjudanteAuditoria.UsuarioAtual := 'sistema';

// Cada operação gera um registro:
// Tabela: AUDITORIA
// - TabelaAfetada, RegistroId, Acao (I/U/D)
// - ValoresAntigos (JSON), ValoresNovos (JSON)
// - Usuario, DataHora
```

---

## Criptografia de Coluna (`MF.Extensions.Encryption.pas`)

Criptografia AES-256 em nível de coluna.

```pascal
type
  TCliente = class
  private
    FCPF: string;
  public
    [Criptografado]
    [Coluna('CPF')]
    property CPF: string read FCPF write FCPF;
  end;

// O ORM criptografa ao salvar e descriptografa ao ler automaticamente
```

---

## Bulk Operations (`MF.Extensions.Bulk.pas`)

Operações em lote usando Array DML do FireDAC.

```pascal
var
  LBulk: TAjudanteOperacoesEmLote;
begin
  LBulk := TAjudanteOperacoesEmLote.Create(FConexao);

  // Inserir 1000 registros em lote
  LBulk.InserirEmLote<TProduto>(LListaProdutos);

  // Atualizar em lote
  LBulk.AtualizarEmLote<TProduto>(LListaProdutos);

  // Excluir em lote
  LBulk.ExcluirEmLote<TProduto>(LIds);
end;
```

---

## Async Streaming (`MF.Extensions.Async.pas`)

Processamento assíncrono de grandes volumes sem carregar tudo em memória.

```pascal
var
  LStream: IAsyncEnumerable<TProduto>;
begin
  LStream := TAsyncStreaming<TProduto>.Create(FConexao,
    'SELECT * FROM PRODUTOS');

  for var LProduto in LStream do
    Processar(LProduto);  // Uma linha por vez
end;
```

---

## Global Filters (`MF.Extensions.GlobalFilters.pas`)

Filtros globais aplicados a todas as queries de uma entidade (similar a EF Core Query Filters).

```pascal
// Adicionar filtro global
TGlobalFilters.Adicionar<TProduto>(
  Criterio('ATIVO').Igual(True)
);

// Todas as queries de TProduto incluirão WHERE ATIVO = 1
```

---

## Concorrência Otimista (`MF.Extensions.Concorrencia.pas`)

Detecção de conflitos via coluna de versão.

```pascal
type
  TProduto = class
  private
    FVersao: Integer;
  public
    [Versao]
    [Coluna('VERSAO')]
    property Versao: Integer read FVersao write FVersao;
  end;

// Se outro usuário alterar o registro entre a leitura e a escrita,
// o ORM lança EErroConcorrencia
```

---

## Shadow Properties (`MF.Extensions.Sombra.pas`)

Preenchimento automático de propriedades de auditoria.

```pascal
type
  TProduto = class
  private
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    [CriadoEm]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;

    [AtualizadoEm]
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

// CriadoEm é preenchido automaticamente no insert
// AtualizadoEm é atualizado automaticamente no update
```

---

## DataSet Bridge (`MF.Extensions.DataSet.pas`)

`TMinusDataSet` — componente `TDataSet` que envolve resultados do ORM, permitindo uso com grids VCL/db-aware.

```pascal
// Em um formulário VCL
MinusDataSet1: TMinusDataSet;
DataSource1.DataSet := MinusDataSet1;

// Alimentar com dados do ORM
MinusDataSet1.Abrir<TProduto>(FConexao);
```

---

## Telemetry ORM (`MF.Extensions.Telemetry.ORM.pas`)

Decorators que criam spans de tracing para cada operação de banco.

```pascal
// As queries geram spans automaticamente:
// - Nome: "DB <Produto>.Salvar"
// - Tags: sql, entidade, duracao_ms
// - Evento: "Query" com o SQL executado
```

---

## Relacionamentos (`MF.Extensions.Relacionamento.pas`)

Carregamento lazy de propriedades de navegação.

```pascal
type
  TPedido = class
  private
    FItens: TObjectList<TItemPedido>;
  public
    [Ignorar]
    property Itens: TObjectList<TItemPedido> read FItens write FItens;
  end;

// Carregar relacionamento
var
  LAjudante: TAjudanteRelacionamento;
begin
  LAjudante := TAjudanteRelacionamento.Create(FConexao);
  LAjudante.CarregarLista<TPedido, TItemPedido>(
    LPedido, 'ID_PEDIDO', LPedido.Itens);
end;
```
