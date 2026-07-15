# Task 3 Report: Dashboard API + Web UI

## What I Implemented

1. **`internal/handler/dashboard.go`** (new) — DashboardHandler with three endpoints:
   - `Index` — renders `index.html` with summary from `GetDashboardSummary`
   - `Traces` — renders `traces.html` with spans from `QuerySpans`
   - `Services` — renders `services.html` via raw `Query` for service aggregation

2. **`internal/store/postgres.go`** — added `Query(ctx, sql, args...) (pgx.Rows, error)` helper

3. **`internal/middleware/apikey.go`** — modified `JWTAuthRequired` to also extract `license_key` from JWT claims (needed by DashboardHandler)

4. **`internal/model/span.go`** — added `DurationMs()` method for template rendering (`.DurationMs` used in traces.html)

5. **`web/templates/index.html`** (new) — dashboard overview with summary cards

6. **`web/templates/traces.html`** (new) — trace explorer table with status highlighting

7. **`web/templates/services.html`** (new) — service list grouped by activity

8. **`web/static/style.css`** (new) — dark header, card layout, table styling

9. **`cmd/server/main.go`** — added `LoadHTMLGlob`, `Static`, JWT secret env, and `/dashboard/*` route group

## Testing

Could not run `go build` or `go test` — Go is not installed on this machine (`go` not found in PATH). All changes are syntactically consistent with the existing codebase patterns.

## Files Changed

| File | Action |
|------|--------|
| `services/telemetry/internal/handler/dashboard.go` | Created |
| `services/telemetry/web/templates/index.html` | Created |
| `services/telemetry/web/templates/traces.html` | Created |
| `services/telemetry/web/templates/services.html` | Created |
| `services/telemetry/web/static/style.css` | Created |
| `services/telemetry/internal/store/postgres.go` | Modified (added Query method) |
| `services/telemetry/internal/middleware/apikey.go` | Modified (extract license_key from JWT) |
| `services/telemetry/internal/model/span.go` | Modified (added DurationMs method) |
| `services/telemetry/cmd/server/main.go` | Modified (wired dashboard routes) |

## Self-Review Findings

1. **Dockerfile needs update** — The current Dockerfile doesn't copy the `web/` directory into the final image. `r.LoadHTMLGlob("web/templates/*")` and `r.Static("/static", "./web/static")` will fail at runtime in Docker because the compiled binary runs from `/` and the `web/` dir is not present. Fix: add `COPY web web` to Dockerfile or update working directory.

2. **No go build/test verification** — Lack of Go toolchain prevented verification. Template syntax, type assertions, and interface compliance are unchecked.

## Issues or Concerns

- The `JWTAuthRequired` middleware previously did not set `license_key`. Had to add `c.Set("license_key", claims["license_key"])` — this assumes JWT tokens carry a `license_key` claim. If the token issuer doesn't include this claim, dashboard pages will fail with a nil pointer assertion on `licenseKey.(string)`.
- Template `traces.html` references `.DurationMs` on Span model — added a `DurationMs()` method to Span.

---

## Fix Round (Commit `6b0bedd1`)

### Issue 1 — JWT `license_key` nil panic (Critical)

**Problem:** `JWTAuthRequired` middleware set `c.Set("license_key", claims["license_key"])`, but the License Server JWT has no `license_key` claim. `licenseKey.(string)` panics on nil.

**Fix:**
- `internal/middleware/apikey.go` — removed `c.Set("license_key", claims["license_key"])` (line 65 deleted)
- `internal/store/postgres.go` — added `GetLicenseKeyByUserID(ctx, userID)` method that queries `licenses` table using `user_id`
- `internal/handler/dashboard.go` — all three handlers (`Index`, `Traces`, `Services`) now extract `user_id` from JWT, call `getLicenseKey(c)` → `h.store.GetLicenseKeyByUserID(...)`, then use the resolved license key for downstream queries. If lookup fails, defaults are returned instead of panic.

### Issue 2 — Dockerfile missing web files

**Problem:** Docker image had no `web/` directory; `LoadHTMLGlob` and `Static` would fail at runtime.

**Fix:** Added `COPY web web` to Dockerfile between the binary copy and `EXPOSE`.

### Verification

- Go toolchain not available on this machine — tests could not be run.
- All changes are consistent with the existing codebase interfaces and patterns.
