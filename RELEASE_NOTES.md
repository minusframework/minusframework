## v0.1.0 — 2026-07-05

### Modulos Free Tier
- **minusframework-core**: Pacotes Runtime/Design compilando, submodules featureflags/telemetry/messaging
- **minusframework-migrator**: 52 testes (50 passam), EntityReader com state-machine, SQLite Table Rebuild
- **minusframework-orm**: 324 testes (323 passam), DLL C-compatible, 21 features demo
- **MinusFrameWork-Meta**: Site Docusaurus, CLI scaffolding, CI/CD pipelines

### Melhorias
- Documentacao e codigo traduzidos para portugues brasileiro
- Licenciamento via feature flags em todos os modulos
- Logos adaptaveis a modo claro/escuro
- Paths de projeto padronizados para estrutura de submodule

---

# Release 428221f..a5efc92

> **Data:** 28/06/2026

## :rocket: Novidades

- prebuilt binaries model, license tiers, remove groupproj ([dfa10fa](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/dfa10fab381a71ec9aff26e7adab8c421f1a65e9))
- full pipeline in deploy-module.yml ([2ec5645](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/2ec5645484deecdfb44b90d15383da282df6f3af))
- deploy-module v2 (+ override step) ([2113754](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/211375476e68ff092aa5651cf7ef961647ab71b3))
- deploy-module v1 (checkout + ci-setup) ([2459761](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/2459761036f05f5e15c0d203e5bd80ca2f35eccb))
- full build pipeline in deploy-module.yml ([fcb955e](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/fcb955eb88ad16ed2865b071804efa03a4a35c73))
- add deploy-module workflow (simple test) ([2a5e398](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/2a5e398d352cb4a898e0a15e613d17453bc29a0e))
- recreate release-module.yml and build-module.ps1 ([61cc729](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/61cc729adc5dd6c14464e22a2252dc692fb1ff99))
- centralized build — release-module.yml + build-module.ps1 ([b8f9df9](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/b8f9df9abca7d1cf47d847ef35f3c9ad13a3f79e))
- add ci-setup.ps1 for private repo CI/CD ([4cf7280](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/4cf7280e14535200ca5902e1f77e970eea986385))

## :bug: Correcoes

- use bds.exe for CE builds, output to Debug ([c83c4f1](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/c83c4f1b26c604db1603c52b5388e48954c1f7d6))
- add blank line between name and on in YAML ([21a61e8](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/21a61e877d3af45269b4dc3a7b86a5af2c88b4b4))
- set BDS env var before msbuild ([4d5bf22](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/4d5bf2249f009c7fff89257d15daea7a15e05420))
- use full MSBuild path in Build step ([5206298](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/5206298ed7d4ded4883edc44ea740b78510540d9))
- use ErrorActionPreference Continue for git commands in override step ([39ba313](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/39ba313e9ed42de011520d981c83ee48d000ba05))
- remove 2>&1 from git cmds, use URL-based auth for origin ([825bfaf](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/825bfaf7087aa2d8f2b6f8498892fd3377ced72b))
- ci-setup uses http.extraheader instead of URL auth ([1deeb54](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/1deeb548e4247ea783dee54449b9d84a2fd11c4b))
- ci-setup clones into meta dir + PAT auth format ([eec0279](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/eec0279e571f65b7e0185abd876eade46ef3a933))
- add 2>&1 to git commands in release-module.yml ([3779f2d](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/3779f2d68d7818bb8eebe89bc0c474ad4b130ee1))
- add missing GetBplDir/GetDcpDir functions in .iss ([bf2dc87](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/bf2dc876c71aa4f53be7335dd15182e802dff7eb))

## :books: Documentacao

- only Free tier available for now ([a5efc92](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/a5efc927042da1b5325e927a81c8a934393fa457))
- hide PIX key behind collapsible section ([e5aba30](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/e5aba302a9c1641bc81fdc740c4a277c0085fc72))
- update PIX key ([925da6e](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/925da6ebfa4df0ce36f24bf1911143e1cd186b27))

## :hammer: Refatoracao

- convert meta-repo to public landing page + installer ([9e78c4d](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/9e78c4dc995cd1ff889b2467f860cfea1766e60a))

## :wrench: Manutencao

- remove broken deploy-module ([6f24029](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/6f240293395d5cefb492217f8231b930225ce6b1))
- remove broken deploy-module.yml ([d38e7d8](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/d38e7d81e86c4170b25979ba41938d30e16c8ad5))
- add test dispatch workflow ([b6f4751](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/b6f47519d97f3f76fddc5bbe596c2f1ea294125d))
- rename release-module.yml to deploy-module.yml (force fresh registration) ([55e0950](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/55e095011e12c415e9852ccb1931fe7f1a4347d6))
- remove release-module.yml (recreating) ([955c424](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/955c4248c2869a73340aea462dbdcfa9954146b5))
- remove build-module.ps1 (recreating) ([1dfe49b](https://github.com/GabrielFerreiraMendes/minusframework-meta/commit/1dfe49bf51f67d50837c824f33395d033fa095d6))

---

**Commits:** 29 | **Autores:** 1

---
*Release gerado automaticamente por generate-release-notes.ps1*

