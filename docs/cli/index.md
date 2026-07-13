---
title: "CLI — MinusFrameWork Command Line"
---

<span class="badge badge-free">Free</span>

# CLI — MinusFrameWork Command Line

A ferramenta de linha de comando `MinusMigrator_CLI.exe` (alias `mfc`) oferece scaffolding rápido para projetos Delphi com MinusORM e Horse.

## Instalação

Inclusa no instalador do MinusFramework em `C:\MinusFramework\Bin\MinusMigrator_CLI.exe` (alias `mfc`).

Ou compile manualmente:

```bash
cd Cli\Source
dcc32 MinusMigrator_CLI.dproj
```

## Uso Rápido

```bash
mfc                            # Lista comandos disponíveis
mfc make:entity Pessoa         # Gera entidade
mfc new api MinhaAPI           # Cria projeto REST
```

## Comandos

- [`make:entity`](commands.md#makeentity) — Gerar entidade ORM
- [`new api`](commands.md#new-api) — Criar projeto REST API

## Plugins

A partir da v0.1.0, o CLI suporta plugins via `IMFPlugin`. Cada plugin pode estender os comandos disponíveis implementando a interface `IMFPlugin`, permitindo adicionar novos subcomandos e lógica personalizada sem modificar o núcleo da CLI.
