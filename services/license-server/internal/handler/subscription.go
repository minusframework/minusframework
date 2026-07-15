package handler

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/stripe/stripe-go/v76"
	portalsession "github.com/stripe/stripe-go/v76/billingportal/session"
	checkoutsession "github.com/stripe/stripe-go/v76/checkout/session"

	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/store"
)

type SubscriptionHandler struct {
	store      *store.Store
	stripeKey  string
	successURL string
	cancelURL  string
}

func NewSubscriptionHandler(s *store.Store) *SubscriptionHandler {
	stripe.Key = os.Getenv("STRIPE_SECRET_KEY")
	return &SubscriptionHandler{
		store:      s,
		stripeKey:  os.Getenv("STRIPE_SECRET_KEY"),
		successURL: os.Getenv("STRIPE_SUCCESS_URL"),
		cancelURL:  os.Getenv("STRIPE_CANCEL_URL"),
	}
}

func (h *SubscriptionHandler) CreateCheckout(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID, ok := userIDRaw.(string)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user identity"})
		return
	}

	var req struct {
		PriceID     string `json:"price_id" binding:"required"`
		ServiceName string `json:"service_name" binding:"required"`
		PlanTier    string `json:"plan_tier" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	params := &stripe.CheckoutSessionParams{
		Mode:       stripe.String(string(stripe.CheckoutSessionModeSubscription)),
		SuccessURL: stripe.String(h.successURL),
		CancelURL:  stripe.String(h.cancelURL),
		LineItems: []*stripe.CheckoutSessionLineItemParams{
			{Price: stripe.String(req.PriceID), Quantity: stripe.Int64(1)},
		},
		Metadata: map[string]string{
			"user_id":      userID,
			"service_name": req.ServiceName,
			"plan_tier":    req.PlanTier,
		},
	}

	sess, err := checkoutsession.New(params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create checkout session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": sess.URL})
}

func (h *SubscriptionHandler) Portal(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID, ok := userIDRaw.(string)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user identity"})
		return
	}

	subs, err := h.store.GetUserSubscriptions(c.Request.Context(), userID)
	if err != nil || len(subs) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "no subscription found"})
		return
	}

	customerID := subs[0].StripeCustomerID
	if customerID == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "no Stripe customer linked"})
		return
	}

	params := &stripe.BillingPortalSessionParams{
		Customer:  stripe.String(customerID),
		ReturnURL: stripe.String(h.successURL),
	}

	ps, err := portalsession.New(params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create portal session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": ps.URL})
}

func (h *SubscriptionHandler) ListMine(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID, ok := userIDRaw.(string)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user identity"})
		return
	}

	subs, err := h.store.GetUserSubscriptions(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list subscriptions"})
		return
	}

	c.JSON(http.StatusOK, subs)
}
