CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE review_status AS ENUM ('pending', 'processing', 'completed', 'failed');

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repo_full_name TEXT NOT NULL,
    pr_number INT NOT NULL,
    pr_title TEXT NOT NULL DEFAULT '',
    pr_author TEXT NOT NULL DEFAULT '',
    commit_sha TEXT NOT NULL DEFAULT '',
    status review_status NOT NULL DEFAULT 'pending',
    structural_valid JSONB,
    llm_analysis JSONB,
    final_decision TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    UNIQUE(repo_full_name, pr_number)
);

CREATE TABLE review_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES reviews(id),
    job_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'queued',
    payload JSONB,
    result JSONB,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
