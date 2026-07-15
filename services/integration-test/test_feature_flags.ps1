$ErrorActionPreference = "Stop"

Write-Host "=== Feature Flags Integration Test ===" -ForegroundColor Cyan

# 1. Health check
Write-Host "Checking health..."
$health = Invoke-RestMethod -Uri "http://localhost:9083/health" -TimeoutSec 5
if ($health.status -ne "ok") { throw "Health check failed" }
Write-Host "  PASS" -ForegroundColor Green

# 2. Create environment (requires JWT — get token from license-server)
Write-Host "Getting JWT..."
$jwtResp = Invoke-RestMethod -Uri "http://localhost:9080/auth/github/callback?code=test" -TimeoutSec 5
$JWT_TOKEN = $jwtResp.token
Write-Host "  JWT obtained" -ForegroundColor Green

Write-Host "Creating environment..."
$envBody = @{name = "staging"} | ConvertTo-Json
$envResp = Invoke-RestMethod -Uri "http://localhost:9083/api/v1/environments" `
    -Method POST -Body $envBody -ContentType "application/json" `
    -Headers @{"Authorization" = "Bearer $JWT_TOKEN"} -TimeoutSec 5
$ENV_ID = $envResp.id
Write-Host "  Created: $ENV_ID" -ForegroundColor Green

# 3. Create flag
Write-Host "Creating flag..."
$flagBody = @{key = "new_checkout"; name = "Novo Checkout"; flag_type = "boolean"} | ConvertTo-Json
$flagResp = Invoke-RestMethod -Uri "http://localhost:9083/api/v1/flags" `
    -Method POST -Body $flagBody -ContentType "application/json" `
    -Headers @{"Authorization" = "Bearer $JWT_TOKEN"} -TimeoutSec 5
$FLAG_ID = $flagResp.id
Write-Host "  Created: $FLAG_ID" -ForegroundColor Green

# 4. Toggle flag on
Write-Host "Toggling flag..."
$toggleBody = @{enabled = $true; environment_id = $ENV_ID; rollout_percentage = 50} | ConvertTo-Json
$toggleResp = Invoke-RestMethod -Uri "http://localhost:9083/api/v1/flags/$FLAG_ID/toggle" `
    -Method PUT -Body $toggleBody -ContentType "application/json" `
    -Headers @{"Authorization" = "Bearer $JWT_TOKEN"} -TimeoutSec 5
if (-not $toggleResp.enabled) { throw "Flag not enabled" }
Write-Host "  Toggle OK" -ForegroundColor Green

# 5. List flags
Write-Host "Listing flags..."
$flags = Invoke-RestMethod -Uri "http://localhost:9083/api/v1/flags?environment_id=$ENV_ID" `
    -Headers @{"Authorization" = "Bearer $JWT_TOKEN"} -TimeoutSec 5
if ($flags.Count -eq 0) { throw "No flags returned" }
Write-Host "  Found $($flags.Count) flag(s)" -ForegroundColor Green

# 6. Verify unauthorized access blocks
Write-Host "Verifying auth rejection..."
try {
    $null = Invoke-RestMethod -Uri "http://localhost:9083/api/v1/flags" -TimeoutSec 5
    throw "Expected 401"
} catch {
    if ($_.Exception.Response.StatusCode -ne 401) { throw "Expected 401, got $($_.Exception.Response.StatusCode)" }
}
Write-Host "  PASS" -ForegroundColor Green

Write-Host "=== All feature flags tests passed ===" -ForegroundColor Cyan
