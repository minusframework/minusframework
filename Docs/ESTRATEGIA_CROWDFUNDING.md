# Estratégia de Crowdfunding — Licença RAD Studio

> **Objetivo:** Arrecadar fundos para adquirir uma licença comercial do RAD Studio (Embarcadero)
> **Valor alvo:** R\$ 15.000 — R\$ 25.000 (~ USD \$2.100 — \$3.500)
> **Licença alvo:** RAD Studio Professional (mínimo) / Enterprise (ideal)
> **Prazo estimado:** 60-90 dias de campanha

---

## Sumário

1. [Contexto e Justificativa](#1-contexto-e-justificativa)
2. [Metas Financeiras](#2-metas-financeiras)
3. [Público-Alvo](#3-público-alvo)
4. [Modelo de Campanha](#4-modelo-de-campanha)
5. [Recompensas por Contribuição](#5-recompensas-por-contribuição)
6. [Canais de Divulgação](#6-canais-de-divulgação)
7. [Cronograma](#7-cronograma)
8. [Riscos e Mitigações](#8-riscos-e-mitigações)
9. [Próximos Passos Imediatos](#9-próximos-passos-imediatos)

---

## 1. Contexto e Justificativa

### 1.1 O Problema

O MinusFramework é atualmente desenvolvido com **Delphi Community Edition** (licença gratuita da Embarcadero). Esta licença **não permite**:

- **Compilação por linha de comando** (`dcc32.exe` recusa: *"does not support command line compiling"*)
- Uso comercial sem restrições
- CI/CD automatizado (GitHub Actions, GitLab CI, etc.)
- Geração de artefatos de build via script

### 1.2 Impacto Concreto

| Limitação | Consequência |
|---|---|
| Sem compilação CLI | Impossível CI/CD, testes automatizados em servidor |
| Sem CI/CD | Cada release exige compilação manual na IDE |
| Sem validação automática | Risco de regressão não detectada |
| Community restringe FireDAC | Apenas acesso local (não cliente/servidor) |
| Percepção de amadorismo | Empresas desconfiam de framework sem CI/CD |

### 1.3 O que a Licença Profissional/Enterprise Desbloqueia

| Funcionalidade | Community | Professional | Enterprise |
|---|---|---|---|
| Compilação CLI (`dcc32.exe`) | ❌ | ✅ | ✅ |
| CI/CD (GitHub Actions, etc.) | ❌ | ✅ | ✅ |
| FireDAC cliente/servidor | ❌ | Local | ✅ |
| Suporte a Linux (servidor) | ❌ | ❌ | ✅ |
| RAD Server | ❌ | ❌ | ✅ |
| DataSnap multi-tier | ❌ | ❌ | ✅ |
| Uso comercial irrestrito | Limitado | ✅ | ✅ |
| MSBuild Task | ❌ | ✅ | ✅ |

### 1.4 Retorno do Investimento

Com a licença, o MinusFramework pode:

1. **Pipeline CI/CD funcional** → testes automáticos a cada commit → qualidade profissional
2. **Benchmarks públicos** → credibilidade vs. Aurelius/EntityDAC
3. **Compilação noturna** → packages BPL sempre atualizados
4. **GetIt Package** → distribuição profissional via Delphi GetIt Manager
5. **Aumento de adoção** → framework confiável para empresas
6. **Potencial de receita** → suporte comercial, consultoria, treinamento

---

## 2. Metas Financeiras

### 2.1 Orçamento Detalhado

| Item | Profissional (USD) | Enterprise (USD) |
|---|---|---|
| Licença nova (com 1 ano de update sub.) | ~\$2.079 | ~\$3.449 |
| Taxas da plataforma de crowdfunding (~8%) | ~\$166 | ~\$276 |
| Recompensas e brindes | ~\$250 | ~\$400 |
| Taxas bancárias/transferência (~3%) | ~\$62 | ~\$103 |
| **Total estimado** | **~\$2.557** | **~\$4.228** |

### 2.2 Metas em Reais (BRL)

| Nível | Valor (BRL) | Equivalente USD | Cobre |
|---|---|---|---|
| **Mínimo viável** | R\$ 12.000 | ~\$2.100 | Licença Professional |
| **Ideal** | R\$ 20.000 | ~\$3.500 | Licença Enterprise |
| **Esticado** | R\$ 30.000 | ~\$5.250 | Enterprise + 2º ano de update |

### 2.3 Modelo "Tudo ou Nada"

Recomendação: campanha **tudo-ou-nada** (All-or-Nothing) — só recebe o dinheiro se atingir a meta. Isso:
- Gera urgência e compromisso
- Evita ficar com valor insuficiente para a licença
- Transmite seriedade para os apoiadores

---

## 3. Público-Alvo

### 3.1 Segmentos

| Segmento | Perfil | Motivação |
|---|---|---|
| **Desenvolvedores Delphi** | Profissionais autônomos, pequenas empresas | Querem uma ORM open source brasileira, leve e funcional |
| **Usuários do MinusFramework** | Quem já usa ou testou o framework | Querem versão estável com CI, suporte a mais bancos, pacotes BPL |
| **Empresas de software** | ISVs, fábricas de software | Precisam de ORM multi-banco confiável; framework reduz custo de desenvolvimento |
| **Comunidade Delphi BR** | Grupos no Telegram, WhatsApp, fóruns | Fortalecer o ecossistema Delphi nacional; orgulho de ter uma ORM brasileira |
| **Entusiastas open source** | Desenvolvedores em geral | Apoiam projetos open source promissores |

### 3.2 Tamanho do Mercado

- Comunidade Delphi Brasil: ~50.000-100.000 desenvolvedores ativos
- Grupos Telegram Delphi BR: ~15.000 membros (múltiplos grupos)
- Empresas usando Delphi no Brasil: ~5.000-10.000
- Potencial de apoiadores: 100-300 pessoas/empresas

---

## 4. Modelo de Campanha

### 4.1 Plataforma Recomendada

| Plataforma | Vantagens | Desvantagens |
|---|---|---|
| **Kickstarter** | Maior alcance global | Taxa 8-10%, precisa de conta internacional |
| **Catarse** | Brasileira, pagamento em R$, Pix | Foco em projetos criativos/culturais |
| **Benfeitoria** | Brasileira, modelo flexível | Menor alcance que Catarse |
| **Apoia.se** | Assinatura recorrente | Não é ideal para campanha única |
| **GitHub Sponsors** | Ideal para projetos open source | Pagamento mensal, não campanha única |
| **Vakinha** | Brasileira, muito conhecida | Mais genérica, menos foco tech |

**Recomendação:** **Catarse** (pagamento em R$, Pix, boleto, cartão) + **GitHub Sponsors** para doação contínua após a campanha.

### 4.2 Formato da Campanha

- **Duração:** 60 dias (2 meses)
- **Meta:** R\$ 20.000 (ideal)
- **Modelo:** Tudo-ou-nada (flexível para "flex" se necessário)
- **Página:** Vídeo de apresentação (2-3 min), texto explicativo, rewards table

### 4.3 Discurso Central (Elevator Pitch)

> *"A maior ORM Delphi open source do Brasil precisa de CI/CD. A Community Edition não compila via linha de comando — sem CI, sem testes automatizados, sem releases confiáveis. Ajude a levar o MinusFramework ao nível profissional: R\$ 20.000 para comprar a licença RAD Studio Enterprise. Em troca, você leva uma ORM multi-banco madura, com suporte a 7 bancos, migração versionada, extensões e muito mais. Código aberto, comunidade forte, futuro profissional."*

---

## 5. Recompensas por Contribuição

### 5.1 Tabela de Recompensas

| Faixa | Valor | Recompensa |
|---|---|---|
| **Apoiador** | R\$ 20 | Nome no README (seção "Apoiadores") |
| **Apoiador Plus** | R\$ 50 | Nome no README + acesso ao canal privado de Telegram |
| **Desenvolvedor** | R\$ 100 | Tudo acima + camiseta virtual (badge) + ebook "ORM Delphi do Zero" |
| **Apoiador Master** | R\$ 200 | Tudo acima + 1 hora de consultoria/suporte via chamada |
| **Empresa Bronze** | R\$ 500 | Logo na página inicial + menção em redes sociais + 3h de suporte |
| **Empresa Prata** | R\$ 1.000 | Logo no README + prioridade em issues + 8h de suporte |
| **Empresa Ouro** | R\$ 2.000 | Logo em destaque + feature request prioritário + 16h de suporte |
| **Patrocinador** | R\$ 5.000 | Naming rights em release (ex: "MinusFramework v2.0 patrocinado por [Empresa]") + suporte premium 40h |

### 5.2 Recompensas Coletivas (para todos)

- Licença do framework: **MIT** (já é, continuará sendo)
- Acesso ao repositório privado de desenvolvimento (se houver)
- Relatórios mensais de progresso

### 5.3 Recompensas Empresariais Detalhadas

Para empresas, pacotes de **suporte comercial**:

| Pacote | Valor/mês | Inclui |
|---|---|---|
| **Basic** | R\$ 200 | Suporte por e-mail, 48h úteis de resposta |
| **Standard** | R\$ 500 | Suporte prioritário 24h + 2h de consultoria/mês |
| **Enterprise** | R\$ 1.500 | Suporte 8h úteis + 8h de consultoria/mês + treinamento remoto |

(Mensalidades pós-campanha para sustentabilidade)

---

## 6. Canais de Divulgação

### 6.1 Canais Primários

| Canal | Ação | Prazo |
|---|---|---|
| **Telegram Delphi BR** (~10k membros) | Post explicativo + link | Dia 1 |
| **WhatsApp grupos Delphi** | Compartilhar em grupos ativos | Dia 1 |
| **LinkedIn** | Artigo detalhado + posts semanais | Semana 1 |
| **YouTube** | Vídeo demonstrando o framework + campanha | Semana 1 |
| **GitHub** | Pin da campanha no README + Discussions | Dia 1 |
| **Twitter/X** | Thread técnica sobre ORM Delphi | Semana 1 |

### 6.2 Canais Secundários

| Canal | Ação | Prazo |
|---|---|---|
| **Stack Overflow PT** | Mencionar em respostas sobre ORM Delphi | Semana 2 |
| **Medium / Dev.to** | Artigo técnico "Construindo uma ORM Delphi" | Semana 2 |
| **Podcasts Delphi** | Participar de episódios (ex: DelphiCast, BoraDelphi) | Semana 2-3 |
| **Fóruns** | Active Delphi, ClubeDelphi, Fórum WBSED | Semana 1 |
| **Newsletters** | Delphi Weekly, DelphiFeeds | Semana 1 |
| **Eventos** | TDN (The Delphi Nation), DelphiCon (se houver) | Mês 2 |

### 6.3 Conteúdo Programado

| Semana | Conteúdo |
|---|---|
| **Pré-campanha (1-2 semanas)** | Teasers: "Maior ORM Delphi BR precisa de você", mostrar gaps atuais (sem CI, sem compilação CLI) |
| **Semana 1** | Lançamento: vídeo + post + artigo explicando o projeto e a meta |
| **Semana 2** | Demo técnica: mostrar o framework funcionando com 7 bancos |
| **Semana 3** | Comparativo: MinusFramework vs Aurelius vs EntityDAC (tabela de features, benchmark preview) |
| **Semana 4** | Case de uso: migração de um projeto real usando MinusMigrator |
| **Semana 5** | Atualização: quanto falta, novos apoiadores, depoimentos |
| **Semana 6** | Reta final: call to action, matching (alguém dobra contribuições na última semana) |
| **Semana 7-8** | Últimos dias: contagem regressiva, agradecimentos |

---

## 7. Cronograma

### 7.1 Timeline

```
Mês 1                Mês 2                Mês 3                Mês 4
├────────────────────┼────────────────────┼────────────────────┼──────────►
│  PRÉ-CAMPANHA      │  CAMPANHA ATIVA    │  PÓS-CAMPANHA      │  ENTREGA
│                     │                     │                     │
│ • Gravar vídeo     │ • Lançamento       │ • Encerrar         │ • Comprar
│ • Criar página     │ • Postagens        │ • Arrecadar fundos │   licença
│ • Contatar         │   diárias/semanais │ • Processar        │ • Setup CI
│   influenciadores  │ • Atualizações     │   recompensas      │ • Primeiro
│ • Preparar rewards │ • Responder        │ • Relatório final  │   build CI
│ • Testar página    │   comentários      │                     │ • Publicar
│                     │ • Matching última  │                     │   BPL/GetIt
│                     │   semana          │                     │
└────────────────────┴────────────────────┴────────────────────┴──────────►
```

### 7.2 Marcos (Milestones)

| Marco | Data | Entregável |
|---|---|---|
| M0: Página no ar | Início Mês 2 | Catarse + GitHub Discussions ativo |
| M1: 50% da meta | Final Semana 3 | R\$ 10.000 |
| M2: 100% da meta | Final Semana 6 | R\$ 20.000 |
| M3: Licença comprada | 30 dias após | Nota fiscal + novo build CI verde |
| M4: CI/CD rodando | 60 dias após | GitHub Actions com compilação, testes, deploy |
| M5: GetIt Package | 90 dias após | Framework publicado no GetIt Manager |

---

## 8. Riscos e Mitigações

### 8.1 Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| **Não atingir a meta** | Média | Alto | Modelo "tudo-ou-nada" protege apoiadores; se próximo da meta, estender prazo 15 dias; considerar modelo "flexível" como plano B |
| **Licença aumentar de preço** | Baixa | Médio | Inflacionar meta em 15% para margem |
| **Câmbio USD/BRL variar** | Média | Médio | Meta em R\$ com margem de segurança de 20% sobre o câmbio atual |
| **Baixa adesão da comunidade** | Média | Alto | Campanha de pré-lançamento para medir interesse; se baixo, adiar e fortalecer comunidade primeiro |
| **Concorrência (Aurelius, EntityDAC)** | Baixa | Baixo | Framework é open source + multi-banco + migrador — diferenciais claros |
| **Problemas legais (licenciamento)** | Baixa | Alto | Consultar termos da Embarcadero; licença MIT já revisada |
| **Atraso na entrega de recompensas** | Baixa | Médio | Recompensas digitais (automáticas) primeiro; consultoria agenda conforme demanda |

### 8.2 Plano B (Se não atingir)

1. **Campanha flexível:** receber o valor mesmo sem atingir a meta, complementar com recursos próprios
2. **Apoio contínuo:** GitHub Sponsors + Open Collective para arrecadação lenta e constante
3. **Alternativa de licenciamento:** Considerar licença educacional/acadêmica (se aplicável, mais barata)
4. **Parceria com empresa:** Buscar empresa de software que precise do framework e queira patrocinar a licença em troca de suporte prioritário

---

## 9. Próximos Passos Imediatos

### 9.1 Checklist Pré-Campanha

- [ ] **Gravar vídeo de 2-3 minutos** apresentando o framework, mostrando o problema da Community Edition e pedindo apoio
- [ ] **Criar página no Catarse** com descrição detalhada, rewards, FAQ
- [ ] **Preparar recompensas digitais** (badges, ebooks, templates de agradecimento)
- [ ] **Criar landing page** simples (GitHub Pages ou Vercel) com link para o Catarse
- [ ] **Contatar influenciadores** do ecossistema Delphi (grupos, youtubers, bloggers)
- [ ] **Preparar posts** para cada canal (Telegram, LinkedIn, Twitter, WhatsApp)
- [ ] **Definir matching** — encontrar 1-2 empresas que dobrem contribuições na última semana
- [ ] **Testar página** com 10 pessoas de confiança antes do lançamento

### 9.2 Conteúdo do Vídeo (Roteiro Sugerido)

1. **Abertura (0:00-0:30)** — Mostrar o framework rodando: "Isto é o MinusFramework — a maior ORM Delphi open source do Brasil"
2. **O problema (0:30-1:00)** — Mostrar o erro do `dcc32.exe` recusando compilar. "Sem licença paga, não temos CI/CD."
3. **O que já foi feito (1:00-1:30)** — Rápido tour: 7 providers, migrator, ORM completo, extensões
4. **O que falta (1:30-2:00)** — CI/CD automatizado, packages BPL, GetIt, benchmarks
5. **O pedido (2:00-2:30)** — "Precisamos de R\$ 20.000 para a licença Enterprise. Veja as recompensas."
6. **Encerramento (2:30-3:00)** — "Ajude a levar o Delphi open source brasileiro ao próximo nível."

### 9.3 Após a Campanha (Se Bem-Sucedida)

| Dias após | Ação |
|---|---|
| +0 (imediatamente) | Agradecer todos os apoiadores publicamente |
| +1 | Comprar a licença RAD Studio |
| +7 | Setup do CI/CD no GitHub Actions |
| +14 | Primeiro build CI verde |
| +21 | Publicar packages BPL compilados |
| +30 | Publicar no GetIt Manager |
| +45 | Relatório completo para apoiadores |
| +60 | Benchmarks públicos vs Aurelius/EntityDAC |
| +90 | Release v2.0 oficial com CI, BPL, GetIt |

---

## Apêndice A — Mensagens Prontas

### Post para Telegram/WhatsApp

```
🚀 Ajude o MinusFramework a ter CI/CD!

O MinusFramework é a maior ORM Delphi open source do Brasil:
✅ 7 providers de banco
✅ ORM completo com Unit of Work
✅ Sistema de migração versionado
✅ Licença MIT

MAS: a Community Edition NÃO compila via linha de comando.
Sem licença paga, sem CI/CD, sem testes automáticos.

📍 Meta: R$ 20.000 para licença RAD Studio Enterprise
📍 Campanha no Catarse: [link]
📍 Duração: 60 dias

Recompensas:
R$ 20 → Nome no README
R$ 100 → E-book + badge
R$ 500 → Logo + suporte para sua empresa

Toda contribuição importa! Compartilhe! 🙏
```

### Post para LinkedIn

```
**MinusFramework: a ORM Delphi brasileira precisa de você**

Há 2 anos construímos a maior ORM Delphi open source do país. Hoje são:
• 60+ arquivos de código
• 7 bancos de dados suportados
• ORM + Migrador + Extensões
• 3 DLLs para consumo de qualquer linguagem

Mas esbarramos em um limite: a Community Edition não compila por linha de comando. Sem CI/CD, sem builds automatizados, sem validação contínua.

Criamos uma campanha de crowdfunding para adquirir a licença RAD Studio Enterprise (R$ 20.000). Em troca, o framework ganha:
• Pipeline CI/CD profissional
• Packages BPL para instalação simples
• Publicação no GetIt Manager
• Benchmarks e validação contínua

Se você desenvolve em Delphi, se usa ORM, ou se acredita em software livre brasileiro: essa campanha é para você.

[link da campanha]

#Delphi #ORM #OpenSource #Crowdfunding #Embarcadero #Brasil
```

---

## Apêndice B — Orçamento Mensal Pós-Licença (Opcional)

| Item | Custo/mês |
|---|---|
| Renovação Update Subscription (~20% da licença/ano) | ~R\$ 300 (rateado) |
| Domínio + hospedagem site | ~R\$ 50 |
| GitHub Actions (créditos extras) | ~R\$ 0 (limite free suficiente) |
| **Total** | **~R\$ 350/mês** |

Sustentabilidade: GitHub Sponsors, Open Collective, ou pacotes de suporte empresarial (R\$ 200-1.500/mês).

---

> **Documento gerado em Junho de 2026**  
> *Estratégia baseada em crowdfunding All-or-Nothing + recompensas digitais + suporte empresarial contínuo.*  
> *Próxima ação: Gravar vídeo de apresentação e criar página no Catarse.*
