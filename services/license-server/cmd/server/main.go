package main

import (
	"context"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/handler"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/middleware"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/store"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"os"
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

	authHandler := handler.NewAuthHandler(db)
	r.GET("/auth/github/login", authHandler.LoginRedirect)
	r.GET("/auth/github/callback", authHandler.Callback)

	licenseHandler := handler.NewLicenseHandler(db)
	subHandler := handler.NewSubscriptionHandler(db)
	webhookHandler := handler.NewWebhookHandler(db)

	r.POST("/stripe/webhook", webhookHandler.HandleStripe)

	// Public endpoints (no auth required)
	r.POST("/licenses/validate", licenseHandler.Validate)
	r.POST("/licenses/activate", licenseHandler.Activate)

	authorized := r.Group("/", middleware.AuthRequired(os.Getenv("JWT_SECRET")))
	authorized.POST("/licenses/generate", licenseHandler.Generate)
	authorized.POST("/licenses/deactivate", licenseHandler.Deactivate)
	authorized.GET("/licenses/mine", licenseHandler.ListMine)

	authorized.POST("/subscriptions/create", subHandler.CreateCheckout)
	authorized.GET("/subscriptions/portal", subHandler.Portal)
	authorized.GET("/subscriptions/mine", subHandler.ListMine)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	addr := os.Getenv("LISTEN_ADDR")
	if addr == "" {
		addr = ":8080"
	}
	log.Printf("License Server listening on %s", addr)
	r.Run(addr)
}
