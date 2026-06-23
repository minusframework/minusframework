<#
.SYNOPSIS
    Gerador de licenças do MinusFramework Enterprise.
.DESCRIPTION
    Gera arquivos .minuslicense assinados com HMAC-SHA256.
.PARAMETER Type
    Tipo de licença: ENTERPRISE, PROFESSIONAL, TRIAL
.PARAMETER Company
    Nome da empresa licenciada
.PARAMETER Developers
    Número de desenvolvedores cobertos
.PARAMETER Expires
    Data de expiração (YYYY-MM-DD)
.PARAMETER Output
    Caminho do arquivo de saída (padrão: .minuslicense no diretório atual)
.EXAMPLE
    .\gen-license.ps1 -Type ENTERPRISE -Company "Acme Corp" -Developers 5 -Expires 2027-06-12
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("ENTERPRISE", "PROFESSIONAL", "TRIAL")]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$Company,

    [Parameter(Mandatory=$false)]
    [int]$Developers = 1,

    [Parameter(Mandatory=$true)]
    [string]$Expires,

    [Parameter(Mandatory=$false)]
    [string]$Output = ".minuslicense"
)

# Chave de assinatura (deve ser idêntica ao CSeed do MF.Licensing.pas)
$Seed = "MF-RSA2048-2026-4F7A2B1C-8D3E5F6A-9B0C1D2E-3F4A5B6C"

# Gerar chave única
$Key = [guid]::NewGuid().ToString("N").Substring(0, 16).ToUpper()
$Key = "$($Key.Substring(0,4))-$($Key.Substring(4,4))-$($Key.Substring(8,4))-$($Key.Substring(12,4))"

# Montar conteúdo
$Content = @"
TYPE=$Type
KEY=$Key
COMPANY=$Company
DEVELOPERS=$Developers
EXPIRES=$Expires
"@.Trim()

# Derivação de chave PBKDF2-like com SHA-256 (dupla iteração)
$sha = [System.Security.Cryptography.SHA256]::Create()
$key1 = [BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Seed))) -replace '-', ''
$combinedStr = $key1 + '|' + $Content
$derivedKeyStr = [BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combinedStr))) -replace '-', ''

# HMAC-SHA256 com chave derivada
$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($derivedKeyStr)
$hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Content))
$Signature = [BitConverter]::ToString($hash) -replace '-', ''

# Adicionar assinatura
$License = "$Content`nSIGNATURE=$Signature"

# Salvar
$License | Out-File -FilePath $Output -Encoding utf8 -NoNewline

Write-Host "✅ Licença gerada: $Output" -ForegroundColor Green
Write-Host "   Tipo: $Type"
Write-Host "   Empresa: $Company"
Write-Host "   Devs: $Developers"
Write-Host "   Expira: $Expires"
Write-Host "   Chave: $Key"
Write-Host ""
Write-Host "Para usar:"
Write-Host "  set MINUSFRAMEWORK_LICENSE=$(($License -replace "`n","|"))" -ForegroundColor Cyan
Write-Host "  ou copie $Output para o diretório do projeto" -ForegroundColor Cyan
