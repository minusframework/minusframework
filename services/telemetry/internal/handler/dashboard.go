package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

type DashboardHandler struct {
	store *store.Store
}

func NewDashboardHandler(s *store.Store) *DashboardHandler {
	return &DashboardHandler{store: s}
}

func (h *DashboardHandler) Index(c *gin.Context) {
	licenseKey, _ := c.Get("license_key")
	summary, err := h.store.GetDashboardSummary(c.Request.Context(), licenseKey.(string))
	if err != nil {
		summary = map[string]interface{}{"active_services": 0, "spans_last_hour": 0, "error_rate": 0}
	}

	c.HTML(http.StatusOK, "index.html", gin.H{
		"summary": summary,
	})
}

func (h *DashboardHandler) Traces(c *gin.Context) {
	licenseKey, _ := c.Get("license_key")
	since := time.Now().Add(-24 * time.Hour)
	until := time.Now()

	spans, err := h.store.QuerySpans(c.Request.Context(), licenseKey.(string), since, until, 100)
	if err != nil {
		spans = nil
	}

	c.HTML(http.StatusOK, "traces.html", gin.H{
		"spans": spans,
	})
}

func (h *DashboardHandler) Services(c *gin.Context) {
	type ServiceInfo struct {
		Name  string `json:"name"`
		Count int    `json:"count"`
	}

	licenseKey, _ := c.Get("license_key")
	rows, err := h.store.Query(c.Request.Context(),
		`SELECT service_name, COUNT(*) as count
		 FROM spans
		 WHERE license_key = $1 AND start_time > now() - interval '24 hours'
		 GROUP BY service_name ORDER BY count DESC`,
		licenseKey.(string),
	)

	var services []ServiceInfo
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var svc ServiceInfo
			rows.Scan(&svc.Name, &svc.Count)
			services = append(services, svc)
		}
	}

	c.HTML(http.StatusOK, "services.html", gin.H{
		"services": services,
	})
}
