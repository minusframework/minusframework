# MinusFeatureFlags â€” Roadmap

> **Ãšltima atualizaÃ§Ã£o:** Junho/2026

## Fase 0 â€” DiagnÃ³stico e bugs crÃ­ticos (ConcluÃ­da)

- Parsear array `regras` do JSON em `TProviderJSON`
- Serializar `Regras`/`Variantes`/`Tags` para JSON
- Popular `criada_em`/`atualizada_em` no INSERT/UPDATE
- `Variante()` considerar regras de targeting para A/B segmentado
- Corrigir `Result.Regras := nil` no `ParseFlag`

## Fase 1 â€” FundaÃ§Ã£o (ConcluÃ­da)

- Testes unitÃ¡rios DUnitX (motor, cache, providers, mÃ©tricas)
- MÃ©tricas persistentes (tabela `feature_flag_metrics`)

## Fase 2 â€” GovernanÃ§a (Pendente)

- Multi-environment (campo `ambiente` + filtro por provider)
- Audit log (tabela `feature_flag_audit`)
- Web dashboard (SPA Vue/Svelte)
- Prerequisite flags (`DependeDe`) â€” OK
- A/B segmentado por regras de targeting â€” OK
- TProviderREST com write (POST/PUT/DELETE)

## Fase 3 â€” Escala (Pendente)

- SDK remoto para Delphi (`MF.FeatureFlags.SDK`)
- Batch evaluation (`POST /api/flags/evaluate`)
- Streaming SSE (`GET /api/flags/stream`)
- Import/Export (`GET/POST /api/flags/export`)
- RBAC (usuÃ¡rios, papÃ©is, Bearer token)
