package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/GabrielFerreiraMendes/minusframework/services/minusai-review/internal/store"
)

type ReviewHandler struct {
	store *store.Store
}

func NewReviewHandler(s *store.Store) *ReviewHandler {
	return &ReviewHandler{store: s}
}

func (h *ReviewHandler) GetByID(c *gin.Context) {
	id := c.Param("id")
	review, err := h.store.GetReview(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "review not found"})
		return
	}
	c.JSON(http.StatusOK, review)
}

func (h *ReviewHandler) List(c *gin.Context) {
	repo := c.Query("repo")
	if repo == "" {
		reviews, err := h.store.ListAll(c.Request.Context())
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list reviews"})
			return
		}
		c.JSON(http.StatusOK, reviews)
		return
	}
	reviews, err := h.store.ListReviews(c.Request.Context(), repo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list reviews"})
		return
	}
	c.JSON(http.StatusOK, reviews)
}
