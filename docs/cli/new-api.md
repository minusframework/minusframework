---
title: "`new api`"
---

<span class="badge badge-free">Free</span>

# `new api`

Cria um projeto REST API completo com servidor Horse + MinusORM.

## Uso

```bash
mfc new api <NomeProjeto> [opções]
```

## Opções

| Flag | Descrição | Padrão |
|------|-----------|--------|
| `--dir` | Diretório do projeto | `./<NomeProjeto>` |

## Exemplo

```bash
mfc new api MeuApp --dir=./meu-app
```

## Estrutura Gerada

```
meu-app/
  minus.json                    # Configuração
  docker-compose.yml            # PostgreSQL para desenvolvimento
  src/
    MeuApp.dpr                  # Entry point do servidor
    Controllers/
      HomeController.pas        # Rota /api
    Models/
    Services/
    Entities/
```

## `MeuApp.dpr`

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
      Res.Send('{ "service": "meuapp", "version": "1.0.0" }');
    end);

  THorse.Get('/health',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send('{ "status": "healthy" }');
    end);

  THorse.Listen(9000);
end.
```

## `docker-compose.yml`

```yaml
version: "3.8"

services:
  database:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app123
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

## Próximos Passos

```bash
cd meu-app
dcc32 src\MeuApp.dpr
src\MeuApp.exe
# http://localhost:9000/api
```
