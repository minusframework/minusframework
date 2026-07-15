param(
    [string]$LicenseKey,
    [string]$GitHubToken,
    [string]$Repo,
    [int]$PRNumber
)

$licenseResult = Invoke-RestMethod -Uri "http://license-server:8080/licenses/validate" `
    -Method POST `
    -Body (@{license_key = $LicenseKey; device_id = "worker-$env:COMPUTERNAME"} | ConvertTo-Json) `
    -ContentType "application/json"

if (-not $licenseResult.valid) {
    Write-Error "License validation failed: $($licenseResult.error)"
    exit 1
}

& ".\MinusAI_Reviewer.exe" `
    --token $GitHubToken `
    --repo $Repo `
    --pr $PRNumber `
    --event opened

if ($LASTEXITCODE -ne 0) {
    Write-Error "Reviewer failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Review posted successfully" -ForegroundColor Green
