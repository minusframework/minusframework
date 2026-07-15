package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"time"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/model"
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

	log.Println("Dispatcher started, polling for structural jobs...")

	for {
		job, err := db.ClaimJob(ctx, string(model.JobStructural))
		if err != nil || job == nil {
			time.Sleep(10 * time.Second)
			continue
		}

		log.Printf("Processing structural job %s (review %s)", job.ID, job.ReviewID)
		review, err := db.GetReview(ctx, job.ReviewID)
		if err != nil {
			log.Printf("Failed to get review: %v", err)
			errResult, _ := json.Marshal(map[string]string{"error": err.Error()})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		cmd := exec.Command("MinusAI_Reviewer.exe",
			"--repo", review.RepoFullName,
			"--pr", fmt.Sprintf("%d", review.PRNumber),
			"--token", os.Getenv("GITHUB_APP_TOKEN"),
			"--event", "opened",
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			log.Printf("Delphi worker failed: %v\nOutput: %s", err, string(output))
			errResult, _ := json.Marshal(map[string]string{"error": err.Error(), "output": string(output)})
			db.CompleteJob(ctx, job.ID, json.RawMessage(errResult))
			continue
		}

		resultJSON, _ := json.Marshal(map[string]string{"output": string(output)})
		db.CompleteJob(ctx, job.ID, json.RawMessage(resultJSON))
		log.Printf("Structural job %s completed", job.ID)
	}
}
