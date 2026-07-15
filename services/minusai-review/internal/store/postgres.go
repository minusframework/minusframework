package store

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/model"
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

func (s *Store) Close() { s.pool.Close() }

func (s *Store) ListAll(ctx context.Context) ([]*model.Review, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, repo_full_name, pr_number, pr_title, pr_author, commit_sha,
		        status, created_at, completed_at
		 FROM reviews ORDER BY created_at DESC LIMIT 50`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var reviews []*model.Review
	for rows.Next() {
		r := &model.Review{}
		if err := rows.Scan(&r.ID, &r.RepoFullName, &r.PRNumber, &r.PRTitle,
			&r.PRAuthor, &r.CommitSHA, &r.Status, &r.CreatedAt, &r.CompletedAt); err != nil {
			return nil, err
		}
		reviews = append(reviews, r)
	}
	return reviews, nil
}

func (s *Store) CreateReview(ctx context.Context, r *model.Review) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO reviews (repo_full_name, pr_number, pr_title, pr_author, commit_sha, status)
		 VALUES ($1, $2, $3, $4, $5, $6)
		 RETURNING id, created_at`,
		r.RepoFullName, r.PRNumber, r.PRTitle, r.PRAuthor, r.CommitSHA, r.Status,
	).Scan(&r.ID, &r.CreatedAt)
}

func (s *Store) GetReview(ctx context.Context, id string) (*model.Review, error) {
	r := &model.Review{}
	err := s.pool.QueryRow(ctx,
		`SELECT id, repo_full_name, pr_number, pr_title, pr_author, commit_sha,
		        status, structural_valid, llm_analysis, final_decision, error_message,
		        created_at, completed_at
		 FROM reviews WHERE id = $1`, id,
	).Scan(&r.ID, &r.RepoFullName, &r.PRNumber, &r.PRTitle, &r.PRAuthor, &r.CommitSHA,
		&r.Status, &r.StructuralValid, &r.LLMAnalysis, &r.FinalDecision, &r.ErrorMessage,
		&r.CreatedAt, &r.CompletedAt)
	if err != nil {
		return nil, err
	}
	return r, nil
}

func (s *Store) ListReviews(ctx context.Context, repo string) ([]*model.Review, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT id, repo_full_name, pr_number, pr_title, pr_author, commit_sha,
		        status, structural_valid, llm_analysis, final_decision, error_message,
		        created_at, completed_at
		 FROM reviews WHERE repo_full_name = $1
		 ORDER BY created_at DESC`, repo)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reviews []*model.Review
	for rows.Next() {
		r := &model.Review{}
		if err := rows.Scan(&r.ID, &r.RepoFullName, &r.PRNumber, &r.PRTitle, &r.PRAuthor,
			&r.CommitSHA, &r.Status, &r.StructuralValid, &r.LLMAnalysis, &r.FinalDecision,
			&r.ErrorMessage, &r.CreatedAt, &r.CompletedAt); err != nil {
			return nil, err
		}
		reviews = append(reviews, r)
	}
	return reviews, nil
}

func (s *Store) CreateJob(ctx context.Context, j *model.Job) error {
	return s.pool.QueryRow(ctx,
		`INSERT INTO review_jobs (review_id, job_type, status)
		 VALUES ($1, $2, $3)
		 RETURNING id, created_at`,
		j.ReviewID, j.JobType, j.Status,
	).Scan(&j.ID, &j.CreatedAt)
}

func (s *Store) ClaimJob(ctx context.Context, jobType string) (*model.Job, error) {
	j := &model.Job{}
	err := s.pool.QueryRow(ctx,
		`UPDATE review_jobs
		 SET status = 'processing', started_at = now()
		 WHERE id = (
		     SELECT id FROM review_jobs
		     WHERE job_type = $1 AND status = 'queued'
		     ORDER BY created_at ASC
		     LIMIT 1
		     FOR UPDATE SKIP LOCKED
		 )
		 RETURNING id, review_id, job_type, status, payload, result, started_at, completed_at, created_at`,
		jobType,
	).Scan(&j.ID, &j.ReviewID, &j.JobType, &j.Status, &j.Payload, &j.Result,
		&j.StartedAt, &j.CompletedAt, &j.CreatedAt)
	if err != nil {
		return nil, err
	}
	return j, nil
}

func (s *Store) CompleteJob(ctx context.Context, jobID string, result json.RawMessage) error {
	_, err := s.pool.Exec(ctx,
		`UPDATE review_jobs SET status = 'completed', result = $1, completed_at = now()
		 WHERE id = $2`, result, jobID)
	return err
}

func (s *Store) UpdateReviewStatus(ctx context.Context, reviewID string, status model.ReviewStatus, result json.RawMessage) error {
	now := time.Now()
	_, err := s.pool.Exec(ctx,
		`UPDATE reviews SET status = $1, llm_analysis = $2, completed_at = $3
		 WHERE id = $4`, status, result, now, reviewID)
	return err
}
