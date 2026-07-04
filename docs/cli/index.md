---
title: "CLI — MinusFrameWork Command Line"
---

# CLI — MinusFrameWork Command Line

A ferramenta de linha de comando `minus.exe` oferece scaffolding rápido para projetos Delphi com MinusORM e Horse.

## Instalação

Inclusa no instalador do MinusFramework em `C:\MinusFramework\Bin\minus.exe`.

Ou compile manualmente:

```bash
cd Cli\Source
dcc32 MinusCLI.dproj
```

## Uso Rápido

```bash
minus                          # Lista comandos disponíveis
minus make:entity Pessoa       # Gera entidade
minus new api MinhaAPI         # Cria projeto REST
```

## Comandos

- [`make:entity`](commands.md#makeentity) — Gerar entidade ORM
- [`new api`](commands.md#new-api) — Criar projeto REST API
