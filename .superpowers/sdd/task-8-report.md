# Task 2 Report: Environments + Flags CRUD REST API

## Status: Complete

## Commit

- **SHA:** `9d3de94302152d04c372affe0385eecaa99e923b`
- **Message:** `feat: add REST API for feature flags and environments CRUD`

## Files Created

| File | Purpose |
|------|---------|
| `internal/model/flag.go` | Flag, FlagValue, CreateFlagRequest structs |
| `internal/model/environment.go` | Environment struct |
| `internal/middleware/auth.go` | JWT Bearer token validation (JWTAuthRequired) |
| `internal/middleware/apikey.go` | X-API-Key + license validation (APIKeyRequired) |
| `internal/handler/environments.go` | List/Create/Delete environments |
| `internal/handler/flags.go` | List/Create/Update/Delete flags + Toggle |

## Files Modified

| File | Change |
|------|--------|
| `internal/store/postgres.go` | Added ListEnvironments, CreateEnvironment, DeleteEnvironment, ListFlags, CreateFlag, UpdateFlag, DeleteFlag, UpsertFlagValue, CreateAuditLog |
| `cmd/server/main.go` | Wired JWT middleware group `/api/v1` with environment and flag routes |
| `go.mod` / `go.sum` | Added `github.com/golang-jwt/jwt/v5` v5.3.1 |

## API Endpoints

All under `/api/v1` (JWT-protected):

| Method | Path | Handler |
|--------|------|---------|
| GET | `/environments` | List environments |
| POST | `/environments` | Create environment |
| DELETE | `/environments/:id` | Delete environment |
| GET | `/flags` | List flags (optional `?environment_id=`) |
| POST | `/flags` | Create flag + audit log |
| PUT | `/flags/:id` | Update flag |
| DELETE | `/flags/:id` | Delete flag + audit log |
| PUT | `/flags/:id/toggle` | Toggle flag value + audit log |

## Build Verification

- `go build ./...` — **PASSED** (no errors)
- `go test ./...` — **PASSED** (all packages compile, no test files)

## Concerns

- The JWT middleware is applied to the entire `/api/v1` group, but the API Key middleware (`middleware.APIKeyRequired`) is defined but not wired to any route group. The task brief shows the routes using JWT only. The API key middleware exists and is ready for future use if needed.
- `ListFlags` accepts an `environmentID` parameter that is currently unused in the SQL query — it queries flags by license_key only. The environment filter is available in the query params for future use.
- No `license_key` extraction from JWT claims into context — the API key middleware sets `license_key`, but JWT middleware only sets `user_id` and `email`. Handlers rely on `c.Get("license_key")` which won't be available under JWT-only auth unless both middlewares are chained.

---

## Fix Report (2026-07-15)

**Commit:** `fix: resolve JWT license_key lookup and ListFlags environment filter`

### Issue 1 (Critical): JWT handlers use missing `license_key` from context

**Root Cause:** JWTAuthRequired middleware sets `user_id` and `email` in context from JWT claims. Handlers called `c.Get("license_key")` which always returned nil because no middleware set it.

**Fix:**
- Added `GetLicenseKeyByUserID` method to `internal/store/postgres.go` that queries active license by user_id.
- Updated `environments.go`: `List` and `Create` handlers now use `c.Get("user_id")` + `GetLicenseKeyByUserID(...)`.
- Updated `flags.go`: `List`, `Create`, `Delete`, `Toggle` handlers now use `c.Get("user_id")` + `GetLicenseKeyByUserID(...)`.

### Issue 2 (Important): `ListFlags` ignores `environmentID` query param

**Root Cause:** `ListFlags` store method signature accepted `environmentID` but the SQL query ignored it.

**Fix:**
- Updated `ListFlags` in `internal/store/postgres.go` to optionally filter by environment via LEFT JOIN on `flag_values` table when `environmentID` is non-empty.

### Build Verification

- `go build ./...` — **PASSED**
