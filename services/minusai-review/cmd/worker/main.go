package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"time"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/model"
	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/service"
	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/store"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is required")
	}

	ctx := context.Background()
	db, err := store.NewPostgres(ctx, dsn)
	if err != nil {
		log.Fatalf("failed to connect: %v", err)
	}
	defer db.Close()

	llmSvc := service.NewLLMService()
	ghSvc := service.NewGitHubService()

	log.Println("Worker started, polling for LLM jobs...")

	for {
		job, err := db.ClaimJob(ctx, string(model.JobLLM))
		if err != nil || job == nil {
			time.Sleep(5 * time.Second)
			continue
		}

		log.Printf("Processing job %s (review %s)", job.ID, job.ReviewID)
		review, err := db.GetReview(ctx, job.ReviewID)
		if err != nil {
			log.Printf("Failed to get review: %v", err)
			errResult, _ := json.Marshal(map[string]string{"error": err.Error()})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		diff, err := ghSvc.GetPRDiff(review.RepoFullName, review.PRNumber)
		if err != nil {
			log.Printf("Failed to get diff: %v", err)
			errResult, _ := json.Marshal(map[string]string{"error": err.Error()})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		files, err := ghSvc.GetPRFiles(review.RepoFullName, review.PRNumber)
		if err != nil {
			log.Printf("Failed to get files: %v", err)
			errResult, _ := json.Marshal(map[string]string{"error": err.Error()})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		result, err := llmSvc.AnalyzeDiff(review.RepoFullName, review.PRNumber, diff, files)
		if err != nil {
			log.Printf("LLM analysis failed: %v", err)
			errResult, _ := json.Marshal(map[string]string{"error": err.Error()})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		resultJSON, _ := json.Marshal(result)
		db.CompleteJob(ctx, job.ID, json.RawMessage(resultJSON))
		db.UpdateReviewStatus(ctx, review.ID, model.ReviewProcessing, json.RawMessage(resultJSON))
		log.Printf("Job %s completed: score=%d, issues=%d", job.ID, result.Score, len(result.Issues))
	}
}
