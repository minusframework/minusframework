CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE license_type AS ENUM ('individual', 'team', 'enterprise');
CREATE TYPE license_status AS ENUM ('active', 'expired', 'revoked', 'suspended');
CREATE TYPE subscription_status AS ENUM ('active', 'past_due', 'canceled', 'trialing', 'incomplete');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    github_id TEXT UNIQUE,
    email TEXT UNIQUE,
    display_name TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE licenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    license_key TEXT UNIQUE NOT NULL,
    license_type license_type NOT NULL,
    status license_status NOT NULL DEFAULT 'active',
    max_activations INT NOT NULL DEFAULT 3,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE license_activations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    license_id UUID NOT NULL REFERENCES licenses(id),
    device_id TEXT NOT NULL,
    device_name TEXT NOT NULL DEFAULT '',
    ip_address TEXT,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(license_id, device_id)
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    stripe_subscription_id TEXT UNIQUE,
    stripe_customer_id TEXT,
    service_name TEXT NOT NULL,
    plan_tier TEXT NOT NULL,
    status subscription_status NOT NULL DEFAULT 'trialing',
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
