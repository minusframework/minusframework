package model

import (
	"encoding/json"
	"time"
)

type JobType string

const (
	JobLLM        JobType = "llm_analysis"
	JobStructural JobType = "structural_validation"
)

type Job struct {
	ID          string          `json:"id"`
	ReviewID    string          `json:"review_id"`
	JobType     JobType         `json:"job_type"`
	Status      string          `json:"status"`
	Payload     json.RawMessage `json:"payload,omitempty"`
	Result      json.RawMessage `json:"result,omitempty"`
	StartedAt   *time.Time      `json:"started_at,omitempty"`
	CompletedAt *time.Time      `json:"completed_at,omitempty"`
	CreatedAt   time.Time       `json:"created_at"`
}
