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
	Enabled           bool   `json:"enabled"`
	EnvironmentID     string `json:"environment_id" binding:"required"`
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
	if req.RolloutPercentage != nil {
		rollout = *req.RolloutPercentage
	}
	value := &model.FlagValue{FlagID: id, EnvironmentID: req.EnvironmentID, Enabled: req.Enabled, RolloutPercentage: rollout}
	if err := h.store.UpsertFlagValue(c.Request.Context(), value); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update flag value"})
		return
	}
	h.store.CreateAuditLog(c.Request.Context(), licenseKey.(string), nil, "flag.toggled", "flag_value", value.ID, nil, value)
	c.JSON(http.StatusOK, value)
}
