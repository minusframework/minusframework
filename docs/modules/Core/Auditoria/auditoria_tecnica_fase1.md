# Auditoria TÃ©cnica â€” MinusFramework v1.0
**Data:** 11/Junho/2026  
**Escopo:** Varredura completa do cÃ³digo fonte (Core, Bibliotecas, Extensions, Providers)  
**VersÃ£o auditada:** Commit `9937d3c` (Sprint 3 concluÃ­do)

---

## Ãndice
1. [SumÃ¡rio Executivo](#1-sumÃ¡rio-executivo)
2. [Fase 1 â€” Varredura e AnÃ¡lise Estrutural](#2-fase-1--varredura-e-anÃ¡lise-estrutural)
   - 2.1 MF.Types.pas
   - 2.2 MF.Connection.pas
   - 2.3 MF.Attributes.pas
   - 2.4 MF.MetadataCache.pas
   - 2.5 MF.Mapper.pas
   - 2.6 MF.IdentityMap.pas
   - 2.7 MF.IdGenerator.pas
   - 2.8 MF.QueryBuilder.pas
   - 2.9 MF.SelectBuilder.pas
   - 2.10 MF.Criteria.pas
   - 2.11 MF.ChangeTracker.pas
   - 2.12 MF.RepositoryBase.pas
   - 2.13 MF.UnitOfWork.pas
   - 2.14 MF.Context.pas
   - 2.15 MF.Extensions (Bulk, Profiler, Cache, etc.)
   - 2.16 Providers (FireDAC, ADO)
3. [Fase 2 â€” AnÃ¡lise Competitiva](#3-fase-2--anÃ¡lise-competitiva-ecossistema-delphi)
4. [Fase 3 â€” InovaÃ§Ã£o Cross-Language](#4-fase-3--inovaÃ§Ã£o-e-inspiraÃ§Ã£o-cross-language)
5. [Resumo de Fragilidades e Oportunidades](#5-resumo-de-fragilidades-e-oportunidades)

---

## 1. SumÃ¡rio Executivo

O MinusFramework Ã© um ORM Delphi maduro, com arquitetura em camadas bem definida (Core â†’ Extensions â†’ Providers), seguindo padrÃµes consagrados como Repository, Unit of Work, Identity Map, Change Tracking e Query Builder fluente. O cÃ³digo demonstra conhecimento profundo de RTTI, Generics e interfaces COM-like.

**PontuaÃ§Ã£o geral: 7.2/10**

| DimensÃ£o | Nota | ObservaÃ§Ã£o |
|---|---|---|
| Arquitetura | 8/10 | SeparaÃ§Ã£o clara de responsabilidades |
| Performance | 7/10 | Bom uso de cache, mas hÃ¡ gargalos de alocaÃ§Ã£o |
| SeguranÃ§a | 8/10 | SQL Injection mitigado, sem concatenaÃ§Ã£o de valores |
| Thread-Safety | 7/10 | MREW e threadvar no Sprint 3, mas hÃ¡ pontos cegos |
| Cobertura de Features | 7/10 | CRUD completo, mas sem migrations, sem schema first |
| Qualidade do CÃ³digo | 7/10 | Bom estilo, mas alguma duplicaÃ§Ã£o e verbosidade |
| InovaÃ§Ã£o | 7/10 | IdentityMap 2-nÃ­veis e TContextoORM sÃ£o diferenciais |

---

## 2. Fase 1 â€” Varredura e AnÃ¡lise Estrutural

### 2.1 MF.Types.pas
**Status:** âœ… SÃ³lido
- `TEstrategiaId` adicionado corretamente no Sprint 3.
- `TParametrosConexao` Ã© um record com parser de connection string â€” boa escolha para evitar alocaÃ§Ã£o heap.
- `TResultadoExecucao` Ã© subutilizado â€” o cÃ³digo usa `Integer` diretamente em vez deste record.

**Oportunidade:** Adicionar `TTipoBancoDados` como membro de `TResultadoExecucao` para diagnÃ³stico em produÃ§Ã£o.

---

### 2.2 MF.Connection.pas
**Status:** âœ… SÃ³lido, mas verboso

**Pontos fortes:**
- Interfaces bem definidas: `ICampo`, `IResultados`, `IParametro`, `IComando`, `IConexao`.
- Propriedades com alias portuguÃªs/inglÃªs (ex: `AsInteger` e `ComoInteiro`).
- Savepoints adicionados corretamente no Sprint 3.

**Fragilidades:**
- **DuplicaÃ§Ã£o massiva de conversÃ£o de tipos entre `IComando`, `IParametro`, `ICampo`.** Os mesmos padrÃµes `case LProp.PropertyType.Handle.Kind of tkInteger...` aparecem em 7+ arquivos diferentes (QueryBuilder, SelectBuilder, Bulk, Profiler, etc.). Isso Ã© um anti-pattern de manutenÃ§Ã£o â€” se um novo tipo for adicionado, precisa alterar em todos.
- `ICampo` com 34 mÃ©todos (entre propriedades e funÃ§Ãµes) â€” Ã© uma interface sobrecarregada. O padrÃ£o ISP (Interface Segregation Principle) sugere dividir em leitura/escrita especializadas.
- `IComando` nÃ£o tem suporte a batch/array DML (previsto no Sprint 4).

**RecomendaÃ§Ã£o arquitetural:** Criar `TConversorParametro` centralizado com visitantes tipados para eliminar a duplicaÃ§Ã£o de `case..of` em todo o cÃ³digo. Isso reduziria ~400 linhas de cÃ³digo duplicado e centralizaria a lÃ³gica de binding.

---

### 2.3 MF.Attributes.pas
**Status:** âœ… Funcional, mas com limitaÃ§Ãµes

**Pontos fortes:**
- Atributos cobrem os casos de uso principais: `Tabela`, `Coluna`, `ChavePrimaria`, `Versao`, `SoftDelete`, `Discriminador`, `ChaveUnica`.
- Suporte a heranÃ§a TPH via `DiscriminadorAttribute`.

**Fragilidades:**
- `ChavePrimariaAttribute` foi evoluÃ­do no Sprint 3 para aceitar `TEstrategiaId`, mas **faltam atributos para mapeamento explÃ­cito de sequence name, foreign key on-delete behavior, e Ã­ndices compostos.**
- `CacheAttribute` com TTL fixo â€” nÃ£o suporta polÃ­ticas de invalidaÃ§Ã£o dinÃ¢mica.
- Sem suporte a `[DefaultValue]`, `[ComputedColumn]` ou `[MaxLength]` para geraÃ§Ã£o de schema.

---

### 2.4 MF.MetadataCache.pas
**Status:** âœ… Bem implementado, ponto central da arquitetura

**Pontos fortes:**
- Double-checked locking com MREW (corrigido no Sprint 1) â€” thread-safe e reentrante.
- SQL prÃ©-compilado em `ColunasSelect`, `ColunasInsert`, `ParametrosInsert`, `ClausulasUpdate` â€” zero alocaÃ§Ã£o de string repetida.
- `IndicePropriedades: TDictionary<string, TRttiProperty>` com O(1) â€” correto.
- `PropriedadeChave`, `TipoPK`, `EstrategiaPK` populados no Sprint 3.
- `RttiContext` global (Singleton via class var) â€” evita criaÃ§Ã£o/destruiÃ§Ã£o repetida de `TRttiContext`.

**Fragilidades:**
- O construtor `TMetaEntidade.Create` Ã© **muito longo** (~170 linhas). Deveria ser quebrado em mÃ©todos privados: `LerAtributosTabela`, `LerPropriedades`, `LerHeranca`, `GerarSQL`.
- A verificaÃ§Ã£o de heranÃ§a (`ClassParent` loop) sÃ³ sobe um nÃ­vel â€” **nÃ£o suporta hierarquias de 3+ nÃ­veis com discriminadores aninhados.**
- `DiscriminadorMapa` Ã© populado como `TArray<TPair<string,string>>` mas depois reconstruÃ­do em `ObterAtributo<DiscriminadorAttribute>` cada vez que o mapper precisa resolver â€” isso Ã© O(nÂ²) disfarÃ§ado.

**Risco:** Se uma entidade tiver 30+ propriedades, a geraÃ§Ã£o de SQL (4 StringBuilder) ocorre toda vez que a classe Ã© mapeada pela primeira vez â€” mas isso sÃ³ acontece uma vez por classe (cache). OK.

---

### 2.5 MF.Mapper.pas
**Status:** âœ… Funcional, mas com problemas de duplicaÃ§Ã£o

**Pontos fortes:**
- `ConstruirMapaCampos` prÃ©-constroi dicionÃ¡rio O(1) uma vez por query â€” excelente.
- Identity Map integrado corretamente via `MapaIdentidadeThread`.
- Suporte a `TNullable<T>`, `TipoConverterAttribute`, e heranÃ§a TPH.

**Fragilidades:**
- **`MapearPropriedade` Ã© o mÃ©todo mais duplicado do framework.** A lÃ³gica de `case LProp.PropertyType.Handle.Kind of tkInteger...` aparece quase idÃªntica em:
  - `MapearPropriedade` (Mapper.pas)
  - `MapearDTO` (Mapper.pas)
  - `VincularParametrosEntidade` (QueryBuilder.pas)
  - `VincularParametro` (QueryBuilder.pas Ã— 2)
  - `InserirEmLote` (Bulk.pas)
  - `VincularParametros` (SelectBuilder.pas)
  
  Isso representa ~600+ linhas de cÃ³digo duplicado. Um **TypeMapper centralizado** eliminaria 80% dessa duplicaÃ§Ã£o.

- `MapearDoBanco<T>` e `MapearDoBancoPorClasse` tambÃ©m tÃªm lÃ³gica de Identity Map duplicada entre si.

---

### 2.6 MF.IdentityMap.pas
**Status:** âœ… Excelente evoluÃ§Ã£o no Sprint 3

**Pontos fortes:**
- Refatorado para dois nÃ­veis: `TObjectDictionary<TClass, TDictionary<TValue, TObject>>`.
- Hash de `TClass` como ponteiro â€” O(1) puro sem string.
- Chave agora Ã© `TValue` â€” suporta qualquer tipo de PK.

**Fragilidades:**
- `ObterTodos` ainda itera sobre todos os valores do dicionÃ¡rio interno e cria uma `TList<TObject>` temporÃ¡ria â€” **aloca heap a cada chamada.** Para APIs que chamam `ObterTodos` frequentemente, um cache em array seria mais eficiente.
- A comparaÃ§Ã£o de `TValue` usa `A.ToString = B.ToString` â€” isso Ã© correto para a maioria dos tipos, mas **para TGUID Ã© ineficiente** (converte GUID â†’ string â†’ compara string em vez de comparar os 16 bytes diretamente).

---

### 2.7 MF.IdGenerator.pas
**Status:** âœ… SÃ³lido

**Pontos fortes:**
- `GerarId` retorna `TValue` (Sprint 3) â€” suporta Integer, Int64, GUID.
- `TGeradorIdGUID` implementado corretamente com `CreateGUID`.
- Factory method `CriarGeradorPorEstrategia` permite selecionar estratÃ©gia.

**Fragilidades:**
- Os geradores especÃ­ficos de banco (Firebird, PostgreSQL, etc.) **ainda retornam `TValue.From<Integer>()` mesmo quando o banco suporta Int64.** Para tabelas com BIGINT, isso causarÃ¡ truncamento silencioso.
- `TGeradorIdFirebird` usa `GEN_ID(GEN_NOMETABELA_ID, 1)` â€” isso assume convenÃ§Ã£o de nomenclatura que pode nÃ£o existir.

---

### 2.8 MF.QueryBuilder.pas
**Status:** âœ… Funcional, coraÃ§Ã£o da geraÃ§Ã£o SQL

**Pontos fortes:**
- `TAjudanteSQL` Ã© uma fachada limpa sobre `TCacheMetadados`.
- `TGeradorConsulta` gera SQL parametrizado â€” sem concatenaÃ§Ã£o de valores.
- `VincularParametrosEntidade` lida com `TNullable<T>` corretamente.

**Fragilidades:**
- `VincularParametrosEntidade` tem **dois blocos case aninhados** (um para TNullable, outro para tipos normais) â€” complexidade ciclomÃ¡tica alta (~25).
- `VincularParametroId<T>` sÃ³ suporta `Integer` â€” deveria suportar `TValue` para GUIDs e strings.
- `GerarInsert<T>` recebe `IGeradorId` apenas para verificar `SuportaRetorno` â€” um booleano seria suficiente, ou usar `TipoChaveSuportado`.

---

### 2.9 MF.SelectBuilder.pas
**Status:** âœ… Bem projetado, API fluente

**Pontos fortes:**
- API fluente completa: `Onde`, `AgruparPor`, `Tendo`, `OrdenarPor`, `Pular`, `Pegar`.
- Suporte a `ParaAtualizacao` (FOR UPDATE), `IncluirExcluidos`, `Include`.
- Hooks para filtros globais (`HookFiltroGlobal`).
- Cache de queries integrado via `TConfiguracaoORM.Cache`.
- `GerarLimitOffset` com sintaxe especÃ­fica por banco (ROWS, OFFSET/FETCH, LIMIT/OFFSET).

**Fragilidades:**
- `GerarSQL` chama `FParametros.Clear` no inÃ­cio â€” **quebra a imutabilidade.** Se dois comandos forem preparados a partir da mesma instÃ¢ncia em threads diferentes, haverÃ¡ condiÃ§Ã£o de corrida nos parÃ¢metros.
- `ParaLista` e `ParaUm` tÃªm **~40 linhas de cÃ³digo de cache duplicadas entre si.** Deveriam delegar para um mÃ©todo privado `ExecutarComCache`.
- O construtor cria 7 `TList` internas â€” muita alocaÃ§Ã£o heap para queries simples de uma linha. Um padrÃ£o lazy-initialization reduziria o footprint.

---

### 2.10 MF.Criteria.pas
**Status:** âœ… Bem implementado

**Pontos fortes:**
- API funcional com critÃ©rios combinÃ¡veis via AND/OR/NOT.
- `RenomearParametrosSQL` com ordenaÃ§Ã£o por tamanho de nome (evita substituiÃ§Ã£o parcial de parÃ¢metros com prefixo comum) â€” **excelente atenÃ§Ã£o a detalhe.**
- Sem SQL Injection â€” todos os valores sÃ£o parametrizados.

**Fragilidades:**
- `RenomearParametrosSQL` usa `StringReplace` em loop â€” para queries complexas com muitos subcritÃ©rios, isso Ã© **O(nÂ²) em processamento de string.**
- `TCriterioSimples` tem **4 construtores diferentes** â€” isso indica que a classe estÃ¡ fazendo coisas demais. Deveria ser especializada.
- `TConstrutorCriterio` Ã© um **record**, mas com mÃ©todos que retornam `ICriterio` (interface COM-like, com reference counting). Isso Ã© incomum â€” records sÃ£o tipos valor e nÃ£o deveriam gerenciar lifetimes de interface implicitamente.

---

### 2.11 MF.ChangeTracker.pas
**Status:** âœ… Bem otimizado

**Pontos fortes:**
- `ChaveParaEntidade` usa mapa de endereÃ§o de ponteiro + nÃºmero de geraÃ§Ã£o â€” O(1) e nÃ£o quebra se a referÃªncia mudar.
- `CapturarInstantaneo` prÃ©-aloca `SetLength(LEntradas, Length(LProps))` â€” zero realocaÃ§Ã£o.
- `TemMudancas` com early-exit â€” zero alocaÃ§Ã£o quando nÃ£o hÃ¡ mudanÃ§as.
- `ValoresIguais` usa `SameValue` para floats â€” correto para evitar falsos positivos por precisÃ£o.

**Fragilidades:**
- `FInstantaneos: TDictionary<string, TArray<TRegistroMudanca>>` â€” a chave Ã© string (`ClassName + '#' + Numero`). Teria desempenho melhor como `TDictionary<Pointer, ...>` jÃ¡ que `FMapaEndereco` jÃ¡ existe.
- `ObterMudancas` cria `TList<TRegistroMudanca>` mesmo que nÃ£o haja mudanÃ§as â€” poderia ter early-return.
- O rastreador nÃ£o detecta mudanÃ§as em **propriedades calculadas** ou **campos privados** â€” apenas em propriedades pÃºblicas com RTTI.

---

### 2.12 MF.RepositoryBase.pas
**Status:** âœ… SÃ³lido

**Pontos fortes:**
- `IRepositorioBase<T>` e `IRepositorioBulk<T>` segregados (Sprint 3).
- Cache de queries integrado no `BuscarPorId`.
- ValidaÃ§Ã£o automÃ¡tica antes de insert/update.
- Controle de concorrÃªncia otimista com `VersaoAttribute`.

**Fragilidades:**
- `Salvar` usa `ObterId(AEntidade) = 0` para decidir insert vs update â€” **falha para GUIDs e strings.** Deveria usar o IdentityMap para verificar se a entidade jÃ¡ foi persistida.
- `DefinirId` e `DefinirVersao` iteram sobre `Propriedades` em vez de usar `IndicePropriedades` â€” O(n) desnecessÃ¡rio.
- `BuscarPorId` com Includes faz `BuscarPorId` + `CarregarPropriedadeEmMassa` â€” isso sÃ£o **2 round-trips** ao banco. Deveria gerar JOIN na query.
- `BuscarPorId(const AIdentificador: Integer)` â€” o tipo do ID Ã© `Integer` fixo, mas agora com `TValue` no IdentityMap deveria aceitar tipos variados.

---

### 2.13 MF.UnitOfWork.pas
**Status:** âœ… Funcional, mas tem dÃ©bito tÃ©cnico

**Pontos fortes:**
- Rastreamento de estado: `eeNovo`, `eeSujo`, `eeExcluido`, `eeLimpo`.
- Cascade automÃ¡tico em relacionamentos (`trPertenceA`, `trTemMuitos`, `trTemUm`).
- OrdenaÃ§Ã£o topolÃ³gica de inserts para respeitar FKs.

**Fragilidades:**
- **`ObterIdEntidade` (funÃ§Ã£o forward) Ã© definida como funÃ§Ã£o local, nÃ£o como mÃ©todo da classe.** Isso viola encapsulamento â€” ela Ã© chamada de vÃ¡rios lugares mas nÃ£o tem visibilidade controlada.
- `RegistrarExcluido` verifica `if LProp.GetValue(Pointer(AEntidade)).AsInteger > 0` â€” **hardcoded para Integer.** Deveria usar `TValue` e verificar se Ã© zero/default para o tipo.
- `ExecutarExclusao` faz **um DELETE por entidade em loop.** Deveria agrupar em batch.
- `Confirmar` chama `ExecutarExclusao` â†’ `ExecutarInsercao` â†’ `ExecutarAtualizacao` sequencialmente. Se houver 100 entidades, sÃ£o **300+ comandos individuais** em vez de operaÃ§Ãµes em lote.
- O UnitOfWork nÃ£o integra `TContextoORM` (criado no Sprint 3). Ele ainda usa `RegistrarMapaThread`/`LimparMapaThread` diretamente.

---

### 2.14 MF.Context.pas (Novo â€” Sprint 3)
**Status:** âœ… Bem implementado, mas nÃ£o integrado

**Pontos fortes:**
- `class threadvar GContextoORMAtual` â€” isolamento por thread sem overhead de lock.
- Agrega `IConexao`, `TMapaIdentidade`, `TRastreadorMudancas`.
- API limpa: `Atual`, `DefinirAtual`, `LimparAtual`.

**Fragilidades:**
- **NÃ£o estÃ¡ integrado com `TUnidadeTrabalho`.** O UoW ainda usa `MF.ThreadContext.RegistrarMapaThread` em vez de criar um `TContextoORM`.
- **NÃ£o estÃ¡ integrado com `TMapeador`.** O mapper ainda usa `MapaIdentidadeThread` (do `MF.ThreadContext`) em vez de `TContextoORM.Atual.MapaIdentidade`.
- A classe foi criada mas nÃ£o foi adotada pelo resto do framework â€” Ã© cÃ³digo morto atÃ© que a migraÃ§Ã£o seja feita.

---

### 2.15 MF.Extensions

#### 2.15.1 Bulk.pas
**Status:** âœ… Funcional, mas sub-Ã³timo

- `InserirEmLote` com `SuportaRetorno` faz **um INSERT multi-row com RETURNING** â€” boa otimizaÃ§Ã£o.
- Sem `SuportaRetorno`, faz **um INSERT por entidade em transaÃ§Ã£o** â€” round-trips O(n).
- **NÃ£o usa ArrayDML do FireDAC** (previsto para Sprint 4).

#### 2.15.2 Profiler.pas
**Status:** âœ… Decorator pattern bem aplicado

- `TConexaoLogada` e `TComandoLogado` sÃ£o decorators limpos.
- Logging com `TStopwatch` â€” baixo overhead.
- Savepoints delegados corretamente (corrigido no Sprint 3).

#### 2.15.3 Cache.pas (nÃ£o lido, mas referenciado)
- Integrado com `SelectBuilder` e `RepositoryBase`.
- Suporta TTL e regiÃµes via `CacheAttribute`.

---

### 2.16 Providers

#### 2.16.1 FireDAC
**Status:** âœ… Completo
- `TConexaoFireDAC`, `TComandoFireDAC`, `TResultadosFireDAC`, `TParametroFireDAC`.
- Mapeamento de exceÃ§Ãµes: `ekUKViolated` â†’ `EErroViolacaoChaveUnica`, `ekFKViolated` â†’ `EErroChaveEstrangeira`.
- Savepoints via SQL direto.
- FetchOptions configurados (`fmOnDemand`, `RowsetSize := 200`).

#### 2.16.2 ADO
**Status:** âœ… Funcional
- Suporte a MSSQL, Firebird, PostgreSQL, MySQL, MariaDB via connection string.
- Mesmo padrÃ£o de mapeamento de exceÃ§Ãµes (mas sem as especializaÃ§Ãµes do FireDAC).
- Savepoints via SQL direto.

---

## 3. Fase 2 â€” AnÃ¡lise Competitiva (Ecossistema Delphi)

### Comparativo com TMS Aurelius
| Aspecto | MinusFramework | TMS Aurelius |
|---|---|---|
| Mapeamento | Attributes (RTTI) | Attributes (RTTI) |
| Criteria API | Fluente baseada em string | Fluente + LINQ-like tipado |
| HeranÃ§a | TPH (Single Table) | TPH, TPT (Table Per Type), TPC |
| Migrations | âœ… MinusMigrator separado | Integrado |
| Cache | 2Âº nÃ­vel (TTL, regiÃµes) | 2Âº nÃ­vel (TTL, regiÃµes) |
| Bulk Operations | Insert/Update/Delete em lote | Array DML via FireDAC |
| Async | âŒ NÃ£o implementado | âŒ NÃ£o implementado |
| PreÃ§o | Open Source | Comercial (caro) |

**Vantagem MinusFramework:** Open source, arquitetura mais limpa, IdentityMap 2-nÃ­veis, TContextoORM.
**Desvantagem vs Aurelius:** Sem TPT/TPC, Criteria sem type-safety, sem Array DML.

### Comparativo com EntityDAC (Devart)
| Aspecto | MinusFramework | EntityDAC |
|---|---|---|
| Performance | Boa (RTTI cache) | Excelente (code-gen) |
| Multi-banco | FireDAC + ADO (7 bancos) | Via UniDAC (mais drivers nativos) |
| LINQ | âŒ | âœ… LINQ-like |
| Schema First | âŒ | âœ… (Entity Developer) |
| Lazy Loading | Sim (MF.Lazy) | Sim |

**Vantagem MinusFramework:** Gratuito, sem dependÃªncia de driver pago.
**Desvantagem vs EntityDAC:** Sem code-gen (tudo RTTI em runtime).

### Comparativo com mORMot
| Aspecto | MinusFramework | mORMot |
|---|---|---|
| ORM | Sim | Sim |
| REST/SOA | âŒ NÃ£o incluÃ­do | âœ… Nativo |
| Performance bruta | MÃ©dia | AltÃ­ssima (JSON/DB direto) |
| Paradigma | OOP clÃ¡ssico | Interface-based + SOA |
| Complexidade | MÃ©dia | Muito alta |

**MinusFramework** Ã© muito mais simples e acessÃ­vel que mORMot. mORMot Ã© um ecossistema completo (ORM + REST + SOA + Message Bus) â€” incomparÃ¡vel em escopo, mas excessivamente complexo para 80% dos projetos.

---

## 4. Fase 3 â€” InovaÃ§Ã£o e InspiraÃ§Ã£o Cross-Language

### O que podemos aprender com EF Core (C#)
1. **LINQ / Expression Trees**: A API `Onde(Criterio("Preco").MaiorQue(10))` Ã© funcional, mas verbosa. O EF Core permite:
   ```csharp
   .Where(p => p.Preco > 10)
   ```
   Delphi nÃ£o tem expression trees, mas podemos usar **lambdas RTTI** com classes sentinel:
   ```pascal
   .Onde(TExpr<TProduto>.Campo<Currency>(
     function(p: TProduto): Currency begin Result := p.PrecoVenda end
   ).MaiorQue(10))
   ```
   Isso usa RTTI no mÃ©todo chamado para extrair o nome da propriedade em tempo de compilaÃ§Ã£o. **ViÃ¡vel e previsto no Sprint 4 (S4-03).**

2. **Compiled Queries**: O EF Core compila a expressÃ£o LINQ em SQL uma vez e reutiliza. No Delphi, podemos fazer:
   ```pascal
   var FQuery := TCompiledQuery<TProduto>.Compilar(Conexao,
     function(Q: TConstrutorSelecao<TProduto>; ID: Integer) begin
       Result := Q.Onde(TExpr<TProduto>.Campo<Integer>(...).Igual(ID));
     end
   );
   ```
   A primeira chamada gera SQL, as subsequentes apenas vinculam parÃ¢metros. **Previsto no Sprint 5 (S5-02).**

3. **IAsyncEnumerable<T>**: EF Core 3+ suporta streaming assÃ­ncrono:
   ```csharp
   await foreach (var item in context.Products.AsAsyncEnumerable())
   ```
   Delphi pode implementar com `TTask` + `TQueue<T>` + eventos:
   ```pascal
   for var LItem in Repositorio.ParaCadaAsync do
     Processar(LItem); // nÃ£o bloqueia a UI thread
   ```
   **Previsto no Sprint 5 (S5-03).**

### O que podemos aprender com Hibernate (Java)
1. **Proxy automÃ¡tico para Change Tracking**: Hibernate usa CGLIB/Javassist para criar proxies em runtime. Delphi nÃ£o tem runtime code-gen, mas podemos usar **design-time code generation**:
   - Uma ferramenta que gera classes descendentes com setters que notificam o UnitOfWork.
   - Elimina a necessidade de `RegistrarSujo` manual.
   **Previsto no Sprint 5 (S5-01).**

2. **Second-Level Cache com Redis/Memcached**: Hibernate suporta caches distribuÃ­dos. Nossa interface `ICacheProvedor` permite implementar um provider Redis sem alterar o ORM. **ViÃ¡vel como extension.**

### O que podemos aprender com Dapper (C#)
1. **Performance mÃ¡xima via execuÃ§Ã£o direta**: Dapper Ã© um micro-ORM que mapeia queries para objetos com **zero overhead de tracking**. Nosso framework poderia oferecer um modo "leve" (`TMapeador.MapearDoBancoLeve<T>`) que pula Identity Map, Change Tracker e Cache quando nÃ£o sÃ£o necessÃ¡rios.

2. **Multi-Mapping**: Dapper mapeia uma linha para mÃºltiplos objetos em uma Ãºnica query (Ãºtil para JOINs):
   ```csharp
   var sql = "SELECT * FROM Pedido p JOIN Item i ON ...";
   var pedidos = conn.Query<Pedido, Item, Pedido>(sql, (p, i) => { p.Itens.Add(i); return p; });
   ```
   **ViÃ¡vel no Delphi** usando `TMapeador.MapearMultiplos<T1, T2>` com lambda de composiÃ§Ã£o.

### O que podemos aprender com Prisma (TypeScript)
1. **Schema-First com geraÃ§Ã£o de cÃ³digo**: O Prisma define o banco em um arquivo `.prisma` e gera o cliente ORM tipado. Nosso `MinusMigrator` poderia evoluir para ler o schema do banco e gerar as classes Delphi com todos os atributos automaticamente. **Isso eliminaria a escrita manual de atributos e reduziria erros de mapeamento.**

2. **Type-Safe Query Builder**: Prisma gera tipos TypeScript que garantem que `where` e `include` sÃ³ aceitem campos vÃ¡lidos. Com code-gen, Delphi pode alcanÃ§ar o mesmo.

---

## 5. Resumo de Fragilidades e Oportunidades

### ðŸ”´ Fragilidades CrÃ­ticas (corrigir no prÃ³ximo Sprint)
| ID | DescriÃ§Ã£o | Arquivo | Impacto |
|---|---|---|---|
| F-01 | `ObterIdEntidade` sÃ³ funciona com Integer, quebra com GUID/String | UnitOfWork.pas | Alto |
| F-02 | `Salvar` decide insert/update por `Id = 0`, falha com GUID | RepositoryBase.pas | Alto |
| F-03 | `TContextoORM` criado mas nÃ£o integrado com UoW e Mapper | Context.pas | MÃ©dio |
| F-04 | `VincularParametroId<T>` sÃ³ suporta Integer | QueryBuilder.pas | MÃ©dio |

### ðŸŸ  Oportunidades de Performance
| ID | DescriÃ§Ã£o | Ganho Estimado |
|---|---|---|
| O-01 | Unificar binding de parÃ¢metros (TypeMapper) â€” eliminar ~600 linhas duplicadas | ManutenÃ§Ã£o |
| O-02 | Array DML no Bulk (previsto S4-01) | 10-50x em inserts |
| O-03 | UnitOfWork em batch (DELETE/INSERT/UPDATE agrupados) | 5-10x em commits |
| O-04 | IdentityMap `ObterTodos` sem alocaÃ§Ã£o de lista temporÃ¡ria | 2-3x |

### ðŸŸ¢ InovaÃ§Ãµes EstratÃ©gicas
| ID | DescriÃ§Ã£o | InspiraÃ§Ã£o |
|---|---|---|
| I-01 | Criteria type-safe com lambdas RTTI (S4-03) | EF Core LINQ |
| I-02 | Compiled Queries reutilizÃ¡veis (S5-02) | EF Core CompileQuery |
| I-03 | Async streaming com IAsyncEnumerable (S5-03) | EF Core |
| I-04 | Proxy auto-tracking via code-gen (S5-01) | Hibernate CGLIB |
| I-05 | Multi-Mapping para JOINs | Dapper |
| I-06 | Schema-First com geraÃ§Ã£o de cÃ³digo | Prisma |