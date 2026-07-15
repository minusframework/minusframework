package model

import (
	"encoding/json"
	"time"
)

type ReviewStatus string

const (
	ReviewPending    ReviewStatus = "pending"
	ReviewProcessing ReviewStatus = "processing"
	ReviewCompleted  ReviewStatus = "completed"
	ReviewFailed     ReviewStatus = "failed"
)

type Review struct {
	ID              string          `json:"id"`
	RepoFullName    string          `json:"repo_full_name"`
	PRNumber        int             `json:"pr_number"`
	PRTitle         string          `json:"pr_title"`
	PRAuthor        string          `json:"pr_author"`
	CommitSHA       string          `json:"commit_sha"`
	Status          ReviewStatus    `json:"status"`
	StructuralValid json.RawMessage `json:"structural_valid,omitempty"`
	LLMAnalysis     json.RawMessage `json:"llm_analysis,omitempty"`
	FinalDecision   string          `json:"final_decision,omitempty"`
	ErrorMessage    string          `json:"error_message,omitempty"`
	CreatedAt       time.Time       `json:"created_at"`
	CompletedAt     *time.Time      `json:"completed_at,omitempty"`
}
