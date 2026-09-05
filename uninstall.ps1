<#
.SYNOPSIS
  omo-zen-spark 설치 되돌리기. 인스톨러가 만든 타임스탬프 백업 중 최신본으로 복원한다.
.EXAMPLE
  .\uninstall.ps1
  .\uninstall.ps1 -ConfigDir "D:\custom-config"
#>
[CmdletBinding()]
param(
  [string]$ConfigDir = (Join-Path $HOME ".config\opencode")
)
$ErrorActionPreference = "Stop"

function Restore-Latest {
  param([string]$Path)
  $dir = Split-Path -Parent $Path
  $base = Split-Path -Leaf $Path
  $cands = Get-ChildItem -LiteralPath $dir -Filter "$base.*.bak" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending
  if (-not $cands) { Write-Host "[skip] no backup for $base"; return }
  Copy-Item -LiteralPath $cands[0].FullName -Destination $Path -Force
  Write-Host "[restored] $base <- $($cands[0].Name)"
}

Restore-Latest -Path (Join-Path $ConfigDir "opencode.json")
Restore-Latest -Path (Join-Path $ConfigDir "opencode.jsonc")
Restore-Latest -Path (Join-Path $ConfigDir "oh-my-openagent.jsonc")
Write-Host "DONE. Restart opencode completely to apply."
