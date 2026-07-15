package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/handler"
	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/middleware"
	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/store"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx := context.Background()
	db, err := store.NewPostgres(ctx, dsn)
	if err != nil {
		log.Fatalf("failed to connect: %v", err)
	}
	defer db.Close()

	r := gin.Default()
	jwtSecret := os.Getenv("JWT_SECRET")

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	r.POST("/api/github/webhook", handler.NewWebhookHandler(db).HandlePR)

	api := r.Group("/api", middleware.AuthRequired(jwtSecret))
	{
		rh := handler.NewReviewHandler(db)
		api.GET("/reviews/:id", rh.GetByID)
		api.GET("/reviews", rh.List)
	}

	addr := os.Getenv("LISTEN_ADDR")
	if addr == "" {
		addr = ":8081"
	}
	log.Printf("MinusAI Review API listening on %s", addr)
	r.Run(addr)
}
