### Task 2: Environments + Flags CRUD REST API

**Files:**
- Create: `services/feature-flags/internal/model/flag.go`
- Create: `services/feature-flags/internal/model/environment.go`
- Create: `services/feature-flags/internal/handler/flags.go`
- Create: `services/feature-flags/internal/handler/environments.go`
- Create: `services/feature-flags/internal/middleware/auth.go`
- Create: `services/feature-flags/internal/middleware/apikey.go`
- Modify: `services/feature-flags/internal/store/postgres.go`
- Modify: `services/feature-flags/cmd/server/main.go`

**Interfaces:**
- Produces: CRUD for environments (`GET/POST/DELETE /api/v1/environments`)
- Produces: CRUD for flags (`GET/POST/PUT/DELETE /api/v1/flags`)
- Produces: `PUT /api/v1/flags/:id/toggle` — toggle flag + audit log
- Consumes: JWT auth middleware, API Key middleware

---

### Step 1: Create model/flag.go

```go
package model

import (
    "encoding/json"
    "time"
)

type FlagType string

const (
    FlagTypeBoolean FlagType = "boolean"
    FlagTypeVariant FlagType = "variant"
)

type Flag struct {
    ID             string    `json:"id"`
    LicenseKey     string    `json:"-"`
    Key            string    `json:"key"`
    Name           string    `json:"name"`
    Description    string    `json:"description,omitempty"`
    FlagType       FlagType  `json:"flag_type"`
    DefaultVariant string    `json:"default_variant,omitempty"`
    CreatedAt      time.Time `json:"created_at"`
    UpdatedAt      time.Time `json:"updated_at"`
}

type FlagValue struct {
    ID               string           `json:"id"`
    FlagID           string           `json:"flag_id"`
    EnvironmentID    string           `json:"environment_id"`
    Enabled          bool             `json:"enabled"`
    VariantValue     json.RawMessage  `json:"variant_value,omitempty"`
    RolloutPercentage int             `json:"rollout_percentage"`
    CreatedAt        time.Time        `json:"created_at"`
    UpdatedAt        time.Time        `json:"updated_at"`
}

type CreateFlagRequest struct {
    Key            string    `json:"key" binding:"required"`
    Name           string    `json:"name" binding:"required"`
    Description    string    `json:"description,omitempty"`
    FlagType       FlagType  `json:"flag_type" binding:"required"`
    DefaultVariant string    `json:"default_variant,omitempty"`
}
```

### Step 2: Create model/environment.go

```go
package model

import "time"

type Environment struct {
    ID         string    `json:"id"`
    LicenseKey string    `json:"-"`
    Name       string    `json:"name"`
    CreatedAt  time.Time `json:"created_at"`
    UpdatedAt  time.Time `json:"updated_at"`
}
```

### Step 3: Create middleware/auth.go

(JWT validation middleware, same pattern as minusai-review and telemetry)

```go
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

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

### Step 4: Create middleware/apikey.go

```go
package middleware

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
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
```

### Step 5: Create handler/environments.go

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/model"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

type EnvironmentHandler struct {
    store *store.Store
}

func NewEnvironmentHandler(s *store.Store) *EnvironmentHandler {
    return &EnvironmentHandler{store: s}
}

func (h *EnvironmentHandler) List(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envs, err := h.store.ListEnvironments(c.Request.Context(), licenseKey.(string))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list environments"})
        return
    }
    c.JSON(http.StatusOK, envs)
}

func (h *EnvironmentHandler) Create(c *gin.Context) {
    var req struct {
        Name string `json:"name" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    licenseKey, _ := c.Get("license_key")
    env := &model.Environment{LicenseKey: licenseKey.(string), Name: req.Name}
    if err := h.store.CreateEnvironment(c.Request.Context(), env); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create environment"})
        return
    }
    c.JSON(http.StatusCreated, env)
}

func (h *EnvironmentHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    if err := h.store.DeleteEnvironment(c.Request.Context(), id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete environment"})
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}
```

### Step 6: Create handler/flags.go

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/model"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

type FlagHandler struct {
    store *store.Store
}

func NewFlagHandler(s *store.Store) *FlagHandler {
    return &FlagHandler{store: s}
}

func (h *FlagHandler) List(c *gin.Context) {
    licenseKey, _ := c.Get("license_key")
    envID := c.Query("environment_id")
    flags, err := h.store.ListFlags(c.Request.Context(), licenseKey.(string), envID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list flags"})
        return
    }
    c.JSON(http.StatusOK, flags)
}

func (h *FlagHandler) Create(c *gin.Context) {
    var req model.CreateFlagRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    licenseKey, _ := c.Get("license_key")
    flag := &model.Flag{
        LicenseKey: licenseKey.(string),
        Key: req.Key, Name: req.Name, Description: req.Description,
        FlagType: req.FlagType, DefaultVariant: req.DefaultVariant,
    }
    if err := h.store.CreateFlag(c.Request.Context(), flag); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create flag"})
        return
    }
    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil, "flag.created", "flag", flag.ID, nil, flag)
    c.JSON(http.StatusCreated, flag)
}

func (h *FlagHandler) Update(c *gin.Context) {
    id := c.Param("id")
    var req model.CreateFlagRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    flag := &model.Flag{ID: id, Key: req.Key, Name: req.Name, Description: req.Description, FlagType: req.FlagType, DefaultVariant: req.DefaultVariant}
    if err := h.store.UpdateFlag(c.Request.Context(), flag); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update flag"})
        return
    }
    c.JSON(http.StatusOK, flag)
}

func (h *FlagHandler) Delete(c *gin.Context) {
    id := c.Param("id")
    licenseKey, _ := c.Get("license_key")
    if err := h.store.DeleteFlag(c.Request.Context(), id); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete flag"})
        return
    }
    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil, "flag.deleted", "flag", id, nil, nil)
    c.JSON(http.StatusOK, gin.H{"status": "deleted"})
}

type toggleRequest struct {
    Enabled          bool   `json:"enabled"`
    EnvironmentID    string `json:"environment_id" binding:"required"`
    RolloutPercentage *int   `json:"rollout_percentage,omitempty"`
}

func (h *FlagHandler) Toggle(c *gin.Context) {
    id := c.Param("id")
    var req toggleRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    licenseKey, _ := c.Get("license_key")
    rollout := 100
    if req.RolloutPercentage != nil { rollout = *req.RolloutPercentage }
    value := &model.FlagValue{FlagID: id, EnvironmentID: req.EnvironmentID, Enabled: req.Enabled, RolloutPercentage: rollout}
    if err := h.store.UpsertFlagValue(c.Request.Context(), value); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update flag value"})
        return
    }
    h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil, "flag.toggled", "flag_value", value.ID, nil, value)
    c.JSON(http.StatusOK, value)
}
```

### Step 7: Add store methods for flags, environments, and audit log

```go
func (s *Store) ListEnvironments(ctx context.Context, licenseKey string) ([]*model.Environment, error) {
    rows, err := s.pool.Query(ctx, `SELECT id, license_key, name, created_at, updated_at FROM environments WHERE license_key = $1 ORDER BY name`, licenseKey)
    if err != nil { return nil, err }
    defer rows.Close()
    var envs []*model.Environment
    for rows.Next() {
        e := &model.Environment{}
        rows.Scan(&e.ID, &e.LicenseKey, &e.Name, &e.CreatedAt, &e.UpdatedAt)
        envs = append(envs, e)
    }
    return envs, nil
}

func (s *Store) CreateEnvironment(ctx context.Context, e *model.Environment) error {
    return s.pool.QueryRow(ctx, `INSERT INTO environments (license_key, name) VALUES ($1, $2) RETURNING id, created_at, updated_at`, e.LicenseKey, e.Name).Scan(&e.ID, &e.CreatedAt, &e.UpdatedAt)
}

func (s *Store) DeleteEnvironment(ctx context.Context, id string) error {
    _, err := s.pool.Exec(ctx, `DELETE FROM environments WHERE id = $1`, id)
    return err
}

func (s *Store) ListFlags(ctx context.Context, licenseKey, environmentID string) ([]*model.Flag, error) {
    rows, err := s.pool.Query(ctx,
        `SELECT f.id, f.key, f.name, f.description, f.flag_type, f.default_variant, f.created_at, f.updated_at
         FROM flags f WHERE f.license_key = $1 ORDER BY f.key`, licenseKey)
    if err != nil { return nil, err }
    defer rows.Close()
    var flags []*model.Flag
    for rows.Next() {
        f := &model.Flag{}
        rows.Scan(&f.ID, &f.Key, &f.Name, &f.Description, &f.FlagType, &f.DefaultVariant, &f.CreatedAt, &f.UpdatedAt)
        flags = append(flags, f)
    }
    return flags, nil
}

func (s *Store) CreateFlag(ctx context.Context, f *model.Flag) error {
    return s.pool.QueryRow(ctx, `INSERT INTO flags (license_key, key, name, description, flag_type, default_variant) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, created_at, updated_at`, f.LicenseKey, f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant).Scan(&f.ID, &f.CreatedAt, &f.UpdatedAt)
}

func (s *Store) UpdateFlag(ctx context.Context, f *model.Flag) error {
    _, err := s.pool.Exec(ctx, `UPDATE flags SET key=$1, name=$2, description=$3, flag_type=$4, default_variant=$5, updated_at=now() WHERE id=$6`, f.Key, f.Name, f.Description, f.FlagType, f.DefaultVariant, f.ID)
    return err
}

func (s *Store) DeleteFlag(ctx context.Context, id string) error {
    _, err := s.pool.Exec(ctx, `DELETE FROM flags WHERE id = $1`, id)
    return err
}

func (s *Store) UpsertFlagValue(ctx context.Context, fv *model.FlagValue) error {
    return s.pool.QueryRow(ctx, `INSERT INTO flag_values (flag_id, environment_id, enabled, variant_value, rollout_percentage) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (flag_id, environment_id) DO UPDATE SET enabled=EXCLUDED.enabled, variant_value=EXCLUDED.variant_value, rollout_percentage=EXCLUDED.rollout_percentage, updated_at=now() RETURNING id, created_at, updated_at`, fv.FlagID, fv.EnvironmentID, fv.Enabled, fv.VariantValue, fv.RolloutPercentage).Scan(&fv.ID, &fv.CreatedAt, &fv.UpdatedAt)
}

func (s *Store) CreateAuditLog(ctx context.Context, licenseKey string, actorID *string, action, resourceType, resourceID string, oldValue, newValue interface{}) error {
    _, err := s.pool.Exec(ctx, `INSERT INTO audit_log (license_key, actor_id, action, resource_type, resource_id, old_value, new_value) VALUES ($1,$2,$3,$4,$5,$6,$7)`, licenseKey, actorID, action, resourceType, resourceID, oldValue, newValue)
    return err
}
```

### Step 8: Wire routes in main.go

```go
import (
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/handler"
    "github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/middleware"
)

// After r := gin.Default()
jwtSecret := os.Getenv("JWT_SECRET")

// JWT-protected API
api := r.Group("/api/v1", middleware.JWTAuthRequired(jwtSecret))
{
    envHandler := handler.NewEnvironmentHandler(db)
    api.GET("/environments", envHandler.List)
    api.POST("/environments", envHandler.Create)
    api.DELETE("/environments/:id", envHandler.Delete)

    flagHandler := handler.NewFlagHandler(db)
    api.GET("/flags", flagHandler.List)
    api.POST("/flags", flagHandler.Create)
    api.PUT("/flags/:id", flagHandler.Update)
    api.DELETE("/flags/:id", flagHandler.Delete)
    api.PUT("/flags/:id/toggle", flagHandler.Toggle)
}
```

### Step 9: Run tests

```bash
cd services/feature-flags && go test ./...
```

### Step 10: Commit

```bash
git add services/feature-flags/
git commit -m "feat: add REST API for feature flags and environments CRUD"
```
