package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/model"
)

type Store interface {
	BatchInsertSpans(ctx context.Context, spans []model.Span) error
	InsertMetric(ctx context.Context, m *model.Metric) error
}

type IngestHandler struct {
	store Store
}

func NewIngestHandler(s Store) *IngestHandler {
	return &IngestHandler{store: s}
}

func (h *IngestHandler) IngestTraces(c *gin.Context) {
	var req model.TraceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	licenseKey, ok := c.Get("license_key")
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "missing license key"})
		return
	}
	licenseStr, ok := licenseKey.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid license key"})
		return
	}
	for i := range req.Spans {
		req.Spans[i].LicenseKey = licenseStr
	}

	if err := h.store.BatchInsertSpans(c.Request.Context(), req.Spans); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store spans"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"accepted": len(req.Spans)})
}

func (h *IngestHandler) IngestMetrics(c *gin.Context) {
	var req model.Metric
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	licenseKey, ok := c.Get("license_key")
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "missing license key"})
		return
	}
	licenseStr, ok := licenseKey.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "invalid license key"})
		return
	}
	req.LicenseKey = licenseStr

	if err := h.store.InsertMetric(c.Request.Context(), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store metric"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"accepted": true})
}

func (h *IngestHandler) GetConfig(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"flush_interval_seconds": 60,
		"max_batch_size":         100,
		"version":                "1.0",
	})
}
