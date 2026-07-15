package handler

import (
	"encoding/json"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/model"
	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/store"
)

type WebhookHandler struct {
	store *store.Store
}

func NewWebhookHandler(s *store.Store) *WebhookHandler {
	return &WebhookHandler{store: s}
}

type pullRequestEvent struct {
	Action      string `json:"action"`
	Number      int    `json:"number"`
	PullRequest struct {
		Title string `json:"title"`
		Body  string `json:"body"`
		Head  struct {
			SHA string `json:"sha"`
		} `json:"head"`
		User struct {
			Login string `json:"login"`
		} `json:"user"`
	} `json:"pull_request"`
	Repository struct {
		FullName string `json:"full_name"`
	} `json:"repository"`
}

func (h *WebhookHandler) HandlePR(c *gin.Context) {
	payload, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "failed to read body"})
		return
	}

	var event pullRequestEvent
	if err := json.Unmarshal(payload, &event); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload"})
		return
	}

	if event.Action != "opened" && event.Action != "synchronize" {
		c.JSON(http.StatusOK, gin.H{"ignored": true})
		return
	}

	review := &model.Review{
		RepoFullName: event.Repository.FullName,
		PRNumber:     event.Number,
		PRTitle:      event.PullRequest.Title,
		PRAuthor:     event.PullRequest.User.Login,
		CommitSHA:    event.PullRequest.Head.SHA,
		Status:       model.ReviewPending,
	}

	if err := h.store.CreateReview(c.Request.Context(), review); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create review"})
		return
	}

	h.store.CreateJob(c.Request.Context(), &model.Job{ReviewID: review.ID, JobType: model.JobLLM, Status: "queued"})
	h.store.CreateJob(c.Request.Context(), &model.Job{ReviewID: review.ID, JobType: model.JobStructural, Status: "queued"})

	c.JSON(http.StatusOK, gin.H{"review_id": review.ID, "status": "queued"})
}
