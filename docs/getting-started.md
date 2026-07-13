---
title: "Getting Started"
---

﻿# Quick Start - O Tour de 5 Minutos

## 1. Instalacao (Free)

Baixe o instalador Free da pagina de releases e execute.

O instalador copia para C:\MinusFramework:

- **BPLs** - pacotes runtime e design-time
- **DCPs** - arquivos de cabecalho
- **DLLs** - ORM (SQLite) e Migrator via C-API
- **CLIs** - MinusMigrator_CLI.exe (alias `mfc`)
- **Samples** - projetos demonstrativos com codigo-fonte

### Configuracao no RAD Studio

1. Abra Tools > Options > Environment Options > Delphi Options > Library
2. Adicione ao Library path:
   C:\MinusFramework\Bpl
   C:\MinusFramework\Dcp
3. Instale os pacotes design-time em Component > Install Packages > Add:
   C:\MinusFramework\Bpl\MinusFramework_Design.bpl

---

## 2. Hello World - SQLite em Memoria

Crie um novo Console Application no Delphi:

```pascal
program HelloMinus;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MF,
  MF.Types;

var LConexao: IConexao;
begin
  LConexao := TConexaoFactory.Criar
    .Driver('SQLite')
    .Database(':memory:')
    .Conectar;
  WriteLn('Conectado ao SQLite em memoria!');
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
    [Coluna('ID')]
    property Id: Integer read FId write FId;
    [Coluna('NOME')]
    property Nome: string read FNome write FNome;
    [Coluna('EMAIL')]
    property Email: string read FEmail write FEmail;
    [Coluna('DATA_CADASTRO')]
    property DataCadastro: TDateTime read FDataCadastro write FDataCadastro;
  end;
```

---

## 4. CRUD Completo

```pascal
var
  LRepos: IRepositorio<TPessoa>;
  LPessoa: TPessoa;
begin
  LRepos := TConexaoFactory.Criar
    .Driver('SQLite')
    .Database(':memory:')
    .Conectar
    .Repositorio<TPessoa>;

  LRepos.GerarTabela;

  // Salvar
  LPessoa := TPessoa.Create;
  LPessoa.Nome := 'Joao da Silva';
  LPessoa.Email := 'joao@email.com';
  LPessoa.DataCadastro := Now;
  LRepos.Salvar(LPessoa);
  WriteLn('Salvo! ID: ', LPessoa.Id);

  // Buscar Todos
  for var LItem in LRepos.BuscarTodos do
    WriteLn(LItem.Nome + ' - ' + LItem.Email);

  // Buscar por ID
  LPessoa := LRepos.BuscarPorId(1);

  // Atualizar
  LPessoa.Nome := 'Joao atualizado';
  LRepos.Salvar(LPessoa);

  // Deletar
  LRepos.Deletar(LPessoa);
end.
```

---

## 5. Proximos Passos

| Topico | Link |
|--------|------|
| ORM Completo (Criteria, UoW) | Documentacao ORM |
| Migracao de Banco | MinusMigrator CLI |
| CLI de Scaffolding | Comandos do mfc |
> Dica: Execute `mfc make:entity Pessoa` no terminal para gerar a unit automaticamente.
