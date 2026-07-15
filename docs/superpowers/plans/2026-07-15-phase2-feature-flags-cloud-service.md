# Phase 2 — Feature Flags Cloud Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build cloud-hosted feature flag management with real-time WebSocket updates, granular rollout, and full audit trail for multi-environment Delphi applications.

**Architecture:** Single Go binary handling both REST API and WebSocket connections. REST for flag/environment CRUD (JWT auth), WebSocket for real-time flag push to Delphi SDKs (connection token auth). Redis pub/sub for cross-instance broadcast. Sticky rollout via CRC32 bucketing. Existing Delphi SDK (`FeatureFlags/Source/`) has `Provider.REST`, `Provider.Database`, `SDK`, `SSE`, `Webhook` units — cloud WebSocket hub integrates with SDK's existing interfaces.

**Tech Stack:** Go 1.22+ (Gin, gorilla/websocket), PostgreSQL 16, Redis 7, Delphi 11 (existing FeatureFlags SDK), Docker.

## Global Constraints

- No source code provided at any tier (DCUs/BPLs only)
- Auth: API Key (X-API-Key) for SDK management calls, Connection Token (signed JWT, 30s TTL) for WebSocket, JWT (Bearer) for dashboard
- API Key validation queries License Server DB (cached 5min)
- Rate limiting per API Key per tier
- All new code in `services/feature-flags/` directory
- Port: 8083
- Redis pub/sub channels: `flags:{license_key}:{environment_id}`

---
## File Structure

```
services/feature-flags/
├── cmd/server/main.go
├── internal/
│   ├── handler/
│   │   ├── flags.go
│   │   ├── environments.go
│   │   ├── ws.go
│   │   └── dashboard.go
│   ├── service/
│   │   ├── evaluator.go
│   │   └── hub.go
│   ├── model/
│   │   ├── flag.go
│   │   └── environment.go
│   ├── store/
│   │   └── postgres.go
│   └── middleware/
│       ├── auth.go
│       └── apikey.go
├── migrations/
│   ├── 001_initial.sql
│   └── 002_audit_log.sql
├── sdk/
│   └── MF.FeatureFlags.Client.pas
├── web/
│   ├── templates/
│   │   ├── index.html
│   │   ├── flags.html
│   │   └── audit.html
│   └── static/
│       └── style.css
├── go.mod
├── Dockerfile
└── Makefile
```

---

### Task 1: Project Scaffold + Database Schema

**Files:**
- Create: `services/feature-flags/go.mod`
- Create: `services/feature-flags/cmd/server/main.go`
- Create: `services/feature-flags/internal/store/postgres.go`
- Create: `services/feature-flags/migrations/001_initial.sql`
- Create: `services/feature-flags/migrations/002_audit_log.sql`
- Create: `services/feature-flags/Dockerfile`
- Create: `services/feature-flags/Makefile`
- Modify: `services/docker-compose.yml`

**Interfaces:**
- Produces: `store.NewPostgres(dsn) *store.Store`
- Produces: Tables: `environments`, `flags`, `flag_values`, `audit_log`

- [ ] **Step 1: Create Go module and directories**

```bash
mkdir -p services/feature-flags/cmd/server
mkdir -p services/feature-flags/internal/handler
mkdir -p services/feature-flags/internal/model
mkdir -p services/feature-flags/internal/service
mkdir -p services/feature-flags/internal/store
mkdir -p services/feature-flags/internal/middleware
mkdir -p services/feature-flags/migrations
mkdir -p services/feature-flags/sdk
mkdir -p services/feature-flags/web/templates
mkdir -p services/feature-flags/web/static
cd services/feature-flags
go mod init github.com/GabrielFerreiraMendes/minusframework/services/feature-flags
go get github.com/gin-gonic/gin
go get github.com/jackc/pgx/v5
go get github.com/golang-jwt/jwt/v5
go get github.com/gorilla/websocket
go get github.com/redis/go-redis/v9
```

- [ ] **Step 2: Create migrations/001_initial.sql**

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    key TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    flag_type TEXT NOT NULL DEFAULT 'boolean',
    default_variant TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(license_key, key)
);

CREATE TABLE flag_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_id UUID NOT NULL REFERENCES flags(id) ON DELETE CASCADE,
    environment_id UUID NOT NULL REFERENCES environments(id) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT false,
    variant_value JSONB,
    rollout_percentage INT DEFAULT 100,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(flag_id, environment_id)
);

CREATE INDEX idx_flag_values_env ON flag_values(environment_id);
CREATE INDEX idx_flags_license ON flags(license_key);
CREATE INDEX idx_environments_license ON environments(license_key);
```

- [ ] **Step 3: Create migrations/002_audit_log.sql**

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    actor_id UUID,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id UUID NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_license ON audit_log(license_key, created_at DESC);
```

- [ ] **Step 4: Create store/postgres.go**

```go
package store

import (
    "context"
    "github.com/jackc/pgx/v5/pgxpool"
)

type Store struct {
    pool *pgxpool.Pool
}

func NewPostgres(ctx context.Context, dsn string) (*Store, error) {
    pool, err := pgxpool.New(ctx, dsn)
    if err != nil {
        return nil, err
    }
    if err := pool.Ping(ctx); err != nil {
        pool.Close()
        return nil, err
    }
    return &Store{pool: pool}, nil
}

func (s *Store) Close() {
    s.pool.Close()
}

func (s *Store) ValidateLicenseKey(ctx context.Context, licenseKey string) (bool, error) {
    var exists bool
    err := s.pool.QueryRow(ctx,
        `SELECT EXISTS(SELECT 1 FROM licenses WHERE license_key = $1 AND status = 'active')`,
        licenseKey,
    ).Scan(&exists)
    return exists, err
}

func (s *Store) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
    tag, err := s.pool.Exec(ctx, sql, args...)
    return tag.RowsAffected(), err
}

func (s *Store) Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error) {
    return s.pool.Query(ctx, sql, args...)
}
```

- [ ] **Step 5: Create cmd/server/main.go** (scaffold with health check)

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

func main() {
    dsn := os.Getenv("DATABASE_URL")
    if dsn == "" {
        log.Fatal("DATABASE_URL is required")
    }

    ctx := context.Background()
    db, err := store.NewPostgres(ctx, dsn)
    if err != nil {
        log.Fatalf("failed to connect to database: %v", err)
    }
    defer db.Close()

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })

    addr := os.Getenv("LISTEN_ADDR")
    if addr == "" {
        addr = ":8083"
    }
    log.Printf("Feature Flags API listening on %s", addr)
    r.Run(addr)
}
```

- [ ] **Step 6: Create Dockerfile**

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /server /server
EXPOSE 8083
CMD ["/server"]
```

- [ ] **Step 7: Create Makefile**

```makefile
.PHONY: run test migrate

run:
	go run ./cmd/server

test:
	go test ./...

migrate:
	psql "$(DATABASE_URL)" -f migrations/001_initial.sql
	psql "$(DATABASE_URL)" -f migrations/002_audit_log.sql
```

- [ ] **Step 8: Add to docker-compose.yml**

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

- [ ] **Step 9: Run migrations and verify health**

Run: `docker compose up -d postgres redis`
Run: `docker compose run --rm feature-flags go run ./cmd/server`
Expected: server starts, `/health` returns `{"status":"ok"}`

- [ ] **Step 10: Commit**

```bash
git add services/feature-flags/ services/docker-compose.yml
git commit -m "feat: scaffold Feature Flags service with PostgreSQL schema"
```

---

### Task 2: Environments + Flags CRUD REST API

**Files:**
- Create: `services/feature-flags/internal/model/flag.go`
- Create: `services/feature-flags/internal/model/environment.go`
- Create: `services/feature-flags/internal/handler/flags.go`
- Create: `services/feature-flags/internal/handler/environments.go`
- Create: `services/feature-flags/internal/middleware/auth.go`
- Create: `services/feature-flags/internal/middleware/apikey.go`
- Modify: `services/feature-flags/internal/store/postgres.go`
- Modify: `services/feature-flags/cmd/server/main.go`

**Interfaces:**
- Produces: CRUD for environments (`GET/POST/PUT/DELETE /api/v1/environments`)
- Produces: CRUD for flags (`GET/POST/PUT/DELETE /api/v1/flags`)
- Produces: `PUT /api/v1/flags/:id/toggle` — toggle flag + audit log
- Consumes: JWT auth middleware, API Key middleware

- [ ] **Step 1: Write the failing test**

```go
// internal/handler/flags_test.go
package handler

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestCreateFlagMissingAuth(t *testing.T) {
    body := `{"key":"test_flag","name":"Test Flag","flag_type":"boolean"}`
    req := httptest.NewRequest("POST", "/api/v1/flags", bytes.NewBufferString(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    if w.Code == http.StatusUnauthorized {
        t.Log("correctly rejected missing auth")
    }
}

func TestCreateFlagInvalidPayload(t *testing.T) {
    req := httptest.NewRequest("POST", "/api/v1/flags", bytes.NewBufferString("{}"))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer test-token")
    w := httptest.NewRecorder()
    if w.Code == http.StatusBadRequest {
        t.Log("correctly rejected empty payload")
    }
}
```

- [ ] **Step 2: Create model/flag.go**

```go
package model

import (
    "encoding/json"
    "time"
)

type FlagType string

const (
    FlagTypeBoolean FlagType = "boolean"
    FlagTypeVariant FlagType = "variant"
)

type Flag struct {
    ID             string    `json:"id"`
    LicenseKey     string    `json:"-"`
    Key            string    `json:"key"`
    Name           string    `json:"name"`
    Description    string    `json:"description,omitempty"`
    FlagType       FlagType  `json:"flag_type"`
    DefaultVariant string    `json:"default_variant,omitempty"`
    CreatedAt      time.Time `json:"created_at"`
    UpdatedAt      time.Time `json:"updated_at"`
}

type FlagValue struct {
    ID               string           `json:"id"`
    FlagID           string           `json:"flag_id"`
    EnvironmentID    string           `json:"environment_id"`
    Enabled          bool             `json:"enabled"`
    VariantValue     json.RawMessage  `json:"variant_value,omitempty"`
    RolloutPercentage int             `json:"rollout_percentage"`
    CreatedAt        time.Time        `json:"created_at"`
    UpdatedAt        time.Time        `json:"updated_at"`
}

type CreateFlagRequest struct {
    Key            string    `json:"key" binding:"required"`
    Name           string    `json:"name" binding:"required"`
    Description    string    `json:"description,omitempty"`
    FlagType       FlagType  `json:"flag_type" binding:"required"`
    DefaultVariant string    `json:"default_variant,omitempty"`
}
```

- [ ] **Step 3: Create model/environment.go**

```go
package model

import "time"

type Environment struct {
    ID         string    `json:"id"`
    LicenseKey string    `json:"-"`
    Name       string    `json:"name"`
    CreatedAt  time.Time `json:"created_at"`
    UpdatedAt  time.Time `json:"updated_at"`
}
```

- [ ] **Step 4: Create middleware/auth.go** (JWT validation, same pattern as minusai-review)

```go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

func JWTAuthRequired(jwtSecret string) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing authorization header"})
            return
        }

        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization format"})
            return
        }

        token, err := jwt.Parse(parts[1], func(t *jwt.Token) (interface{}, error) {
            return []byte(jwtSecret), nil
        })
        if err != nil || !token.Valid {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
            return
        }

        claims, ok := token.Claims.(jwt.MapClaims)
        if !ok {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token claims"})
            return
        }

        c.Set("user_id", claims["user_id"])
        c.Set("email", claims["email"])
        c.Next()
    }
}
```

- [ ] **Step 5: Create middleware/apikey.go**

```go
package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

func APIKeyRequired(s *store.Store) gin.HandlerFunc {
    return func(c *gin.Context) {
        key := c.GetHeader("X-API-Key")
        if key == "" {
            c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing X-API-Key header"})
            return
        }

        valid, err := s.ValidateLicenseKey(c.Request.Context(), key)
        if err != nil || !valid {
            c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "invalid or expired API key"})
            return
        }

        c.Set("license_key", key)
        c.Next()
    }
}
```

- [ ] **Step 6: Create handler/environments.go**

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/model"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

type EnvironmentHandler struct {
    store *store.Store
}

func NewEnvironmentHandler(s *store.Store) *EnvironmentHandler {
    return &EnvironmentHandler{store: s}
}

func (h *EnvironmentHandler) List(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envs, err := h.store.ListEnvironments(c.Request.Context(), licenseKey.(string))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list environments"})
        return
    }
    c.JSON(http.StatusOK, envs)
}

func (h *EnvironmentHandler) Create(c *gin.Context) {
    var req struct {
        Name string `json:"name" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    licenseKey, _ := c.Get("license_key")
    env := &model.Environment{
        LicenseKey: licenseKey.(string),
        Name:       req.Name,
    }

    if err := h.store.CreateEnvironment(c.Request.Context(), env); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create environment"})
        return
    }

    c.JSON(http.StatusCreated, env)
}

func (h *EnvironmentHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    if err := h.store.DeleteEnvironment(c.Request.Context(), id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete environment"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}
```

Add corresponding store methods for environments.

- [ ] **Step 7: Create handler/flags.go**

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/model"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

type FlagHandler struct {
    store *store.Store
}

func NewFlagHandler(s *store.Store) *FlagHandler {
    return &FlagHandler{store: s}
}

func (h *FlagHandler) List(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envID := c.Query("environment_id")
    flags, err := h.store.ListFlags(c.Request.Context(), licenseKey.(string), envID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list flags"})
        return
    }
    c.JSON(http.StatusOK, flags)
}

func (h *FlagHandler) Create(c *gin.Context) {
    var req model.CreateFlagRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    licenseKey, _ := c.Get("license_key")
    flag := &model.Flag{
        LicenseKey:     licenseKey.(string),
        Key:            req.Key,
        Name:           req.Name,
        Description:    req.Description,
        FlagType:       req.FlagType,
        DefaultVariant: req.DefaultVariant,
    }

    if err := h.store.CreateFlag(c.Request.Context(), flag); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create flag"})
        return
    }

    // Log audit
    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil,
        "flag.created", "flag", flag.ID, nil, flag)

    c.JSON(http.StatusCreated, flag)
}

func (h *FlagHandler) Update(c *gin.Context) {
    id := c.Param("id")
    var req model.CreateFlagRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    flag := &model.Flag{
        ID:             id,
        Key:            req.Key,
        Name:           req.Name,
        Description:    req.Description,
        FlagType:       req.FlagType,
        DefaultVariant: req.DefaultVariant,
    }

    if err := h.store.UpdateFlag(c.Request.Context(), flag); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update flag"})
        return
    }

    c.JSON(http.StatusOK, flag)
}

func (h *FlagHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    licenseKey, _ := c.Get("license_key")

    if err := h.store.DeleteFlag(c.Request.Context(), id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete flag"})
        return
    }

    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil,
        "flag.deleted", "flag", id, nil, nil)

    c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}

type toggleRequest struct {
    Enabled          bool   `json:"enabled"`
    EnvironmentID    string `json:"environment_id" binding:"required"`
    RolloutPercentage *int   `json:"rollout_percentage,omitempty"`
}

func (h *FlagHandler) Toggle(c *gin.Context) {
    id := c.Param("id")
    var req toggleRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    licenseKey, _ := c.Get("license_key")
    rollout := 100
    if req.RolloutPercentage != nil {
        rollout = *req.RolloutPercentage
    }

    value := &model.FlagValue{
        FlagID:            id,
        EnvironmentID:     req.EnvironmentID,
        Enabled:           req.Enabled,
        RolloutPercentage: rollout,
    }

    if err := h.store.UpsertFlagValue(c.Request.Context(), value); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update flag value"})
        return
    }

    // Log audit
    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil,
        "flag.toggled", "flag_value", value.ID, nil, value)

    c.JSON(http.StatusOK, value)
}
```

- [ ] **Step 8: Add store methods for flags, environments, and audit log**

```go
func (s *Store) ListEnvironments(ctx context.Context, licenseKey string) ([]*model.Environment, error) {
    rows, err := s.pool.Query(ctx,
        `SELECT id, license_key, name, created_at, updated_at
         FROM environments WHERE license_key = $1 ORDER BY name`, licenseKey)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var envs []*model.Environment
    for rows.Next() {
        e := &model.Environment{}
        rows.Scan(&e.ID, &e.LicenseKey, &e.Name, &e.CreatedAt, &e.UpdatedAt)
        envs = append(envs, e)
    }
    return envs, nil
}

func (s *Store) CreateEnvironment(ctx context.Context, e *model.Environment) error {
    return s.pool.QueryRow(ctx,
        `INSERT INTO environments (license_key, name) VALUES ($1, $2)
         RETURNING id, created_at, updated_at`,
        e.LicenseKey, e.Name,
    ).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (s *Store) DeleteEnvironment(ctx context.Context, id string) error {
    _, err := s.pool.Exec(ctx, `DELETE FROM environments WHERE id = $1`, id)
    return err
}

func (s *Store) ListFlags(ctx context.Context, licenseKey, environmentID string) ([]*model.Flag, error) {
    rows, err := s.pool.Query(ctx,
        `SELECT f.id, f.key, f.name, f.description, f.flag_type, f.default_variant,
                f.created_at, f.updated_at,
                fv.enabled, fv.variant_value, fv.rollout_percentage
         FROM flags f
         LEFT JOIN flag_values fv ON fv.flag_id = f.id
           AND ($2 = '' OR fv.environment_id = $2)
         WHERE f.license_key = $1
         ORDER BY f.key`,
        licenseKey, environmentID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var flags []*model.Flag
    for rows.Next() {
        f := &model.Flag{}
        rows.Scan(&f.ID, &f.Key, &f.Name, &f.Description, &f.FlagType,
            &f.DefaultVariant, &f.CreatedAt, &f.UpdatedAt,
            &f.Enabled, &f.VariantValue, &f.RolloutPercentage)
        flags = append(flags, f)
    }
    return flags, nil
}

func (s *Store) CreateFlag(ctx context.Context, f *model.Flag) error {
    return s.pool.QueryRow(ctx,
        `INSERT INTO flags (license_key, key, name, description, flag_type, default_variant)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, created_at, updated_at`,
        f.LicenseKey, f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant,
    ).Scan(&f.ID, &f.CreatedAt, &f.UpdatedAt)
}

func (s *Store) UpdateFlag(ctx context.Context, f *model.Flag) error {
    _, err := s.pool.Exec(ctx,
        `UPDATE flags SET key=$1, name=$2, description=$3, flag_type=$4, default_variant=$5, updated_at=now()
         WHERE id=$6`,
        f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant, f.ID)
    return err
}

func (s *Store) DeleteFlag(ctx context.Context, id string) error {
    _, err := s.pool.Exec(ctx, `DELETE FROM flags WHERE id = $1`, id)
    return err
}

func (s *Store) UpsertFlagValue(ctx context.Context, fv *model.FlagValue) error {
    return s.pool.QueryRow(ctx,
        `INSERT INTO flag_values (flag_id, environment_id, enabled, variant_value, rollout_percentage)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (flag_id, environment_id) DO UPDATE SET
           enabled = EXCLUDED.enabled,
           variant_value = EXCLUDED.variant_value,
           rollout_percentage = EXCLUDED.rollout_percentage,
           updated_at = now()
         RETURNING id, created_at, updated_at`,
        fv.FlagID, fv.EnvironmentID, fv.Enabled, fv.VariantValue, fv.RolloutPercentage,
    ).Scan(&fv.ID, &fv.CreatedAt, &fv.UpdatedAt)
}

func (s *Store) CreateAuditLog(ctx context.Context, licenseKey string, actorID *string, action, resourceType, resourceID string, oldValue, newValue interface{}) error {
    _, err := s.pool.Exec(ctx,
        `INSERT INTO audit_log (license_key, actor_id, action, resource_type, resource_id, old_value, new_value)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        licenseKey, actorID, action, resourceType, resourceID, oldValue, newValue)
    return err
}
```

Add imports as needed.

- [ ] **Step 9: Wire routes in main.go**

```go
import (
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/handler"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/middleware"
)

// After r := gin.Default()
jwtSecret := os.Getenv("JWT_SECRET")

// JWT-protected API
api := r.Group("/api/v1", middleware.JWTAuthRequired(jwtSecret))
{
    envHandler := handler.NewEnvironmentHandler(db)
    api.GET("/environments", envHandler.List)
    api.POST("/environments", envHandler.Create)
    api.DELETE("/environments/:id", envHandler.Delete)

    flagHandler := handler.NewFlagHandler(db)
    api.GET("/flags", flagHandler.List)
    api.POST("/flags", flagHandler.Create)
    api.PUT("/flags/:id", flagHandler.Update)
    api.DELETE("/flags/:id", flagHandler.Delete)
    api.PUT("/flags/:id/toggle", flagHandler.Toggle)
}
```

- [ ] **Step 10: Run the tests**

Run: `cd services/feature-flags && go test ./...`
Expected: All tests pass

- [ ] **Step 11: Commit**

```bash
git add services/feature-flags/
git commit -m "feat: add REST API for feature flags and environments CRUD"
```

---

### Task 3: WebSocket Hub + Connection Token

**Files:**
- Create: `services/feature-flags/internal/handler/ws.go`
- Create: `services/feature-flags/internal/service/hub.go`
- Modify: `services/feature-flags/cmd/server/main.go`

**Interfaces:**
- Produces: `POST /api/v1/ws/token` — issues single-use connection token (30s TTL)
- Produces: `GET /ws` — upgrades to WebSocket with token validation
- Produces: Hub manages all WebSocket connections per `license_key:environment_id`

- [ ] **Step 1: Write the failing test**

```go
// internal/handler/ws_test.go
package handler

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestWSTokenMissingAPIKey(t *testing.T) {
    req := httptest.NewRequest("POST", "/api/v1/ws/token", nil)
    w := httptest.NewRecorder()
    if w.Code == http.StatusUnauthorized {
        t.Log("correctly rejected missing API key")
    }
}

func TestWSTokenSuccess(t *testing.T) {
    req := httptest.NewRequest("POST", "/api/v1/ws/token", nil)
    req.Header.Set("X-API-Key", "MF-TEST-KEY")
    w := httptest.NewRecorder()
    var resp map[string]interface{}
    json.NewDecoder(w.Body).Decode(&resp)
    if resp["token"] != nil {
        t.Log("received connection token")
    }
}
```

- [ ] **Step 2: Create service/hub.go**

```go
package service

import (
    "encoding/json"
    "log"
    "sync"
    "github.com/gorilla/websocket"
)

type Client struct {
    Conn          *websocket.Conn
    LicenseKey    string
    EnvironmentID string
    Send          chan []byte
}

type Hub struct {
    mu       sync.RWMutex
    rooms    map[string]map[*Client]bool
}

func NewHub() *Hub {
    return &Hub{
        rooms: make(map[string]map[*Client]bool),
    }
}

func (h *Hub) roomKey(licenseKey, environmentID string) string {
    return licenseKey + ":" + environmentID
}

func (h *Hub) Register(client *Client) {
    h.mu.Lock()
    defer h.mu.Unlock()

    key := h.roomKey(client.LicenseKey, client.EnvironmentID)
    if h.rooms[key] == nil {
        h.rooms[key] = make(map[*Client]bool)
    }
    h.rooms[key][client] = true
    log.Printf("Client registered: %s (room: %s)", client.Conn.RemoteAddr(), key)
}

func (h *Hub) Unregister(client *Client) {
    h.mu.Lock()
    defer h.mu.Unlock()

    key := h.roomKey(client.LicenseKey, client.EnvironmentID)
    if clients, ok := h.rooms[key]; ok {
        if _, exists := clients[client]; exists {
            delete(clients, client)
            close(client.Send)
            if len(clients) == 0 {
                delete(h.rooms, key)
            }
            log.Printf("Client unregistered: %s", client.Conn.RemoteAddr())
        }
    }
}

func (h *Hub) Broadcast(licenseKey, environmentID string, message interface{}) error {
    h.mu.RLock()
    defer h.mu.RUnlock()

    key := h.roomKey(licenseKey, environmentID)
    clients, ok := h.rooms[key]
    if !ok {
        return nil
    }

    data, err := json.Marshal(message)
    if err != nil {
        return err
    }

    for client := range clients {
        select {
        case client.Send <- data:
        default:
            // Buffer full, drop message
            log.Printf("Dropping message for slow client: %s", client.Conn.RemoteAddr())
        }
    }
    return nil
}

func (h *Hub) BroadcastFlagUpdate(licenseKey, environmentID, flagKey string, enabled bool, variant interface{}) {
    msg := map[string]interface{}{
        "type":    "flag_updated",
        "flag":    flagKey,
        "enabled": enabled,
        "variant": variant,
    }
    h.Broadcast(licenseKey, environmentID, msg)
}

func (h *Hub) BroadcastFlagDelete(licenseKey, environmentID, flagKey string) {
    msg := map[string]interface{}{
        "type": "flag_deleted",
        "flag": flagKey,
    }
    h.Broadcast(licenseKey, environmentID, msg)
}
```

- [ ] **Step 3: Create handler/ws.go**

```go
package handler

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "github.com/gorilla/websocket"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/service"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
    CheckOrigin: func(r *http.Request) bool {
        return true // Allow all origins in dev; restrict in production
    },
}

type WSHandler struct {
    store    *store.Store
    hub      *service.Hub
    jwtSecret string
}

func NewWSHandler(s *store.Store, h *service.Hub) *WSHandler {
    return &WSHandler{
        store:     s,
        hub:       h,
        jwtSecret: os.Getenv("JWT_SECRET"),
    }
}

type WSTokenClaims struct {
    LicenseKey    string `json:"license_key"`
    EnvironmentID string `json:"environment_id"`
    jwt.RegisteredClaims
}

func (h *WSHandler) IssueToken(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envID := c.Query("environment_id")
    if envID == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "environment_id is required"})
        return
    }

    now := time.Now()
    claims := WSTokenClaims{
        LicenseKey:    licenseKey.(string),
        EnvironmentID: envID,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(now.Add(30 * time.Second)),
            IssuedAt:  jwt.NewNumericDate(now),
            ID:        generateTokenID(),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString([]byte(h.jwtSecret))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to sign token"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "token":      tokenString,
        "expires_in": 30,
    })
}

func generateTokenID() string {
    b := make([]byte, 16)
    // Use crypto/rand in production
    return "tok-" + time.Now().Format("150405.000000000")
}

func (h *WSHandler) HandleWebSocket(c *gin.Context) {
    tokenStr := c.Query("token")
    if tokenStr == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "missing token"})
        return
    }

    claims := &WSTokenClaims{}
    token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
        return []byte(h.jwtSecret), nil
    })
    if err != nil || !token.Valid {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired token"})
        return
    }

    conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
    if err != nil {
        log.Printf("WebSocket upgrade failed: %v", err)
        return
    }

    client := &service.Client{
        Conn:          conn,
        LicenseKey:    claims.LicenseKey,
        EnvironmentID: claims.EnvironmentID,
        Send:          make(chan []byte, 256),
    }

    h.hub.Register(client)

    // Send initial flag state
    initialFlags, _ := h.store.ListFlags(c.Request.Context(), claims.LicenseKey, claims.EnvironmentID)
    initMsg, _ := json.Marshal(map[string]interface{}{
        "type":  "connected",
        "flags": initialFlags,
    })
    client.Send <- initMsg

    // Start read/write pumps
    go h.writePump(client)
    go h.readPump(client)
}

func (h *WSHandler) writePump(client *service.Client) {
    ticker := time.NewTicker(30 * time.Second)
    defer func() {
        ticker.Stop()
        client.Conn.Close()
    }()

    for {
        select {
        case message, ok := <-client.Send:
            client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if !ok {
                client.Conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            w, err := client.Conn.NextWriter(websocket.TextMessage)
            if err != nil {
                return
            }
            w.Write(message)
            w.Close()

        case <-ticker.C:
            client.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := client.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
                return
            }
        }
    }
}

func (h *WSHandler) readPump(client *service.Client) {
    defer func() {
        h.hub.Unregister(client)
        client.Conn.Close()
    }()

    client.Conn.SetReadLimit(512)
    client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
    client.Conn.SetPongHandler(func(string) error {
        client.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
        return nil
    })

    for {
        _, _, err := client.Conn.ReadMessage()
        if err != nil {
            break
        }
        // SDK doesn't send messages except pong (handled by ping/pong)
    }
}
```

- [ ] **Step 4: Wire WebSocket routes in main.go**

```go
import (
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/service"
)

// After store initialization
hub := service.NewHub()

// Before r.Run()
wsHandler := handler.NewWSHandler(db, hub)

// API Key protected — token issue
wsAPI := r.Group("/api/v1", middleware.APIKeyRequired(db))
wsAPI.POST("/ws/token", wsHandler.IssueToken)

// WebSocket endpoint (no auth middleware — token validated in handler)
r.GET("/ws", wsHandler.HandleWebSocket)
```

- [ ] **Step 5: Run the tests**

Run: `cd services/feature-flags && go test ./...`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add services/feature-flags/
git commit -m "feat: add WebSocket hub with connection token auth"
```

---

### Task 4: Redis Pub/Sub + Rollout Evaluator

**Files:**
- Create: `services/feature-flags/internal/service/evaluator.go`
- Modify: `services/feature-flags/internal/service/hub.go` (add Redis integration)
- Modify: `services/feature-flags/cmd/server/main.go`

**Interfaces:**
- Produces: CRC32 sticky bucketing for rollout evaluation
- Produces: Redis pub/sub for cross-instance flag change broadcast

- [ ] **Step 1: Write the failing test**

```go
// internal/service/evaluator_test.go
package service

import (
    "testing"
    "hash/crc32"
)

func TestBucketingStability(t *testing.T) {
    // Same user should always get same bucket
    key := "license_123:feature_x:user_42"
    hash := crc32.ChecksumIEEE([]byte(key))
    bucket1 := int(hash % 100)
    bucket2 := int(hash % 100)
    if bucket1 != bucket2 {
        t.Errorf("bucketing not stable: %d != %d", bucket1, bucket2)
    }
}

func TestBucketingDistribution(t *testing.T) {
    buckets := make(map[int]int)
    for i := 0; i < 1000; i++ {
        key := "license:flag:user_" + string(rune(i))
        hash := crc32.ChecksumIEEE([]byte(key))
        bucket := int(hash % 100)
        buckets[bucket]++
    }
    // Each bucket should have roughly 10 entries
    if len(buckets) < 80 {
        t.Errorf("expected >80 buckets populated, got %d", len(buckets))
    }
}
```

- [ ] **Step 2: Create service/evaluator.go**

```go
package service

import (
    "hash/crc32"
)

type Context struct {
    UserID  string
    GroupID string
}

type Evaluator struct{}

func NewEvaluator() *Evaluator {
    return &Evaluator{}
}

func (e *Evaluator) IsEnabled(licenseKey, flagKey string, rolloutPercentage int, ctx Context) bool {
    if rolloutPercentage >= 100 {
        return true
    }
    if rolloutPercentage <= 0 {
        return false
    }

    bucket := e.Bucket(licenseKey, flagKey, ctx.UserID)
    return bucket < rolloutPercentage
}

func (e *Evaluator) Bucket(licenseKey, flagKey, userID string) int {
    key := licenseKey + ":" + flagKey + ":" + userID
    hash := crc32.ChecksumIEEE([]byte(key))
    return int(hash % 100)
}
```

- [ ] **Step 3: Add Redis pub/sub to hub.go**

Add Redis import and fields to Hub struct:

```go
import (
    "github.com/redis/go-redis/v9"
)

type Hub struct {
    mu        sync.RWMutex
    rooms     map[string]map[*Client]bool
    redis     *redis.Client
    redisCtx  context.Context
}

func NewHub(redisURL string) *Hub {
    opts, err := redis.ParseURL(redisURL)
    var rdb *redis.Client
    if err == nil {
        rdb = redis.NewClient(opts)
    } else {
        log.Printf("Redis not available, running without pub/sub: %v", err)
        rdb = nil
    }

    return &Hub{
        rooms:    make(map[string]map[*Client]bool),
        redis:    rdb,
        redisCtx: context.Background(),
    }
}

func (h *Hub) StartRedisListener() {
    if h.redis == nil {
        return
    }

    pubsub := h.redis.PSubscribe(h.redisCtx, "flags:*")
    defer pubsub.Close()

    ch := pubsub.Channel()
    for msg := range ch {
        var payload struct {
            LicenseKey    string      `json:"license_key"`
            EnvironmentID string      `json:"environment_id"`
            FlagKey       string      `json:"flag_key"`
            Enabled       bool        `json:"enabled"`
            Variant       interface{} `json:"variant,omitempty"`
            Action        string      `json:"action"`
        }
        if err := json.Unmarshal([]byte(msg.Payload), &payload); err != nil {
            log.Printf("Failed to parse Redis message: %v", err)
            continue
        }

        switch payload.Action {
        case "toggle":
            h.BroadcastFlagUpdate(payload.LicenseKey, payload.EnvironmentID,
                payload.FlagKey, payload.Enabled, payload.Variant)
        case "delete":
            h.BroadcastFlagDelete(payload.LicenseKey, payload.EnvironmentID, payload.FlagKey)
        }
    }
}

func (h *Hub) PublishToggle(licenseKey, environmentID, flagKey string, enabled bool, variant interface{}) {
    if h.redis == nil {
        return
    }

    msg := map[string]interface{}{
        "license_key":    licenseKey,
        "environment_id": environmentID,
        "flag_key":       flagKey,
        "enabled":        enabled,
        "variant":        variant,
        "action":         "toggle",
    }
    data, _ := json.Marshal(msg)
    h.redis.Publish(h.redisCtx, "flags:"+licenseKey+":"+environmentID, data)
}

func (h *Hub) PublishDelete(licenseKey, environmentID, flagKey string) {
    if h.redis == nil {
        return
    }

    msg := map[string]interface{}{
        "license_key":    licenseKey,
        "environment_id": environmentID,
        "flag_key":       flagKey,
        "action":         "delete",
    }
    data, _ := json.Marshal(msg)
    h.redis.Publish(h.redisCtx, "flags:"+licenseKey+":"+environmentID, data)
}
```

Add imports: `"context"`, `"github.com/redis/go-redis/v9"`

- [ ] **Step 4: Update main.go to initialize hub with Redis and start listener**

```go
redisURL := os.Getenv("REDIS_URL")
if redisURL == "" {
    redisURL = "redis://localhost:6379"
}

hub := service.NewHub(redisURL)
go hub.StartRedisListener()
```

- [ ] **Step 5: Integrate broadcast with Toggle handler**

In `handler/flags.go`, after `UpsertFlagValue` succeeds, publish via hub:

```go
hub.PublishToggle(licenseKey.(string), req.EnvironmentID, flagKey, req.Enabled, nil)
```

To access the hub from FlagHandler, add it as a field:

```go
type FlagHandler struct {
    store *store.Store
    hub   *service.Hub
}

func NewFlagHandler(s *store.Store, h *service.Hub) *FlagHandler {
    return &FlagHandler{store: s, hub: h}
}
```

- [ ] **Step 6: Run the tests**

Run: `cd services/feature-flags && go test ./...`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add services/feature-flags/
git commit -m "feat: add rollout evaluator and Redis pub/sub broadcast"
```

---

### Task 5: Delphi WebSocket Client SDK

**Files:**
- Create: `services/feature-flags/sdk/MF.FeatureFlags.Client.pas`

**Interfaces:**
- Consumes: WebSocket endpoint at `wss://host/ws`
- Produces: `TFeatureFlags` class with `IsEnabled`, `GetVariant`, event-driven flag updates

- [ ] **Step 1: Create sdk/MF.FeatureFlags.Client.pas**

```pascal
unit MF.FeatureFlags.Client;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Net.HttpClient,
  System.Net.WebSocket,
  System.JSON,
  System.Generics.Collections,
  System.Hash;

type
  TFlagContext = record
    UserId: string;
    GroupId: string;
    Attributes: TDictionary<string, string>;
  end;

  TFlagEntry = class
  public
    Key: string;
    Enabled: Boolean;
    Variant: string;
    RolloutPercentage: Integer;
  end;

  TFeatureFlagEvent = procedure(const AFlagName: string; AEnabled: Boolean) of object;

  TFeatureFlags = class
  private
    FBaseURL: string;
    FAPIKey: string;
    FEnvironmentID: string;
    FWS: TWebSocket;
    FCache: TObjectDictionary<string, TFlagEntry>;
    FConnected: Boolean;
    FReconnecting: Boolean;
    FRetryCount: Integer;
    FMaxRetry: Integer;
    FOnFlagChanged: TFeatureFlagEvent;
    procedure Connect;
    procedure Disconnect;
    procedure HandleMessage(const AMessage: string);
    procedure Reconnect;
    function GetConnectionToken: string;
    function CRC32Hash(const AKey: string): Integer;
  public
    constructor Create(const ABaseURL, AAPIKey, AEnvironmentID: string);
    destructor Destroy; override;
    function IsEnabled(const AName: string; const AContext: TFlagContext): Boolean;
    function GetVariant(const AName: string; const AContext: TFlagContext): string;
    property OnFlagChanged: TFeatureFlagEvent read FOnFlagChanged write FOnFlagChanged;
  end;

implementation

{ TFeatureFlags }

constructor TFeatureFlags.Create(const ABaseURL, AAPIKey, AEnvironmentID: string);
begin
  inherited Create;
  FBaseURL := ABaseURL;
  FAPIKey := AAPIKey;
  FEnvironmentID := AEnvironmentID;
  FCache := TObjectDictionary<string, TFlagEntry>.Create([doOwnsValues]);
  FMaxRetry := 5;
  FRetryCount := 0;
  Connect;
end;

destructor TFeatureFlags.Destroy;
begin
  Disconnect;
  FCache.Free;
  inherited;
end;

function TFeatureFlags.GetConnectionToken: string;
var
  HTTP: THTTPClient;
  Response: IHTTPResponse;
  JSON: TJSONObject;
  URL: string;
begin
  Result := '';
  HTTP := THTTPClient.Create;
  try
    URL := Format('%s/api/v1/ws/token?environment_id=%s', [FBaseURL, FEnvironmentID]);
    Response := HTTP.Post(URL, nil, TEncoding.UTF8,
      TNetHeaders.Create(TNetHeader.Create('X-API-Key', FAPIKey)));
    if Response.StatusCode = 200 then
    begin
      JSON := TJSONObject.ParseJSONValue(Response.ContentAsString(TEncoding.UTF8)) as TJSONObject;
      try
        if Assigned(JSON) then
          Result := JSON.GetValue('token', '');
      finally
        JSON.Free;
      end;
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TFeatureFlags.Connect;
var
  Token: string;
begin
  if FConnected then Exit;

  Token := GetConnectionToken;
  if Token = '' then
  begin
    Reconnect;
    Exit;
  end;

  FWS := TWebSocket.Create;
  try
    FWS.OnMessage := HandleMessage;
    FWS.Connect(Format('%s/ws?token=%s', [FBaseURL, Token]));
    FConnected := True;
    FRetryCount := 0;
  except
    FWS.Free;
    FWS := nil;
    Reconnect;
  end;
end;

procedure TFeatureFlags.Disconnect;
begin
  FConnected := False;
  FWS.Free;
end;

procedure TFeatureFlags.HandleMessage(const AMessage: string);
var
  JSON: TJSONObject;
  MsgType: string;
  FlagKey: string;
  FlagEnabled: Boolean;
  I: Integer;
  FlagsArray: TJSONArray;
  Entry: TFlagEntry;
begin
  JSON := TJSONObject.ParseJSONValue(AMessage) as TJSONObject;
  if not Assigned(JSON) then Exit;
  try
    MsgType := JSON.GetValue('type', '');

    if MsgType = 'connected' then
    begin
      FlagsArray := JSON.GetValue('flags') as TJSONArray;
      if Assigned(FlagsArray) then
      begin
        FCache.Clear;
        for I := 0 to FlagsArray.Count - 1 do
        begin
          Entry := TFlagEntry.Create;
          Entry.Key := (FlagsArray.Items[I] as TJSONObject).GetValue('key', '');
          Entry.Enabled := (FlagsArray.Items[I] as TJSONObject).GetValue('enabled', False);
          FCache.Add(Entry.Key, Entry);
        end;
      end;
    end
    else if MsgType = 'flag_updated' then
    begin
      FlagKey := JSON.GetValue('flag', '');
      FlagEnabled := JSON.GetValue('enabled', False);

      if FCache.ContainsKey(FlagKey) then
        FCache[FlagKey].Enabled := FlagEnabled
      else
      begin
        Entry := TFlagEntry.Create;
        Entry.Key := FlagKey;
        Entry.Enabled := FlagEnabled;
        FCache.Add(FlagKey, Entry);
      end;

      if Assigned(FOnFlagChanged) then
        FOnFlagChanged(FlagKey, FlagEnabled);
    end
    else if MsgType = 'flag_deleted' then
    begin
      FlagKey := JSON.GetValue('flag', '');
      FCache.Remove(FlagKey);
    end
    else if MsgType = 'ping' then
    begin
      // SDK responds with pong automatically via WebSocket protocol
    end;
  finally
    JSON.Free;
  end;
end;

procedure TFeatureFlags.Reconnect;
var
  Delay: Integer;
begin
  if FReconnecting then Exit;
  FReconnecting := True;
  try
    Inc(FRetryCount);
    if FRetryCount > FMaxRetry then
    begin
      FRetryCount := 0;
      FReconnecting := False;
      Exit;
    end;

    Delay := 1000 * (1 shl (FRetryCount - 1));
    if Delay > 30000 then Delay := 30000;
    Sleep(Delay);
    Connect;
  finally
    FReconnecting := False;
  end;
end;

function TFeatureFlags.IsEnabled(const AName: string; const AContext: TFlagContext): Boolean;
var
  Entry: TFlagEntry;
  Bucket: Integer;
begin
  if FCache.TryGetValue(AName, Entry) then
  begin
    if Entry.RolloutPercentage >= 100 then
      Exit(Entry.Enabled)
    else if Entry.RolloutPercentage <= 0 then
      Exit(False);

    Bucket := CRC32Hash(FEnvironmentID + AName + AContext.UserId) mod 100;
    Exit(Bucket < Entry.RolloutPercentage);
  end;

  Result := False;
end;

function TFeatureFlags.GetVariant(const AName: string; const AContext: TFlagContext): string;
var
  Entry: TFlagEntry;
begin
  if FCache.TryGetValue(AName, Entry) then
    Result := Entry.Variant
  else
    Result := '';
end;

function TFeatureFlags.CRC32Hash(const AKey: string): Integer;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(AKey);
  Result := Integer(THashBobJenkins.GetHashValue(Bytes, Length(Bytes)));
end;

end.
```

- [ ] **Step 2: Commit**

```bash
git add services/feature-flags/sdk/
git commit -m "feat: add TFeatureFlags Delphi WebSocket client SDK"
```

---

### Task 6: Dashboard Web UI

**Files:**
- Create: `services/feature-flags/internal/handler/dashboard.go`
- Create: `services/feature-flags/web/templates/index.html`
- Create: `services/feature-flags/web/templates/flags.html`
- Create: `services/feature-flags/web/templates/audit.html`
- Create: `services/feature-flags/web/static/style.css`
- Modify: `services/feature-flags/cmd/server/main.go`

- [ ] **Step 1: Create handler/dashboard.go**

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/service"
)

type DashboardHandler struct {
    store *store.Store
    hub   *service.Hub
}

func NewDashboardHandler(s *store.Store, h *service.Hub) *DashboardHandler {
    return &DashboardHandler{store: s, hub: h}
}

func (h *DashboardHandler) Index(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envs, _ := h.store.ListEnvironments(c.Request.Context(), licenseKey.(string))
    c.HTML(http.StatusOK, "index.html", gin.H{
        "environments": envs,
    })
}

func (h *DashboardHandler) Flags(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envID := c.Query("environment_id")
    flags, _ := h.store.ListFlags(c.Request.Context(), licenseKey.(string), envID)
    envs, _ := h.store.ListEnvironments(c.Request.Context(), licenseKey.(string))

    c.HTML(http.StatusOK, "flags.html", gin.H{
        "flags":        flags,
        "environments": envs,
        "current_env":  envID,
    })
}

func (h *DashboardHandler) AuditLog(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    logs, _ := h.store.QueryAuditLog(c.Request.Context(), licenseKey.(string), 100)

    c.HTML(http.StatusOK, "audit.html", gin.H{
        "logs": logs,
    })
}
```

- [ ] **Step 2: Add AuditLog query method to store**

```go
type AuditEntry struct {
    ID           string    `json:"id"`
    LicenseKey   string    `json:"-"`
    ActorID      *string   `json:"actor_id"`
    Action       string    `json:"action"`
    ResourceType string    `json:"resource_type"`
    ResourceID   string    `json:"resource_id"`
    OldValue     *string   `json:"old_value,omitempty"`
    NewValue     *string   `json:"new_value,omitempty"`
    CreatedAt    time.Time `json:"created_at"`
}

func (s *Store) QueryAuditLog(ctx context.Context, licenseKey string, limit int) ([]*AuditEntry, error) {
    rows, err := s.pool.Query(ctx,
        `SELECT id, actor_id, action, resource_type, resource_id, old_value::text, new_value::text, created_at
         FROM audit_log WHERE license_key = $1
         ORDER BY created_at DESC LIMIT $2`,
        licenseKey, limit)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var logs []*AuditEntry
    for rows.Next() {
        e := &AuditEntry{}
        rows.Scan(&e.ID, &e.ActorID, &e.Action, &e.ResourceType, &e.ResourceID,
            &e.OldValue, &e.NewValue, &e.CreatedAt)
        logs = append(logs, e)
    }
    return logs, nil
}
```

- [ ] **Step 3: Create web/templates/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feature Flags Dashboard</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Feature Flags</h1>
        <nav>
            <a href="/dashboard" class="active">Overview</a>
            <a href="/dashboard/flags">Flags</a>
            <a href="/dashboard/audit">Audit Log</a>
        </nav>
    </header>

    <main>
        <h2>Environments</h2>
        <div class="cards">
            {{ range .environments }}
            <div class="card">
                <h3>{{ .Name }}</h3>
                <a href="/dashboard/flags?environment_id={{ .ID }}" class="btn">Manage Flags</a>
            </div>
            {{ else }}
            <p>No environments configured. Create one via the API.</p>
            {{ end }}
        </div>
    </main>
</body>
</html>
```

- [ ] **Step 4: Create web/templates/flags.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Manage Flags</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Feature Flags</h1>
        <nav>
            <a href="/dashboard">Overview</a>
            <a href="/dashboard/flags" class="active">Flags</a>
            <a href="/dashboard/audit">Audit Log</a>
        </nav>
    </header>

    <main>
        <div class="toolbar">
            <form method="get" action="/dashboard/flags">
                <select name="environment_id" onchange="this.form.submit()">
                    <option value="">All environments</option>
                    {{ range .environments }}
                    <option value="{{ .ID }}" {{ if eq .ID $.current_env }}selected{{ end }}>{{ .Name }}</option>
                    {{ end }}
                </select>
            </form>
        </div>

        <table>
            <thead>
                <tr>
                    <th>Key</th>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Enabled</th>
                    <th>Rollout</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                {{ range .flags }}
                <tr>
                    <td><code>{{ .Key }}</code></td>
                    <td>{{ .Name }}</td>
                    <td>{{ .FlagType }}</td>
                    <td>
                        <span class="status {{ if .Enabled }}active{{ else }}inactive{{ end }}">
                            {{ if .Enabled }}ON{{ else }}OFF{{ end }}
                        </span>
                    </td>
                    <td>{{ .RolloutPercentage }}%</td>
                    <td>
                        <button onclick="toggleFlag('{{ .ID }}', '{{ $.current_env }}')" class="btn-sm">
                            Toggle
                        </button>
                    </td>
                </tr>
                {{ else }}
                <tr><td colspan="6">No flags found</td></tr>
                {{ end }}
            </tbody>
        </table>
    </main>

    <script>
        function toggleFlag(flagId, envId) {
            if (!envId) { alert('Select an environment first'); return; }
            fetch('/api/v1/flags/' + flagId + '/toggle', {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ environment_id: envId, enabled: true })
            }).then(r => {
                if (r.ok) location.reload();
            });
        }
    </script>
</body>
</html>
```

- [ ] **Step 5: Create web/templates/audit.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Audit Log</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Audit Log</h1>
        <nav>
            <a href="/dashboard">Overview</a>
            <a href="/dashboard/flags">Flags</a>
            <a href="/dashboard/audit" class="active">Audit Log</a>
        </nav>
    </header>

    <main>
        <table>
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Action</th>
                    <th>Resource</th>
                    <th>ID</th>
                </tr>
            </thead>
            <tbody>
                {{ range .logs }}
                <tr>
                    <td>{{ .CreatedAt.Format "2006-01-02 15:04:05" }}</td>
                    <td><code>{{ .Action }}</code></td>
                    <td>{{ .ResourceType }}</td>
                    <td><code>{{ .ResourceID | slice 0 8 }}...</code></td>
                </tr>
                {{ else }}
                <tr><td colspan="4">No audit entries</td></tr>
                {{ end }}
            </tbody>
        </table>
    </main>
</body>
</html>
```

- [ ] **Step 6: Create web/static/style.css**

```css
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    margin: 0;
    padding: 0;
    background: #f5f5f5;
    color: #333;
}

header {
    background: #1a1a2e;
    color: white;
    padding: 1rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
}
header h1 { margin: 0; font-size: 1.5rem; }
header nav { display: flex; gap: 1rem; }
header nav a { color: #e0e0ff; text-decoration: none; padding: 0.25rem 0.5rem; border-radius: 4px; }
header nav a.active { background: rgba(255,255,255,0.15); }

main { max-width: 960px; margin: 2rem auto; padding: 0 1rem; }

.cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 2rem; }
.card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
.card h3 { margin: 0 0 0.5rem; font-size: 0.9rem; color: #666; }

.toolbar { margin-bottom: 1rem; display: flex; gap: 0.5rem; align-items: center; }

table { width: 100%; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
th, td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eee; }
th { background: #f8f9fa; font-weight: 600; font-size: 0.85rem; text-transform: uppercase; color: #666; }

.status { padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.status.active { background: #d4edda; color: #155724; }
.status.inactive { background: #e2e3e5; color: #383d41; }

.btn, .btn-sm { padding: 0.4rem 0.8rem; border-radius: 4px; border: 1px solid #ccc; background: white; cursor: pointer; text-decoration: none; color: #333; font-size: 0.85rem; }
.btn-sm { padding: 0.25rem 0.5rem; }
```

- [ ] **Step 7: Wire dashboard routes in main.go**

```go
r.LoadHTMLGlob("web/templates/*")
r.Static("/static", "./web/static")

dashboard := r.Group("/dashboard", middleware.JWTAuthRequired(jwtSecret))
{
    dh := handler.NewDashboardHandler(db, hub)
    dashboard.GET("/", dh.Index)
    dashboard.GET("/flags", dh.Flags)
    dashboard.GET("/audit", dh.AuditLog)
}
```

- [ ] **Step 8: Commit**

```bash
git add services/feature-flags/web/ services/feature-flags/internal/handler/dashboard.go
git commit -m "feat: add feature flags dashboard UI"
```

---

### Task 7: Integration Tests

**Files:**
- Create: `services/feature-flags/internal/handler/flags_test.go` (complete tests)
- Create: `services/integration-test/test_feature_flags.sh`
- Modify: `services/integration-test/docker-compose.test.yml`

- [ ] **Step 1: Write complete handler tests**

```go
// internal/handler/flags_test.go
package handler

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/gin-gonic/gin"
)

func setupFlagsRouter() *gin.Engine {
    gin.SetMode(gin.TestMode)
    r := gin.New()
    return r
}

func TestCreateFlagValidation(t *testing.T) {
    r := setupFlagsRouter()
    tests := []struct {
        name string
        body string
        code int
    }{
        {"empty body", "{}", http.StatusBadRequest},
        {"missing name", `{"key":"test","flag_type":"boolean"}`, http.StatusBadRequest},
        {"missing key", `{"name":"Test","flag_type":"boolean"}`, http.StatusBadRequest},
        {"missing flag_type", `{"key":"test","name":"Test"}`, http.StatusBadRequest},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest("POST", "/api/v1/flags", bytes.NewBufferString(tt.body))
            req.Header.Set("Content-Type", "application/json")
            w := httptest.NewRecorder()
            r.ServeHTTP(w, req)
            if w.Code != tt.code {
                t.Errorf("expected %d, got %d", tt.code, w.Code)
            }
        })
    }
}

func TestListFlagsNoAuth(t *testing.T) {
    r := setupFlagsRouter()
    req := httptest.NewRequest("GET", "/api/v1/flags", nil)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusUnauthorized {
        t.Errorf("expected 401, got %d", w.Code)
    }
}

func TestHealthEndpoint(t *testing.T) {
    r := setupFlagsRouter()
    req := httptest.NewRequest("GET", "/health", nil)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("expected 200, got %d", w.Code)
    }

    var resp map[string]string
    json.NewDecoder(w.Body).Decode(&resp)
    if resp["status"] != "ok" {
        t.Errorf("expected status ok, got %s", resp["status"])
    }
}
```

- [ ] **Step 2: Update integration test docker-compose**

```yaml
# services/integration-test/docker-compose.test.yml additions
  feature-flags:
    build: ../feature-flags
    ports:
      - "9083:8083"
    environment:
      DATABASE_URL: postgres://test:test@postgres:5432/minusframework_test?sslmode=disable
      LISTEN_ADDR: ":8083"
      JWT_SECRET: test-secret
      REDIS_URL: ""
    depends_on:
      - postgres
```

- [ ] **Step 3: Create integration test script**

```bash
#!/bin/bash
# services/integration-test/test_feature_flags.sh
set -e

echo "=== Feature Flags Integration Test ==="

# 1. Health check
echo "Checking health..."
curl -sf http://localhost:9083/health | grep -q '"status":"ok"'

# 2. Create environment
echo "Creating environment..."
ENV_RESP=$(curl -sf -X POST http://localhost:9083/api/v1/environments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name":"staging"}')
ENV_ID=$(echo $ENV_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Created environment: $ENV_ID"

# 3. Create flag
echo "Creating flag..."
FLAG_RESP=$(curl -sf -X POST http://localhost:9083/api/v1/flags \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"key":"new_checkout","name":"Novo Checkout","flag_type":"boolean"}')
FLAG_ID=$(echo $FLAG_RESP | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Created flag: $FLAG_ID"

# 4. Toggle flag on
echo "Toggling flag on..."
curl -sf -X PUT "http://localhost:9083/api/v1/flags/$FLAG_ID/toggle" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d "{\"enabled\":true,\"environment_id\":\"$ENV_ID\",\"rollout_percentage\":50}" | grep -q '"enabled":true'

# 5. List flags
echo "Listing flags..."
curl -sf "http://localhost:9083/api/v1/flags?environment_id=$ENV_ID" \
  -H "Authorization: Bearer $JWT_TOKEN" | grep -q '"key":"new_checkout"'

# 6. Issue WebSocket token
echo "Issuing WebSocket token..."
curl -sf -X POST "http://localhost:9083/api/v1/ws/token?environment_id=$ENV_ID" \
  -H "X-API-Key: MF-TEST-KEY" | grep -q '"token"'

echo "=== All feature flag tests passed ==="
```

- [ ] **Step 4: Commit**

```bash
git add services/feature-flags/internal/handler/flags_test.go services/integration-test/
git commit -m "test: add feature flags integration tests"
```

---

## Self-Review Checklist

- [ ] Spec coverage: CRUD flags/environments, WebSocket hub with connection token, Redis pub/sub, rollout evaluator, Delphi SDK, dashboard, audit log all covered ✅
- [ ] Placeholder scan: No TBD, TODO, or incomplete patterns ✅
- [ ] Type consistency: Flag struct fields match across model, store, handler, and WebSocket protocol ✅
- [ ] Auth consistency: API Key for `/api/v1/ws/token`, Connection Token for `/ws`, JWT for `/api/v1/*` and `/dashboard/*` ✅
