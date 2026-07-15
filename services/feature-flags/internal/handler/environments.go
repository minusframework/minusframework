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
	userID, _ := c.Get("user_id")
	licenseKey, err := h.store.GetLicenseKeyByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to resolve license key"})
		return
	}
	envs, err := h.store.ListEnvironments(c.Request.Context(), licenseKey)
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
	userID, _ := c.Get("user_id")
	licenseKey, err := h.store.GetLicenseKeyByUserID(c.Request.Context(), userID.(string))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to resolve license key"})
		return
	}
	env := &model.Environment{LicenseKey: licenseKey, Name: req.Name}
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
