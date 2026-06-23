# Convenções de Nomenclatura — MinusFramework

> **Adotado em:** Junho/2026
> **Versão:** 1.0

## Princípio

O MinusFramework adota **português como idioma primário** para nomes de tipos, métodos e documentação.  
Aliases em inglês são fornecidos para os tipos principais visando adoção internacional.

## Regra Geral

| Elemento | Idioma | Exemplo |
|----------|--------|---------|
| **Units** | Inglês | `MF.Connection.pas`, `MF.RepositoryBase.pas` |
| **Interfaces** | Inglês ou Português | `IConexao`, `IRepositorioBase<T>` |
| **Classes** | Português (preferencial) | `TRepositorioBase<T>`, `TUnidadeTrabalho` |
| **Métodos** | Português | `BuscarPorId`, `Salvar`, `Confirmar` |
| **Atributos** | Português | `Tabela`, `Coluna`, `ChavePrimaria` |
| **Comentários** | Português | `/// <summary>...</summary>` |

## Aliases em Inglês

Para facilitar adoção por desenvolvedores internacionais, os seguintes aliases estão disponíveis:

| Nome em Português | Alias em Inglês |
|-------------------|-----------------|
| `TUnidadeTrabalho` | `TUnitOfWork` |
| `TRepositorioBase<T>` | `TRepository<T>` |
| `TMapaIdentidade` | `TIdentityMap` |
| `TRastreadorMudancas` | `TChangeTracker` |
| `TConstrutorSelecao<T>` | `TSelectBuilder<T>` |
| `TConstrutorCriterio` | `TCriteriaBuilder` |
| `EExcecaoORM` | `EORMException` |
| `IConexao` | `IConnection` |
| `IComando` | `ICommand` |
| `IResultados` | `IResultSet` |

## Exceções

- **Units de providers** usam nomes em inglês: `MF.Provider.FireDAC.pas`
- **Interfaces base** podem ter nomes em inglês por compatibilidade com padrões Delphi
- **Código de terceiros** (Horse, JOSE, etc.) mantém sua nomenclatura original

## Migração de Código Legado

Código que ainda usa padrões antigos (ex: `TORMConnectionParams`) deve ser migrado gradualmente.
A prioridade é não quebrar a API pública.
