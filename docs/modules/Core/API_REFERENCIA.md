# MinusFramework â€” ReferÃªncia da API PÃºblica

> Interfaces, classes e mÃ©todos pÃºblicos do MinusORM v2.0
> **Ãšltima atualizaÃ§Ã£o:** Junho 2026 â€” Sprint 4 (ArrayDML)

---

## ConexÃ£o (`MF.Connection.pas`, `MF.Types.pas`)

### `IConexao`

A interface central de abstraÃ§Ã£o do banco de dados.

```pascal
IConexao = interface
  function CriarComando: IComando;
  procedure Conectar(const AParametros: TParametrosConexao);
  procedure Desconectar;
  function EstaConectado: Boolean;
  procedure IniciarTransacao;
  procedure Confirmar;
  procedure Reverter;
  function EmTransacao: Boolean;
  function TipoBancoDados: TTipoBancoDados;
  function ParametrosConexao: TParametrosConexao;
  function ClausulaDeLock: string;
  // Savepoints (Sprint 3)
  procedure CriarSavepoint(const ANome: string);
  procedure LiberarSavepoint(const ANome: string);
  procedure ReverterParaSavepoint(const ANome: string);
end;
```

### `IComando`

```pascal
IComando = interface
  property SQL: string read ObterSQL write DefinirSQL;
  function ParametroPorNome(const ANome: string): IParametro;
  function ParametroPorIndice(AIndex: Integer): IParametro;
  function Executar: Integer;          // INSERT/UPDATE/DELETE â†’ linhas afetadas
  function ExecutarConsulta: IResultados; // SELECT â†’ resultset
  procedure Cancelar;
  // Array DML â€” execuÃ§Ã£o em lote com 1 round-trip (Sprint 4)
  function SuportaArrayDML: Boolean;
  procedure DefinirArraySize(ASize: Integer);
  function ExecutarArray(ACount: Integer): Integer;
end;
```

### `IParametro`

```pascal
IParametro = interface
  property AsInteger: Integer read ComoInteiro write DefinirInteiro;
  property AsString: string read ComoTexto write DefinirTexto;
  property AsBoolean: Boolean read ComoBooleano write DefinirBooleano;
  property AsDateTime: TDateTime read ComoDataHora write DefinirDataHora;
  property AsCurrency: Currency read ComoMoeda write DefinirMoeda;
  property AsInt64: Int64 read ComoInteiro64 write DefinirInteiro64;
  property AsDouble: Double read ComoDecimal write DefinirDecimal;
  procedure DefinirBytes(const AValor: TBytes);
  function EhNulo: Boolean;
  function Nome: string;
  procedure Limpar;
  // Array DML â€” valores por Ã­ndice (Sprint 4)
  procedure DefinirArraySize(ASize: Integer);
  procedure DefinirValorNoIndice(AIndice: Integer; const AValor: TValue);
end;
```

### `IResultados`

```pascal
IResultados = interface
  function Proximo: Boolean;           // AvanÃ§a; retorna False se nÃ£o hÃ¡ mais registros
  function CampoPorNome(const ANome: string): ICampo;
  function CampoPorIndice(AIndice: Integer): ICampo;
  function QuantidadeCampos: Integer;
  function NomesCampos: TArray<string>;
  property EOF: Boolean read FimDados;
  procedure Fechar;
end;
```

### `ICampo`

```pascal
ICampo = interface
  function ComoInteiro: Integer;
  function ComoInteiro64: Int64;
  function ComoTexto: string;
  function ComoMoeda: Currency;
  function ComoDecimal: Double;
  function ComoBooleano: Boolean;
  function ComoDataHora: TDateTime;
  function ComoBytes: TBytes;
  function EhNulo: Boolean;
  function NomeCampo: string;
  function TipoDados: TTipoBancoDados;
end;
```

---

## ConfiguraÃ§Ã£o (`MF.Config.pas`)

### `TConfiguracaoORM`

Gerencia conexÃµes nomeadas e cache de segundo nÃ­vel.

```pascal
class procedure RegistrarConexao(const ANome: string; AConexao: IConexao);
class procedure RegistrarConexaoComParametros(const ANome: string;
  const AParametros: TParametrosConexao);
class function Conexao(const ANome: string = 'default'): IConexao;
class function ConexaoPadrao: IConexao;
class procedure DefinirConexaoPadrao(AConexao: IConexao);
class function ConexaoExiste(const ANome: string): Boolean;
class procedure RemoverConexao(const ANome: string);
class procedure Limpar;
class property Cache: ICacheProvedor read GetCache write SetCache;
```

---

## Connection Strings (`MF.Types.pas`)

### `TParametrosConexao`

```pascal
TParametrosConexao = record
  DriverName: string;   // 'FB' | 'PG' | 'SQLite' | 'MySQL'
  Database: string;
  Username: string;
  Password: string;
  Host: string;
  Port: Integer;
  VendorLib: string;
  CharacterSet: string;

  constructor Create(const ADriverName, ADatabase, AUsername,
    APassword, AHost: string; APort: Integer);
  class function Parse(const AConnectionString: string): TParametrosConexao; static;
end;
```

**Formato da connection string:**
```
firebird://usuario:senha@host:3050/caminho/banco.fdb?parametro=valor
postgresql://usuario:senha@host:5432/banco?parametro=valor
mysql://usuario:senha@host:3306/banco?parametro=valor
sqlite://caminho/banco.db
```

---

## Provider Registry (`MF.Provider.pas`)

### `TRegistroProvedores`

```pascal
class procedure RegistrarFabrica(AFabrica: IFabricaConexao);
class procedure RemoverFabrica(const ANomeProvedor: string);
class function CriarConexao(const AParametros: TParametrosConexao): IConexao;
class function ObterNomesProvedores: TArray<string>;
class function LocalizarFabrica(const ANomeProvedor: string): IFabricaConexao;
class procedure Limpar;
```

**Providers implementados:** `FB` (Firebird), `PG` (PostgreSQL), `SQLite`, `MySQL`

---

## ORM Core

### `TUnidadeTrabalho` (`MF.UnitOfWork.pas`)

Gerencia transaÃ§Ãµes e filas de CRUD com Change Tracking.

```pascal
constructor Create(AConexao: IConexao);
destructor Destroy; override;

procedure RegistrarNovo(const AEntidade: TObject);
procedure RegistrarSujo(const AEntidade: TObject);
procedure RegistrarExcluido(const AEntidade: TObject);
procedure Confirmar;    // DELETE â†’ INSERT â†’ UPDATE em uma transaÃ§Ã£o
procedure Reverter;     // Limpa as filas sem tocar no banco
procedure Limpar;

function ObterEstado(const AEntidade: TObject): TEstadoEntidade; // eeNovo|eeSujo|eeExcluido|eeLimpo
function ObterTodosNovos: TArray<TObject>;
function ObterTodosSujos: TArray<TObject>;
function ObterTodosExcluidos: TArray<TObject>;

property MapaIdentidade: TMapaIdentidade;
property RastreadorMudancas: TRastreadorMudancas;
```

**Fluxo do `Confirmar`:**
1. `IniciarTransacao`
2. Executa DELETE para entidades excluÃ­das (respeita SoftDelete)
3. Executa INSERT para entidades novas (gera ID via `IGeradorId`)
4. Executa UPDATE para entidades sujas (com lock otimista se `[Versao]`)
5. `Confirmar` (commit)
6. Limpa as filas e invalida cache

### `IRepositorioBase<T>` / `TRepositorioBase<T>` (`MF.RepositoryBase.pas`)

```pascal
IRepositorioBase<T: class> = interface
  function BuscarPorId(const AIdentificador: Integer): T;
  function BuscarTodos: TObjectList<T>;
  procedure Salvar(const AEntidade: T);           // Insert se Id=0, Update se Id>0
  procedure Excluir(const AIdentificador: Integer);
  function ParaCada(const AAccao: TFunc<T, Boolean>): Integer;
  function InserirEmLote(const AEntidades: TEnumerable<T>): TArray<Integer>;
  procedure AtualizarEmLote(const AEntidades: TEnumerable<T>);
  procedure ExcluirEmLote(const AIdentificadores: TEnumerable<Integer>);
end;
```

**MÃ©todos virtuais (override para customizaÃ§Ã£o):**
```pascal
function ObterOrdenacao: string; virtual;           // ORDER BY padrÃ£o
procedure AntesExcluir(const AIdentificador: Integer); virtual;
procedure AposBuscarPorId(const AEntidade: T); virtual;
```

**ObservaÃ§Ã£o:** `TRepositorioBase<T>.Salvar` lida com ciclo completo:
- Se `Id = 0` â†’ INSERT (com ou sem RETURNING, conforme `IGeradorId.SuportaRetorno`)
- Se `Id > 0` â†’ UPDATE (com validaÃ§Ã£o de versÃ£o e `EErroConcorrencia`)
- Valida `[NotNull]`, `[ChaveUnica]`, dispara shadow properties e auditoria

### `TMapaIdentidade` (`MF.IdentityMap.pas`)

Cache de primeiro nÃ­vel por classe + ID.

```pascal
procedure Adicionar(const AEntidade: TObject; const AId: Integer);
function Obter(const AClasse: TClass; const AId: Integer): TObject;
function Contem(const AClasse: TClass; const AId: Integer): Boolean;
procedure Remover(const AClasse: TClass; const AId: Integer);
procedure Limpar;
function ObterTodos(const AClasse: TClass): TArray<TObject>;
```

### `TRastreadorMudancas` (`MF.ChangeTracker.pas`)

Detecta mudanÃ§as por snapshot de RTTI.

```pascal
procedure CapturarInstantaneo(const AEntidade: TObject);
function TemMudancas(const AEntidade: TObject): Boolean;
function ObterMudancas(const AEntidade: TObject): TArray<TRegistroMudanca>;
procedure AceitarMudancas(const AEntidade: TObject);
procedure Limpar;
```

---

## Mapeamento (`MF.Mapper.pas`, `MF.Attributes.pas`)

### `TMapeador`

```pascal
class function MapearDoBanco<T: class>(const AResultados: IResultados): T; static;
class function MapearLista<T: class>(const AResultados: IResultados): TObjectList<T>; static;
```

### Atributos de Mapeamento

| Atributo | Alvo | DescriÃ§Ã£o |
|---|---|---|
| `[Tabela('NOME')]` | Classe | Nome da tabela no banco |
| `[Coluna('NOME')]` | Propriedade | Nome da coluna |
| `[ChavePrimaria]` | Propriedade | Identificador Ãºnico |
| `[Ignorar]` | Propriedade | Campo nÃ£o persistente |
| `[NotNull]` | Propriedade | ValidaÃ§Ã£o de obrigatoriedade |
| `[ReadOnly]` | Propriedade | ExcluÃ­do de INSERT/UPDATE |
| `[Versao('col', 1)]` | Propriedade | Lock otimista |
| `[Cache(ttl, 'regiao')]` | Classe | Cache de segundo nÃ­vel |
| `[SoftDelete('col', tipo)]` | Classe | ExclusÃ£o lÃ³gica |
| `[ChaveUnica('grupo', ['cols'])]` | Classe | Unique key |
| `[Relacionamento(tipo, fk, pk)]` | Propriedade | Navigation property |
| `[ChaveEstrangeira('NOME')]` | Propriedade | Nome da FK |
| `[CriadoEm]` | Propriedade | Shadow: setado automÃ¡tico no INSERT |
| `[AtualizadoEm]` | Propriedade | Shadow: setado automÃ¡tico no INSERT/UPDATE |

---

## Query Builders (`MF.SelectBuilder.pas`, `MF.Criteria.pas`)

### `TConstrutorSelecao<T>`

```pascal
class function Consulta(AConexao: IConexao;
  const ACampos: TArray<string> = []): TConstrutorSelecao<T>;

function Onde(ACriterio: ICriterio): TConstrutorSelecao<T>;
function OrdenarPor(const ACampo: string): TConstrutorSelecao<T>;
function Pular(AQuantidade: Integer): TConstrutorSelecao<T>;
function Pegar(AQuantidade: Integer): TConstrutorSelecao<T>;
function ParaLista: TObjectList<T>;
function ParaUnico: T;
function Contar: Integer;
function SQL: string;
```

### Criteria API (`MF.Criteria.pas`)

```pascal
function Criterio(const ANome: string): ICriterio;          // factory
function OuCriterios(const ACriterios: TArray<ICriterio>): ICriterio;
function E(const ALeft, ARight: ICriterio): ICriterio;
function Existe(const ASQL: string): ICriterio;
function Nao(const ACriterio: ICriterio): ICriterio;

// ICriterio:
function Igual(const AValor: TValue): ICriterio;
function MaiorQue(const AValor: TValue): ICriterio;
function MenorQue(const AValor: TValue): ICriterio;
function MaiorOuIgual(const AValor: TValue): ICriterio;
function MenorOuIgual(const AValor: TValue): ICriterio;
function Diferente(const AValor: TValue): ICriterio;
function Entre(const A, B: TValue): ICriterio;
function Como(const APadrao: string): ICriterio;      // LIKE
function EmSubconsulta(const ASQL: string): ICriterio; // IN (subquery)
function EhNulo: ICriterio;
function NaoEhNulo: ICriterio;
```

---

## ID Generator (`MF.IdGenerator.pas`)

### `IGeradorId`

```pascal
type
  IGeradorId = interface
    function GerarId(AComando: IComando; const ANomeTabela: string): Integer;
    function SuportaRetorno: Boolean;  // True: Firebird/PG (RETURNING); False: SQLite/MySQL (last_insert)
  end;
```

### `TFabricaGeradorId`

```pascal
class function CriarGerador(ATipoBanco: TTipoBancoDados): IGeradorId; static;
```

- `bdFirebird` â†’ `TGeradorIdFirebird` (GEN_GEN_TABELA_ID via RETURNING)
- `bdPostgreSQL` â†’ `TGeradorIdPostgreSQL` (NEXTVAL via RETURNING)
- `bdSQLite` â†’ `TGeradorIdSQLite` (last_insert_rowid())
- `bdMySQL` â†’ `TGeradorIdMySQL` (LAST_INSERT_ID())

---

## ExceÃ§Ãµes (`MF.Exceptions.pas`)

```pascal
EExcecaoORM = class(Exception);
  EErroConexao = class(EExcecaoORM);
  EErroMapeamento = class(EExcecaoORM);
  EErroRepositorio = class(EExcecaoORM);
  EErroConcorrencia = class(EExcecaoORM);
  ERecursoNaoImplementado = class(EExcecaoORM);
```

---

## Testes com Mocks (`Tests/ORM/Test.ORM.Mock.pas`)

O framework inclui mocks reutilizÃ¡veis para testes unitÃ¡rios sem banco de dados:

| Mock | Implementa | Uso |
|---|---|---|
| `TConexaoMock` | `IConexao` | Rastreia `IniciarTransacao`, `Confirmar`, `Reverter`; retorna `TComandoMock` |
| `TComandoMock` | `IComando` | Rastreia SQL e parÃ¢metros; `ExecutarResult` e `ExecutarConsultaResult` configurÃ¡veis |
| `TParametroMock` | `IParametro` | Armazena valores setados |
| `TResultadosMock` | `IResultados` | `Adicionar(nome, valor)` para simular linhas de resultado |
| `TCampoMock` | `ICampo` | Armazena nome + `TValue` |

```pascal
// Exemplo: testar UnitOfWork sem banco
var
  LMock: TConexaoMock;
  LUoW: TUnidadeTrabalho;
  LProduto: TTesteProduto;
begin
  LMock := TConexaoMock.Create(bdSQLite);
  LUoW := TUnidadeTrabalho.Create(LMock);
  LProduto := TTesteProduto.Create;
  try
    LProduto.Nome := 'Teste';
    LUoW.RegistrarNovo(LProduto);
    LUoW.Confirmar;
    Assert.AreEqual(1, LMock.IniciarTransacaoChamado);
    Assert.AreEqual(1, LMock.ConfirmarChamado);
    Assert.IsTrue(LMock.Comandos[0].SQL.Contains('INSERT'));
  finally
    LProduto.Free;
    LUoW.Free;
  end;
end;
```
