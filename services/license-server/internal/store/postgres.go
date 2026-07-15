package store

import (
	"context"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/model"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

type Store struct {
	pool *pgxpool.Pool
}

func NewPostgres(ctx context.Context, dsn string) (*Store, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		return nil, err
	}
	return &Store{pool: pool}, nil
}

func (s *Store) Close() {
	s.pool.Close()
}

func (s *Store) UpsertUser(ctx context.Context, user *model.User) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO users (github_id, email, display_name, avatar_url)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (github_id) DO UPDATE SET
           email = EXCLUDED.email,
           display_name = EXCLUDED.display_name,
           avatar_url = EXCLUDED.avatar_url,
           updated_at = now()
         RETURNING id, created_at, updated_at`,
		user.GitHubID, user.Email, user.DisplayName, user.AvatarURL,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
}

func (s *Store) CreateLicense(ctx context.Context, lic *model.License) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO licenses (user_id, license_key, license_type, max_activations, expires_at)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, status, created_at, updated_at`,
		lic.UserID, lic.LicenseKey, lic.LicenseType, lic.MaxActivations, lic.ExpiresAt,
	).Scan(&lic.ID, &lic.Status, &lic.CreatedAt, &lic.UpdatedAt)
}

func (s *Store) GetLicenseByKey(ctx context.Context, key string) (*model.License, error) {
	lic := &model.License{}
	err := s.pool.QueryRow(ctx,
		`SELECT id, user_id, license_key, license_type, status, max_activations, expires_at, created_at, updated_at
         FROM licenses WHERE license_key = $1`, key,
	).Scan(&lic.ID, &lic.UserID, &lic.LicenseKey, &lic.LicenseType, &lic.Status,
		&lic.MaxActivations, &lic.ExpiresAt, &lic.CreatedAt, &lic.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return lic, nil
}

func (s *Store) GetUserLicenses(ctx context.Context, userID string) ([]*model.License, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, user_id, license_key, license_type, status, max_activations, expires_at, created_at, updated_at
         FROM licenses WHERE user_id = $1 ORDER BY created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var licenses []*model.License
	for rows.Next() {
		lic := &model.License{}
		if err := rows.Scan(&lic.ID, &lic.UserID, &lic.LicenseKey, &lic.LicenseType,
			&lic.Status, &lic.MaxActivations, &lic.ExpiresAt, &lic.CreatedAt, &lic.UpdatedAt); err != nil {
			return nil, err
		}
		licenses = append(licenses, lic)
	}
	return licenses, nil
}

func (s *Store) CountActivations(ctx context.Context, licenseID string) (int, error) {
	var count int
	err := s.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM license_activations WHERE license_id = $1`, licenseID).Scan(&count)
	return count, err
}

func (s *Store) CreateActivation(ctx context.Context, act *model.Activation) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO license_activations (license_id, device_id, device_name, ip_address)
         VALUES ($1, $2, $3, $4)
         RETURNING id, activated_at, last_seen_at`,
		act.LicenseID, act.DeviceID, act.DeviceName, act.IPAddress,
	).Scan(&act.ID, &act.ActivatedAt, &act.LastSeenAt)
}

func (s *Store) DeleteActivation(ctx context.Context, licenseID, deviceID string) error {
	_, err := s.pool.Exec(ctx,
		`DELETE FROM license_activations WHERE license_id = $1 AND device_id = $2`,
		licenseID, deviceID)
	return err
}

func (s *Store) CreateSubscription(ctx context.Context, sub *model.Subscription) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO subscriptions (user_id, stripe_subscription_id, stripe_customer_id, service_name, plan_tier, status, current_period_start, current_period_end)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		 RETURNING id, created_at, updated_at`,
		sub.UserID, sub.StripeSubscriptionID, sub.StripeCustomerID, sub.ServiceName, sub.PlanTier, sub.Status, sub.CurrentPeriodStart, sub.CurrentPeriodEnd,
	).Scan(&sub.ID, &sub.CreatedAt, &sub.UpdatedAt)
}

func (s *Store) UpdateSubscriptionStripe(ctx context.Context, subID, stripeSubID, stripeCustomerID string) error {
	_, err := s.pool.Exec(ctx,
		`UPDATE subscriptions SET stripe_subscription_id = $2, stripe_customer_id = $3, updated_at = now() WHERE id = $1`,
		subID, stripeSubID, stripeCustomerID)
	return err
}

func (s *Store) UpdateSubscriptionStatus(ctx context.Context, stripeSubID, status string, periodEnd *time.Time) error {
	_, err := s.pool.Exec(ctx,
		`UPDATE subscriptions SET status = $2, current_period_end = $3, updated_at = now() WHERE stripe_subscription_id = $1`,
		stripeSubID, status, periodEnd)
	return err
}

func (s *Store) GetUserSubscriptions(ctx context.Context, userID string) ([]*model.Subscription, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, user_id, stripe_subscription_id, stripe_customer_id, service_name, plan_tier, status, current_period_start, current_period_end, created_at, updated_at
		 FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var subs []*model.Subscription
	for rows.Next() {
		sub := &model.Subscription{}
		if err := rows.Scan(&sub.ID, &sub.UserID, &sub.StripeSubscriptionID, &sub.StripeCustomerID,
			&sub.ServiceName, &sub.PlanTier, &sub.Status, &sub.CurrentPeriodStart, &sub.CurrentPeriodEnd,
			&sub.CreatedAt, &sub.UpdatedAt); err != nil {
			return nil, err
		}
		subs = append(subs, sub)
	}
	return subs, nil
}
