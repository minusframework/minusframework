# Hybrid Business Model Design

**Date:** 2026-07-14
**Status:** Draft
**Scope:** MinusFrameWork ecosystem (meta-repo + 9 module repos)

---

## 1. Context

MinusFrameWork is a Delphi framework composed of 9 modules: Core, ORM, Migrator, CLI, FeatureFlags, Messaging, Extensions, Telemetry, and AI. It is distributed via an Inno Setup installer and currently has no formal commercial model.

The goal is to define a hybrid business model:
- **Perpetual license** for the core framework modules (distributed via installer, no source code)
- **Cloud SaaS subscriptions** for AI Review, Telemetry, and Feature Flags
- A **License Server** as a central hub managing both models

---

## 2. Business Model Overview

| Channel | Modules | Model |
|---------|---------|-------|
| **Installer (perpetual)** | Core, ORM, Migrator, CLI, Messaging, Extensions | Perpetual license + 1 year updates + support |
| **Cloud SaaS** | MinusAI Review, Telemetry, Feature Flags | Monthly/annual subscription |
| **License Server** | All (hub) | Central auth, billing, user management |

### Source Code Policy

**No source code is provided at any tier.** All modules are distributed as compiled DCUs/BPLs via the installer. This protects intellectual property and prevents unauthorized redistribution. Mitigations include:
- Comprehensive API documentation
- Responsive support (Slack/Discord for paid tiers)
- Source code available under NDA for Enterprise tier only

---

## 3. License Server (Hub Central)

### Role
Single hub that manages everything:
- Perpetual license key validation (online + offline)
- Cloud subscription management (creation, renewal, cancellation)
- User accounts and SSO (GitHub OAuth)
- Billing integration (Stripe)
- Customer portal (licenses, invoices, history)

### Architecture

```
Client → Installer → License Server (validate key)
Client → Cloud Service → License Server (verify subscription)
Client → Browser → License Server Portal (manage account)
```

### Key Features
- Online validation: real-time check against License Server
- Offline fallback: signed license file for air-gapped environments
- Device activation limit per license
- Subscription sync: when cloud subscription expires, service stops
- Webhook notifications for subscription events

### Tech
- API: Go (Gin)
- DB: PostgreSQL
- Cache: Redis
- Auth: GitHub OAuth + JWT
- Billing: Stripe

---

## 4. Cloud Services

Each cloud service is an **independent project** with its own Go API, database tables, and deployment. They share the License Server for auth but are otherwise decoupled.

### 4.1 MinusAI Review

**Purpose**: Automated PR review for Delphi projects. Validates commit messages, naming conventions, PR size, test existence, and performs semantic code analysis via LLM.

**Components**:
- **GitHub App**: receives webhook events (pull_request.opened, synchronize)
- **API Go**: receives webhooks, enqueues review jobs, serves dashboard
- **LLM Service**: Go module that calls OpenAI/Claude with PR diff
- **Delphi Worker**: Windows process that runs structural validation and posts review comments via GitHub API
- **Dashboard**: Web UI for review history, stats, configuration

**Flow**:
1. GitHub webhook → API Go → validate event → enqueue job
2. LLM Service analyzes diff → writes semantic analysis result
3. Delphi Worker picks up job → runs structural validation
4. Worker merges LLM + structural results → posts PR review (approve/request changes)
5. Dashboard updates with review record

### 4.2 Telemetry

**Purpose**: Usage analytics and monitoring for apps built with MinusFrameWork. Gives development teams visibility into how their framework is performing in production.

**Components**:
- **SDK Delphi**: lightweight client library (existing code in FeatureFlags.Metrics)
- **API Go**: ingests telemetry data, serves dashboards
- **Dashboard**: charts for usage, performance, errors, version distribution

**Data collected** (opt-in, anonymous):
- Framework version
- Component usage frequency
- Error counts and types
- Performance metrics (query times, etc.)

### 4.3 Feature Flags (Managed)

**Purpose**: Cloud-hosted feature flag management. Rollout, kill switch, A/B testing without infrastructure setup.

**Components**:
- **SDK Delphi**: consults API for flag resolution at runtime
- **API Go**: CRUD for flags, environments, targeting rules
- **Dashboard**: Web UI for managing flags, rollouts, experiments
- **Edge caching**: flags cached via CDN for low latency

---

## 5. Pricing Tiers

### Perpetual (Installer)

| Tier | Price | Includes |
|------|-------|----------|
| **Individual** | $199/dev (perpetual) | 1 developer, all core modules, 1 year updates |
| **Team** (up to 5 devs) | $699/year (subscription) | 5 devs, core modules, priority support |
| **Enterprise** | Custom | Unlimited devs, ILMT, NDA source access, dedicated support |

### Cloud Services (Monthly/Annual)

| Service | Starter | Pro | Enterprise |
|---------|---------|-----|------------|
| **MinusAI Review** | $29/mo (1 repo) | $99/mo (10 repos) | Custom |
| **Telemetry** | $19/mo (1 app) | $59/mo (5 apps) | Custom |
| **Feature Flags** | $39/mo (1k flags) | $129/mo (10k flags) | Custom |

### Bundles
- **Indie Pack**: Individual perpetual + MinusAI Starter + Telemetry Starter = $249
- **Team Pack**: Team subscription + MinusAI Pro + Telemetry Pro + Feature Flags Pro = $949/year

---

## 6. Distribution

### Installer (Inno Setup)
- Downloads MinusFrameWork core (DCUs/BPLs)
- Prompts for license key
- Validates key against License Server
- If valid → installs core modules
- Shows upsell banners for cloud services

### Cloud Services
- Each service is a standalone web app
- Accessible via `service.minusframework.dev`
- GitHub OAuth login (backed by License Server)
- Stripe checkout for subscription
- In-app onboarding wizard

---

## 7. Implementation Phases

### Phase 1 — Foundation (Months 1-3)
- License Server MVP: key validation, GitHub OAuth, Stripe integration
- MinusAI Review MVP: webhook ingestion, Delphi worker (existing), PR review posting
- Installer update: license key prompt, validation flow

### Phase 2 — Cloud Services (Months 4-6)
- Telemetry service: API + SDK + basic dashboard
- Feature Flags service: API + SDK + dashboard MVP
- MinusAI Review: LLM integration, dashboard

### Phase 3 — Polish (Months 7-9)
- Portal: unified customer dashboard (licenses, subscriptions, invoices)
- Bundles and automatic discounts
- Self-service onboarding for all services
- Documentation site updates

---

## 8. Open Questions

- Should the License Server be open-source (self-hostable) or proprietary-only?
- Is $199/dev competitive for the Delphi market? (DevExpress: $999/dev, TMS: ~$500/dev)
- Should cloud services offer a free tier to drive adoption?
- Should MinusAI Review support GitLab/Bitbucket in later phases?
- What is the upgrade path for existing beta users?
