package handler

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/model"
	"github.com/GabrielFerreiraMendes/minusframework/services/license-server/internal/store"
)

var httpClient = &http.Client{Timeout: 15 * time.Second}

type AuthHandler struct {
	store          *store.Store
	jwtSecret      string
	githubClientID string
	githubSecret   string
}

func NewAuthHandler(s *store.Store) *AuthHandler {
	return &AuthHandler{
		store:          s,
		jwtSecret:      os.Getenv("JWT_SECRET"),
		githubClientID: os.Getenv("GITHUB_CLIENT_ID"),
		githubSecret:   os.Getenv("GITHUB_CLIENT_SECRET"),
	}
}

type githubUserResponse struct {
	ID        int    `json:"id"`
	Login     string `json:"login"`
	Email     string `json:"email"`
	AvatarURL string `json:"avatar_url"`
}

func (h *AuthHandler) generateState() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func (h *AuthHandler) LoginRedirect(c *gin.Context) {
	state := h.generateState()
	url := fmt.Sprintf(
		"https://github.com/login/oauth/authorize?client_id=%s&state=%s&scope=read:user,user:email",
		h.githubClientID, state,
	)
	c.Redirect(http.StatusTemporaryRedirect, url)
}

func (h *AuthHandler) Callback(c *gin.Context) {
	code := c.Query("code")
	if code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing code"})
		return
	}

	state := c.Query("state")
	if state == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing state parameter"})
		return
	}

	tokenURL := fmt.Sprintf(
		"https://github.com/login/oauth/access_token?client_id=%s&client_secret=%s&code=%s",
		h.githubClientID, h.githubSecret, code,
	)
	req, _ := http.NewRequest("POST", tokenURL, nil)
	req.Header.Set("Accept", "application/json")
	resp, err := httpClient.Do(req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "token exchange failed"})
		return
	}
	defer resp.Body.Close()

	var tokenResp struct {
		AccessToken string `json:"access_token"`
	}
	json.NewDecoder(resp.Body).Decode(&tokenResp)
	if tokenResp.AccessToken == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid code"})
		return
	}

	userReq, _ := http.NewRequest("GET", "https://api.github.com/user", nil)
	userReq.Header.Set("Authorization", "Bearer "+tokenResp.AccessToken)
	userResp, err := httpClient.Do(userReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch user"})
		return
	}
	defer userResp.Body.Close()

	var ghUser githubUserResponse
	json.NewDecoder(userResp.Body).Decode(&ghUser)

	user := &model.User{
		GitHubID:    fmt.Sprintf("%d", ghUser.ID),
		Email:       ghUser.Email,
		DisplayName: ghUser.Login,
		AvatarURL:   ghUser.AvatarURL,
	}
	err = h.store.UpsertUser(c.Request.Context(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save user"})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"email":   user.Email,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
		"iat":     time.Now().Unix(),
	})
	tokenString, _ := token.SignedString([]byte(h.jwtSecret))

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user":  user,
	})
}
