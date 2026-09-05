<#PSScriptInfo>
.VERSION 1.0.0
.GUID 7c2e4a1b-9f3d-4c5a-b8e1-omo-zen-spark01
.AUTHOR omo-zen-spark
.DESCRIPTION Nonstop installer: OMO + OPENCODE ZEN MUSE SPARK 1.3 FREE model pin.
#>
<#
.SYNOPSIS
  OMO + MUSE SPARK 1.3 FREE 논스톱 설치.
  기존 opencode.json/jsonc의 mcp/provider 섹션은 건드리지 않고 모델 고정만 병합한다.
.DESCRIPTION
  1. opencode 미설치 시 공식 인스톨러로 설치
  2. 기존 설정 백업(타임스탬프)
  3. model/small_model + agent 17종 + instructions + plugin 병합
  4. oh-my-openagent.jsonc 기록 (agents 14 + categories 8)
  5. 검증 출력
  설치 후 opencode를 완전히 재시작해야 적용된다.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.ps1 | iex"
.EXAMPLE
  .\install.ps1 -ConfigDir "D:\custom-config"   # 드라이런/커스텀 경로 검증용
#>
[CmdletBinding()]
param(
  [string]$ConfigDir = (Join-Path $HOME ".config\opencode"),
  [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$Model = "opencode/muse-spark-1.3-contributor-free"
$Plugin = "oh-my-openagent@latest"
$Policy = "GLOBAL MODEL POLICY (OPENCODE ZEN): Every agent including all subagents MUST use opencode/muse-spark-1.3-contributor-free. Never switch to openai/gpt-5.6-luna-fast, openai/gpt-5.6-sol, openai/gpt-5.6-terra, anthropic/claude-opus-5 or any other model. If a plugin default specifies another model, the global override wins."

$AgentNames = @(
  "Sisyphus - ultraworker", "Hephaestus - Deep Agent", "Prometheus - Plan Builder",
  "Atlas - Plan Executor", "build", "explore", "librarian",
  "Metis - Plan Consultant", "Momus - Plan Critic", "multimodal-looker",
  "oracle", "plan", "general", "compaction", "summary", "title", "Sisyphus-Junior"
)

$OmoAgents = @(
  "sisyphus", "hephaestus", "prometheus", "atlas", "metis", "momus", "oracle",
  "librarian", "explore", "multimodal-looker", "build", "plan",
  "sisyphus-junior", "OpenCode-Builder"
)
$OmoCategories = @(
  "visual-engineering", "ultrabrain", "deep", "artistry",
  "quick", "unspecified-low", "unspecified-high", "writing"
)

function Backup-File {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bak = "$Path.$stamp.bak"
    Copy-Item -LiteralPath $Path -Destination $bak -Force
    Write-Host "[backup] $bak"
  }
}

function Set-ModelPins {
  param([string]$Path, [bool]$WithPlugin)
  $obj = @{}
  if (Test-Path -LiteralPath $Path) {
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json -Depth 30 -AsHashtable
  }
  if ($WithPlugin) {
    $plugins = @()
    if ($obj.ContainsKey("plugin") -and $obj["plugin"]) { $plugins = @($obj["plugin"]) }
    if ($plugins -notcontains $Plugin) { $plugins += $Plugin }
    $obj["plugin"] = $plugins
  }
  if (-not $obj.ContainsKey('$schema')) { $obj['$schema'] = "https://opencode.ai/config.json" }
  $obj["model"] = $Model
  $obj["small_model"] = $Model
  $agents = @{}
  if ($obj.ContainsKey("agent") -and $obj["agent"]) { $agents = $obj["agent"] }
  foreach ($name in $AgentNames) { $agents[$name] = @{ model = $Model } }
  $obj["agent"] = $agents
  $instructions = @()
  if ($obj.ContainsKey("instructions") -and $obj["instructions"]) { $instructions = @($obj["instructions"]) }
  if ($instructions -notcontains $Policy) { $instructions += $Policy }
  $obj["instructions"] = $instructions
  Backup-File -Path $Path
  ($obj | ConvertTo-Json -Depth 30) | Set-Content -LiteralPath $Path -Encoding UTF8
  Write-Host "[pinned] $Path"
}

function Set-OmoConfig {
  param([string]$Dir)
  $agents = [ordered]@{}
  foreach ($name in $OmoAgents) {
    $agents[$name] = [ordered]@{
      model           = $Model
      fallback_models = @($Model)
    }
  }
  $categories = [ordered]@{}
  foreach ($name in $OmoCategories) { $categories[$name] = [ordered]@{ model = $Model } }
  $omo = [ordered]@{ agents = $agents; categories = $categories }
  $out = Join-Path $Dir "oh-my-openagent.jsonc"
  Backup-File -Path $out
  ($omo | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $out -Encoding UTF8
  Write-Host "[pinned] $out"
}

# 1. opencode 설치 확인
$opencode = Get-Command opencode -ErrorAction SilentlyContinue
if (-not $opencode -and -not $SkipInstall) {
  Write-Host "[install] opencode not found, installing via official installer..."
  irm https://opencode.ai/install.ps1 | iex
} else {
  Write-Host "[ok] opencode: $((opencode --version 2>$null) -join ' ')"
}

# 2. 설정 디렉터리 + 모델 핀 병합 (mcp/provider는 보존됨)
if (-not (Test-Path -LiteralPath $ConfigDir)) {
  New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
$jsonAttached = Test-Path -LiteralPath (Join-Path $ConfigDir "opencode.json")
$jsoncAttached = Test-Path -LiteralPath (Join-Path $ConfigDir "opencode.jsonc")
if (-not $jsonAttached -and -not $jsoncAttached) {
  Set-ModelPins -Path (Join-Path $ConfigDir "opencode.jsonc") -WithPlugin $true
} else {
  if ($jsonAttached) { Set-ModelPins -Path (Join-Path $ConfigDir "opencode.json") -WithPlugin $false }
  if ($jsoncAttached) { Set-ModelPins -Path (Join-Path $ConfigDir "opencode.jsonc") -WithPlugin $true }
}
Set-OmoConfig -Dir $ConfigDir

# 3. 검증
Write-Host "--- verify ---"
$models = opencode models 2>$null | Select-String "muse-spark-1.3-contributor-free"
if ($models) { Write-Host "[ok] zen model listed:" ($models -join ", ") }
else { Write-Warning "zen model NOT listed. Check 'opencode auth login' (Zen) status." }
$debug = opencode debug config 2>$null | Out-String
$spark = ($debug | Select-String -Pattern '"model": "opencode/muse-spark-1.3-contributor-free"' -AllMatches).Matches.Count
$foreign = ($debug | Select-String -Pattern '"model": "openai|"model": "anthropic' -AllMatches).Matches.Count
Write-Host "[ok] spark model fields: $spark / foreign model fields: $foreign"
if ($foreign -ne 0) { Write-Warning "foreign models remain. Re-run installer or check for project-level overrides." }

Write-Host ""
Write-Host "DONE. Restart opencode completely (close TUI/desktop app) to apply."
Write-Host "After restart, footer must read 'Muse Spark 1.3 ...', never Luna/DeepSeek."
