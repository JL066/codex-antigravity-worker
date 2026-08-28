# ==============================================================================
# codex-antigravity-worker Windows 11 PowerShell Installer
# Note: Prepared and structured for Windows; pending formal on-device verification.
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$SkillsDest = Join-Path $CodexHome "skills\antigravity-flash-worker"
$ConfigFile = Join-Path $CodexHome "config.toml"

Write-Host "=== Codex Antigravity Worker Windows Installation ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check Antigravity CLI (`agy.exe`)
Write-Host "[1/4] Checking Google Antigravity CLI ('agy.exe')..." -ForegroundColor Yellow
$AgyCmd = Get-Command "agy.exe" -ErrorAction SilentlyContinue
if ($AgyCmd) {
    Write-Host "      Found agy at: $($AgyCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "      [!] 'agy.exe' not found in PATH." -ForegroundColor DarkYellow
    Write-Host "          Ensure Google Antigravity CLI is installed and authenticated." -ForegroundColor Gray
}

# 2. Check `agy-mcp.exe`
Write-Host "[2/4] Checking 'agy-mcp.exe' MCP Server..." -ForegroundColor Yellow
$AgyMcpCmd = Get-Command "agy-mcp.exe" -ErrorAction SilentlyContinue
if ($AgyMcpCmd) {
    Write-Host "      Found agy-mcp at: $($AgyMcpCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "      [!] 'agy-mcp.exe' not found in PATH." -ForegroundColor DarkYellow
    Write-Host "          Download Windows release binary from: https://github.com/tphakala/agy-mcp/releases" -ForegroundColor Gray
}

# 3. Install Codex Skill
Write-Host "[3/4] Installing 'antigravity-flash-worker' Codex Skill..." -ForegroundColor Yellow
if (-not (Test-Path $SkillsDest)) {
    New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null
}
$SkillSource = Join-Path $RepoRoot "skills\antigravity-flash-worker\SKILL.md"
$SkillTarget = Join-Path $SkillsDest "SKILL.md"
Copy-Item -Path $SkillSource -Destination $SkillTarget -Force
Write-Host "      Installed skill to: $SkillTarget" -ForegroundColor Green

# 4. Check Codex Configuration
Write-Host "[4/4] Checking Codex MCP configuration ($ConfigFile)..." -ForegroundColor Yellow
if ((Test-Path $ConfigFile) -and (Select-String -Path $ConfigFile -SimpleMatch "[mcp_servers.agy]" -Quiet)) {
    Write-Host "      'agy' MCP server is already registered in $ConfigFile." -ForegroundColor Green
} else {
    Write-Host "      'agy' MCP server is NOT yet registered in $ConfigFile." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      To register, add the following to $ConfigFile:" -ForegroundColor Gray
    Write-Host "      ------------------------------------------------------" -ForegroundColor DarkGray
    $ExampleConfig = Get-Content (Join-Path $RepoRoot "config\codex-mcp.example.toml") -Raw
    Write-Host $ExampleConfig
    Write-Host "      ------------------------------------------------------" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
