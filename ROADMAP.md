# Roadmap

## 🟢 Fase 1 — Community (gratuito) [CONCLUIDO] ✅
- [x] ORM com 7 bancos (Firebird, PostgreSQL, SQLite, MySQL, MariaDB, MSSQL, Oracle)
- [x] Migrator CLI
- [x] Mensageria (Horse + JWT)
- [x] Telemetria
- [x] Feature Flags
- [x] 9 repositórios extraídos com CI/CD próprio (incluindo MinusAI)
- [x] Meta-repo público como landing page + setup-dev.ps1
- [x] Licenciamento Community integrado (trial + offline validation)

## 🔵 Fase 2 — Amadurecimento [EM ANDAMENTO] 🔄
- [x] Documentação completa (wiki + exemplos)
- [x] Documentação completa dos módulos (instalação, API, exemplos)
- [x] CLI de scaffolding (`make:entity`, `new api`)
- [ ] Testes automatizados no CI (self-hosted runner com Delphi)
- [ ] Dashboard de telemetria
- [x] Publicação da primeira Release (v0.1.0)
- [ ] Correção dos bloqueios de compilação (MF.FeatureFlags.Licensing.pas, etc.)
- [ ] **MinusAI** — Servidor MCP e agentes inteligentes
  - [x] MCP Server base (JSON-RPC 2.0 sobre stdio)
  - [x] Ferramenta `explicar_codigo` (analisa .pas)
  - [x] Ferramenta `gerar_entidade` (gera entidade ORM)
  - [x] Ferramenta `criar_migracao` (gera migração)
  - [x] Ferramenta `executar_consulta` (SQL simulado)
  - [ ] Conexão real FireDAC
  - [ ] Agente de scaffolding
  - [ ] Agente de documentação automática

## 🟡 Fase 3 — Licenciamento pago
- [ ] **Portal de cadastro e planos** — página web para escolha de licença
- [ ] **Integração com gateway de pagamento** (Stripe / Asaas / Mercado Pago)
- [ ] **Geração automática de chave** via License Server
- [ ] **Server de validação online** (`api.minusframework.com.br/v1/licenca`)
- [ ] Distribuição de BPLs compiladas (Professional + Enterprise)
- [ ] Self-hosted runner GitHub Actions com Delphi 23.0

## 🟣 Fase 4 — Enterprise
- [ ] Provider Oracle, DB2
- [ ] IDE Expert (Delphi IDE plugin)
- [ ] Suporte SLA
- [ ] Chat de suporte direto
- [ ] Web Dashboard

---

> 💡 A Community Edition é **MIT** e pode ser usada livremente.
> Planos pagos desbloqueiam recursos avançados e suporte prioritário.
> [Saiba mais](https://minusframework.com.br) (em breve)
