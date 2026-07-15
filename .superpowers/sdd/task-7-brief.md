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
COPY web web
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
  build: ./feature-flags
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
