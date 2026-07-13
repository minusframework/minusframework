# MinusAI Reviewer Bot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a PR review bot as part of MinusAI that validates structural rules, performs semantic analysis via MCP, and can scan the entire codebase.

**Architecture:** Extend the existing MinusAI MCP server with new tools (review_pr, scan_codebase) and a standalone CLI runner. Structural validation is local; semantic analysis reuses the existing MCP infrastructure with LLM integration.

**Tech Stack:** Delphi 11+, MinusAI MCP Server, GitHub REST API, JSON-RPC 2.0

## Global Constraints

- All new units go under `Source/Tools/` with prefix `AI.`
- All MCP tools must follow the existing pattern: `RegisterTool` + tool function
- GitHub API calls use `TNetHTTPClient` (available in Delphi 11+)
- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`, `perf:`
- Naming pattern: `TClasse`, `IMetodo`, `FPropriedade`, `MetodoCamelCase`
- PR size limit: 500 lines or 20 files (configurable via JSON config file)
- All tests go in `Tests/` directory

---

### Task 1: GitHub API Client

**Files:**
- Create: `Source/Tools/AI.GitHubAPI.pas`

**Interfaces:**
- Consumes: Nothing (standalone unit)
- Produces: `TGitHubPRReviewer` class with methods to post reviews, approve/request changes

**Implementation:**

```pascal
unit AI.GitHubAPI;

interface

uses
  System.JSON, System.Net.HttpClient, System.Net.URLEncode, System.SysUtils;

type
  TReviewEvent = (reApprove, reRequestChanges, reComment);
  TReviewComment = record
    Path: string;
    Line: Integer;
    Body: string;
  end;

  TGitHubPRReviewer = class
  private
    FToken: string;
    FRepo: string;
    FPRNumber: Integer;
    FHttpClient: THTTPClient;
    function BuildUrl(const APath: string): string;
    function Post(const AUrl: string; ABody: TJSONObject): TJSONObject;
  public
    constructor Create(const AToken, ARepo: string; APRNumber: Integer);
    destructor Destroy; override;
    procedure PostReview(const AEvent: TReviewEvent; const ABody: string; const AComments: TArray<TReviewComment>);
    procedure PostComment(const ABody: string);
    procedure Approve(const ABody: string);
    procedure RequestChanges(const ABody: string);
  end;

implementation

{ TGitHubPRReviewer }

constructor TGitHubPRReviewer.Create(const AToken, ARepo: string; APRNumber: Integer);
begin
  FToken := AToken;
  FRepo := ARepo;
  FPRNumber := APRNumber;
  FHttpClient := THTTPClient.Create;
  FHttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
  FHttpClient.CustomHeaders['Accept'] := 'application/vnd.github.v3+json';
  FHttpClient.CustomHeaders['User-Agent'] := 'MinusAI-Reviewer/1.0';
end;

destructor TGitHubPRReviewer.Destroy;
begin
  FHttpClient.Free;
  inherited;
end;

function TGitHubPRReviewer.BuildUrl(const APath: string): string;
begin
  Result := 'https://api.github.com/repos/' + FRepo + APath;
end;

function TGitHubPRReviewer.Post(const AUrl: string; ABody: TJSONObject): TJSONObject;
var
  LResponse: IHTTPResponse;
  LStream: TStringStream;
begin
  LStream := TStringStream.Create(ABody.ToJSON);
  try
    LResponse := FHttpClient.Post(AUrl, LStream);
    if LResponse.StatusCode >= 300 then
      raise Exception.CreateFmt('GitHub API error %d: %s', [LResponse.StatusCode, LResponse.ContentAsString]);
    Result := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
  finally
    LStream.Free;
  end;
end;

procedure TGitHubPRReviewer.PostReview(const AEvent: TReviewEvent; const ABody: string; const AComments: TArray<TReviewComment>);
var
  LBody: TJSONObject;
  LComments: TJSONArray;
  LComment: TJSONObject;
  LEventStr: string;
  I: Integer;
begin
  LBody := TJSONObject.Create;
  try
    case AEvent of
      reApprove: LEventStr := 'APPROVE';
      reRequestChanges: LEventStr := 'REQUEST_CHANGES';
      reComment: LEventStr := 'COMMENT';
    end;
    LBody.AddPair('event', LEventStr);
    LBody.AddPair('body', ABody);
    if Length(AComments) > 0 then
    begin
      LComments := TJSONArray.Create;
      for I := 0 to High(AComments) do
      begin
        LComment := TJSONObject.Create;
        LComment.AddPair('path', AComments[I].Path);
        LComment.AddPair('line', TJSONNumber.Create(AComments[I].Line));
        LComment.AddPair('body', AComments[I].Body);
        LComments.Add(LComment);
      end;
      LBody.AddPair('comments', LComments);
    end;
    Post(BuildUrl('/pulls/' + FPRNumber.ToString + '/reviews'), LBody);
  finally
    LBody.Free;
  end;
end;

procedure TGitHubPRReviewer.PostComment(const ABody: string);
var
  LBody: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('body', ABody);
    Post(BuildUrl('/issues/' + FPRNumber.ToString + '/comments'), LBody);
  finally
    LBody.Free;
  end;
end;

procedure TGitHubPRReviewer.Approve(const ABody: string);
begin
  PostReview(reApprove, ABody, []);
end;

procedure TGitHubPRReviewer.RequestChanges(const ABody: string);
begin
  PostReview(reRequestChanges, ABody, []);
end;

end.
```

- [ ] **Step 1:** Create `AI.GitHubAPI.pas` with the code above
- [ ] **Step 2:** Create `Tests/Test.AI.GitHubAPI.pas` with mock tests for URL building and review posting
- [ ] **Step 3:** Run tests and verify they pass
- [ ] **Step 4:** Commit

---

### Task 2: Structural Validation Engine

**Files:**
- Create: `Source/Tools/AI.Validator.pas`

**Interfaces:**
- Consumes: Nothing (standalone)
- Produces: `TValidationEngine` with validation methods

**Implementation:**

```pascal
unit AI.Validator;

interface

uses
  System.JSON, System.RegularExpressions, System.SysUtils, System.Classes,
  System.Generics.Collections;

type
  TValidationSeverity = (vsError, vsWarning, vsInfo);
  TValidationResult = record
    Rule: string;
    Severity: TValidationSeverity;
    Message: string;
    FilePath: string;
    Line: Integer;
  end;
  TCommitMessage = record
    Raw: string;
    CommitType: string;
    Scope: string;
    Description: string;
  end;

  TValidationEngine = class
  private
    FMaxLines: Integer;
    FMaxFiles: Integer;
    FRequireTestsForTypes: TArray<string>;
    FAllowedCommitTypes: TArray<string>;
  public
    constructor Create;
    function ValidateCommitMessage(const AMessage: string): TArray<TValidationResult>;
    function ValidateFileNaming(const AFilePaths: TArray<string>): TArray<TValidationResult>;
    function ValidatePRSize(const AChangedLines: Integer; const AChangedFiles: Integer): TArray<TValidationResult>;
    function ValidateTestExistence(const ACommitType: string; const AChangedFiles: TArray<string>): TArray<TValidationResult>;
    procedure LoadConfig(const AConfig: TJSONObject);
  end;

implementation

{ TValidationEngine }

const
  CONVENTIONAL_COMMIT_PATTERN = '^(feat|fix|docs|chore|refactor|test|ci|perf)(\(.+\))?!?: .+$';
  DELPHI_CLASS_PATTERN = '^T[A-Z][A-Za-z0-9]+$';
  DELPHI_INTERFACE_PATTERN = '^I[A-Z][A-Za-z0-9]+$';
  DELPHI_FIELD_PATTERN = '^F[A-Z][A-Za-z0-9]+$';
  DELPHI_METHOD_PATTERN = '^[a-z][A-Za-z0-9]+$';

constructor TValidationEngine.Create;
begin
  FMaxLines := 500;
  FMaxFiles := 20;
  FRequireTestsForTypes := TArray<string>.Create('feat', 'fix');
  FAllowedCommitTypes := TArray<string>.Create('feat', 'fix', 'docs', 'chore', 'refactor', 'test', 'ci', 'perf');
end;

function TValidationEngine.ValidateCommitMessage(const AMessage: string): TArray<TValidationResult>;
var
  LRegex: TRegEx;
begin
  SetLength(Result, 0);
  LRegex := TRegEx.Create(CONVENTIONAL_COMMIT_PATTERN, [roIgnoreCase]);
  if not LRegex.IsMatch(AMessage) then
  begin
    SetLength(Result, 1);
    Result[0].Rule := 'conventional-commit';
    Result[0].Severity := vsError;
    Result[0].Message := 'Commit message does not follow Conventional Commits pattern: ' +
      'type(scope): description. Allowed types: feat, fix, docs, chore, refactor, test, ci, perf.';
  end;
end;

function TValidationEngine.ValidateFileNaming(const AFilePaths: TArray<string>): TArray<TValidationResult>;
var
  LPath: string;
  LFileName: string;
  LResults: TList<TValidationResult>;
begin
  LResults := TList<TValidationResult>.Create;
  try
    for LPath in AFilePaths do
    begin
      LFileName := ExtractFileName(LPath);
      if LFileName.EndsWith('.pas') then
      begin
        if not TRegEx.IsMatch(LFileName, '^[A-Z][A-Za-z0-9.]*\.pas$') then
        begin
          LResults.Add(TValidationResult.Create(
            'delphi-naming', vsError,
            'File "' + LFileName + '" does not follow Pascal naming: UnitName.pas',
            LPath, 0
          ));
        end;
      end;
    end;
    Result := LResults.ToArray;
  finally
    LResults.Free;
  end;
end;

function TValidationEngine.ValidatePRSize(const AChangedLines: Integer; const AChangedFiles: Integer): TArray<TValidationResult>;
begin
  SetLength(Result, 0);
  if AChangedLines > FMaxLines then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Rule := 'pr-size-lines';
    Result[High(Result)].Severity := vsError;
    Result[High(Result)].Message := Format('PR exceeds %d lines (%d). Break into smaller PRs.', [FMaxLines, AChangedLines]);
  end;
  if AChangedFiles > FMaxFiles then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Rule := 'pr-size-files';
    Result[High(Result)].Severity := vsError;
    Result[High(Result)].Message := Format('PR exceeds %d files (%d). Break into smaller PRs.', [FMaxFiles, AChangedFiles]);
  end;
end;

function TValidationEngine.ValidateTestExistence(const ACommitType: string; const AChangedFiles: TArray<string>): TArray<TValidationResult>;
var
  LHasTests: Boolean;
  LFile: string;
  I: Integer;
begin
  SetLength(Result, 0);
  for I := 0 to High(FRequireTestsForTypes) do
  begin
    if SameText(FRequireTestsForTypes[I], ACommitType) then
    begin
      LHasTests := False;
      for LFile in AChangedFiles do
      begin
        if LFile.Contains('\Tests\') or LFile.Contains('/Tests/') then
        begin
          LHasTests := True;
          Break;
        end;
      end;
      if not LHasTests then
      begin
        SetLength(Result, 1);
        Result[0].Rule := 'require-tests';
        Result[0].Severity := vsError;
        Result[0].Message := Format('Commits of type "%s" require test files in Tests/ directory.', [ACommitType]);
      end;
      Break;
    end;
  end;
end;

procedure TValidationEngine.LoadConfig(const AConfig: TJSONObject);
begin
  if Assigned(AConfig.Values['maxLines']) then
    FMaxLines := (AConfig.Values['maxLines'] as TJSONNumber).AsInt;
  if Assigned(AConfig.Values['maxFiles']) then
    FMaxFiles := (AConfig.Values['maxFiles'] as TJSONNumber).AsInt;
end;

end.
```

- [ ] **Step 1:** Create `AI.Validator.pas` with the code above
- [ ] **Step 2:** Create `Tests/Test.AI.Validator.pas` with tests for commit message, naming, PR size, test existence
- [ ] **Step 3:** Run tests and verify they pass
- [ ] **Step 4:** Commit

---

### Task 3: PR Review Tool (MCP)

**Files:**
- Create: `Source/Tools/AI.ReviewPR.pas`
- Modify: `Source/MiniusAI_MCP.dpr` (register new tool)

**Interfaces:**
- Consumes: `TGitHubPRReviewer`, `TValidationEngine`
- Produces: MCP tool `review_pr` and `review_pr_status`

**Implementation:**

```pascal
unit AI.ReviewPR;

interface

uses
  MCP.Server, MCP.Types;

procedure RegistrarReviewPR(AServer: TMCServer);
procedure RegistrarReviewPRStatus(AServer: TMCServer);

implementation

uses
  AI.GitHubAPI, AI.Validator, System.JSON, System.SysUtils, System.Classes;

procedure RegistrarReviewPR(AServer: TMCServer);
begin
  AServer.RegisterTool('review_pr',
    'Revisa um Pull Request do GitHub: valida estrutura, nomenclatura, tamanho e testes. ' +
    'Se configurado com LLM, faz análise semântica do código alterado.',
    'revisar_pr',
    function(const AParams: TJSONObject): TMCPToolResult
    var
      LToken, LRepo: string;
      LPRNumber: Integer;
      LReviewer: TGitHubPRReviewer;
      LValidator: TValidationEngine;
      LResults: TArray<TValidationResult>;
      LResult: TValidationResult;
      LComments: TArray<TReviewComment>;
      LHasErrors: Boolean;
      LBody: TStringBuilder;
      LComment: TReviewComment;
    begin
      LToken := (AParams.Values['token'] as TJSONString).Value;
      LRepo := (AParams.Values['repo'] as TJSONString).Value;
      LPRNumber := (AParams.Values['pr_number'] as TJSONNumber).AsInt;

      LReviewer := TGitHubPRReviewer.Create(LToken, LRepo, LPRNumber);
      LValidator := TValidationEngine.Create;
      LBody := TStringBuilder.Create;
      try
        LHasErrors := False;

        if AParams.Values['commit_message'] <> nil then
          LResults := LValidator.ValidateCommitMessage(
            (AParams.Values['commit_message'] as TJSONString).Value
          );

        if AParams.Values['changed_files'] <> nil then
        begin
          LResults := LResults + LValidator.ValidateFileNaming(
            TJSONUtils.ToStringArray(AParams.Values['changed_files'] as TJSONArray)
          );
        end;

        if (AParams.Values['changed_lines'] <> nil) and (AParams.Values['total_files'] <> nil) then
        begin
          LResults := LResults + LValidator.ValidatePRSize(
            (AParams.Values['changed_lines'] as TJSONNumber).AsInt,
            (AParams.Values['total_files'] as TJSONNumber).AsInt
          );
        end;

        LBody.Append('## MinusAI Reviewer Report' + sLineBreak + sLineBreak);

        for LResult in LResults do
        begin
          case LResult.Severity of
            vsError: begin
              LHasErrors := True;
              LBody.Append('❌ **Erro** (' + LResult.Rule + '): ' + LResult.Message + sLineBreak);
            end;
            vsWarning: LBody.Append('⚠️ **Aviso** (' + LResult.Rule + '): ' + LResult.Message + sLineBreak);
            vsInfo: LBody.Append('ℹ️ **Info** (' + LResult.Rule + '): ' + LResult.Message + sLineBreak);
          end;
        end;

        if LHasErrors then
        begin
          LBody.Append(sLineBreak + '**Resultado: Mudanças solicitadas.**');
          LReviewer.RequestChanges(LBody.ToString);
        end
        else
        begin
          LBody.Append(sLineBreak + '**Resultado: Aprovado.**');
          LReviewer.Approve(LBody.ToString);
        end;

        Result.Content := TJSONArray.Create;
        Result.Content.Add(TJSONObject.Create.AddPair('status', 'review_posted'));
      finally
        LReviewer.Free;
        LValidator.Free;
        LBody.Free;
      end;
    end
  );
end;

procedure RegistrarReviewPRStatus(AServer: TMCServer);
begin
  AServer.RegisterTool('review_pr_status',
    'Verifica o status da revisão mais recente de um PR.',
    'revisar_pr_status',
    function(const AParams: TJSONObject): TMCPToolResult
    begin
      Result.Content := TJSONArray.Create;
      Result.Content.Add(TJSONObject.Create.AddPair('status', 'pending'));
    end
  );
end;

end.
```

- [ ] **Step 1:** Create `AI.ReviewPR.pas`
- [ ] **Step 2:** Modify `MinusAI_MCP.dpr` to call `RegistrarReviewPR` and `RegistrarReviewPRStatus`
- [ ] **Step 3:** Compile and verify no errors
- [ ] **Step 4:** Create `Tests/Test.AI.ReviewPR.pas`
- [ ] **Step 5:** Commit

---

### Task 4: Codebase Scanner Tool

**Files:**
- Create: `Source/Tools/AI.CodebaseScan.pas`

**Interfaces:**
- Consumes: `AI.Validator`
- Produces: MCP tool `scan_codebase`

**Implementation:**

```pascal
unit AI.CodebaseScan;

interface

uses
  MCP.Server, MCP.Types;

procedure RegistrarCodebaseScan(AServer: TMCServer);

implementation

uses
  AI.Validator, System.JSON, System.SysUtils, System.Classes,
  System.Generics.Collections, System.IOUtils;

procedure RegistrarCodebaseScan(AServer: TMCServer);
begin
  AServer.RegisterTool('scan_codebase',
    'Varre toda a codebase em busca de violacoes de padroes: nomenclatura, estrutura e conformidade.',
    'scan_codebase',
    function(const AParams: TJSONObject): TMCPToolResult
    var
      LRootDir: string;
      LValidator: TValidationEngine;
      LResults: TList<TValidationResult>;
      LFiles: TArray<string>;
      LFile: string;
      LResult: TValidationResult;
      LJsonResult: TJSONObject;
      LJsonResults: TJSONArray;
    begin
      LRootDir := (AParams.Values['root'] as TJSONString).Value;
      LValidator := TValidationEngine.Create;
      LResults := TList<TValidationResult>.Create;
      try
        if TDirectory.Exists(LRootDir) then
        begin
          LFiles := TDirectory.GetFiles(LRootDir, '*.pas', TSearchOption.soAllDirectories);
          for LFile in LFiles do
            LResults.AddRange(LValidator.ValidateFileNaming([LFile]));
        end;

        LJsonResults := TJSONArray.Create;
        for LResult in LResults do
        begin
          LJsonResult := TJSONObject.Create;
          LJsonResult.AddPair('rule', LResult.Rule);
          LJsonResult.AddPair('severity', TJSONNumber.Create(Integer(LResult.Severity)));
          LJsonResult.AddPair('message', LResult.Message);
          LJsonResult.AddPair('file', LResult.FilePath);
          LJsonResult.AddPair('line', TJSONNumber.Create(LResult.Line));
          LJsonResults.Add(LJsonResult);
        end;

        Result.Content := TJSONArray.Create;
        Result.Content.Add(TJSONObject.Create
          .AddPair('total_files', TJSONNumber.Create(Length(LFiles)))
          .AddPair('violations', TJSONNumber.Create(LResults.Count))
          .AddPair('results', LJsonResults)
        );
      finally
        LValidator.Free;
        LResults.Free;
      end;
    end
  );
end;

end.
```

- [ ] **Step 1:** Create `AI.CodebaseScan.pas` with the code above
- [ ] **Step 2:** Register `RegistrarCodebaseScan` in `MinusAI_MCP.dpr`
- [ ] **Step 3:** Compile and verify no errors
- [ ] **Step 4:** Create `Tests/Test.AI.CodebaseScan.pas` with tests that scan a temp directory
- [ ] **Step 5:** Commit

---

### Task 5: Reviewer CLI Runner

**Files:**
- Create: `Source/MiniusAI_Reviewer.dpr`
- Create: `Source/MiniusAI_Reviewer.dproj`

**Interfaces:**
- Consumes: All previous units
- Produces: Standalone EXE callable from GitHub Actions

**Implementation:**

```pascal
program MinusAI_Reviewer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.JSON, AI.GitHubAPI, AI.Validator, AI.ReviewPR;

var
  LToken, LRepo, LEvent, LPRNumberStr: string;
  LPRNumber: Integer;
  LReviewer: TGitHubPRReviewer;
  LValidator: TValidationEngine;
begin
  // Usage: MinusAI_Reviewer.exe --token GH_TOKEN --repo owner/repo --pr 123 --event opened
  LToken := ParamStr(2);
  LRepo := ParamStr(4);
  LPRNumberStr := ParamStr(6);
  LEvent := ParamStr(8);
  LPRNumber := StrToInt(LPRNumberStr);

  LReviewer := TGitHubPRReviewer.Create(LToken, LRepo, LPRNumber);
  LValidator := TValidationEngine.Create;
  try
    // Run validation and post review
    LReviewer.RequestChanges('Review by MinusAI — structural validation pending...');
    WriteLn('Review posted for PR #' + LPRNumberStr + ' on ' + LRepo);
  finally
    LReviewer.Free;
    LValidator.Free;
  end;
end.
```

- [ ] **Step 1:** Create `MinusAI_Reviewer.dpr` and `.dproj`
- [ ] **Step 2:** Compile and verify
- [ ] **Step 3:** Commit

---

### Task 6: GitHub Actions Workflow

**Files:**
- Create: `.github/workflows/review-pr.yml` (template)
- Create: `review-pr.yml` templates for all 9 repos

**Implementation:**

```yaml
name: Review PR

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      
      - name: MinusAI Code Review
        uses: GabrielFerreiraMendes/minusframework-ai/.github/actions/review-pr@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          pr-number: ${{ github.event.pull_request.number }}
          repo: ${{ github.repository }}
          commit-message: ${{ github.event.pull_request.title }}
```

- [ ] **Step 1:** Create `.github/workflows/review-pr.yml` in `minusframework-ai`
- [ ] **Step 2:** Create `.github/workflows/codebase-scan.yml` for periodic scans
- [ ] **Step 3:** Commit

---

### Task 7: Workflow Templates for All Repos

**Files:**
- Create: `minusframework-core/.github/workflows/review-pr.yml`
- Create: `minusframework-orm/.github/workflows/review-pr.yml`
- Create: `minusframework-migrator/.github/workflows/review-pr.yml`
- Create: `minusframework-cli/.github/workflows/review-pr.yml`
- Create: `minusframework-extensions/.github/workflows/review-pr.yml`
- Create: `minusframework-messaging/.github/workflows/review-pr.yml`
- Create: `minusframework-featureflags/.github/workflows/review-pr.yml`
- Create: `minusframework-telemetry/.github/workflows/review-pr.yml`

- [ ] **Step 1:** Deploy workflow template to all 8 repos
- [ ] **Step 2:** Commit each
