---
title: "CLI — Comandos"
---

<span class="badge badge-free">Free</span>

# CLI — Comandos

A CLI `MinusMigrator_CLI.exe` (alias `mfc`) é uma ferramenta de scaffolding que acelera a criação de projetos e entidades.

## Uso

```bash
mfc <comando> [argumentos]
```

## Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `make:entity` | Gera uma entidade ORM (POCO + atributos) |
| `new api` | Cria um projeto REST API (Horse + MinusORM) |

---

## `make:entity`

Gera um arquivo `.pas` com a entidade mapeada pronta para uso com o MinusORM.

```bash
mfc make:entity Produto
```

### Exemplo de saída

Gera `src/Entities/Produto.pas`:

```pascal
unit Entities.Produto;

interface

uses
  System.SysUtils,
  MF.Attributes;

type
  [Tabela('produto')]
  TProduto = class
  private
    FId: Integer;
    FNome: string;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('id')]
    property Id: Integer read FId write FId;

    [Coluna('nome')]
    property Nome: string read FNome write FNome;

    [Coluna('criadoEm')]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

implementation

end.
```

### Opções

| Flag | Descrição | Padrão |
|------|-----------|--------|
| `--fields=Nome:string,Preco:Currency` | Lista de campos personalizados | Id, Nome, CriadoEm |
| `--output=src/Entities` | Diretório de saída | `src/Entities` |

```bash
mfc make:entity Produto --fields=Nome:string,Preco:Currency,Estoque:Integer
```

---

## `new api`

Cria um projeto REST API completo com servidor Horse.

```bash
mfc new api MeuApp --dir=./meu-app
```

### Estrutura gerada

```
meu-app/
  minus.json                  # Configuração do projeto
  docker-compose.yml          # PostgreSQL para desenvolvimento
  src/
    MeuApp.dpr                # Entry point do servidor
    Controllers/
      HomeController.pas      # Rota /api
    Models/
    Services/
    Entities/
```

### `src/MeuApp.dpr`

```pascal
program MeuApp;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Controllers.Home in 'Controllers\HomeController.pas';

begin
  THorse.Use(Jhonson);

  THorse.Get('/',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send('{"service": "meuapp", "version": "1.0.0"}');
    end);

  THorse.Get('/health',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send('{ "status": "healthy" }');
    end);

  THorse.Listen(9000);
end.
```

### Compilar e Executar

```bash
cd meu-app
dcc32 src\MeuApp.dpr
src\MeuApp.exe
# Servidor ouvindo em http://localhost:9000
```
