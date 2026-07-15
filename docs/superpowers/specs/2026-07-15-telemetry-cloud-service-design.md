# Telemetry Cloud Service — Design

**Date:** 2026-07-15
**Status:** Draft v2
**Scope:** Phase 2 — Telemetry cloud service (API + Cloud Exporter + Dashboard)

---

## 1. Overview

Cloud service for collecting and visualizing telemetry from applications built with MinusFrameWork. The **SDK already exists** (`Telemetry/Source/`, ~1650 lines) and is OpenTelemetry-compatible (spans, traces, metrics, exporters for Jaeger/Zipkin/OTLP). This service adds a cloud ingestion endpoint and dashboard — no new SDK is needed.

## 2. Architecture

```
App (existing SDK) ──OTLP──▶ API Go ──▶ PostgreSQL
  MF.Telemetry.pas     POST /v1/traces    │
  + CloudExporter      POST /v1/metrics   └──▶ Dashboard Web
```

- **SDK**: exists in module `Telemetry/Source/`. A new `TCloudExporter` class sends spans/metrics to the cloud API via OTLP HTTP protocol
- **API Go**: ingests OTLP traces/metrics, serves dashboard data, manages auth
- **Dashboard**: Web UI for trace explorer, service map, error drilldown, latency percentiles
- Auth: API Key (ingestion) + JWT (dashboard)

## 3. SDK — Cloud Exporter (new, ~200 lines)

The core SDK (`MF.Telemetry.pas`, `MF.Telemetry.Exporter.pas`) already handles tracing, metrics, structured logging, and exports. The cloud service needs only a new backend:

**File:** `services/telemetry/sdk/MF.Telemetry.Cloud.pas`

```pascal
unit MF.Telemetry.Cloud;

interface

uses
  MF.Telemetry, MF.Telemetry.Exporter;

type
  TCloudExporter = class(TBaseExporter)
  private
    FAPIKey: string;
    FBaseURL: string;
  public
    constructor Create(const ABaseURL, AAPIKey: string);
    procedure ExportSpan(ASpan: ISpan); override;
    procedure ExportMetric(AMetric: IMetric); override;
  end;
```

- SDK sends batches every 60s (configurable via `GET /api/v1/config`)
- Uses HTTP/1.1 with keep-alive
- Reconnection: exponential backoff (1s → 2s → 4s → max 60s)
- Fallback: buffers in memory when API is unreachable (up to 10k events)

## 4. API Go

### Stack
- Go (Gin)
- PostgreSQL 16
- Auth: API Key (ingestion), JWT (dashboard, via License Server)

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /v1/traces | API Key (X-API-Key) | OTLP trace ingestion |
| POST | /v1/metrics | API Key (X-API-Key) | OTLP metric ingestion |
| GET | /api/v1/config | Public | SDK configuration (interval, URL) |
| GET | /api/v1/dashboard/summary | JWT | Overview stats |
| GET | /api/v1/dashboard/traces | JWT | Trace explorer |
| GET | /api/v1/dashboard/services | JWT | Service map |
| GET | /api/v1/dashboard/errors | JWT | Error timeline |
| GET | /api/v1/dashboard/performance | JWT | Latency P50/P95/P99 |

### Data Model

```sql
-- Traces/Spans (OTLP-compatible)
CREATE TABLE spans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    trace_id TEXT NOT NULL,
    span_id TEXT NOT NULL,
    parent_span_id TEXT,
    operation_name TEXT NOT NULL,
    service_name TEXT NOT NULL,
    span_kind TEXT NOT NULL,  -- 'internal','server','client','producer','consumer'
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    duration_ms NUMERIC GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (end_time - start_time)) * 1000
    ) STORED,
    status TEXT NOT NULL DEFAULT 'ok',
    tags JSONB DEFAULT '{}',
    events JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Metrics (Counter, Gauge, Histogram)
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_type TEXT NOT NULL,  -- 'counter','gauge','histogram'
    value NUMERIC NOT NULL,
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Rollup tables
CREATE TABLE spans_hourly (
    hour TIMESTAMPTZ NOT NULL,
    license_key TEXT NOT NULL,
    service_name TEXT NOT NULL,
    operation_name TEXT NOT NULL,
    count INT NOT NULL DEFAULT 0,
    error_count INT NOT NULL DEFAULT 0,
    p50_ms NUMERIC, p95_ms NUMERIC, p99_ms NUMERIC
);

CREATE TABLE metrics_hourly (
    hour TIMESTAMPTZ NOT NULL,
    license_key TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    sum NUMERIC NOT NULL,
    count INT NOT NULL DEFAULT 0,
    min NUMERIC, max NUMERIC, avg NUMERIC
);

-- Indexes
CREATE INDEX idx_spans_trace ON spans(license_key, trace_id);
CREATE INDEX idx_spans_time ON spans(license_key, start_time DESC);
CREATE INDEX idx_spans_errors ON spans(license_key, status) WHERE status = 'error';
CREATE INDEX idx_metrics_time ON metrics(license_key, metric_name, timestamp DESC);
```

### Retention & Rollup

| Tier | Raw retention | Rollup retention | Aggregation |
|------|--------------|-----------------|-------------|
| Starter | 7 days | 30 days (hourly) | Daily cron |
| Pro | 30 days | 90 days (hourly) | Daily cron |
| Enterprise | Custom | Custom | Custom |

Rollup job runs daily via cron inside the Go binary (goroutine with ticker).

## 5. Auth Model

| Endpoint | Auth | Mechanism |
|----------|------|-----------|
| `POST /v1/traces`, `POST /v1/metrics` | API Key | `X-API-Key` header. Key derived from license key, validated against License Server DB |
| `GET /api/v1/dashboard/*` | JWT | `Authorization: Bearer` — JWT from License Server (same as MinusAI Review) |
| `GET /api/v1/config` | Public | No auth needed |

API Key validation: `SELECT 1 FROM licenses WHERE license_key = $1 AND status = 'active'` (cached for 5min).

Rate limiting per API Key (by tier):
- Starter: 100 req/min
- Pro: 1000 req/min
- Enterprise: Custom

## 6. Dashboard

Web UI (same styling as MinusAI Review dashboard):
- **Overview**: active services, traces/min, error rate, top operations
- **Trace Explorer**: search by trace ID, service, time range; waterfall view per trace
- **Service Map**: dependency graph between services (from parent_span_id relationships)
- **Errors**: grouped by operation, first/last seen, count trend
- **Performance**: P50/P95/P99 latency charts per endpoint

## 7. Monetization

| Tier | Apps | Events/mo | Raw retention | Price |
|------|------|-----------|--------------|-------|
| Starter | 1 | 100k | 7 days | $19/mo |
| Pro | 5 | 1M | 30 days | $59/mo |
| Enterprise | Custom | Custom | Custom | Custom |

Enforced via License Server subscription tier check on API Key validation middleware.

## 8. Project Structure

```
services/telemetry/
├── cmd/server/main.go
├── internal/
│   ├── handler/
│   │   ├── ingest.go        # OTLP ingestion (POST /v1/traces, /v1/metrics)
│   │   └── dashboard.go     # Dashboard API
│   ├── service/
│   │   ├── aggregator.go    # Hourly rollup
│   │   └── retention.go     # TTL cleanup
│   ├── model/
│   │   ├── span.go
│   │   └── metric.go
│   ├── store/
│   │   └── postgres.go
│   └── middleware/
│       ├── auth.go          # JWT validation (reuses pattern from minusai-review)
│       └── apikey.go        # API Key validation for ingestion
├── migrations/
│   ├── 001_spans.sql
│   └── 002_metrics.sql
├── sdk/
│   └── MF.Telemetry.Cloud.pas  # Cloud exporter (extends existing SDK)
├── web/
│   ├── templates/
│   └── static/
├── go.mod
└── Dockerfile
```

## 9. Docker Compose

Port: **8082**

```yaml
telemetry:
  build: ./services/telemetry
  ports:
    - "8082:8082"
  environment:
    DATABASE_URL: postgres://postgres:postgres@postgres:5432/minusframework?sslmode=disable
    LISTEN_ADDR: ":8082"
    JWT_SECRET: ${JWT_SECRET}
  depends_on:
    - postgres
```

## 10. Health Check

`GET /health` returns `{"status":"ok"}` (same pattern as other services).

## 11. Stripe Integration

Tier limits enforced via middleware that queries License Server for the subscription tier:
```go
// Middleware checks license_key → License Server → tier limits
func RateLimitByTier(tier string) gin.HandlerFunc { ... }
```

When tier changes (Stripe webhook), License Server broadcasts to affected services (or SDK reconnects on next flush).
