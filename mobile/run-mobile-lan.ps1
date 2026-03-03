param(
    [string]$BackendHostIp,
    [int]$Port = 8000,
    [string]$ApiPrefix = '/api/v1',
    [string]$DeviceId,
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = 'Stop'

function Get-LocalIpv4Address {
    $config = Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4Address -and
            $_.IPv4DefaultGateway -and
            $_.NetAdapter.Status -eq 'Up'
        } |
        Select-Object -First 1

    if ($config -and $config.IPv4Address) {
        return $config.IPv4Address.IPAddress
    }

    throw 'Unable to detect an active IPv4 address. Pass -BackendHostIp manually.'
}

if ([string]::IsNullOrWhiteSpace($BackendHostIp)) {
    $BackendHostIp = Get-LocalIpv4Address
}

$apiBaseUrl = "http://$BackendHostIp`:$Port$ApiPrefix"
$healthUrl = "http://$BackendHostIp`:$Port/api/v1/health/"

Write-Host "Using backend host: $BackendHostIp"
Write-Host "API_BASE_URL: $apiBaseUrl"

if (-not $SkipHealthCheck) {
    Write-Host "Checking backend health: $healthUrl"
    try {
        $healthResponse = Invoke-WebRequest -UseBasicParsing -Uri $healthUrl -TimeoutSec 5
        Write-Host "Backend health OK: $($healthResponse.Content)"
    }
    catch {
        throw "Backend health check failed at $healthUrl. Start backend first, or pass -SkipHealthCheck. Error: $($_.Exception.Message)"
    }
}

$flutterArgs = @('run', "--dart-define=API_BASE_URL=$apiBaseUrl")
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $flutterArgs += @('-d', $DeviceId)
}

Push-Location $PSScriptRoot
try {
    & flutter @flutterArgs
}
finally {
    Pop-Location
}
