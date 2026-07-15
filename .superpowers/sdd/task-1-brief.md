### Task 1: Project Scaffold + Database Schema

**Files:**
- Create: `services/telemetry/go.mod`
- Create: `services/telemetry/cmd/server/main.go`
- Create: `services/telemetry/internal/store/postgres.go`
- Create: `services/telemetry/migrations/001_spans.sql`
- Create: `services/telemetry/migrations/002_metrics.sql`
- Create: `services/telemetry/Dockerfile`
- Create: `services/telemetry/Makefile`
- Modify: `services/docker-compose.yml`

**Interfaces:**
- Produces: `store.NewPostgres(dsn) *store.Store`
- Produces: Tables: `spans`, `metrics`, `spans_hourly`, `metrics_hourly`

- [ ] **Step 1: Create Go module and directories**

```bash
mkdir -p services/telemetry/cmd/server
mkdir -p services/telemetry/internal/handler
mkdir -p services/telemetry/internal/model
mkdir -p services/telemetry/internal/service
mkdir -p services/telemetry/internal/store
mkdir -p services/telemetry/internal/middleware
mkdir -p services/telemetry/migrations
mkdir -p services/telemetry/sdk
mkdir -p services/telemetry/web/templates
mkdir -p services/telemetry/web/static
cd services/telemetry
go mod init github.com/GabrielFerreiraMendes/minusframework/services/telemetry
go get github.com/gin-gonic/gin
go get github.com/jackc/pgx/v5
go get github.com/golang-jwt/jwt/v5
```

- [ ] **Step 2: Create migrations/001_spans.sql**

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE spans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    trace_id TEXT NOT NULL,
    span_id TEXT NOT NULL,
    parent_span_id TEXT,
    operation_name TEXT NOT NULL,
    service_name TEXT NOT NULL,
    span_kind TEXT NOT NULL,
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

CREATE TABLE spans_hourly (
    hour TIMESTAMPTZ NOT NULL,
    license_key TEXT NOT NULL,
    service_name TEXT NOT NULL,
    operation_name TEXT NOT NULL,
    count INT NOT NULL DEFAULT 0,
    error_count INT NOT NULL DEFAULT 0,
    p50_ms NUMERIC,
    p95_ms NUMERIC,
    p99_ms NUMERIC
);

CREATE INDEX idx_spans_trace ON spans(license_key, trace_id);
CREATE INDEX idx_spans_time ON spans(license_key, start_time DESC);
CREATE INDEX idx_spans_errors ON spans(license_key, status) WHERE status = 'error';
```

- [ ] **Step 3: Create migrations/002_metrics.sql**

```sql
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_key TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    value NUMERIC NOT NULL,
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE metrics_hourly (
    hour TIMESTAMPTZ NOT NULL,
    license_key TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    sum NUMERIC NOT NULL,
    count INT NOT NULL DEFAULT 0,
    min NUMERIC,
    max NUMERIC,
    avg NUMERIC
);

CREATE INDEX idx_metrics_time ON metrics(license_key, metric_name, timestamp DESC);
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
```

- [ ] **Step 5: Create cmd/server/main.go** (scaffold with health check only)

```go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
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
        addr = ":8082"
    }
    log.Printf("Telemetry API listening on %s", addr)
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
EXPOSE 8082
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
	psql "$(DATABASE_URL)" -f migrations/001_spans.sql
	psql "$(DATABASE_URL)" -f migrations/002_metrics.sql
```

- [ ] **Step 8: Add to docker-compose.yml**

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

- [ ] **Step 9: Run migrations and verify health**

Run: `docker compose up -d postgres`
Run: `docker compose run --rm telemetry go run ./cmd/server`
Expected: server starts, `/health` returns `{"status":"ok"}`

- [ ] **Step 10: Commit**

```bash
git add services/telemetry/ services/docker-compose.yml
git commit -m "feat: scaffold Telemetry service with PostgreSQL schema"
```
