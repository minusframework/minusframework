package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/handler"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/middleware"
	"github.com/GabrielFerreiraMendes/minusframework/services/telemetry/internal/store"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx := context.Background()
	db, err := store.NewPostgres(ctx, dsn)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer db.Close()

	r := gin.Default()
	r.LoadHTMLGlob("web/templates/*")
	r.Static("/static", "./web/static")

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	ingestHandler := handler.NewIngestHandler(db)

	r.GET("/api/v1/config", ingestHandler.GetConfig)

	ingest := r.Group("/v1", middleware.APIKeyRequired(db))
	ingest.POST("/traces", ingestHandler.IngestTraces)
	ingest.POST("/metrics", ingestHandler.IngestMetrics)

	jwtSecret := os.Getenv("JWT_SECRET")

	dashboard := r.Group("/dashboard", middleware.JWTAuthRequired(jwtSecret))
	{
		dh := handler.NewDashboardHandler(db)
		dashboard.GET("/", dh.Index)
		dashboard.GET("/traces", dh.Traces)
		dashboard.GET("/services", dh.Services)
	}

	addr := os.Getenv("LISTEN_ADDR")
	if addr == "" {
		addr = ":8082"
	}
	log.Printf("Telemetry API listening on %s", addr)
	r.Run(addr)
}
