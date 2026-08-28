$ErrorActionPreference = "Stop"

Write-Host "Checking Node.js / npm..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js is not installed or not available in PATH."
}
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx is not available in PATH."
}

Write-Host "Installing/updating joshyattridge/amazon-kdp-skill..."
& npx.cmd skills add joshyattridge/amazon-kdp-skill

if ($LASTEXITCODE -ne 0) {
    throw "amazon-kdp-skill installation failed with exit code $LASTEXITCODE."
}

Write-Host "Applying tested local hardening..."
& (Join-Path $PSScriptRoot "harden-kdp-skill.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "amazon-kdp-skill hardening failed with exit code $LASTEXITCODE."
}

Write-Host "amazon-kdp-skill installation and hardening completed."
Write-Host "Recommended read-only verification: .\scripts\kdp-smoke.ps1"
Write-Host "Amazon login/MFA must be completed by the user in the visible browser window when explicitly started later."
