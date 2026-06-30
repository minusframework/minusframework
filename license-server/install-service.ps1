param(
  [switch]$Remove,
  [switch]$Start,
  [switch]$Stop,
  [switch]$Status
)

$ServiceName = 'MinusLicenseServer'
$NodePath = (Get-Command node).Source
$ServerDir = $PSScriptRoot
$ServerScript = Join-Path $ServerDir 'server.js'
$NssmDir = Join-Path $ServerDir 'nssm'
$NssmExe = Join-Path $NssmDir 'nssm.exe'

# Check admin
$IsAdmin = [Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
  Write-Host "ERROR: Execute como Administrador (botao direito > Run as Administrator)" -ForegroundColor Red
  exit 1
}

if ($Remove) {
  & $NssmExe stop $ServiceName 2>$null
  & $NssmExe remove $ServiceName confirm 2>$null
  Write-Host "Servico $ServiceName removido."
  return
}

if ($Start) {
  & $NssmExe start $ServiceName 2>&1
  return
}

if ($Stop) {
  & $NssmExe stop $ServiceName 2>&1
  return
}

if ($Status) {
  $s = Get-Service $ServiceName -ErrorAction SilentlyContinue
  if ($s) { Write-Host "${ServiceName}: $($s.Status)" } else { Write-Host "${ServiceName}: nao instalado" }
  return
}

# --- Download NSSM ---
if (-not (Test-Path $NssmExe)) {
  Write-Host 'Baixando NSSM...'
  $url = 'https://nssm.cc/release/nssm-2.24.zip'
  $zip = Join-Path $env:TEMP 'nssm.zip'
  Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
  New-Item -ItemType Directory -Path $NssmDir -Force | Out-Null
  Copy-Item "$env:TEMP\nssm-2.24\win64\nssm.exe" -Destination $NssmExe
  Remove-Item $zip -Force
  Remove-Item "$env:TEMP\nssm-2.24" -Recurse -Force
  Write-Host 'NSSM baixado.'
}

# --- Instalar servico ---
& $NssmExe install $ServiceName $NodePath $ServerScript
& $NssmExe set $ServiceName AppDirectory $ServerDir
& $NssmExe set $ServiceName AppStdout (Join-Path $ServerDir 'logs\stdout.log')
& $NssmExe set $ServiceName AppStderr (Join-Path $ServerDir 'logs\stderr.log')
& $NssmExe set $ServiceName AppRotateFiles 1
& $NssmExe set $ServiceName DisplayName 'MinusFrameWork License Server'
& $NssmExe set $ServiceName Description 'Gera e valida chaves de licenca RSA-2048 para o MinusFrameWork'
& $NssmExe set $ServiceName Start SERVICE_AUTO_START

Write-Host "Servico $ServiceName instalado. Iniciando..."
& $NssmExe start $ServiceName 2>&1
Start-Sleep 2
Get-Service $ServiceName | Format-Table Name, Status, DisplayName -AutoSize
