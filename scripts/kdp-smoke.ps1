$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillRoot = Join-Path $repoRoot ".agents\skills\amazon-kdp"
$apiBase = "http://127.0.0.1:3001"
$healthUrl = "$apiBase/api/kdp/health"
$statusUrl = "$apiBase/api/kdp/status"
$startedServer = $false
$serverProcess = $null

if (-not (Test-Path $skillRoot)) {
    throw "Amazon KDP skill not found at $skillRoot"
}

# Avoid Windows localhost/IPv6 resolution differences in Node fetch.
$env:KDP_API_URL = $apiBase

function Test-KdpHealth {
    try {
        $health = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 2
        return ($health.ok -eq $true)
    }
    catch {
        return $false
    }
}

try {
    if (-not (Test-KdpHealth)) {
        Write-Host "KDP server is not running. Starting local server..."
        $serverProcess = Start-Process -FilePath "npm.cmd" `
            -ArgumentList @("run", "server:start") `
            -WorkingDirectory $skillRoot `
            -PassThru
        $startedServer = $true

        $ready = $false
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Milliseconds 500
            if (Test-KdpHealth) {
                $ready = $true
                break
            }
            if ($serverProcess.HasExited) {
                throw "KDP server exited before becoming healthy (exit code $($serverProcess.ExitCode))."
            }
        }
        if (-not $ready) {
            throw "KDP server did not become healthy at $healthUrl"
        }
    }

    Write-Host "Health endpoint: OK"

    $directStatus = Invoke-RestMethod -Uri $statusUrl -Method Get -TimeoutSec 10
    Write-Host ("Direct status endpoint: " + ($directStatus | ConvertTo-Json -Compress))

    Push-Location $skillRoot
    try {
        Write-Host "Running upstream CLI status with KDP_API_URL=$env:KDP_API_URL ..."
        & npm.cmd run status
        if ($LASTEXITCODE -ne 0) {
            throw "Upstream npm run status failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host "KDP read-only smoke test passed. No login or write operation was performed."
}
finally {
    if ($startedServer -and $serverProcess -and -not $serverProcess.HasExited) {
        Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped temporary KDP server process."
    }
}
