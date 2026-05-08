# AnesFlow GitHub Pages Deployer
$ErrorActionPreference = "Continue"

function ShowError($msg) {
    Write-Host ""
    Write-Host "  ERROR: $msg" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}

Clear-Host
Write-Host ""
Write-Host "  AnesFlow GitHub Pages Deployer" -ForegroundColor Cyan
Write-Host "  ==============================" -ForegroundColor Cyan
Write-Host ""

$AppDir = "C:\Users\ajbur\OneDrive\Documents\Claude\Projects\AnesFlow"
$RepoName = "anesflow"

# Move into app folder
Set-Location $AppDir
Write-Host "  Working in: $AppDir" -ForegroundColor White

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    ShowError "git not found. Install from https://git-scm.com/"
}
Write-Host "  [OK] git found" -ForegroundColor Green

# Init repo if needed
if (-not (Test-Path ".git")) {
    git init -b main
    Write-Host "  [OK] Git repo initialized" -ForegroundColor Green
} else {
    Write-Host "  [OK] Git repo exists" -ForegroundColor Green
}

# Set identity
$gName = (git config user.name 2>$null)
if (-not $gName) {
    git config user.name "Austin Burns"
    git config user.email "ajburns515@gmail.com"
}

# Commit
git add .
git commit -m "Deploy AnesFlow v4 - Reading Recommendations + Mobile iOS UX"
Write-Host "  [OK] Files committed" -ForegroundColor Green

# Check for GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing GitHub CLI via winget..." -ForegroundColor Yellow
    winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
    $env:PATH = $env:PATH + ";C:\Program Files\GitHub CLI"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    ShowError "GitHub CLI not found after install. Download from https://cli.github.com/ and re-run deploy.bat"
}
Write-Host "  [OK] GitHub CLI found" -ForegroundColor Green

# Auth check
$authOut = (gh auth status 2>&1) -join " "
if ($authOut -notmatch "Logged in") {
    Write-Host "  Opening GitHub login in your browser..." -ForegroundColor Yellow
    gh auth login --web --git-protocol https
}

$ghUser = (gh api user --jq .login 2>$null)
if (-not $ghUser) {
    ShowError "Could not get GitHub username. Try running: gh auth login"
}
Write-Host "  [OK] Logged in as: $ghUser" -ForegroundColor Green

# Create repo and push (skip if remote already set)
$remote = (git remote get-url origin 2>$null)
if (-not $remote) {
    Write-Host "  Creating GitHub repo '$RepoName'..." -ForegroundColor White
    gh repo create $RepoName --public --description "AnesFlow Anesthesia Suite" --source . --remote origin --push
    Write-Host "  [OK] Repo created and pushed" -ForegroundColor Green
} else {
    Write-Host "  [OK] Remote exists, pushing..." -ForegroundColor Green
    git push -u origin main
}

# Enable GitHub Pages
Write-Host "  Enabling GitHub Pages..." -ForegroundColor White
gh api "repos/$ghUser/$RepoName/pages" --method POST -f "source[branch]=main" -f "source[path]=/" 2>$null
Write-Host "  [OK] GitHub Pages enabled" -ForegroundColor Green

# Done
$url = "https://$ghUser.github.io/$RepoName"
Write-Host ""
Write-Host "  ================================" -ForegroundColor Green
Write-Host "  DEPLOYED!" -ForegroundColor Green
Write-Host "  ================================" -ForegroundColor Green
Write-Host ""
Write-Host "  URL: $url" -ForegroundColor Cyan
Write-Host ""
Write-Host "  On iPhone:" -ForegroundColor White
Write-Host "  1. Open Safari -> go to the URL above" -ForegroundColor White
Write-Host "  2. Tap Share -> Add to Home Screen" -ForegroundColor White
Write-Host ""
Write-Host "  (Pages can take ~1 min to go live. 404 = wait and refresh)" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
