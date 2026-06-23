# 📜 Constituição do Projeto — MinusFramework

> **Propósito:** Este documento define as regras, padrões e restrições que TODA contribuição ao MinusFramework deve respeitar — seja feita por humano ou IA.
>
> **Última atualização:** 12 de Junho de 2026
> **Versão:** 1.1

---

## 1. 🏗️ Arquitetura — Regras de Ouro

### 1.1 Estrutura de Diretórios

```
Source/
├── Bibliotecas/           ← CÓDIGO COMPARTILHADO entre 2+ projetos
│   ├── MF.Types.pas
│   ├── MF.Connection.pas
│   ├── MF.Exceptions.pas
│   ├── MF.Config.pas
│   ├── MF.Provider.pas
│   ├── MF.Attributes.pas
│   └── Providers/         ← Implementações de acesso a dados
├── Core/                  ← SOMENTE ORM (não referenciado pelo Migrator)
├── Extensions/            ← Extensões do ORM
└── Migrator/             ← Migrator isolado
```

### 🔴 REGRA CRÍTICA

> **Se uma unit é usada por 2+ projetos (ORM, Migrator, Demo), ela DEVE estar em `Bibliotecas/`.**
>
> **Nenhuma unit em `Core/` pode ser referenciada diretamente pelo Migrator.**

### 1.2 Dependências

| Regra | Descrição |
|-------|-----------|
| **Máximo 9 dependências MF na interface** | Dependências internas vão no `implementation uses` |
| **Zero dependências circulares** | `A → B → C → A` é proibido |
| **Core não depende de Extensions** | Extensions dependem de Core, nunca o contrário |
| **Migrator não depende de Core** | Migrator só depende de Bibliotecas |

### 1.3 Acoplamento Permitido

```
✅ PERMITIDO:
  Bibliotecas → (nada)
  Core → Bibliotecas
  Extensions → Core → Bibliotecas
  Migrator → Bibliotecas

❌ PROIBIDO:
  Bibliotecas → Core
  Core → Extensions
  Core → Migrator
  Migrator → Core
```

### 1.4 Decomposição do Repositório (ISP)

O `TRepositorioBase<T>` foi decomposto seguindo **Interface Segregation Principle**:

| Unit | Responsabilidade | Linhas |
|------|-----------------|--------|
| `MF.RepositoryBase.pas` | `TRepositorioBase<T>` implementando CRUD + bulk + async + hooks | ~500 |
| `MF.Repository.Bulk.pas` | `IRepositorioBulk<T>` — interface segregada para operações em lote | ~30 |
| `MF.Repository.Async.pas` | `IRepositorioAsync<T>` — interface segregada para operações assíncronas | ~40 |

**Design:**
- `IRepositorioBase<T>` — 5 métodos core: BuscarPorId, BuscarTodos, Salvar, Excluir, ParaCada
- `IRepositorioBulk<T>` — 4 métodos bulk (unit própria, sem depender de Core)
- `IRepositorioAsync<T>` — 4 métodos async (unit própria)
- `TRepositorioBase<T>` implementa as 3 interfaces — **retrocompatível**
- Consumidores que só precisam de bulk/async podem depender apenas da interface correspondente

```pascal
// Apenas CRUD
var Repo: IRepositorioBase<TProduto>;
Repo := TRepositorioBase<TProduto>.Create(Conexao);

// Precisa de bulk também? Use IRepositorioBulk<T>
var Bulk: IRepositorioBulk<TProduto>;
Bulk := Repo as IRepositorioBulk<TProduto>;
Bulk.InserirEmLote(Lista);

// Ou use o tipo concreto (tem todos os métodos)
var Repo := TRepositorioBase<TProduto>.Create(Conexao);
Repo.InserirEmLote(Lista);       // bulk
Repo.SalvarAsync(Produto);       // async
```

---

## 2. 📝 Código — Padrões Obrigatórios

### 2.1 Nomenclatura

| Elemento | Idioma | Exemplo |
|----------|--------|---------|
| Units | Inglês | `MF.RepositoryBase.pas` |
| Classes | Português | `TRepositorioBase<T>` |
| Interfaces | Inglês ou Português | `IConexao`, `IRepositorioBase<T>` |
| Métodos | Português | `BuscarPorId`, `Salvar` |
| Propriedades | Português | `NomeTabela`, `ChavePrimaria` |
| Parâmetros | `A` + PascalCase | `AEntidade`, `AIdentificador` |
| Locais | `L` + PascalCase | `LComando`, `LResultado` |
| Constantes | UPPER_SNAKE | `QUERY_LENTA_THRESHOLD_MS` |

### 2.2 Estrutura de Unit

```pascal
unit MF.Example;

interface

uses
  // 1. System units (ordem alfabética)
  System.SysUtils,
  System.Generics.Collections,
  // 2. MF Bibliotecas (ordem alfabética)
  MF.Connection,
  MF.Types,
  // 3. MF Core (se aplicável)
  MF.MetadataCache;

type
  /// <summary>Documentação XML obrigatória em classes públicas.</summary>
  TExemplo = class
  private
    FCampo: Integer;
  public
    constructor Create;
    procedure MetodoPublico;
  end;

implementation

uses
  // Dependências internas aqui (reduz acoplamento da interface)
  MF.Extensions.Cache;

// Implementação...
end.
```

### 2.3 Documentação de Código

| Regra | Descrição |
|-------|-----------|
| **100% classes públicas** | Toda classe pública deve ter `/// <summary>` |
| **100% métodos públicos** | Todo método público deve ter `/// <summary>` |
| **100% interfaces** | Toda interface deve ter documentação |
| **Parâmetros** | Descrever com `/// <param name="...">` quando não óbvios |
| **Retorno** | Descrever com `/// <returns>` quando não óbvio |

### 2.4 Limites de Qualidade

| Métrica | Limite | Ação se exceder |
|---------|--------|-----------------|
| Linhas por unit | 500 | Refatorar em units menores |
| Métodos públicos por classe | 10 | Aplicar Interface Segregation |
| Dependências MF na interface | 9 | Mover para implementation |
| Parâmetros por método | 4 | Usar record de opções ou builder |
| Linhas por método | 40 | Extrair sub-métodos privados |
| Níveis de indentação | 3 | Extrair para métodos |

---

## 3. 🧪 Qualidade — Anti-Patterns PROIBIDOS

### 🔴 Nunca fazer

```pascal
// ❌ Magic numbers
if DuracaoMs > 100 then  // O que é 100?

// ✅ Constantes nomeadas
const QUERY_LENTA_THRESHOLD_MS = 100;
if DuracaoMs > QUERY_LENTA_THRESHOLD_MS then

// ❌ Boolean flag parameter
procedure Buscar(AIncluirExcluidos: Boolean);

// ✅ Métodos separados ou enum
procedure Buscar; 
procedure BuscarIncluindoExcluidos;

// ❌ Exception vazia
except end;

// ✅ Sempre trate ou re-levante
except
  on E: Exception do
  begin
    Log(E.Message);
    raise;
  end;
end;

// ❌ String SQL concatenada (SQL injection)
LComando.SQL := 'SELECT * FROM ' + Tabela + ' WHERE ID = ' + Id.ToString;

// ✅ Parâmetros nomeados
LComando.SQL := 'SELECT * FROM ' + Tabela + ' WHERE ID = :id';
LComando.ParametroPorNome('id').AsInteger := Id;
```

---

## 4. 🔒 Segurança

| Regra | Descrição |
|-------|-----------|
| **Nunca hardcode secrets** | Seeds, chaves, senhas → variáveis de ambiente ou config |
| **SQL parameterizado** | Nunca concatenar input do usuário em SQL |
| **Licenciamento offline-first** | Validação de licença não depende de rede |
| **Licensing seed externo** | `CSeed` em `MF.Licensing.pas` deve ser sobrescrito em produção |

---

## 5. 📦 Commits — Conventional Commits

### Formato

```
<tipo>(<escopo>): <descrição curta>

<corpo opcional>
```

### Tipos e quando usar

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Mudança de código sem alterar comportamento |
| `perf` | Otimização de performance |
| `docs` | Documentação apenas |
| `test` | Testes |
| `chore` | Tarefas de manutenção |
| `style` | Formatação, espaçamento |

### Escopos

```
feat(orm): ...
fix(migrator): ...
refactor(core): ...
docs(roadmap): ...
perf(RTTI): ...
```

### 🔴 REGRA: Commits Atômicos

> Cada commit deve conter **UM único propósito**. Não misture refatoração com feature nova no mesmo commit.

---

## 6. 🤖 Instruções para IAs

> **Toda IA atuando neste projeto DEVE:**

1. **Ler este documento** antes de qualquer modificação
2. **Respeitar a arquitetura** — não criar dependências entre camadas proibidas
3. **Documentar código novo** — 100% de cobertura XML doc em APIs públicas
4. **Commits atômicos** — um propósito por commit
5. **Verificar acoplamento** — `interface uses` ≤ 9 deps MF
6. **Nunca quebrar a API pública** — mudanças breaking requerem nova major version
7. **Build limpo** — zero erros, zero warnings
8. **Testar antes de commitar** — verificar se compila em todos os projetos
9. **Não duplicar código** — verificar se já existe antes de criar
10. **Português primário** — código e comentários em português, aliases em inglês

### Checklist pré-commit da IA

```
[ ] Build: MinusFramework_Runtime.dpk ✅
[ ] Build: MinusORM.dll ✅
[ ] Build: MinusMigrator_CLI.exe ✅
[ ] Build: MinusDemo.exe ✅
[ ] Zero erros, zero warnings
[ ] XML doc em todas classes/métodos públicos novos
[ ] Interface uses ≤ 9 deps MF
[ ] Nenhum magic number
[ ] Parâmetros ≤ 4 por método
[ ] Commit atômico com mensagem semantic
```

---

## 7. 📋 Code Review Checklist

### Para todo PR

```
[ ] Respeita a arquitetura em camadas?
[ ] Nenhuma dependência circular?
[ ] Novas units em diretório correto (Bibliotecas/Core/Extensions/Migrator)?
[ ] XML doc em todas APIs públicas novas?
[ ] Constantes nomeadas (sem magic numbers)?
[ ] SQL parameterizado (sem concatenação)?
[ ] Transações atômicas em operações de escrita?
[ ] Nomenclatura consistente (português / A/L prefix)?
[ ] Sem boolean flags em parâmetros?
[ ] Métodos ≤ 40 linhas?
[ ] Compila em todos os 9 projetos?
```

---

## 8. 🎯 Roadmap de Qualidade

| Meta | Status | Target |
|------|--------|--------|
| Documentação XML | 91% | 100% |
| Acoplamento interface | 9 deps MF | 5 deps MF |
| Cobertura de testes | ~30% | 60% |
| Zero code smells | 2 restantes | 0 |
| God units (500+ linhas) | 4 | 0 (v2.0) |

---

> **"Código é lido 10x mais do que é escrito. Escreva para quem vai ler."**
