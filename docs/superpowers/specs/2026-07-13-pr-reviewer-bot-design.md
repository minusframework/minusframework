# Design: MinusAI Reviewer Bot

## Objetivo
Criar um bot revisor automático de Pull Requests que valide padrões de projeto, sugira melhorias e bloqueie PRs fora de conformidade em todos os 9 repositórios do MinusFrameWork.

## Arquitetura

```
GitHub → Webhook PR/Push → MinusAI_Reviewer.exe (CLI)
                                  │
                    ┌─────────────┼─────────────┐
                    ▼             ▼             ▼
             Validação       Análise        Codebase
             Estrutural     Semântica       Scan
             (local)        (MCP+LLM)      (periódico)
                    │             │             │
                    └─────────────┼─────────────┘
                                  ▼
                         GitHub API (review)
```

### Componentes
1. **MinusAI_Reviewer.dpr** — CLI Delphi que processa eventos de PR/push
2. **Regras estruturais** — embutidas na CLI, bloqueantes (commits, pastas, tamanho, naming, testes)
3. **MCP Client** — integração com MinusAI MCP para análise semântica (LLM)
4. **GitHub API Client** — posta reviews com comentários inline, approve/request changes
5. **Codebase Scanner** — varredura periódica da base completa

## Regras de Validação

### Estruturais (bloqueantes)
| Regra | Descrição |
|-------|-----------|
| Conventional Commits | `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`, `perf:` |
| Estrutura de pastas | `Source/`, `Tests/`, `Packages/`, `Docs/` conforme padrão |
| Tamanho de PR | Máx 500 linhas ou 20 arquivos (configurável) |
| Nomenclatura Delphi | `TClasse`, `IMetodo`, `FPropriedade`, `MetodoCamelCase` |
| Requisição de testes | Se `feat:` ou `fix:`, deve haver arquivos em `Tests/` |

### Semânticas (sugestão via LLM via MCP)
- Violações de SOLID
- Complexidade ciclomática alta
- Falta de tratamento de exceções
- Acoplamento excessivo
- Duplicação de código

### Codebase Scan (varredura periódica)
- Consistência de nomenclatura em toda a base
- Arquivos órfãos ou não compilados
- Conformidade com Object Calisthenics

## Fluxo de Execução

1. **PR aberto ou sincronizado** → GitHub Action dispara `MinusAI_Reviewer.exe`
2. **Validação estrutural** → executa primeiro, se falhar → `REQUEST_CHANGES` e bloqueia merge
3. **Análise semântica** → se estrutural passar, envia diff para MCP/LLM → posta sugestões como comentários
4. **Status final** → approve automático se todas as regras passarem, ou request changes se falhar

## Implementação

O bot será implementado dentro do módulo `minusframework-ai` como parte do MinusAI, reutilizando:
- `MinusMCPServer` — para análise semântica via LLM
- GitHub API via `TNetHTTPClient`
- CLI existente `MinusAI_MCP.exe` como base

## Licenciamento
Enterprise (parte do MinusAI)
