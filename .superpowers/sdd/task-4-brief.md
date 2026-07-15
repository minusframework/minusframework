### Task 4: Aggregation + Retention

**Files:**
- Create: `services/telemetry/internal/service/aggregator.go`
- Create: `services/telemetry/internal/service/retention.go`
- Modify: `services/telemetry/cmd/server/main.go`

**Interfaces:**
- Consumes: `store.Store` for raw data query and rollup insert
- Produces: Hourly rollup in `spans_hourly` and `metrics_hourly` tables

- [ ] **Step 1: Write the failing test**

```go
// internal/service/aggregator_test.go
package service

import (
    "testing"
)

func TestAggregatorInterval(t *testing.T) {
    agg := NewAggregator(nil)
    if agg.interval != time.Hour {
        t.Errorf("expected interval 1h, got %v", agg.interval)
    }
}

func TestRetentionTTL(t *testing.T) {
    ret := NewRetention(nil)
    if ret == nil {
        t.Error("expected non-nil retention")
    }
}
```

- [ ] **Step 2: Create service/aggregator.go**

```go
package service

import (
    "context"
    "log"
    "time"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

type Aggregator struct {
    store    *store.Store
    interval time.Duration
    stopCh   chan struct{}
}

func NewAggregator(s *store.Store) *Aggregator {
    return &Aggregator{
        store:    s,
        interval: time.Hour,
        stopCh:   make(chan struct{}),
    }
}

func (a *Aggregator) Start(ctx context.Context) {
    ticker := time.NewTicker(a.interval)
    defer ticker.Stop()

    // Run once on startup
    a.runOnce(ctx)

    for {
        select {
        case <-ticker.C:
            a.runOnce(ctx)
        case <-a.stopCh:
            log.Println("Aggregator stopped")
            return
        }
    }
}

func (a *Aggregator) Stop() {
    close(a.stopCh)
}

func (a *Aggregator) runOnce(ctx context.Context) {
    log.Println("Running hourly aggregation...")

    // Aggregate spans
    _, err := a.store.Exec(ctx,
        `INSERT INTO spans_hourly (hour, license_key, service_name, operation_name, count, error_count, p50_ms, p95_ms, p99_ms)
         SELECT
           date_trunc('hour', start_time) as hour,
           license_key,
           service_name,
           operation_name,
           COUNT(*) as count,
           COUNT(*) FILTER (WHERE status = 'error') as error_count,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY duration_ms) as p50_ms,
           percentile_cont(0.95) WITHIN GROUP (ORDER BY duration_ms) as p95_ms,
           percentile_cont(0.99) WITHIN GROUP (ORDER BY duration_ms) as p99_ms
         FROM spans
         WHERE start_time >= date_trunc('hour', now() - interval '1 hour')
           AND start_time < date_trunc('hour', now())
         GROUP BY hour, license_key, service_name, operation_name
         ON CONFLICT (hour, license_key, service_name, operation_name) DO NOTHING`,
    )
    if err != nil {
        log.Printf("Span aggregation failed: %v", err)
    }

    // Aggregate metrics
    _, err = a.store.Exec(ctx,
        `INSERT INTO metrics_hourly (hour, license_key, metric_name, metric_type, sum, count, min, max, avg)
         SELECT
           date_trunc('hour', timestamp) as hour,
           license_key,
           metric_name,
           metric_type,
           SUM(value) as sum,
           COUNT(*) as count,
           MIN(value) as min,
           MAX(value) as max,
           AVG(value) as avg
         FROM metrics
         WHERE timestamp >= date_trunc('hour', now() - interval '1 hour')
           AND timestamp < date_trunc('hour', now())
         GROUP BY hour, license_key, metric_name, metric_type
         ON CONFLICT (hour, license_key, metric_name, metric_type) DO NOTHING`,
    )
    if err != nil {
        log.Printf("Metric aggregation failed: %v", err)
    }

    log.Println("Aggregation complete")
}
```

- [ ] **Step 3: Add Exec helper to store/postgres.go**

```go
func (s *Store) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
    tag, err := s.pool.Exec(ctx, sql, args...)
    return tag.RowsAffected(), err
}
```

- [ ] **Step 4: Create service/retention.go**

```go
package service

import (
    "context"
    "log"
    "time"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

type Retention struct {
    store *store.Store
}

func NewRetention(s *store.Store) *Retention {
    return &Retention{store: s}
}

func (r *Retention) Run(ctx context.Context) {
    // Delete raw spans older than retention per tier
    tiers := []struct {
        days int
        tier string
    }{
        {7, "starter"},
        {30, "pro"},
    }

    for _, t := range tiers {
        deleted, err := r.store.Exec(ctx,
            `DELETE FROM spans
             WHERE license_key IN (
               SELECT license_key FROM subscriptions
               WHERE plan_tier = $1 AND status = 'active'
             )
             AND start_time < now() - make_interval(days => $2)`,
            t.tier, t.days,
        )
        if err != nil {
            log.Printf("Retention cleanup for %s failed: %v", t.tier, err)
        } else if deleted > 0 {
            log.Printf("Deleted %d old spans for %s tier", deleted, t.tier)
        }
    }
}
```

- [ ] **Step 5: Start aggregator and retention in main.go**

```go
import (
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/service"
)

// After db initialization
agg := service.NewAggregator(db)
go agg.Start(ctx)

ret := service.NewRetention(db)
go func() {
    ticker := time.NewTicker(24 * time.Hour)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            ret.Run(ctx)
        }
    }
}()
```

- [ ] **Step 6: Run the tests**

Run: `cd services/telemetry && go test ./...`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add services/telemetry/
git commit -m "feat: add hourly aggregation and retention cleanup"
```
