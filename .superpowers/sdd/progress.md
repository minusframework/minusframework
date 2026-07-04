Task 1: complete (commits bd8edd7..0bd0235, review clean after fix)
Task 2: complete (commit a6914d0, build passes, brand CSS applied)
---
Phase 1A: Security (.gitignore + key regeneration) — complete
Phase 1B: Compilation blockers investigation — complete (circular dep fixed in Task 1, search paths OK, 2 {$R *.res} added)
Phase 1C: Docs fixes (duplicates, [Campo]→[Coluna]) — complete
Phase 1D: Config fixes (Docusaurus warning, .gitignore) — complete
Task 1: Circular dependency fix — complete (callback pattern)
Task 2: .dproj search paths — complete (no changes needed, paths already correct)
Task 3: {$R *.res} — complete (added to MinusTelemetry_Runtime.dpk and MinusMessaging_Design.dpk)
Task 4: release.ps1 — complete (created)
Task 5: .gitignore standardization — complete (all 9 submodules)
Task 6: CI/CD pipeline — complete (release-prep.yml created)
Task 7: Docs review — complete (clean, one typo fixed)
Task 8: Installer validation — complete (well-structured, OK)
Task 9: Security audit — complete (PASS, no secrets found)
Task 10: CLI readiness — complete (10 discrepancies found, all fixed: [Campo]→[Coluna] in source, docs aligned, non-existent flags removed)
---
## Site Revitalization (2026-07-04)
Task 1: 404.html customizado — complete
Task 2: CNAME file — complete
Task 3: CI otimizada (cache, deploy preview, healthcheck) — complete
Task 4: Badge de status no README — complete
Task 5: Expandir docs AI/Telemetry/Messaging — complete
Task 6: Sidebar categorizada — complete
Task 7: Badges Free/Pro/Enterprise em 24 docs — complete
Task 8: Breadcrumbs automáticos — complete
Task 9: i18n pt-BR + en — complete
Task 10: Refinamento CSS (animações, tipografia, dark mode) — complete
Task 11: Redesign Homepage (seção Por que MinusFrameWork?) — complete
Task 12: Redesign Pricing (toggle mensal/anual) — complete
Task 13: SEO/Performance (meta tags, sitemap, robots) — complete
Task 14: Lighthouse audit — cancelled (opt-in)
Task 15: Fix SVG logo (remove redundant text, use pure icon) — complete
Task 16: Prevent navbar title truncation (flex-shrink: 0) — complete
Task 17: Adjust navbar vertical padding (0.75rem top/bottom, 0.5rem item padding) — complete
Build: PASS (pt-BR + en, zero warnings)
