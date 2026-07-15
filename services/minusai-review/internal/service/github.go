package service

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

var httpClient = &http.Client{Timeout: 30 * time.Second}

type GitHubService struct {
	token string
}

func NewGitHubService() *GitHubService {
	return &GitHubService{token: os.Getenv("GITHUB_APP_TOKEN")}
}

func (s *GitHubService) GetPRDiff(repo string, prNumber int) (string, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s/pulls/%d", repo, prNumber)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+s.token)
	req.Header.Set("Accept", "application/vnd.github.v3.diff")
	resp, err := httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to fetch diff: %w", err)
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read diff body: %w", err)
	}
	return string(b), nil
}

func (s *GitHubService) GetPRFiles(repo string, prNumber int) ([]string, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s/pulls/%d/files", repo, prNumber)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+s.token)
	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var files []struct {
		Filename string `json:"filename"`
	}
	json.NewDecoder(resp.Body).Decode(&files)
	names := make([]string, len(files))
	for i, f := range files {
		names[i] = f.Filename
	}
	return names, nil
}
