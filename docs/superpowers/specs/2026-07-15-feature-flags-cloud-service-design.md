# Feature Flags Cloud Service — Design

**Date:** 2026-07-15
**Status:** Draft v2
**Scope:** Phase 2 — Feature Flags managed cloud service (API + WebSocket + SDK + Dashboard)

---

## 1. Overview

Cloud-hosted feature flag management for multi-environment Delphi applications. Real-time updates via WebSocket, gradual rollout with sticky bucketing, full audit trail.

## 2. Architecture

```
App (SDK Delphi) ──WebSocket──▶ API Go ──▶ PostgreSQL
  IsEnabled/GetVariant         │          └──▶ Redis (pub/sub)
                               ├──▶ REST API
                               └──▶ Dashboard Web
```

- **SDK Delphi**: WebSocket client with connection token auth, local cache, exponential backoff reconnection
- **API Go**: Single binary (REST + WebSocket), flag evaluation, Redis pub/sub for cross-instance broadcast
- **Redis**: Pub/sub channels per tenant+environment for flag changes
- **Dashboard**: Feature management web UI
- Auth: Connection token (WebSocket), JWT (dashboard), API Key (SDK management calls)

## 3. SDK Delphi (WebSocket Client)

### Connection Flow
```
1. SDK calls POST /api/v1/ws/token with API Key in X-API-Key header
2. Server returns { "token": "eyJ...", "expires_in": 30 }
3. SDK connects wss://host/ws?token=eyJ... (token single-use, 30s expiry)
4. Server validates token, establishes WebSocket, pushes initial flag state
```

### SDK API
```pascal
type
  TFlagContext = record
    UserId: string;
    GroupId: string;
    Attributes: TDictionary<string, string>;
  end;

  TFeatureFlagEvent = procedure(const AFlagName: string; AEnabled: Boolean) of object;

  TFeatureFlags = class
  private
    FWS: TWebSocket;
    FCache: TDictionary<string, Boolean>;
    FRetryCount: Integer;
  public
    constructor Create(const ABaseURL, AAPIKey, AEnvironment: string);
    function IsEnabled(const AName: string; const AContext: TFlagContext): Boolean;
    function GetVariant(const AName: string; const AContext: TFlagContext): string;
    property OnFlagChanged: TFeatureFlagEvent;
  end;
```

### Resilience
- **Reconnection**: exponential backoff 1s → 2s → 4s → 8s → max 30s
- **Heartbeat**: server sends ping every 30s; client responds pong
- **Local cache**: last known flag values stored in memory
- **Cache persistence**: optional file-based cache for app restart survival
- **Startup**: returns `false`/`''` for all flags if never connected; logs warning
- **Buffered updates**: flag changes received while disconnected are applied on reconnect

### Rollout Algorithm
```pascal
// Sticky bucketing: same user always sees same flag value
bucket := CRC32(LicenseKey + FlagKey + AContext.UserId) mod 100;
enabled := bucket < RolloutPercentage;
```

## 4. API Go (Single Binary)

### Stack
- Go (Gin + gorilla/websocket)
- PostgreSQL 16
- Redis 7 (pub/sub for WebSocket broadcast across instances)
- Auth: Connection token (WS), JWT (dashboard), API Key (SDK)
- Single binary: `cmd/server/main.go` handles both REST API and WebSocket hub

### Endpoints

**REST API:**
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /api/v1/ws/token | API Key | Issue WebSocket connection token |
| GET | /api/v1/flags | JWT | List flags for environment |
| POST | /api/v1/flags | JWT | Create flag |
| PUT | /api/v1/flags/:id | JWT | Update flag |
| DELETE | /api/v1/flags/:id | JWT | Delete flag |
| GET | /api/v1/environments | JWT | List environments |
| POST | /api/v1/environments | JWT | Create environment |

**WebSocket:**
| Path | Auth | Description |
|------|------|-------------|
| /ws | Connection token (query param) | Real-time flag updates |

### Data Model

```sql
CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    name TEXT NOT NULL,  -- 'dev', 'staging', 'production'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    flag_type TEXT NOT NULL DEFAULT 'boolean',  -- 'boolean', 'variant'
    default_variant TEXT,  -- value when disabled
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(license_key, key)
);

CREATE TABLE flag_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_id UUID NOT NULL REFERENCES flags(id) ON DELETE CASCADE,
    environment_id UUID NOT NULL REFERENCES environments(id) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT false,
    variant_value JSONB,  -- supports complex types (string, number, JSON)
    rollout_percentage INT DEFAULT 100,  -- 0-100
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(flag_id, environment_id)
);

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    actor_id UUID,
    action TEXT NOT NULL,  -- 'flag.created','flag.updated','flag.toggled','flag.deleted'
    resource_type TEXT NOT NULL,
    resource_id UUID NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_flag_values_env ON flag_values(environment_id);
CREATE INDEX idx_audit_license ON audit_log(license_key, created_at DESC);
```

### Redis Pub/Sub

When a flag is toggled via REST API:
1. Handler updates DB
2. Handler publishes to Redis channel `flags:{license_key}:{environment_id}`
3. All WebSocket hub instances consume the channel
4. Hub fans out to connected SDKs

Fallback: if Redis is unreachable, SDK uses last cached values. Dashboard and API still work (WebSocket updates are best-effort).

### Connection Token

```go
type WSToken struct {
    LicenseKey    string `json:"license_key"`
    EnvironmentID string `json:"environment_id"`
    ExpiresAt     int64  `json:"exp"`
}

// POST /api/v1/ws/token → validates API Key → returns signed JWT (30s TTL)
// SDK presents token as query param: /ws?token=<jwt>
// Server validates: not expired, single-use (cache in Redis/memory)
```

## 5. WebSocket Protocol

### Connection
```
SDK → Server: /ws?token=<connection_token>
Server → SDK: {"type": "connected", "flags": [{"key":"flag_a","enabled":true}, ...]}
```

### Events (Server → SDK)
```json
{"type": "flag_updated", "flag": "new_checkout", "enabled": true, "variant": {"color": "blue"}}
{"type": "flag_deleted", "flag": "old_feature"}
{"type": "bulk_sync", "flags": [...]}
{"type": "ping"}
```

### Events (SDK → Server)
```json
{"type": "pong"}
```

## 6. Dashboard

Feature management web UI (same styling as MinusAI Review):
- Flag list with search/filter by environment
- Create/edit flag form (key, name, type, default variant)
- Per-environment toggle with rollout percentage slider
- Audit log (who changed what, when)
- Environment management

## 7. Monetization

| Tier | Flags | Environments | Requests/mo | Price |
|------|-------|-------------|-------------|-------|
| Starter | 25 | 3 (dev/staging/prod) | 50k | $19/mo |
| Pro | Unlimited | 10 | 500k | $59/mo |
| Enterprise | Unlimited | Unlimited | Custom | Custom |

Enforced via License Server subscription tier check on API Key and dashboard JWT middleware.

## 8. Project Structure

```
services/feature-flags/
├── cmd/server/main.go           # Single binary (REST + WebSocket)
├── internal/
│   ├── handler/
│   │   ├── flags.go             # CRUD flags
│   │   ├── environments.go      # CRUD environments
│   │   ├── ws.go                # WebSocket handler + token issue
│   │   └── dashboard.go         # Dashboard data
│   ├── service/
│   │   ├── evaluator.go         # Rollout evaluation (CRC32 bucketing)
│   │   └── hub.go               # WebSocket connection manager + Redis pub/sub
│   ├── model/
│   │   ├── flag.go
│   │   └── environment.go
│   └── store/
│       └── postgres.go
├── middleware/
│   ├── auth.go                  # JWT validation
│   └── apikey.go                # API Key validation
├── migrations/
│   ├── 001_initial.sql
│   └── 002_audit_log.sql
├── sdk/
│   └── MF.FeatureFlags.Client.pas  # WebSocket client SDK
├── web/
│   ├── templates/
│   └── static/
├── go.mod
└── Dockerfile
```

## 9. Docker Compose

Port: **8083**

```yaml
feature-flags:
  build: ./services/feature-flags
  ports:
    - "8083:8083"
  environment:
    DATABASE_URL: postgres://postgres:postgres@postgres:5432/minusframework?sslmode=disable
    LISTEN_ADDR: ":8083"
    JWT_SECRET: ${JWT_SECRET}
    REDIS_URL: redis://redis:6379
  depends_on:
    - postgres
    - redis
```

## 10. Health Check

`GET /health` returns `{"status":"ok"}`.

## 11. Stripe Integration

Tier limits enforced via middleware that queries License Server for subscription tier on every SDK auth (API Key validation) and dashboard login (JWT validation). When subscription expires, API Key validation fails and SDK receives disconnect.
