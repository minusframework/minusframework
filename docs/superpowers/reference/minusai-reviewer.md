# MinusAI Reviewer Bot

## Overview

The MinusAI Reviewer bot automatically reviews Pull Requests across all MinusFrameWork repos, validating adherence to project standards before human review.

## Architecture

```
GitHub PR → review-pr.yml workflow → MinusAI_Reviewer.exe → GitHub API → PR review comments
                ↓
         (optional) MCP Server → scan_codebase, review_pr tools
```

## Components

| Component | File | Purpose |
|-----------|------|---------|
| CLI Runner | `Source/MinusAI_Reviewer.dpr` | Entry point for GitHub Actions |
| MCP Server | `Source/MinueAI_MCP.dpr` | MCP protocol server for IDE/CLI tools |
| GitHub API Client | `Source/Tools/AI.GitHubAPI.pas` | HTTP client for GitHub PR review API |
| Validation Engine | `Source/Tools/AI.Validator.pas` | Structural validation rules engine |
| PR Review Tools | `Source/Tools/AI.ReviewPR.pas` | MCP tools: `review_pr`, `review_pr_status` |
| Codebase Scanner | `Source/Tools/AI.CodebaseScan.pas` | MCP tool: `scan_codebase` |

## Validation Rules

| Rule | Severity | Description |
|------|----------|-------------|
| `conventional-commit` | ERROR | PR title must follow Conventional Commits: `type(scope): description` |
| `delphi-naming` | ERROR | Pascal files must follow `T[CamelCase].pas` naming |
| `pr-size-lines` | ERROR | PR exceeds 500 changed lines (configurable) |
| `pr-size-files` | ERROR | PR exceeds 20 files (configurable) |
| `require-tests` | ERROR | `feat` and `fix` commits require tests in `Tests/` directory |

### Configuration via JSON

```json
{
  "maxLines": 500,
  "maxFiles": 20,
  "requireTestsFor": ["feat", "fix"]
}
```

## GitHub Actions Workflow

Each repo has `.github/workflows/review-pr.yml`:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v5
      - name: MinusAI Code Review
        uses: GabrielFerreiraMendes/minusframework-ai/.github/actions/review-pr@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ github.event.pull_request.number }}
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_TOKEN` | Yes | GitHub Personal Access Token with repo scope |
| `MCP_DB_DRIVER` | No | FireDAC database driver (for MCP tools) |
| `MCP_DB_*` | No | Database connection params (MCP tools) |

## Repositories with Workflows

- minusframework-core
- minusframework-orm
- minusframework-migrator
- minusframework-cli
- minusframework-extensions
- minusframework-messaging
- minusframework-featureflags
- minusframework-telemetry

## Appendix: Post-Review Actions

- **Approved PR** → `APPROVE` review event posted
- **Violations found** → `REQUEST_CHANGES` review event posted with detailed report
- **Error/network failure** → Exception logged, workflow fails (visible in Actions tab)
