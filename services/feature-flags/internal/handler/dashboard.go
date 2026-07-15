package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
)

type DashboardHandler struct {
	store *store.Store
}

func NewDashboardHandler(s *store.Store) *DashboardHandler {
	return &DashboardHandler{store: s}
}

func (h *DashboardHandler) Index(c *gin.Context) {
	userID, _ := c.Get("user_id")
	licenseKey, err := h.store.GetLicenseKeyByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		c.HTML(http.StatusOK, "index.html", gin.H{"environments": nil})
		return
	}
	envs, _ := h.store.ListEnvironments(c.Request.Context(), licenseKey)
	c.HTML(http.StatusOK, "index.html", gin.H{"environments": envs})
}

func (h *DashboardHandler) Flags(c *gin.Context) {
	userID, _ := c.Get("user_id")
	licenseKey, err := h.store.GetLicenseKeyByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		c.HTML(http.StatusOK, "flags.html", gin.H{"flags": nil, "environments": nil})
		return
	}
	envID := c.Query("environment_id")
	flags, _ := h.store.ListFlags(c.Request.Context(), licenseKey, envID)
	envs, _ := h.store.ListEnvironments(c.Request.Context(), licenseKey)
	c.HTML(http.StatusOK, "flags.html", gin.H{"flags": flags, "environments": envs, "current_env": envID})
}

func (h *DashboardHandler) AuditLog(c *gin.Context) {
	userID, _ := c.Get("user_id")
	licenseKey, err := h.store.GetLicenseKeyByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		c.HTML(http.StatusOK, "audit.html", gin.H{"logs": nil})
		return
	}
	logs, _ := h.store.QueryAuditLog(c.Request.Context(), licenseKey, 100)
	c.HTML(http.StatusOK, "audit.html", gin.H{"logs": logs})
}
