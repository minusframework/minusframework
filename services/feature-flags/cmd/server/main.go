package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"github.com/gin-gonic/gin"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/handler"
	"github.com/GabrielFerreiraMendes/minusframework/services/feature-flags/internal/middleware"
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

	addr := os.Getenv("LISTEN_ADDR")
	if addr == "" {
		addr = ":8083"
	}

	jwtSecret := os.Getenv("JWT_SECRET")

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

	log.Printf("Feature Flags API listening on %s", addr)
	r.Run(addr)
}
