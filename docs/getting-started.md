# Quick Start — O Tour de 5 Minutos

## 1. Instalação (Free)

Baixe o instalador Free da [página de releases](https://github.com/GabrielFerreiraMendes/minusframework/releases/latest) e execute.

O instalador copia para `C:\MinusFramework`:

- **BPLs** — pacotes runtime e design-time
- **DCPs** — arquivos de cabeçalho
- **DLLs** — ORM (SQLite) e Migrator via C-API
- **CLIs** — `MinusMigrator.exe`, `minus.exe`
- **Samples** — projetos demonstrativos com código-fonte

### Configuração no RAD Studio

1. Abra `Tools > Options > Environment Options > Delphi Options > Library`
2. Adicione ao `Library path`:
   ```
   C:\MinusFramework\Bpl
   C:\MinusFramework\Dcp
   ```
3. Instale os pacotes design-time em `Component > Install Packages > Add`:
   ```
   C:\MinusFramework\Bpl\MinusFramework_Design.bpl
   ```

> **Pro/Enterprise:** Consulte [Licenciamento](licensing.md) para adquirir acesso a todos os bancos, mensageria, telemetria e AI.

---

## 2. Hello World — SQLite em Memória

Crie um novo **Console Application** no Delphi e adicione as uses:

```pascal
program HelloMinus;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MF,
  MF.Types;
```

### Conecte ao SQLite

```pascal
var
  LConexao: IConexao;
begin
  LConexao := TConexaoFactory.Criar
    .Driver('SQLite')
    .Database(':memory:')
    .Conectar;

  WriteLn('Conectado ao SQLite em memória!');
  ReadLn;
end.
```

---

## 3. Mapeie uma Entidade

```pascal
type
  [Tabela('PESSOA')]
  TPessoa = class(TMFEntity)
  private
    FId: Integer;
    FNome: string;
    FEmail: string;
    FDataCadastro: TDateTime;
  public
    [ChavePrimaria]
    [AutoIncremento]
    [Campo('ID')]
    property Id: Integer read FId write FId;

    [Campo('NOME', 100)]
    property Nome: string read FNome write FNome;

    [Campo('EMAIL', 150)]
    property Email: string read FEmail write FEmail;

    [Campo('DATA_CADASTRO')]
    property DataCadastro: TDateTime read FDataCadastro write FDataCadastro;
  end;
```

---

## 4. CRUD Completo

```pascal
var
  LRepos: IRepositorio<TPessoa>;
  LPessoa: TPessoa;
  LTodas: TArray<TPessoa>;
begin
  LRepos := TConexaoFactory.Criar
    .Driver('SQLite')
    .Database(':memory:')
    .Conectar
    .Repositorio<TPessoa>;

  // Criar tabela automaticamente
  LRepos.GerarTabela;

  // --- Salvar ---
  LPessoa := TPessoa.Create;
  LPessoa.Nome := 'João da Silva';
  LPessoa.Email := 'joao@email.com';
  LPessoa.DataCadastro := Now;
  LRepos.Salvar(LPessoa);
  WriteLn('Salvo! ID: ', LPessoa.Id);

  // --- Buscar Todos ---
  LTodas := LRepos.BuscarTodos;
  for var LItem in LTodas do
    WriteLn(LItem.Nome, ' — ', LItem.Email);

  // --- Buscar por ID ---
  LPessoa := LRepos.BuscarPorId(1);
  if LPessoa <> nil then
    WriteLn('Encontrado: ', LPessoa.Nome);

  // --- Atualizar ---
  LPessoa.Nome := 'João atualizado';
  LRepos.Salvar(LPessoa);

  // --- Deletar ---
  LRepos.Deletar(LPessoa);
end.
```

---

## 5. Próximos Passos

| Tópico | Link |
|--------|------|
| ORM Completo (Criteria API, UoW) | [Documentação ORM](orm/crud.md) |
| Migração de Banco | [MinusMigrator CLI](migrator/cli.md) |
| CLI de Scaffolding | [Comandos do minus.exe](cli/commands.md) |
| Servidor MCP de IA | [MinusAI](ai/mcp-server.md) — Enterprise |
| Mensageria | [MinusMessaging](messaging/config.md) — Pro |
| Tiers de Licença | [Licenciamento](licensing.md) |

---

!!! tip "Dica"
    Execute `minus make:entity Pessoa` no terminal para gerar a unit automaticamente — o CLI usa templates otimizados com todos os atributos ORM.
