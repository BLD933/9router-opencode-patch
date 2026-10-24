# 9router OpenCode free-lane patch - Windows installer
# Usage (PowerShell):
#   $env:OPENCODE_API_KEY = "oc_sk_..."
#   $env:OPENCODE_ORG_ID  = "wrk_..."
#   .\install.ps1

$ErrorActionPreference = "Stop"

if (-not $env:OPENCODE_API_KEY) { throw "Set `$env:OPENCODE_API_KEY = 'oc_sk_...'" }
if (-not $env:OPENCODE_ORG_ID)  { throw "Set `$env:OPENCODE_ORG_ID = 'wrk_...'" }

$NinerouterApp = if ($env:NINEROUTER_APP) { $env:NINEROUTER_APP } else { "$env:APPDATA\npm\node_modules\9router\app" }
$Chunks = Join-Path $NinerouterApp ".next-cli-build\server\chunks"
if (-not (Test-Path $Chunks)) { throw "9router chunks not found at $Chunks. Install 9router first: npm i -g 9router@0.5.109" }

$Python = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } elseif (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { throw "Python not found. Install from https://www.python.org/downloads/" }
$Bun = if (Get-Command bun -ErrorAction SilentlyContinue) { "bun" } else { throw "Bun not found. Install: powershell -c `"irm bun.sh/install.ps1 | iex`"" }

$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:NINEROUTER_APP = $NinerouterApp
& $Python (Join-Path $Dir "patch9router.py")

# Start sidecar if not already listening
$portOpen = $false
try { $c = New-Object Net.Sockets.TcpClient("127.0.0.1",8199); $c.Close(); $portOpen = $true } catch {}
if (-not $portOpen) {
    Start-Process -FilePath $Bun -ArgumentList (Join-Path $Dir "ocside.mjs") -RedirectStandardOutput (Join-Path $Dir "ocside.log") -RedirectStandardError (Join-Path $Dir "ocside.err.log") -WindowStyle Hidden
    Start-Sleep -Seconds 3
    Get-Content (Join-Path $Dir "ocside.log") -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Sidecar started on 127.0.0.1:8199"
Write-Host "Now start 9router:  9router -t -n --skip-update"
Write-Host "Test:  curl http://localhost:20128/v1/chat/completions -H 'Authorization: Bearer <9router-key>' -H 'Content-Type: application/json' -d '{\"model\":\"opencode/deepseek-v4.1-flash-free\",\"messages\":[{\"role\":\"user\",\"content\":\"say ok\"}],\"max_tokens\":16,\"stream\":false}'"
