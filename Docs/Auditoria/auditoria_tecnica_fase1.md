# Auditoria Técnica — MinusFramework v1.0
**Data:** 11/Junho/2026  
**Escopo:** Varredura completa do código fonte (Core, Bibliotecas, Extensions, Providers)  
**Versão auditada:** Commit `9937d3c` (Sprint 3 concluído)

---

## Índice
1. [Sumário Executivo](#1-sumário-executivo)
2. [Fase 1 — Varredura e Análise Estrutural](#2-fase-1--varredura-e-análise-estrutural)
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
3. [Fase 2 — Análise Competitiva](#3-fase-2--análise-competitiva-ecossistema-delphi)
4. [Fase 3 — Inovação Cross-Language](#4-fase-3--inovação-e-inspiração-cross-language)
5. [Resumo de Fragilidades e Oportunidades](#5-resumo-de-fragilidades-e-oportunidades)

---

## 1. Sumário Executivo

O MinusFramework é um ORM Delphi maduro, com arquitetura em camadas bem definida (Core → Extensions → Providers), seguindo padrões consagrados como Repository, Unit of Work, Identity Map, Change Tracking e Query Builder fluente. O código demonstra conhecimento profundo de RTTI, Generics e interfaces COM-like.

**Pontuação geral: 7.2/10**

| Dimensão | Nota | Observação |
|---|---|---|
| Arquitetura | 8/10 | Separação clara de responsabilidades |
| Performance | 7/10 | Bom uso de cache, mas há gargalos de alocação |
| Segurança | 8/10 | SQL Injection mitigado, sem concatenação de valores |
| Thread-Safety | 7/10 | MREW e threadvar no Sprint 3, mas há pontos cegos |
| Cobertura de Features | 7/10 | CRUD completo, mas sem migrations, sem schema first |
| Qualidade do Código | 7/10 | Bom estilo, mas alguma duplicação e verbosidade |
| Inovação | 7/10 | IdentityMap 2-níveis e TContextoORM são diferenciais |

---

## 2. Fase 1 — Varredura e Análise Estrutural

### 2.1 MF.Types.pas
**Status:** ✅ Sólido
- `TEstrategiaId` adicionado corretamente no Sprint 3.
- `TParametrosConexao` é um record com parser de connection string — boa escolha para evitar alocação heap.
- `TResultadoExecucao` é subutilizado — o código usa `Integer` diretamente em vez deste record.

**Oportunidade:** Adicionar `TTipoBancoDados` como membro de `TResultadoExecucao` para diagnóstico em produção.

---

### 2.2 MF.Connection.pas
**Status:** ✅ Sólido, mas verboso

**Pontos fortes:**
- Interfaces bem definidas: `ICampo`, `IResultados`, `IParametro`, `IComando`, `IConexao`.
- Propriedades com alias português/inglês (ex: `AsInteger` e `ComoInteiro`).
- Savepoints adicionados corretamente no Sprint 3.

**Fragilidades:**
- **Duplicação massiva de conversão de tipos entre `IComando`, `IParametro`, `ICampo`.** Os mesmos padrões `case LProp.PropertyType.Handle.Kind of tkInteger...` aparecem em 7+ arquivos diferentes (QueryBuilder, SelectBuilder, Bulk, Profiler, etc.). Isso é um anti-pattern de manutenção — se um novo tipo for adicionado, precisa alterar em todos.
- `ICampo` com 34 métodos (entre propriedades e funções) — é uma interface sobrecarregada. O padrão ISP (Interface Segregation Principle) sugere dividir em leitura/escrita especializadas.
- `IComando` não tem suporte a batch/array DML (previsto no Sprint 4).

**Recomendação arquitetural:** Criar `TConversorParametro` centralizado com visitantes tipados para eliminar a duplicação de `case..of` em todo o código. Isso reduziria ~400 linhas de código duplicado e centralizaria a lógica de binding.

---

### 2.3 MF.Attributes.pas
**Status:** ✅ Funcional, mas com limitações

**Pontos fortes:**
- Atributos cobrem os casos de uso principais: `Tabela`, `Coluna`, `ChavePrimaria`, `Versao`, `SoftDelete`, `Discriminador`, `ChaveUnica`.
- Suporte a herança TPH via `DiscriminadorAttribute`.

**Fragilidades:**
- `ChavePrimariaAttribute` foi evoluído no Sprint 3 para aceitar `TEstrategiaId`, mas **faltam atributos para mapeamento explícito de sequence name, foreign key on-delete behavior, e índices compostos.**
- `CacheAttribute` com TTL fixo — não suporta políticas de invalidação dinâmica.
- Sem suporte a `[DefaultValue]`, `[ComputedColumn]` ou `[MaxLength]` para geração de schema.

---

### 2.4 MF.MetadataCache.pas
**Status:** ✅ Bem implementado, ponto central da arquitetura

**Pontos fortes:**
- Double-checked locking com MREW (corrigido no Sprint 1) — thread-safe e reentrante.
- SQL pré-compilado em `ColunasSelect`, `ColunasInsert`, `ParametrosInsert`, `ClausulasUpdate` — zero alocação de string repetida.
- `IndicePropriedades: TDictionary<string, TRttiProperty>` com O(1) — correto.
- `PropriedadeChave`, `TipoPK`, `EstrategiaPK` populados no Sprint 3.
- `RttiContext` global (Singleton via class var) — evita criação/destruição repetida de `TRttiContext`.

**Fragilidades:**
- O construtor `TMetaEntidade.Create` é **muito longo** (~170 linhas). Deveria ser quebrado em métodos privados: `LerAtributosTabela`, `LerPropriedades`, `LerHeranca`, `GerarSQL`.
- A verificação de herança (`ClassParent` loop) só sobe um nível — **não suporta hierarquias de 3+ níveis com discriminadores aninhados.**
- `DiscriminadorMapa` é populado como `TArray<TPair<string,string>>` mas depois reconstruído em `ObterAtributo<DiscriminadorAttribute>` cada vez que o mapper precisa resolver — isso é O(n²) disfarçado.

**Risco:** Se uma entidade tiver 30+ propriedades, a geração de SQL (4 StringBuilder) ocorre toda vez que a classe é mapeada pela primeira vez — mas isso só acontece uma vez por classe (cache). OK.

---

### 2.5 MF.Mapper.pas
**Status:** ✅ Funcional, mas com problemas de duplicação

**Pontos fortes:**
- `ConstruirMapaCampos` pré-constroi dicionário O(1) uma vez por query — excelente.
- Identity Map integrado corretamente via `MapaIdentidadeThread`.
- Suporte a `TNullable<T>`, `TipoConverterAttribute`, e herança TPH.

**Fragilidades:**
- **`MapearPropriedade` é o método mais duplicado do framework.** A lógica de `case LProp.PropertyType.Handle.Kind of tkInteger...` aparece quase idêntica em:
  - `MapearPropriedade` (Mapper.pas)
  - `MapearDTO` (Mapper.pas)
  - `VincularParametrosEntidade` (QueryBuilder.pas)
  - `VincularParametro` (QueryBuilder.pas × 2)
  - `InserirEmLote` (Bulk.pas)
  - `VincularParametros` (SelectBuilder.pas)
  
  Isso representa ~600+ linhas de código duplicado. Um **TypeMapper centralizado** eliminaria 80% dessa duplicação.

- `MapearDoBanco<T>` e `MapearDoBancoPorClasse` também têm lógica de Identity Map duplicada entre si.

---

### 2.6 MF.IdentityMap.pas
**Status:** ✅ Excelente evolução no Sprint 3

**Pontos fortes:**
- Refatorado para dois níveis: `TObjectDictionary<TClass, TDictionary<TValue, TObject>>`.
- Hash de `TClass` como ponteiro — O(1) puro sem string.
- Chave agora é `TValue` — suporta qualquer tipo de PK.

**Fragilidades:**
- `ObterTodos` ainda itera sobre todos os valores do dicionário interno e cria uma `TList<TObject>` temporária — **aloca heap a cada chamada.** Para APIs que chamam `ObterTodos` frequentemente, um cache em array seria mais eficiente.
- A comparação de `TValue` usa `A.ToString = B.ToString` — isso é correto para a maioria dos tipos, mas **para TGUID é ineficiente** (converte GUID → string → compara string em vez de comparar os 16 bytes diretamente).

---

### 2.7 MF.IdGenerator.pas
**Status:** ✅ Sólido

**Pontos fortes:**
- `GerarId` retorna `TValue` (Sprint 3) — suporta Integer, Int64, GUID.
- `TGeradorIdGUID` implementado corretamente com `CreateGUID`.
- Factory method `CriarGeradorPorEstrategia` permite selecionar estratégia.

**Fragilidades:**
- Os geradores específicos de banco (Firebird, PostgreSQL, etc.) **ainda retornam `TValue.From<Integer>()` mesmo quando o banco suporta Int64.** Para tabelas com BIGINT, isso causará truncamento silencioso.
- `TGeradorIdFirebird` usa `GEN_ID(GEN_NOMETABELA_ID, 1)` — isso assume convenção de nomenclatura que pode não existir.

---

### 2.8 MF.QueryBuilder.pas
**Status:** ✅ Funcional, coração da geração SQL

**Pontos fortes:**
- `TAjudanteSQL` é uma fachada limpa sobre `TCacheMetadados`.
- `TGeradorConsulta` gera SQL parametrizado — sem concatenação de valores.
- `VincularParametrosEntidade` lida com `TNullable<T>` corretamente.

**Fragilidades:**
- `VincularParametrosEntidade` tem **dois blocos case aninhados** (um para TNullable, outro para tipos normais) — complexidade ciclomática alta (~25).
- `VincularParametroId<T>` só suporta `Integer` — deveria suportar `TValue` para GUIDs e strings.
- `GerarInsert<T>` recebe `IGeradorId` apenas para verificar `SuportaRetorno` — um booleano seria suficiente, ou usar `TipoChaveSuportado`.

---

### 2.9 MF.SelectBuilder.pas
**Status:** ✅ Bem projetado, API fluente

**Pontos fortes:**
- API fluente completa: `Onde`, `AgruparPor`, `Tendo`, `OrdenarPor`, `Pular`, `Pegar`.
- Suporte a `ParaAtualizacao` (FOR UPDATE), `IncluirExcluidos`, `Include`.
- Hooks para filtros globais (`HookFiltroGlobal`).
- Cache de queries integrado via `TConfiguracaoORM.Cache`.
- `GerarLimitOffset` com sintaxe específica por banco (ROWS, OFFSET/FETCH, LIMIT/OFFSET).

**Fragilidades:**
- `GerarSQL` chama `FParametros.Clear` no início — **quebra a imutabilidade.** Se dois comandos forem preparados a partir da mesma instância em threads diferentes, haverá condição de corrida nos parâmetros.
- `ParaLista` e `ParaUm` têm **~40 linhas de código de cache duplicadas entre si.** Deveriam delegar para um método privado `ExecutarComCache`.
- O construtor cria 7 `TList` internas — muita alocação heap para queries simples de uma linha. Um padrão lazy-initialization reduziria o footprint.

---

### 2.10 MF.Criteria.pas
**Status:** ✅ Bem implementado

**Pontos fortes:**
- API funcional com critérios combináveis via AND/OR/NOT.
- `RenomearParametrosSQL` com ordenação por tamanho de nome (evita substituição parcial de parâmetros com prefixo comum) — **excelente atenção a detalhe.**
- Sem SQL Injection — todos os valores são parametrizados.

**Fragilidades:**
- `RenomearParametrosSQL` usa `StringReplace` em loop — para queries complexas com muitos subcritérios, isso é **O(n²) em processamento de string.**
- `TCriterioSimples` tem **4 construtores diferentes** — isso indica que a classe está fazendo coisas demais. Deveria ser especializada.
- `TConstrutorCriterio` é um **record**, mas com métodos que retornam `ICriterio` (interface COM-like, com reference counting). Isso é incomum — records são tipos valor e não deveriam gerenciar lifetimes de interface implicitamente.

---

### 2.11 MF.ChangeTracker.pas
**Status:** ✅ Bem otimizado

**Pontos fortes:**
- `ChaveParaEntidade` usa mapa de endereço de ponteiro + número de geração — O(1) e não quebra se a referência mudar.
- `CapturarInstantaneo` pré-aloca `SetLength(LEntradas, Length(LProps))` — zero realocação.
- `TemMudancas` com early-exit — zero alocação quando não há mudanças.
- `ValoresIguais` usa `SameValue` para floats — correto para evitar falsos positivos por precisão.

**Fragilidades:**
- `FInstantaneos: TDictionary<string, TArray<TRegistroMudanca>>` — a chave é string (`ClassName + '#' + Numero`). Teria desempenho melhor como `TDictionary<Pointer, ...>` já que `FMapaEndereco` já existe.
- `ObterMudancas` cria `TList<TRegistroMudanca>` mesmo que não haja mudanças — poderia ter early-return.
- O rastreador não detecta mudanças em **propriedades calculadas** ou **campos privados** — apenas em propriedades públicas com RTTI.

---

### 2.12 MF.RepositoryBase.pas
**Status:** ✅ Sólido

**Pontos fortes:**
- `IRepositorioBase<T>` e `IRepositorioBulk<T>` segregados (Sprint 3).
- Cache de queries integrado no `BuscarPorId`.
- Validação automática antes de insert/update.
- Controle de concorrência otimista com `VersaoAttribute`.

**Fragilidades:**
- `Salvar` usa `ObterId(AEntidade) = 0` para decidir insert vs update — **falha para GUIDs e strings.** Deveria usar o IdentityMap para verificar se a entidade já foi persistida.
- `DefinirId` e `DefinirVersao` iteram sobre `Propriedades` em vez de usar `IndicePropriedades` — O(n) desnecessário.
- `BuscarPorId` com Includes faz `BuscarPorId` + `CarregarPropriedadeEmMassa` — isso são **2 round-trips** ao banco. Deveria gerar JOIN na query.
- `BuscarPorId(const AIdentificador: Integer)` — o tipo do ID é `Integer` fixo, mas agora com `TValue` no IdentityMap deveria aceitar tipos variados.

---

### 2.13 MF.UnitOfWork.pas
**Status:** ✅ Funcional, mas tem débito técnico

**Pontos fortes:**
- Rastreamento de estado: `eeNovo`, `eeSujo`, `eeExcluido`, `eeLimpo`.
- Cascade automático em relacionamentos (`trPertenceA`, `trTemMuitos`, `trTemUm`).
- Ordenação topológica de inserts para respeitar FKs.

**Fragilidades:**
- **`ObterIdEntidade` (função forward) é definida como função local, não como método da classe.** Isso viola encapsulamento — ela é chamada de vários lugares mas não tem visibilidade controlada.
- `RegistrarExcluido` verifica `if LProp.GetValue(Pointer(AEntidade)).AsInteger > 0` — **hardcoded para Integer.** Deveria usar `TValue` e verificar se é zero/default para o tipo.
- `ExecutarExclusao` faz **um DELETE por entidade em loop.** Deveria agrupar em batch.
- `Confirmar` chama `ExecutarExclusao` → `ExecutarInsercao` → `ExecutarAtualizacao` sequencialmente. Se houver 100 entidades, são **300+ comandos individuais** em vez de operações em lote.
- O UnitOfWork não integra `TContextoORM` (criado no Sprint 3). Ele ainda usa `RegistrarMapaThread`/`LimparMapaThread` diretamente.

---

### 2.14 MF.Context.pas (Novo — Sprint 3)
**Status:** ✅ Bem implementado, mas não integrado

**Pontos fortes:**
- `class threadvar GContextoORMAtual` — isolamento por thread sem overhead de lock.
- Agrega `IConexao`, `TMapaIdentidade`, `TRastreadorMudancas`.
- API limpa: `Atual`, `DefinirAtual`, `LimparAtual`.

**Fragilidades:**
- **Não está integrado com `TUnidadeTrabalho`.** O UoW ainda usa `MF.ThreadContext.RegistrarMapaThread` em vez de criar um `TContextoORM`.
- **Não está integrado com `TMapeador`.** O mapper ainda usa `MapaIdentidadeThread` (do `MF.ThreadContext`) em vez de `TContextoORM.Atual.MapaIdentidade`.
- A classe foi criada mas não foi adotada pelo resto do framework — é código morto até que a migração seja feita.

---

### 2.15 MF.Extensions

#### 2.15.1 Bulk.pas
**Status:** ✅ Funcional, mas sub-ótimo

- `InserirEmLote` com `SuportaRetorno` faz **um INSERT multi-row com RETURNING** — boa otimização.
- Sem `SuportaRetorno`, faz **um INSERT por entidade em transação** — round-trips O(n).
- **Não usa ArrayDML do FireDAC** (previsto para Sprint 4).

#### 2.15.2 Profiler.pas
**Status:** ✅ Decorator pattern bem aplicado

- `TConexaoLogada` e `TComandoLogado` são decorators limpos.
- Logging com `TStopwatch` — baixo overhead.
- Savepoints delegados corretamente (corrigido no Sprint 3).

#### 2.15.3 Cache.pas (não lido, mas referenciado)
- Integrado com `SelectBuilder` e `RepositoryBase`.
- Suporta TTL e regiões via `CacheAttribute`.

---

### 2.16 Providers

#### 2.16.1 FireDAC
**Status:** ✅ Completo
- `TConexaoFireDAC`, `TComandoFireDAC`, `TResultadosFireDAC`, `TParametroFireDAC`.
- Mapeamento de exceções: `ekUKViolated` → `EErroViolacaoChaveUnica`, `ekFKViolated` → `EErroChaveEstrangeira`.
- Savepoints via SQL direto.
- FetchOptions configurados (`fmOnDemand`, `RowsetSize := 200`).

#### 2.16.2 ADO
**Status:** ✅ Funcional
- Suporte a MSSQL, Firebird, PostgreSQL, MySQL, MariaDB via connection string.
- Mesmo padrão de mapeamento de exceções (mas sem as especializações do FireDAC).
- Savepoints via SQL direto.

---

## 3. Fase 2 — Análise Competitiva (Ecossistema Delphi)

### Comparativo com TMS Aurelius
| Aspecto | MinusFramework | TMS Aurelius |
|---|---|---|
| Mapeamento | Attributes (RTTI) | Attributes (RTTI) |
| Criteria API | Fluente baseada em string | Fluente + LINQ-like tipado |
| Herança | TPH (Single Table) | TPH, TPT (Table Per Type), TPC |
| Migrations | ✅ MinusMigrator separado | Integrado |
| Cache | 2º nível (TTL, regiões) | 2º nível (TTL, regiões) |
| Bulk Operations | Insert/Update/Delete em lote | Array DML via FireDAC |
| Async | ❌ Não implementado | ❌ Não implementado |
| Preço | Open Source | Comercial (caro) |

**Vantagem MinusFramework:** Open source, arquitetura mais limpa, IdentityMap 2-níveis, TContextoORM.
**Desvantagem vs Aurelius:** Sem TPT/TPC, Criteria sem type-safety, sem Array DML.

### Comparativo com EntityDAC (Devart)
| Aspecto | MinusFramework | EntityDAC |
|---|---|---|
| Performance | Boa (RTTI cache) | Excelente (code-gen) |
| Multi-banco | FireDAC + ADO (7 bancos) | Via UniDAC (mais drivers nativos) |
| LINQ | ❌ | ✅ LINQ-like |
| Schema First | ❌ | ✅ (Entity Developer) |
| Lazy Loading | Sim (MF.Lazy) | Sim |

**Vantagem MinusFramework:** Gratuito, sem dependência de driver pago.
**Desvantagem vs EntityDAC:** Sem code-gen (tudo RTTI em runtime).

### Comparativo com mORMot
| Aspecto | MinusFramework | mORMot |
|---|---|---|
| ORM | Sim | Sim |
| REST/SOA | ❌ Não incluído | ✅ Nativo |
| Performance bruta | Média | Altíssima (JSON/DB direto) |
| Paradigma | OOP clássico | Interface-based + SOA |
| Complexidade | Média | Muito alta |

**MinusFramework** é muito mais simples e acessível que mORMot. mORMot é um ecossistema completo (ORM + REST + SOA + Message Bus) — incomparável em escopo, mas excessivamente complexo para 80% dos projetos.

---

## 4. Fase 3 — Inovação e Inspiração Cross-Language

### O que podemos aprender com EF Core (C#)
1. **LINQ / Expression Trees**: A API `Onde(Criterio("Preco").MaiorQue(10))` é funcional, mas verbosa. O EF Core permite:
   ```csharp
   .Where(p => p.Preco > 10)
   ```
   Delphi não tem expression trees, mas podemos usar **lambdas RTTI** com classes sentinel:
   ```pascal
   .Onde(TExpr<TProduto>.Campo<Currency>(
     function(p: TProduto): Currency begin Result := p.PrecoVenda end
   ).MaiorQue(10))
   ```
   Isso usa RTTI no método chamado para extrair o nome da propriedade em tempo de compilação. **Viável e previsto no Sprint 4 (S4-03).**

2. **Compiled Queries**: O EF Core compila a expressão LINQ em SQL uma vez e reutiliza. No Delphi, podemos fazer:
   ```pascal
   var FQuery := TCompiledQuery<TProduto>.Compilar(Conexao,
     function(Q: TConstrutorSelecao<TProduto>; ID: Integer) begin
       Result := Q.Onde(TExpr<TProduto>.Campo<Integer>(...).Igual(ID));
     end
   );
   ```
   A primeira chamada gera SQL, as subsequentes apenas vinculam parâmetros. **Previsto no Sprint 5 (S5-02).**

3. **IAsyncEnumerable<T>**: EF Core 3+ suporta streaming assíncrono:
   ```csharp
   await foreach (var item in context.Products.AsAsyncEnumerable())
   ```
   Delphi pode implementar com `TTask` + `TQueue<T>` + eventos:
   ```pascal
   for var LItem in Repositorio.ParaCadaAsync do
     Processar(LItem); // não bloqueia a UI thread
   ```
   **Previsto no Sprint 5 (S5-03).**

### O que podemos aprender com Hibernate (Java)
1. **Proxy automático para Change Tracking**: Hibernate usa CGLIB/Javassist para criar proxies em runtime. Delphi não tem runtime code-gen, mas podemos usar **design-time code generation**:
   - Uma ferramenta que gera classes descendentes com setters que notificam o UnitOfWork.
   - Elimina a necessidade de `RegistrarSujo` manual.
   **Previsto no Sprint 5 (S5-01).**

2. **Second-Level Cache com Redis/Memcached**: Hibernate suporta caches distribuídos. Nossa interface `ICacheProvedor` permite implementar um provider Redis sem alterar o ORM. **Viável como extension.**

### O que podemos aprender com Dapper (C#)
1. **Performance máxima via execução direta**: Dapper é um micro-ORM que mapeia queries para objetos com **zero overhead de tracking**. Nosso framework poderia oferecer um modo "leve" (`TMapeador.MapearDoBancoLeve<T>`) que pula Identity Map, Change Tracker e Cache quando não são necessários.

2. **Multi-Mapping**: Dapper mapeia uma linha para múltiplos objetos em uma única query (útil para JOINs):
   ```csharp
   var sql = "SELECT * FROM Pedido p JOIN Item i ON ...";
   var pedidos = conn.Query<Pedido, Item, Pedido>(sql, (p, i) => { p.Itens.Add(i); return p; });
   ```
   **Viável no Delphi** usando `TMapeador.MapearMultiplos<T1, T2>` com lambda de composição.

### O que podemos aprender com Prisma (TypeScript)
1. **Schema-First com geração de código**: O Prisma define o banco em um arquivo `.prisma` e gera o cliente ORM tipado. Nosso `MinusMigrator` poderia evoluir para ler o schema do banco e gerar as classes Delphi com todos os atributos automaticamente. **Isso eliminaria a escrita manual de atributos e reduziria erros de mapeamento.**

2. **Type-Safe Query Builder**: Prisma gera tipos TypeScript que garantem que `where` e `include` só aceitem campos válidos. Com code-gen, Delphi pode alcançar o mesmo.

---

## 5. Resumo de Fragilidades e Oportunidades

### 🔴 Fragilidades Críticas (corrigir no próximo Sprint)
| ID | Descrição | Arquivo | Impacto |
|---|---|---|---|
| F-01 | `ObterIdEntidade` só funciona com Integer, quebra com GUID/String | UnitOfWork.pas | Alto |
| F-02 | `Salvar` decide insert/update por `Id = 0`, falha com GUID | RepositoryBase.pas | Alto |
| F-03 | `TContextoORM` criado mas não integrado com UoW e Mapper | Context.pas | Médio |
| F-04 | `VincularParametroId<T>` só suporta Integer | QueryBuilder.pas | Médio |

### 🟠 Oportunidades de Performance
| ID | Descrição | Ganho Estimado |
|---|---|---|
| O-01 | Unificar binding de parâmetros (TypeMapper) — eliminar ~600 linhas duplicadas | Manutenção |
| O-02 | Array DML no Bulk (previsto S4-01) | 10-50x em inserts |
| O-03 | UnitOfWork em batch (DELETE/INSERT/UPDATE agrupados) | 5-10x em commits |
| O-04 | IdentityMap `ObterTodos` sem alocação de lista temporária | 2-3x |

### 🟢 Inovações Estratégicas
| ID | Descrição | Inspiração |
|---|---|---|
| I-01 | Criteria type-safe com lambdas RTTI (S4-03) | EF Core LINQ |
| I-02 | Compiled Queries reutilizáveis (S5-02) | EF Core CompileQuery |
| I-03 | Async streaming com IAsyncEnumerable (S5-03) | EF Core |
| I-04 | Proxy auto-tracking via code-gen (S5-01) | Hibernate CGLIB |
| I-05 | Multi-Mapping para JOINs | Dapper |
| I-06 | Schema-First com geração de código | Prisma |