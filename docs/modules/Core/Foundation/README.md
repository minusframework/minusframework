# Foundation Libraries

**Pacote:** MinusFramework_Runtime  
**DiretÃ³rio:** `Source\Bibliotecas\`

Camada base do framework. ContÃ©m tipos fundamentais, abstraÃ§Ãµes de conexÃ£o, registro de provedores e utilitÃ¡rios.

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
EstratÃ©gias de geraÃ§Ã£o de ID:

| Valor | DescriÃ§Ã£o |
|-------|-----------|
| `eiIdentidade` | Auto-incremento nativo do banco |
| `eiSequencia` | Sequence/Generator |
| `eiGUID` | GUID gerado em memÃ³ria |
| `eiManual` | AtribuiÃ§Ã£o manual |

### `TParametrosConexao`
ParÃ¢metros de conexÃ£o com banco de dados.

**Propriedades:**
- `DriverName` â€” Nome do driver FireDAC (`FB`, `SQLite`, `PG`, `MySQL`, `MariaDB`, etc.)
- `Database` â€” Caminho do banco ou nome do database
- `Username` / `Password` â€” Credenciais
- `Host` / `Port` â€” EndereÃ§o do servidor
- `CharacterSet` â€” Charset (ex: `UTF8`)
- `VendorLib` â€” Caminho da biblioteca nativa (ex: `fbclient.dll`)
- `ExtendedParams` â€” Pares chave/valor adicionais

**MÃ©todos:**
- `Parse(const AConexaoStr: string): TParametrosConexao` â€” Converte string de conexÃ£o no formato `<driver>://<user>:<pass>@<host>:<port>/<db>` para parÃ¢metros

### `TResultadoExecucao`
Resultado de execuÃ§Ã£o de comando SQL:
- `LinhasAfetadas: Integer`
- `IdAutoGerado: Variant`

---

## MF.Connection (`Source\Bibliotecas\MF.Connection.pas`)

AbstraÃ§Ãµes de conexÃ£o com banco de dados. Todo o ORM trabalha atravÃ©s dessas interfaces, nunca diretamente com FireDAC/ADO.

### Interfaces

**`ICampo`** â€” Valor de um campo em um result set:
- `ComoInteiro`, `ComoTexto`, `ComoBooleano`, `ComoData`, `ComoMoeda`, `ComoFloat`, `ComoVariant`
- `EhNulo`, `NomeCampo`, `TipoDados`

**`IParametro`** â€” ParÃ¢metro de query:
- `Nome`, `Valor`, `TipoBanco`
- `DefinirTexto`, `DefinirInteiro`, `DefinirMoeda`, `DefinirBooleano`, `DefinirNulo`

**`IComando`** â€” Comando SQL executÃ¡vel:
- `SQL: string`
- `Executar: TResultadoExecucao`
- `ExecutarConsulta: IResultados`
- `ParametroPorNome(const ANome: string): IParametro`
- `Preparar`, `Cancelar`

**`IResultados`** â€” Result set:
- `Proximo: Boolean`
- `NomesCampos: TArray<string>`
- `CampoPorNome(const ANome: string): ICampo`
- `CampoPorIndice(AIndice: Integer): ICampo`
- `Fechar`, `EOF`

**`IConexao`** â€” ConexÃ£o com o banco:
- `Conectar(const AParametros: TParametrosConexao)`
- `CriarComando: IComando`
- `IniciarTransacao`, `Confirmar`, `Reverter`
- `EmTransacao`, `EstaConectado`, `Desconectar`
- `CriarSavepoint`, `LiberarSavepoint`, `ReverterParaSavepoint`

**`IFabricaConexao`** â€” Factory de conexÃµes:
- `CriarConexao(const AParametros: TParametrosConexao): IConexao`
- `NomeProvedor: string`

---

## MF.Provider (`Source\Bibliotecas\MF.Provider.pas`)

Registro central de provedores de banco de dados.

**`TRegistroProvedores`** (singleton):
- `RegistrarFabrica(const ANome: string; AFabrica: IFabricaConexao)` â€” Registra um provedor
- `RemoverFabrica(const ANome: string)` â€” Remove provedor
- `CriarConexao(const AParametros: TParametrosConexao): IConexao` â€” Cria conexÃ£o pelo driver name
- `ObterNomesProvedores: TArray<string>` â€” Lista provedores disponÃ­veis

---

## MF.Config (`Source\Bibliotecas\MF.Config.pas`)

ConfiguraÃ§Ã£o global do ORM.

**`TConfiguracaoORM`** (class):
- `Configurar(const AConexaoStr: string)` â€” Configura a partir de string de conexÃ£o
- `ConexaoPadrao: IConexao` â€” ConexÃ£o padrÃ£o global
- `ConfiguracaoPool: TConfiguracaoPool` â€” Pool de conexÃµes (HikariCP-style)
- `FeatureFlags: TFeatureFlags` â€” Acesso ao subsistema de feature flags
- `CacheAtivo: Boolean` â€” Habilita cache

---

## MF.Attributes (`Source\Bibliotecas\MF.Attributes.pas`)

Atributos RTTI para mapeamento objeto-relacional.

| Atributo | Alvo | DescriÃ§Ã£o |
|----------|------|-----------|
| `Tabela` | Classe | Nome da tabela no banco |
| `Coluna` | Propriedade | Nome da coluna |
| `ChavePrimaria` | Propriedade | Chave primÃ¡ria (com estratÃ©gia) |
| `Ignorar` | Propriedade | Ignora no mapeamento |
| `SoftDelete` | Classe | Habilita soft delete |
| `Cache` | Classe | Configura cache (TTL, regiÃ£o) |
| `Versao` | Propriedade | Coluna de versÃ£o (concorrÃªncia) |
| `CriadoEm` / `AtualizadoEm` | Propriedade | Timestamps automÃ¡ticos |
| `CriadoPor` / `AtualizadoPor` | Propriedade | Auditoria de usuÃ¡rio |
| `ChaveUnica` | Propriedade | Unique constraint |
| `AutoMapear` | Classe | Configura auto-mapping |
| `TPHEntidade` | Classe | Table-per-Hierarchy (heranÃ§a) |
| `Discriminador` | Classe | Coluna discriminadora para TPH |

---

## MF.Exceptions (`Source\Bibliotecas\MF.Exceptions.pas`)

Hierarquia completa de exceÃ§Ãµes:

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

Pool de conexÃµes estilo HikariCP.

**`TConfiguracaoPool`:**
- `MinSize` â€” ConexÃµes mÃ­nimas (default: 2)
- `MaxSize` â€” ConexÃµes mÃ¡ximas (default: 10)
- `TimeoutMs` â€” Timeout para adquirir conexÃ£o (default: 30000)
- `HealthCheckMs` â€” Intervalo de health check (default: 60000)
- `MaxLifetimeMs` â€” Tempo mÃ¡ximo de vida (default: 180000)

**`TPoolConexoes`:**
- Thread-safe
- Health checks periÃ³dicos
- ExpansÃ£o/contraÃ§Ã£o dentro dos limites

---

## Provedores FireDAC (`Source\Bibliotecas\Providers\`)

ImplementaÃ§Ãµes concretas usando FireDAC.

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
Provider alternativo usando ADO (para conexÃµes com SQL Server legado).

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
