$ErrorActionPreference = "Stop"

Write-Host "Checking Node.js / npm..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js is not installed or not available in PATH."
}
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx is not available in PATH."
}

Write-Host "Installing/updating joshyattridge/amazon-kdp-skill..."
npx skills add joshyattridge/amazon-kdp-skill

if ($LASTEXITCODE -ne 0) {
    throw "amazon-kdp-skill installation failed with exit code $LASTEXITCODE."
}

Write-Host "amazon-kdp-skill installation completed."
Write-Host "Next step: let the agent check the KDP session. Amazon login/MFA must be completed by the user in the visible browser window when requested."
