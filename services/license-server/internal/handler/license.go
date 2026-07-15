package handler

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/model"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/store"
)

var httpClient = &http.Client{Timeout: 15 * time.Second}

type LicenseHandler struct {
	store *store.Store
}

func NewLicenseHandler(s *store.Store) *LicenseHandler {
	return &LicenseHandler{store: s}
}

func generateKey() string {
	b := make([]byte, 20)
	rand.Read(b)
	key := hex.EncodeToString(b)
	return "MF-" + key[:4] + "-" + key[4:8] + "-" + key[8:12] + "-" + key[12:16]
}

type generateRequest struct {
	UserID         string     `json:"user_id" binding:"required"`
	LicenseType    string     `json:"license_type" binding:"required"`
	MaxActivations int        `json:"max_activations"`
	ExpiresAt      *time.Time `json:"expires_at,omitempty"`
}

func (h *LicenseHandler) Generate(c *gin.Context) {
	var req generateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.MaxActivations <= 0 {
		req.MaxActivations = 3
	}

	lic := &model.License{
		UserID:         req.UserID,
		LicenseKey:     generateKey(),
		LicenseType:    req.LicenseType,
		MaxActivations: req.MaxActivations,
		ExpiresAt:      req.ExpiresAt,
	}

	if err := h.store.CreateLicense(c.Request.Context(), lic); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create license"})
		return
	}

	c.JSON(http.StatusCreated, lic)
}

func (h *LicenseHandler) Validate(c *gin.Context) {
	var req struct {
		LicenseKey string `json:"license_key" binding:"required"`
		DeviceID   string `json:"device_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lic, err := h.store.GetLicenseByKey(c.Request.Context(), req.LicenseKey)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "license not found", "valid": false})
		return
	}

	if lic.Status != "active" {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "license is " + lic.Status,
			"valid": false,
		})
		return
	}

	if lic.ExpiresAt != nil && time.Now().After(*lic.ExpiresAt) {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "license has expired",
			"valid": false,
		})
		return
	}

	count, _ := h.store.CountActivations(c.Request.Context(), lic.ID)
	if count >= lic.MaxActivations {
		c.JSON(http.StatusForbidden, gin.H{
			"error": "maximum activations reached",
			"valid": false,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":           true,
		"license_type":    lic.LicenseType,
		"max_activations": lic.MaxActivations,
		"activations":     count,
	})
}

func (h *LicenseHandler) Activate(c *gin.Context) {
	var req struct {
		LicenseKey string `json:"license_key" binding:"required"`
		DeviceID   string `json:"device_id" binding:"required"`
		DeviceName string `json:"device_name"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lic, err := h.store.GetLicenseByKey(c.Request.Context(), req.LicenseKey)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "license not found"})
		return
	}

	if lic.Status != "active" {
		c.JSON(http.StatusForbidden, gin.H{"error": "license is " + lic.Status})
		return
	}

	count, _ := h.store.CountActivations(c.Request.Context(), lic.ID)
	if count >= lic.MaxActivations {
		c.JSON(http.StatusForbidden, gin.H{"error": "maximum activations reached"})
		return
	}

	act := &model.Activation{
		LicenseID:  lic.ID,
		DeviceID:   req.DeviceID,
		DeviceName: req.DeviceName,
		IPAddress:  c.ClientIP(),
	}

	if err := h.store.CreateActivation(c.Request.Context(), act); err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "device already activated"})
		return
	}

	c.JSON(http.StatusCreated, act)
}

func (h *LicenseHandler) Deactivate(c *gin.Context) {
	var req struct {
		LicenseKey string `json:"license_key" binding:"required"`
		DeviceID   string `json:"device_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lic, err := h.store.GetLicenseByKey(c.Request.Context(), req.LicenseKey)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "license not found"})
		return
	}

	if err := h.store.DeleteActivation(c.Request.Context(), lic.ID, req.DeviceID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to deactivate"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "deactivated"})
}

func (h *LicenseHandler) ListMine(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID, ok := userIDRaw.(string)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user identity"})
		return
	}

	licenses, err := h.store.GetUserLicenses(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list licenses"})
		return
	}

	c.JSON(http.StatusOK, licenses)
}
