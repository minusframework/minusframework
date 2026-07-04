---
title: "MinusORM"
---

# MinusORM

ORM com RTTI, queries fluentes, Unit of Work e 7 providers de banco.

## Funcionalidades

- **Mapeamento por Atributos** — `[Tabela]`, `[ChavePrimaria]`, `[AutoIncremento]`, `[Coluna]`, `[Nullable]`
- **Repositório Genérico** — `IRepositorio<T>` com CRUD completo
- **Criteria API** — consultas type-safe fluentes
- **Unit of Work** — change tracking, identity map, transações
- **7 Providers** — SQLite, Firebird, PostgreSQL, MySQL, MariaDB, MSSQL, Oracle
- **Cache** — cache L1 (identity map) e L2 configurável
- **Soft Delete** — deleção lógica automática
- **Auditoria** — quem criou, alterou, quando
- **Lazy Loading** — carregamento sob demanda de relacionamentos

## Exemplo Rápido

```pascal
uses MF, MF.Types, MF.Attributes;

type
  [Tabela('PRODUTO')]
  TProduto = class(TMFEntity)
  private
    FId: Integer;
    FNome: string;
    FPreco: Currency;
  public
    [ChavePrimaria]
    [AutoIncremento]
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Preco: Currency read FPreco write FPreco;
  end;
```

## Seções

- [CRUD Básico](crud.md)
- [Mapeamento de Entidades](entities.md)
- [Criteria API](criteria.md)
- [Unit of Work](unit-of-work.md)
- [Providers](providers.md)
