package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/handler"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/middleware"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/service"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/store"
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
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "redis://localhost:6379"
	}
	hub := service.NewHub(redisURL)
	go hub.StartRedisListener()

	addr := os.Getenv("LISTEN_ADDR")
	if addr == "" {
		addr = ":8083"
	}

	jwtSecret := os.Getenv("JWT_SECRET")

	wsHandler := handler.NewWSHandler(db, hub)
	wsAPI := r.Group("/api/v1", middleware.APIKeyRequired(db))
	wsAPI.POST("/ws/token", wsHandler.IssueToken)
	r.GET("/ws", wsHandler.HandleWebSocket)

	api := r.Group("/api/v1", middleware.JWTAuthRequired(jwtSecret))
	{
		envHandler := handler.NewEnvironmentHandler(db)
		api.GET("/environments", envHandler.List)
		api.POST("/environments", envHandler.Create)
		api.DELETE("/environments/:id", envHandler.Delete)

		flagHandler := handler.NewFlagHandler(db, hub)
		api.GET("/flags", flagHandler.List)
		api.POST("/flags", flagHandler.Create)
		api.PUT("/flags/:id", flagHandler.Update)
		api.DELETE("/flags/:id", flagHandler.Delete)
		api.PUT("/flags/:id/toggle", flagHandler.Toggle)
	}

	r.LoadHTMLGlob("web/templates/*")
	r.Static("/static", "./web/static")

	dashboard := r.Group("/dashboard", middleware.JWTAuthRequired(jwtSecret))
	{
		dh := handler.NewDashboardHandler(db)
		dashboard.GET("/", dh.Index)
		dashboard.GET("/flags", dh.Flags)
		dashboard.GET("/audit", dh.AuditLog)
	}

	log.Printf("Feature Flags API listening on %s", addr)
	r.Run(addr)
}
