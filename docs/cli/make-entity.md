---
title: "`make:entity`"
---

<span class="badge badge-free">Free</span>

# `make:entity`

Gera uma entidade ORM completa com atributos de mapeamento.

## Uso

```bash
mfc make:entity <NomeEntidade> [opções]
```

## Opções

| Flag | Descrição | Padrão |
|------|-----------|--------|
| `--fields` | Lista de campos personalizados | Id, Nome, CriadoEm |
| `--output` | Diretório de saída | `src/Entities` |

## Exemplos

### Básico

```bash
mfc make:entity Produto
```

### Com campos personalizados

```bash
mfc make:entity Produto --fields=Nome:string,Preco:Currency,Estoque:Integer,CategoriaId:Integer
```

## Saída Gerada

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
    FPreco: Currency;
    FEstoque: Integer;
    FCategoriaId: Integer;
    FCriadoEm: TDateTime;
  public
    [ChavePrimaria]
    [AutoIncremento]
    [Coluna('id')]
    property Id: Integer read FId write FId;

    [Coluna('nome')]
    property Nome: string read FNome write FNome;

    [Coluna('preco')]
    property Preco: Currency read FPreco write FPreco;

    [Coluna('estoque')]
    property Estoque: Integer read FEstoque write FEstoque;

    [Coluna('categoria_id')]
    property CategoriaId: Integer read FCategoriaId write FCategoriaId;

    [Coluna('criado_em')]
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

implementation

end.
```


