package handler

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/webhook"

	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/model"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/store"
)

type WebhookHandler struct {
	store         *store.Store
	webhookSecret string
}

func NewWebhookHandler(s *store.Store) *WebhookHandler {
	return &WebhookHandler{
		store:         s,
		webhookSecret: os.Getenv("STRIPE_WEBHOOK_SECRET"),
	}
}

func (h *WebhookHandler) HandleStripe(c *gin.Context) {
	const maxBodyBytes = 65536
	body, err := io.ReadAll(io.LimitReader(c.Request.Body, maxBodyBytes))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to read body"})
		return
	}

	event, err := webhook.ConstructEvent(body, c.GetHeader("Stripe-Signature"), h.webhookSecret)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid signature"})
		return
	}

	switch event.Type {
	case "checkout.session.completed":
		h.handleCheckoutCompleted(c, event)
	case "customer.subscription.updated":
		h.handleSubscriptionUpdated(c, event)
	case "customer.subscription.deleted":
		h.handleSubscriptionDeleted(c, event)
	default:
		c.JSON(http.StatusOK, gin.H{"status": "unhandled event type"})
		return
	}
}

func (h *WebhookHandler) handleCheckoutCompleted(c *gin.Context, event stripe.Event) {
	var session stripe.CheckoutSession
	if err := json.Unmarshal(event.Data.Raw, &session); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse checkout session"})
		return
	}

	sub := &model.Subscription{
		UserID:               session.Metadata["user_id"],
		StripeSubscriptionID: session.Subscription.ID,
		StripeCustomerID:     session.Customer.ID,
		ServiceName:          session.Metadata["service_name"],
		PlanTier:             session.Metadata["plan_tier"],
		Status:               string(session.Status),
		CurrentPeriodStart:   time.Unix(session.Created, 0),
	}

	if err := h.store.CreateSubscription(c.Request.Context(), sub); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create subscription"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "subscription created"})
}

func (h *WebhookHandler) handleSubscriptionUpdated(c *gin.Context, event stripe.Event) {
	var sub stripe.Subscription
	if err := json.Unmarshal(event.Data.Raw, &sub); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse subscription"})
		return
	}

	var periodEnd *time.Time
	if sub.CurrentPeriodEnd > 0 {
		t := time.Unix(sub.CurrentPeriodEnd, 0)
		periodEnd = &t
	}

	if err := h.store.UpdateSubscriptionStatus(c.Request.Context(), sub.ID, string(sub.Status), periodEnd); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update subscription"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "subscription updated"})
}

func (h *WebhookHandler) handleSubscriptionDeleted(c *gin.Context, event stripe.Event) {
	var sub stripe.Subscription
	if err := json.Unmarshal(event.Data.Raw, &sub); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to parse subscription"})
		return
	}

	now := time.Now()
	if err := h.store.UpdateSubscriptionStatus(c.Request.Context(), sub.ID, "canceled", &now); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to cancel subscription"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "subscription canceled"})
}
