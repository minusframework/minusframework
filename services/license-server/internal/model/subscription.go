package model

import "time"

type Subscription struct {
	ID                   string     `json:"id"`
	UserID               string     `json:"user_id"`
	StripeSubscriptionID string     `json:"stripe_subscription_id,omitempty"`
	StripeCustomerID     string     `json:"stripe_customer_id,omitempty"`
	ServiceName          string     `json:"service_name"`
	PlanTier             string     `json:"plan_tier"`
	Status               string     `json:"status"`
	CurrentPeriodStart   time.Time  `json:"current_period_start"`
	CurrentPeriodEnd     *time.Time `json:"current_period_end,omitempty"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
}
