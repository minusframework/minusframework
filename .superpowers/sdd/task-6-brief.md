### Task 6: Integration Tests

**Files:**
- Create: `services/telemetry/internal/handler/ingest_test.go` (complete tests)
- Modify: `services/integration-test/docker-compose.test.yml`
- Create: `services/integration-test/test_telemetry.sh`

- [ ] **Step 1: Write complete ingestion tests**

```go
// internal/handler/ingest_test.go
package handler

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/gin-gonic/gin"
)

func setupTestRouter() *gin.Engine {
    gin.SetMode(gin.TestMode)
    r := gin.New()
    // Mock store would be injected here
    return r
}

func TestIngestTracesMissingAPIKey(t *testing.T) {
    r := setupTestRouter()
    body := `{"trace_id":"abc","spans":[{"span_id":"1","operation_name":"test"}]}`
    req := httptest.NewRequest("POST", "/v1/traces", bytes.NewBufferString(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusUnauthorized {
        t.Errorf("expected 401, got %d", w.Code)
    }
}

func TestIngestTracesBadJSON(t *testing.T) {
    r := setupTestRouter()
    req := httptest.NewRequest("POST", "/v1/traces", bytes.NewBufferString("not json"))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-API-Key", "test-key")
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusBadRequest {
        t.Errorf("expected 400, got %d", w.Code)
    }
}

func TestGetConfig(t *testing.T) {
    r := setupTestRouter()
    req := httptest.NewRequest("GET", "/api/v1/config", nil)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("expected 200, got %d", w.Code)
    }

    var resp map[string]interface{}
    json.NewDecoder(w.Body).Decode(&resp)
    if resp["flush_interval_seconds"] == nil {
        t.Error("expected flush_interval_seconds in response")
    }
}

func TestHealthEndpoint(t *testing.T) {
    r := setupTestRouter()
    req := httptest.NewRequest("GET", "/health", nil)
    w := httptest.NewRecorder()
    r.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("expected 200, got %d", w.Code)
    }
}
```

- [ ] **Step 2: Update integration test docker-compose**

```yaml
# services/integration-test/docker-compose.test.yml
version: "3.9"
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: minusframework_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"

  telemetry:
    build: ../telemetry
    ports:
      - "9082:8082"
    environment:
      DATABASE_URL: postgres://test:test@postgres:5432/minusframework_test?sslmode=disable
      LISTEN_ADDR: ":8082"
      JWT_SECRET: test-secret
```

- [ ] **Step 3: Create integration test script**

```bash
#!/bin/bash
# services/integration-test/test_telemetry.sh
set -e

echo "=== Telemetry Integration Test ==="

# 1. Health check
echo "Checking health..."
curl -sf http://localhost:9082/health | grep -q '"status":"ok"'

# 2. Get config
echo "Getting config..."
curl -sf http://localhost:9082/api/v1/config | grep -q 'flush_interval_seconds'

# 3. Ingest a trace
echo "Ingesting trace..."
curl -sf -X POST http://localhost:9082/v1/traces \
  -H "Content-Type: application/json" \
  -H "X-API-Key: MF-TEST-KEY" \
  -d '{"trace_id":"abc123","spans":[{"span_id":"span1","parent_span_id":"","operation_name":"test.op","service_name":"test-svc","span_kind":"internal","start_time":"2026-07-15T00:00:00Z","end_time":"2026-07-15T00:00:01Z","status":"ok"}]}' | grep -q '"accepted":1'

# 4. Ingest a metric
echo "Ingesting metric..."
curl -sf -X POST http://localhost:9082/v1/metrics \
  -H "Content-Type: application/json" \
  -H "X-API-Key: MF-TEST-KEY" \
  -d '{"metric_name":"requests_total","metric_type":"counter","value":1,"tags":{"method":"GET"},"timestamp":"2026-07-15T00:00:00Z"}' | grep -q '"accepted":true'

# 5. Verify ingestion rejected without API key
echo "Verifying auth rejection..."
curl -sf -X POST http://localhost:9082/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"trace_id":"xyz","spans":[]}' | grep -q 'missing'

echo "=== All telemetry tests passed ==="
```

- [ ] **Step 4: Run integration tests**

Run: `docker compose -f services/integration-test/docker-compose.test.yml up -d`
Run: `bash services/integration-test/test_telemetry.sh`
Expected: All checks pass, "All telemetry tests passed"

- [ ] **Step 5: Commit**

```bash
git add services/telemetry/internal/handler/ingest_test.go services/integration-test/
git commit -m "test: add telemetry integration tests"
```
