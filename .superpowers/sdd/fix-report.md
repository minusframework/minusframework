# Branch Review Fix Report

**Date:** 2026-07-15
**Branch:** feat/phase1-license-server-minusai
**Base:** 3375a3e8

## Build Verification

```
services/feature-flags: go build ./...  PASS
services/feature-flags: go vet ./...    PASS
services/telemetry:    go build ./...   PASS
services/telemetry:    go vet ./...     PASS
```

## Fixes Applied

### Commit 1: C1 + C4 — WebSocket protocol and reconnect thread leak (Delphi SDK)

**File:** `services/feature-flags/sdk/MF.FeatureFlags.Client.pas`

- **C1 (Critical):** Changed `HandleFlagUpdated` and `HandleFlagDeleted` to read `'flag'` instead of `'key'` from JSON messages, matching the server-side `hub.go` which sends `"flag": flagKey`.
- **C4 (Critical):** Added thread lifecycle check in `ScheduleReconnect` — if `FReconnectThread` is already assigned, it nullifies the client reference, terminates the existing thread, and sets it to nil before creating a new one.

### Commit 2: C2 + I7 — Retention goroutine stop channel and metrics cleanup

**Files:** `services/telemetry/cmd/server/main.go`, `services/telemetry/internal/service/retention.go`

- **C2 (Critical):** Replaced the inline leaky goroutine with a proper `Retention.Start(ctx)` method using a `stopCh` channel (same pattern as `Aggregator`). The main function now calls `ret.Start(ctx)` as a goroutine.
- **I7 (Important):** Added metrics cleanup query alongside spans cleanup in `runOnce()`, using the same tier-based retention logic. Also cleaned up unused `time` import in `main.go`.

### Commit 3: C3 + I5 + I10 — Cross-tenant flag access, env fields, duplicate key

**Files:** `services/feature-flags/internal/store/postgres.go`, `services/feature-flags/internal/handler/flags.go`, `services/feature-flags/internal/model/flag.go`

- **C3 (Critical):** Added `license_key` parameter to `GetFlagByID` query (`AND license_key = $2`). Updated call site in `flags.go` Toggle handler to pass the authenticated license key.
- **I5 (Important):** Added `Enabled *bool`, `VariantValue *json.RawMessage`, `RolloutPercentage *int` fields to the `Flag` struct. Modified `ListFlags` scan to populate these fields directly instead of discarding local variables.
- **I10 (Important):** Added `FlagKeyExists` method to the store for duplicate key checking. Updated the Create handler to check for duplicates before insert and return `409 Conflict` if the key already exists. Removed unused `encoding/json` import from postgres.go.

### Commit 4: I6 — JWT user_id validation

**Files:** `services/telemetry/internal/middleware/apikey.go`, `services/feature-flags/internal/middleware/auth.go`

- **I6 (Important):** Added comma-ok type assertion for `claims["user_id"]` and an explicit empty string check in both `JWTAuthRequired` middlewares. Returns `401 Unauthorized` with `"invalid token: missing user_id"` if the user_id claim is missing or empty.

### Commit 5: I9 + I11 — Ingest type assertion and dashboard scan errors

**Files:** `services/telemetry/internal/handler/ingest.go`, `services/telemetry/internal/store/postgres.go`

- **I9 (Important):** Replaced unchecked type assertions (`licenseKey.(string)`) in both `IngestTraces` and `IngestMetrics` with proper comma-ok patterns. Returns `500 Internal Server Error` if the license key is missing or not a string.
- **I11 (Important):** Added error handling for all three `QueryRow().Scan()` calls in `GetDashboardSummary`. Each scan error is now checked and returned immediately rather than silently ignored.

### Commit 6: I8 — Dashboard flags toggle UI

**Files:** `services/feature-flags/internal/handler/dashboard.go`, `services/feature-flags/web/templates/flags.html`, `services/feature-flags/web/static/style.css`

- **I8 (Important):** Replaced static `<span class="status inactive">disabled</span>` with dynamic toggle buttons. When an environment is selected, each flag row shows an `enabled`/`disabled` button that calls `PUT /api/v1/flags/:id/toggle` via fetch with the auth token and environment ID.
- Dashboard handler now passes `auth_token` (Authorization header) to the template.
- Added CSS styles for `.toggle-btn` (active/inactive/hover/disabled states).
- Token is passed via `data-auth-token` attribute on the `<main>` element for safe HTML escaping.

## Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| C1 | WebSocket protocol mismatch | Critical | Fixed |
| C2 | Retention goroutine leak | Critical | Fixed |
| C3 | Cross-tenant GetFlagByID | Critical | Fixed |
| C4 | Delphi reconnect thread leak | Critical | Fixed |
| I5 | ListFlags drops env data | Important | Fixed |
| I6 | JWT user_id validation | Important | Fixed |
| I7 | Retention metrics cleanup | Important | Fixed |
| I8 | Dashboard flags toggle UI | Important | Fixed |
| I9 | Ingest unchecked assertion | Important | Fixed |
| I10 | CreateFlag duplicate handling | Important | Fixed |
| I11 | Dashboard scan errors | Important | Fixed |
