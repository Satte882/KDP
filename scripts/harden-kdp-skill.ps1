$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillRoot = Join-Path $repoRoot ".agents\skills\amazon-kdp"
$packageJson = Join-Path $skillRoot "package.json"
$publishFile = Join-Path $skillRoot "server\src\kdpPublish.ts"
$sheetJsPackage = "https://cdn.sheetjs.com/xlsx-0.20.3/xlsx-0.20.3.tgz"

if (-not (Test-Path $packageJson)) {
    throw "Amazon KDP skill package.json not found at $packageJson"
}
if (-not (Test-Path $publishFile)) {
    throw "Amazon KDP publish source not found at $publishFile"
}

Write-Host "Hardening repo-local Amazon KDP skill..."

# 1) Replace the stale vulnerable npm-registry SheetJS release with the
# official SheetJS CE 0.20.3 package. --ignore-scripts avoids unrelated
# postinstall effects while changing this dependency.
Push-Location $skillRoot
try {
    Write-Host "Installing SheetJS 0.20.3 from the official SheetJS CDN..."
    & npm.cmd install --ignore-scripts --save-exact $sheetJsPackage
    if ($LASTEXITCODE -ne 0) {
        throw "SheetJS upgrade failed with exit code $LASTEXITCODE"
    }

    Write-Host "Running production dependency audit..."
    & npm.cmd audit --omit=dev
    if ($LASTEXITCODE -ne 0) {
        throw "npm audit still reports production vulnerabilities after hardening."
    }
}
finally {
    Pop-Location
}

# 2) Work around a current upstream scope bug in kdpPublish.ts.
# Upstream declares `const saveResult` inside hasMetadata(...) but references
# saveResult later outside that block. tsx/esbuild transpiles despite the TS
# diagnostic, so the live write path can otherwise hit an undefined binding.
$content = Get-Content -Raw -Path $publishFile

$alreadyFixed = $content -match 'if \(saveResult && !saveResult\.saved && saveResult\.filled\.length > 0\)'
$hasBrokenDeclaration = $content -match 'const saveResult = await saveDetailsOnPage\('
$hasBrokenUse = $content -match 'if \(!saveResult\.saved && saveResult\.filled\.length > 0\)'

if ($alreadyFixed) {
    Write-Host "Publish saveResult scope fix already present; no source patch needed."
}
elseif ($hasBrokenDeclaration -and $hasBrokenUse) {
    $declarationPattern = '(?s)(if \(!dryRun && \(hasMetadata\(request\.details\) \|\| request\.categories\?\.length\)\) \{\s*try \{\s*)(if \(hasMetadata\(request\.details\)\) \{\s*)const saveResult = await saveDetailsOnPage\('
    $declarationReplacement = '$1let saveResult: Awaited<ReturnType<typeof saveDetailsOnPage>> | undefined`r`n        $2saveResult = await saveDetailsOnPage('

    $patched = [regex]::Replace($content, $declarationPattern, $declarationReplacement, 1)
    if ($patched -eq $content) {
        throw "Expected upstream saveResult declaration pattern was not found. Refusing to patch unknown source."
    }

    $patched = $patched -replace 'if \(!saveResult\.saved && saveResult\.filled\.length > 0\)', 'if (saveResult && !saveResult.saved && saveResult.filled.length > 0)'
    Set-Content -Path $publishFile -Value $patched -Encoding UTF8
    Write-Host "Applied local kdpPublish.ts saveResult scope fix."
}
else {
    throw "Upstream kdpPublish.ts differs from the known vulnerable/fixed shapes. Review upstream before applying local hardening."
}

Write-Host "KDP skill hardening completed."
Write-Host "Note: .agents/ is generated local state. Re-run this script after reinstalling/updating the upstream skill."
