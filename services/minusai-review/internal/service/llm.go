package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

var llmHTTPClient = &http.Client{Timeout: 30 * time.Second}

type LLMService struct {
	apiKey string
	model  string
}

func NewLLMService() *LLMService {
	model := os.Getenv("LLM_MODEL")
	if model == "" {
		model = "gpt-4o"
	}
	return &LLMService{
		apiKey: os.Getenv("OPENAI_API_KEY"),
		model:  model,
	}
}

type llmMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type llmRequest struct {
	Model       string       `json:"model"`
	Messages    []llmMessage `json:"messages"`
	Temperature float64      `json:"temperature"`
}

type llmResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

type AnalysisResult struct {
	Score       int      `json:"score"`
	Summary     string   `json:"summary"`
	Issues      []Issue  `json:"issues"`
	Suggestions []string `json:"suggestions"`
}

type Issue struct {
	Severity   string `json:"severity"`
	File       string `json:"file,omitempty"`
	Line       int    `json:"line,omitempty"`
	Message    string `json:"message"`
	Suggestion string `json:"suggestion,omitempty"`
}

func (s *LLMService) AnalyzeDiff(repo string, prNumber int, diff string, files []string) (*AnalysisResult, error) {
	prompt := fmt.Sprintf(`You are a senior Delphi code reviewer. Analyze this pull request.

Repository: %s
PR Number: %d
Files changed: %s

Diff:
%s

Review the code for:
1. Correctness: logic errors, race conditions, null pointer risks
2. Delphi idioms: exception usage, memory management, interface segregation
3. Performance: unnecessary allocations, slow queries, tight loops
4. Security: SQL injection, path traversal, hardcoded secrets
5. Style: follows Delphi naming conventions? Unit organization?

Return a JSON object with:
- "score": 0-100
- "summary": brief summary of findings
- "issues": array of {severity: "error|warning|info", file: "path", line: 123, message: "description", suggestion: "how to fix"}
- "suggestions": array of improvement ideas`,
		repo, prNumber, strings.Join(files, ", "), diff)

	reqBody := llmRequest{
		Model: s.model,
		Messages: []llmMessage{
			{Role: "system", Content: "You are a senior Delphi code reviewer. Respond with valid JSON only."},
			{Role: "user", Content: prompt},
		},
		Temperature: 0.3,
	}

	body, _ := json.Marshal(reqBody)
	httpReq, _ := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", bytes.NewReader(body))
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	resp, err := llmHTTPClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("LLM API call failed: %w", err)
	}
	defer resp.Body.Close()

	var llmResp llmResponse
	if err := json.NewDecoder(resp.Body).Decode(&llmResp); err != nil {
		return nil, fmt.Errorf("failed to decode LLM response: %w", err)
	}
	if len(llmResp.Choices) == 0 {
		return nil, fmt.Errorf("LLM returned no choices")
	}

	var result AnalysisResult
	content := llmResp.Choices[0].Message.Content
	content = strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(content, "```json"), "```"))
	content = strings.TrimSuffix(content, "```")
	content = strings.TrimSpace(content)

	if err := json.Unmarshal([]byte(content), &result); err != nil {
		return nil, fmt.Errorf("failed to parse LLM response: %w\nResponse: %s", err, content)
	}
	return &result, nil
}
