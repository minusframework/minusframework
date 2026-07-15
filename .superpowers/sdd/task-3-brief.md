### Task 3: Dashboard API + Web UI

**Files:**
- Create: `services/telemetry/internal/handler/dashboard.go`
- Create: `services/telemetry/web/templates/index.html`
- Create: `services/telemetry/web/templates/traces.html`
- Create: `services/telemetry/web/templates/services.html`
- Create: `services/telemetry/web/static/style.css`
- Modify: `services/telemetry/cmd/server/main.go`

**Interfaces:**
- Consumes: `store.QuerySpans()`, `store.GetDashboardSummary()` from Task 2
- Produces: Dashboard HTML pages with JWT auth

- [ ] **Step 1: Create handler/dashboard.go**

```go
package handler

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

type DashboardHandler struct {
    store *store.Store
}

func NewDashboardHandler(s *store.Store) *DashboardHandler {
    return &DashboardHandler{store: s}
}

func (h *DashboardHandler) Index(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    summary, err := h.store.GetDashboardSummary(c.Request.Context(), licenseKey.(string))
    if err != nil {
        summary = map[string]interface{}{"active_services": 0, "spans_last_hour": 0, "error_rate": 0}
    }

    c.HTML(http.StatusOK, "index.html", gin.H{
        "summary": summary,
    })
}

func (h *DashboardHandler) Traces(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    since := time.Now().Add(-24 * time.Hour)
    until := time.Now()

    spans, err := h.store.QuerySpans(c.Request.Context(), licenseKey.(string), since, until, 100)
    if err != nil {
        spans = nil
    }

    c.HTML(http.StatusOK, "traces.html", gin.H{
        "spans": spans,
    })
}

func (h *DashboardHandler) Services(c *gin.Context) {
    type ServiceInfo struct {
        Name  string `json:"name"`
        Count int    `json:"count"`
    }

    licenseKey, _ := c.Get("license_key")
    rows, err := h.store.Query(c.Request.Context(),
        `SELECT service_name, COUNT(*) as count
         FROM spans
         WHERE license_key = $1 AND start_time > now() - interval '24 hours'
         GROUP BY service_name ORDER BY count DESC`,
        licenseKey.(string),
    )

    var services []ServiceInfo
    if err == nil {
        defer rows.Close()
        for rows.Next() {
            var svc ServiceInfo
            rows.Scan(&svc.Name, &svc.Count)
            services = append(services, svc)
        }
    }

    c.HTML(http.StatusOK, "services.html", gin.H{
        "services": services,
    })
}
```

Note: Add a `Query` method to store that returns `pgx.Rows` for raw queries.

- [ ] **Step 2: Add Query helper to store/postgres.go**

```go
func (s *Store) Query(ctx context.Context, sql string, args ...interface{}) (pgx.Rows, error) {
    return s.pool.Query(ctx, sql, args...)
}
```

Add import: `"github.com/jackc/pgx/v5"`

- [ ] **Step 3: Create web/templates/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Telemetry Dashboard</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Telemetry</h1>
        <nav>
            <a href="/dashboard" class="active">Overview</a>
            <a href="/dashboard/traces">Traces</a>
            <a href="/dashboard/services">Services</a>
        </nav>
    </header>

    <main>
        <div class="cards">
            <div class="card">
                <h3>Active Services</h3>
                <p class="value">{{ .summary.active_services }}</p>
            </div>
            <div class="card">
                <h3>Spans (last hour)</h3>
                <p class="value">{{ .summary.spans_last_hour }}</p>
            </div>
            <div class="card">
                <h3>Error Rate</h3>
                <p class="value">{{ printf "%.1f" .summary.error_rate }}%</p>
            </div>
        </div>
    </main>
</body>
</html>
```

- [ ] **Step 4: Create web/templates/traces.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Trace Explorer</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Trace Explorer</h1>
        <nav>
            <a href="/dashboard">Overview</a>
            <a href="/dashboard/traces" class="active">Traces</a>
            <a href="/dashboard/services">Services</a>
        </nav>
    </header>

    <main>
        <table>
            <thead>
                <tr>
                    <th>Trace ID</th>
                    <th>Service</th>
                    <th>Operation</th>
                    <th>Duration</th>
                    <th>Status</th>
                    <th>Time</th>
                </tr>
            </thead>
            <tbody>
                {{ range .spans }}
                <tr class="{{ if eq .Status "error" }}error-row{{ end }}">
                    <td><code>{{ .TraceID | slice 0 12 }}...</code></td>
                    <td>{{ .ServiceName }}</td>
                    <td>{{ .OperationName }}</td>
                    <td>{{ .DurationMs }}ms</td>
                    <td><span class="status {{ .Status }}">{{ .Status }}</span></td>
                    <td>{{ .StartTime.Format "15:04:05" }}</td>
                </tr>
                {{ else }}
                <tr><td colspan="6">No traces found</td></tr>
                {{ end }}
            </tbody>
        </table>
    </main>
</body>
</html>
```

- [ ] **Step 5: Create web/templates/services.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Service Map</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <header>
        <h1>Services</h1>
        <nav>
            <a href="/dashboard">Overview</a>
            <a href="/dashboard/traces">Traces</a>
            <a href="/dashboard/services" class="active">Services</a>
        </nav>
    </header>

    <main>
        <h2>Active Services (24h)</h2>
        <div class="service-list">
            {{ range .services }}
            <div class="service-card">
                <strong>{{ .Name }}</strong>
                <span>{{ .Count }} spans</span>
            </div>
            {{ else }}
            <p>No services active in the last 24 hours.</p>
            {{ end }}
        </div>
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
.card .value { font-size: 2rem; font-weight: 700; margin: 0; }

table { width: 100%; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
th, td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid #eee; }
th { background: #f8f9fa; font-weight: 600; font-size: 0.85rem; text-transform: uppercase; color: #666; }
tr.error-row { background: #fff5f5; }

.status { padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; font-weight: 600; }
.status.ok { background: #d4edda; color: #155724; }
.status.error { background: #f8d7da; color: #721c24; }

.service-list { display: grid; gap: 0.5rem; }
.service-card { background: white; padding: 1rem; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center; }
```

- [ ] **Step 7: Wire dashboard routes in main.go**

```go
r.LoadHTMLGlob("web/templates/*")
r.Static("/static", "./web/static")

jwtSecret := os.Getenv("JWT_SECRET")

dashboard := r.Group("/dashboard", middleware.JWTAuthRequired(jwtSecret))
{
    dh := handler.NewDashboardHandler(db)
    dashboard.GET("/", dh.Index)
    dashboard.GET("/traces", dh.Traces)
    dashboard.GET("/services", dh.Services)
}
```

- [ ] **Step 8: Commit**

```bash
git add services/telemetry/web/ services/telemetry/internal/handler/dashboard.go
git commit -m "feat: add telemetry dashboard with trace explorer and service map"
```
