# Foundation Libraries

**Pacote:** MinusFramework_Runtime  
**Diretório:** `Source\Bibliotecas\`

Camada base do framework. Contém tipos fundamentais, abstrações de conexão, registro de provedores e utilitários.

---

## MF.Types (`Source\Bibliotecas\MF.Types.pas`)

Tipos fundamentais usados por todo o framework.

### `TTipoBancoDados`
Enum dos bancos suportados:

| Valor | Banco |
|-------|-------|
| `bdDesconhecido` | - |
| `bdFirebird` | Firebird |
| `bdPostgreSQL` | PostgreSQL |
| `bdSQLite` | SQLite |
| `bdMySQL` | MySQL |
| `bdMariaDB` | MariaDB |
| `bdMSSQL` | SQL Server |
| `bdOracle` | Oracle |
| `bdDB2` | IBM DB2 |

### `TEstrategiaId`
Estratégias de geração de ID:

| Valor | Descrição |
|-------|-----------|
| `eiIdentidade` | Auto-incremento nativo do banco |
| `eiSequencia` | Sequence/Generator |
| `eiGUID` | GUID gerado em memória |
| `eiManual` | Atribuição manual |

### `TParametrosConexao`
Parâmetros de conexão com banco de dados.

**Propriedades:**
- `DriverName` — Nome do driver FireDAC (`FB`, `SQLite`, `PG`, `MySQL`, `MariaDB`, etc.)
- `Database` — Caminho do banco ou nome do database
- `Username` / `Password` — Credenciais
- `Host` / `Port` — Endereço do servidor
- `CharacterSet` — Charset (ex: `UTF8`)
- `VendorLib` — Caminho da biblioteca nativa (ex: `fbclient.dll`)
- `ExtendedParams` — Pares chave/valor adicionais

**Métodos:**
- `Parse(const AConexaoStr: string): TParametrosConexao` — Converte string de conexão no formato `<driver>://<user>:<pass>@<host>:<port>/<db>` para parâmetros

### `TResultadoExecucao`
Resultado de execução de comando SQL:
- `LinhasAfetadas: Integer`
- `IdAutoGerado: Variant`

---

## MF.Connection (`Source\Bibliotecas\MF.Connection.pas`)

Abstrações de conexão com banco de dados. Todo o ORM trabalha através dessas interfaces, nunca diretamente com FireDAC/ADO.

### Interfaces

**`ICampo`** — Valor de um campo em um result set:
- `ComoInteiro`, `ComoTexto`, `ComoBooleano`, `ComoData`, `ComoMoeda`, `ComoFloat`, `ComoVariant`
- `EhNulo`, `NomeCampo`, `TipoDados`

**`IParametro`** — Parâmetro de query:
- `Nome`, `Valor`, `TipoBanco`
- `DefinirTexto`, `DefinirInteiro`, `DefinirMoeda`, `DefinirBooleano`, `DefinirNulo`

**`IComando`** — Comando SQL executável:
- `SQL: string`
- `Executar: TResultadoExecucao`
- `ExecutarConsulta: IResultados`
- `ParametroPorNome(const ANome: string): IParametro`
- `Preparar`, `Cancelar`

**`IResultados`** — Result set:
- `Proximo: Boolean`
- `NomesCampos: TArray<string>`
- `CampoPorNome(const ANome: string): ICampo`
- `CampoPorIndice(AIndice: Integer): ICampo`
- `Fechar`, `EOF`

**`IConexao`** — Conexão com o banco:
- `Conectar(const AParametros: TParametrosConexao)`
- `CriarComando: IComando`
- `IniciarTransacao`, `Confirmar`, `Reverter`
- `EmTransacao`, `EstaConectado`, `Desconectar`
- `CriarSavepoint`, `LiberarSavepoint`, `ReverterParaSavepoint`

**`IFabricaConexao`** — Factory de conexões:
- `CriarConexao(const AParametros: TParametrosConexao): IConexao`
- `NomeProvedor: string`

---

## MF.Provider (`Source\Bibliotecas\MF.Provider.pas`)

Registro central de provedores de banco de dados.

**`TRegistroProvedores`** (singleton):
- `RegistrarFabrica(const ANome: string; AFabrica: IFabricaConexao)` — Registra um provedor
- `RemoverFabrica(const ANome: string)` — Remove provedor
- `CriarConexao(const AParametros: TParametrosConexao): IConexao` — Cria conexão pelo driver name
- `ObterNomesProvedores: TArray<string>` — Lista provedores disponíveis

---

## MF.Config (`Source\Bibliotecas\MF.Config.pas`)

Configuração global do ORM.

**`TConfiguracaoORM`** (class):
- `Configurar(const AConexaoStr: string)` — Configura a partir de string de conexão
- `ConexaoPadrao: IConexao` — Conexão padrão global
- `ConfiguracaoPool: TConfiguracaoPool` — Pool de conexões (HikariCP-style)
- `FeatureFlags: TFeatureFlags` — Acesso ao subsistema de feature flags
- `CacheAtivo: Boolean` — Habilita cache

---

## MF.Attributes (`Source\Bibliotecas\MF.Attributes.pas`)

Atributos RTTI para mapeamento objeto-relacional.

| Atributo | Alvo | Descrição |
|----------|------|-----------|
| `Tabela` | Classe | Nome da tabela no banco |
| `Coluna` | Propriedade | Nome da coluna |
| `ChavePrimaria` | Propriedade | Chave primária (com estratégia) |
| `Ignorar` | Propriedade | Ignora no mapeamento |
| `SoftDelete` | Classe | Habilita soft delete |
| `Cache` | Classe | Configura cache (TTL, região) |
| `Versao` | Propriedade | Coluna de versão (concorrência) |
| `CriadoEm` / `AtualizadoEm` | Propriedade | Timestamps automáticos |
| `CriadoPor` / `AtualizadoPor` | Propriedade | Auditoria de usuário |
| `ChaveUnica` | Propriedade | Unique constraint |
| `AutoMapear` | Classe | Configura auto-mapping |
| `TPHEntidade` | Classe | Table-per-Hierarchy (herança) |
| `Discriminador` | Classe | Coluna discriminadora para TPH |

---

## MF.Exceptions (`Source\Bibliotecas\MF.Exceptions.pas`)

Hierarquia completa de exceções:

```
EExcecaoORM
 +-- EErroConexao
 |    +-- ENaoConectado
 |    +-- EFalhaConexao
 +-- EProvedorNaoEncontrado
 +-- EErroProvedor
 |    +-- EErroBancoDados
 |    +-- EErroViolacaoChaveUnica
 |    +-- EErroChaveEstrangeira
 +-- EErroTransacao
 |    +-- ETransacaoEmAndamento
 |    +-- ETransacaoNaoIniciada
 +-- EErroMapeamento
 |    +-- EEntidadeNaoEncontrada
 +-- EErroValidacao
 +-- EErroRepositorio
 +-- EErroCache
 +-- EErroPaginacao
```

---

## MF.ConnectionPool (`Source\Bibliotecas\MF.ConnectionPool.pas`)

Pool de conexões estilo HikariCP.

**`TConfiguracaoPool`:**
- `MinSize` — Conexões mínimas (default: 2)
- `MaxSize` — Conexões máximas (default: 10)
- `TimeoutMs` — Timeout para adquirir conexão (default: 30000)
- `HealthCheckMs` — Intervalo de health check (default: 60000)
- `MaxLifetimeMs` — Tempo máximo de vida (default: 180000)

**`TPoolConexoes`:**
- Thread-safe
- Health checks periódicos
- Expansão/contração dentro dos limites

---

## Provedores FireDAC (`Source\Bibliotecas\Providers\`)

Implementações concretas usando FireDAC.

| Unit | Driver | Banco |
|------|--------|-------|
| `MF.Provider.FireDAC.Firebird.pas` | `FB` | Firebird |
| `MF.Provider.FireDAC.SQLite.pas` | `SQLite` | SQLite |
| `MF.Provider.FireDAC.PostgreSQL.pas` | `PG` | PostgreSQL |
| `MF.Provider.FireDAC.MySQL.pas` | `MySQL` | MySQL |
| `MF.Provider.FireDAC.MariaDB.pas` | `MySQL` | MariaDB (usa driver MySQL) |
| `MF.Provider.FireDAC.MSSQL.pas` | `MSSQL` | SQL Server |
| `MF.Provider.FireDAC.Oracle.pas` | `Ora` | Oracle |
| `MF.Provider.FireDAC.DB2.pas` | `DB2` | IBM DB2 |

### Provedor ADO (`MF.Provider.ADO.pas`)
Provider alternativo usando ADO (para conexões com SQL Server legado).

### Criando um provedor customizado

```pascal
// 1. Implementar IFabricaConexao
TMeuProvider = class(TInterfacedObject, IFabricaConexao)
  function CriarConexao(const AParametros: TParametrosConexao): IConexao;
  function NomeProvedor: string;
end;

// 2. Registrar
TRegistroProvedores.RegistrarFabrica('MyDB', TMeuProvider.Create);
```
