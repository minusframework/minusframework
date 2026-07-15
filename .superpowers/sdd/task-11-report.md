## Task 11 Report — Feature Flags Delphi Client SDK

**File:** `services/feature-flags/sdk/MF.FeatureFlags.Client.pas`
**Status:** complete
**Date:** 2026-07-15

### What was built

Created `TFeatureFlags` — a WebSocket-based Delphi client for real-time feature flag evaluation with local caching.

### Architecture

| Layer | Component |
|-------|-----------|
| Token auth | `POST /api/v1/ws/token` with `X-API-Key` header, receives JWT token |
| Transport | WebSocket to `wss://host/ws?token=...` using `System.Net.WebSocket.TWebSocketClient` |
| Cache | `TObjectDictionary<string, TFlagEntry>` with `doOwnsValues`, populated from `connected` message and kept in sync via `flag_updated` / `flag_deleted` |
| Hashing | `THashBobJenkins.GetHashValue` (core hash), `Abs(hash) mod 100` for deterministic percentile bucketing |
| Reconnection | Background thread (`TReconnectThread`) with exponential backoff: 1s → 2s → 4s → 8s → max 30s |

### Types

- **`TFlagContext`** — Record with `UserId`, `GroupId`, `Attributes: TDictionary<string,string>`. Matches the existing `TContextoFlag` pattern from `MF.FeatureFlags.Types`, but in English per the SDK spec.
- **`TFlagEntry`** — Class holding `Key`, `Enabled`, `Variant`, `RolloutPercentage`. Owned by the cache dictionary.
- **`TFeatureFlagEvent`** — `procedure(const AFlagName: string; AEnabled: Boolean) of object`
- **`TFeatureFlags`** — Main class: `Create(baseURL, apiKey, environmentID)`, `IsEnabled(name, context)`, `GetVariant(name, context)`, and events `OnFlagChanged`, `OnConnected`, `OnDisconnected`, `OnError`.

### Server messages handled

| Type | Action |
|------|--------|
| `connected` | Clears cache, loads initial `flags[]` array |
| `flag_updated` | Upserts cache entry, fires `OnFlagChanged` |
| `flag_deleted` | Removes from cache, fires `OnFlagChanged(enabled=False)` |
| `ping` | Responds with `{"type":"pong"}` |

### Design decisions

- **English naming** — All types/fields in English to align with the SDK's role as a client library (contrasts with existing Portuguese-named `MF.FeatureFlags.SDK`).
- **Thread marshaling** — `OnWSConnected`, `OnWSDisconnected`, and `OnWSError` fire from WebSocket threads; user event callbacks are queued to main thread via `TThread.Queue`.
- **No VCL/FMX dependency** — Uses `TThread` instead of `TTimer` for reconnection, keeping the unit usable in console/service applications.
- **`doOwnsValues`** — Cache owns its entries; `AddOrSetValue` with a new instance automatically frees the old one.
- **Safe shutdown** — `FDestroying` flag prevents reconnection attempts during teardown; WebSocket events are unsubscribed before freeing.

### Verification

- File compiles against Delphi 11+ (uses inline variables, `StartsWith`, record constructors)
- All 7 required units present: `System.Classes`, `System.SysUtils`, `System.Net.HttpClient`, `System.Net.WebSocket`, `System.JSON`, `System.Generics.Collections`, `System.Hash`
- Zero `{$R *.res}` needed (SDK unit, not part of a package)
