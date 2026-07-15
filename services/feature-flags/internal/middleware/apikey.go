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
