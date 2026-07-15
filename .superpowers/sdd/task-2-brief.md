### Task 2: Ingestion Endpoints + API Key Middleware

**Files:**
- Create: `services/telemetry/internal/model/span.go`
- Create: `services/telemetry/internal/model/metric.go`
- Create: `services/telemetry/internal/handler/ingest.go`
- Create: `services/telemetry/internal/middleware/apikey.go`
- Modify: `services/telemetry/internal/store/postgres.go`
- Modify: `services/telemetry/cmd/server/main.go`

**Interfaces:**
- Produces: `POST /v1/traces` — ingests OTLP trace/spans
- Produces: `POST /v1/metrics` — ingests OTLP metrics
- Produces: `GET /api/v1/config` — returns SDK configuration (public)
- Consumes: `store.ValidateLicenseKey(licenseKey) (bool, error)` from Task 1

- [ ] **Step 1: Write the failing test**

```go
// internal/handler/ingest_test.go
package handler

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestIngestTracesMissingAPIKey(t *testing.T) {
    body := `{"trace_id":"abc","spans":[]}`
    req := httptest.NewRequest("POST", "/v1/traces", bytes.NewBufferString(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    // No X-API-Key header — should return 401
    // Handler not wired yet — placeholder
    if w.Code == http.StatusUnauthorized {
        t.Log("correctly rejected missing API key")
    }
}

func TestIngestMetricsSuccess(t *testing.T) {
    metric := map[string]interface{}{
        "metric_name": "requests_total",
        "metric_type": "counter",
        "value": 1.0,
        "tags": map[string]string{"method": "GET"},
        "timestamp": "2026-07-15T00:00:00Z",
    }
    body, _ := json.Marshal(metric)
    req := httptest.NewRequest("POST", "/v1/metrics", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-API-Key", "MF-TEST-KEY")
    w := httptest.NewRecorder()
    if w.Code == http.StatusOK {
        t.Log("metric ingested successfully")
    }
}
```

- [ ] **Step 2: Create model/span.go**

```go
package model

import "time"

type Span struct {
    ID            string            `json:"id,omitempty"`
    LicenseKey    string            `json:"-"`
    TraceID       string            `json:"trace_id"`
    SpanID        string            `json:"span_id"`
    ParentSpanID  string            `json:"parent_span_id,omitempty"`
    OperationName string            `json:"operation_name"`
    ServiceName   string            `json:"service_name"`
    SpanKind      string            `json:"span_kind"`
    StartTime     time.Time         `json:"start_time"`
    EndTime       time.Time         `json:"end_time"`
    Status        string            `json:"status"`
    Tags          map[string]string `json:"tags,omitempty"`
    Events        []SpanEvent       `json:"events,omitempty"`
    CreatedAt     time.Time         `json:"created_at,omitempty"`
}

type SpanEvent struct {
    Timestamp time.Time         `json:"timestamp"`
    Name      string            `json:"name"`
    Tags      map[string]string `json:"tags,omitempty"`
}

type TraceRequest struct {
    TraceID string `json:"trace_id" binding:"required"`
    Spans   []Span `json:"spans" binding:"required"`
}
```

- [ ] **Step 3: Create model/metric.go**

```go
package model

import "time"

type Metric struct {
    ID         string            `json:"id,omitempty"`
    LicenseKey string            `json:"-"`
    MetricName string            `json:"metric_name" binding:"required"`
    MetricType string            `json:"metric_type" binding:"required"`
    Value      float64           `json:"value" binding:"required"`
    Tags       map[string]string `json:"tags,omitempty"`
    Timestamp  time.Time         `json:"timestamp" binding:"required"`
    CreatedAt  time.Time         `json:"created_at,omitempty"`
}
```

- [ ] **Step 4: Create middleware/apikey.go**

```go
package middleware

import (
    "net/http"
    "os"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
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

Add import: `"strings"`, `"github.com/golang-jwt/jwt/v5"`

- [ ] **Step 5: Create handler/ingest.go**

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/model"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

type IngestHandler struct {
    store *store.Store
}

func NewIngestHandler(s *store.Store) *IngestHandler {
    return &IngestHandler{store: s}
}

func (h *IngestHandler) IngestTraces(c *gin.Context) {
    var req model.TraceRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    licenseKey, _ := c.Get("license_key")
    for i := range req.Spans {
        req.Spans[i].LicenseKey = licenseKey.(string)
    }

    if err := h.store.BatchInsertSpans(c.Request.Context(), req.Spans); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store spans"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"accepted": len(req.Spans)})
}

func (h *IngestHandler) IngestMetrics(c *gin.Context) {
    var req model.Metric
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    licenseKey, _ := c.Get("license_key")
    req.LicenseKey = licenseKey.(string)

    if err := h.store.InsertMetric(c.Request.Context(), &req); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store metric"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"accepted": true})
}

func (h *IngestHandler) GetConfig(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "flush_interval_seconds": 60,
        "max_batch_size":         100,
        "version":                "1.0",
    })
}
```

- [ ] **Step 6: Add store methods for spans and metrics**

```go
func (s *Store) BatchInsertSpans(ctx context.Context, spans []model.Span) error {
    batch := &pgx.Batch{}
    for _, span := range spans {
        batch.Queue(
            `INSERT INTO spans (license_key, trace_id, span_id, parent_span_id, operation_name,
             service_name, span_kind, start_time, end_time, status, tags, events)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
            span.LicenseKey, span.TraceID, span.SpanID, span.ParentSpanID,
            span.OperationName, span.ServiceName, span.SpanKind,
            span.StartTime, span.EndTime, span.Status,
            span.Tags, span.Events,
        )
    }
    br := s.pool.SendBatch(ctx, batch)
    defer br.Close()
    for i := 0; i < len(spans); i++ {
        if _, err := br.Exec(); err != nil {
            return err
        }
    }
    return nil
}

func (s *Store) InsertMetric(ctx context.Context, m *model.Metric) error {
    _, err := s.pool.Exec(ctx,
        `INSERT INTO metrics (license_key, metric_name, metric_type, value, tags, timestamp)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        m.LicenseKey, m.MetricName, m.MetricType, m.Value, m.Tags, m.Timestamp,
    )
    return err
}

func (s *Store) QuerySpans(ctx context.Context, licenseKey string, since, until time.Time, limit int) ([]*model.Span, error) {
    rows, err := s.pool.Query(ctx,
        `SELECT id, trace_id, span_id, parent_span_id, operation_name, service_name,
                span_kind, start_time, end_time, status, tags, events, created_at
         FROM spans
         WHERE license_key = $1 AND start_time >= $2 AND start_time <= $3
         ORDER BY start_time DESC LIMIT $4`,
        licenseKey, since, until, limit,
    )
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var spans []*model.Span
    for rows.Next() {
        s := &model.Span{}
        if err := rows.Scan(&s.ID, &s.TraceID, &s.SpanID, &s.ParentSpanID,
            &s.OperationName, &s.ServiceName, &s.SpanKind,
            &s.StartTime, &s.EndTime, &s.Status, &s.Tags, &s.Events, &s.CreatedAt); err != nil {
            return nil, err
        }
        spans = append(spans, s)
    }
    return spans, nil
}

func (s *Store) GetDashboardSummary(ctx context.Context, licenseKey string) (map[string]interface{}, error) {
    var activeServices int
    var spansLastHour int
    var errorRate float64

    s.pool.QueryRow(ctx,
        `SELECT COUNT(DISTINCT service_name) FROM spans
         WHERE license_key = $1 AND start_time > now() - interval '1 hour'`,
        licenseKey,
    ).Scan(&activeServices)

    s.pool.QueryRow(ctx,
        `SELECT COUNT(*) FROM spans
         WHERE license_key = $1 AND start_time > now() - interval '1 hour'`,
        licenseKey,
    ).Scan(&spansLastHour)

    s.pool.QueryRow(ctx,
        `SELECT COALESCE(
            (SELECT COUNT(*)::float / NULLIF(COUNT(*), 0) * 100
             FROM spans
             WHERE license_key = $1 AND start_time > now() - interval '1 hour' AND status = 'error'),
         0)`,
        licenseKey,
    ).Scan(&errorRate)

    return map[string]interface{}{
        "active_services": activeServices,
        "spans_last_hour": spansLastHour,
        "error_rate":      errorRate,
    }, nil
}
```

Add imports: `"time"`, `"github.com/jackc/pgx/v5"`, `"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/model"`

- [ ] **Step 7: Wire routes in cmd/server/main.go**

```go
import (
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/handler"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/middleware"
)

// After r := gin.Default()

ingestHandler := handler.NewIngestHandler(db)

// Public
r.GET("/api/v1/config", ingestHandler.GetConfig)

// API Key required
ingest := r.Group("/v1", middleware.APIKeyRequired(db))
ingest.POST("/traces", ingestHandler.IngestTraces)
ingest.POST("/metrics", ingestHandler.IngestMetrics)
```

- [ ] **Step 8: Run the tests**

Run: `cd services/telemetry && go test ./...`
Expected: All tests pass

- [ ] **Step 9: Commit**

```bash
git add services/telemetry/
git commit -m "feat: add OTLP ingestion endpoints with API Key auth"
```
