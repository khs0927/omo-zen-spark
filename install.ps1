<#PSScriptInfo>
.VERSION 1.1.0
.GUID 7c2e4a1b-9f3d-4c5a-b8e1-omo-zen-spark01
.AUTHOR omo-zen-spark
.DESCRIPTION Nonstop installer: OMO + OPENCODE ZEN MUSE SPARK 1.3 FREE model pin.
#>
<#
.SYNOPSIS
  OMO + MUSE SPARK 1.3 FREE 논스톱 설치 (Windows PowerShell 5.1 / PS 7 모두 지원).
  기존 opencode.json/jsonc의 mcp/provider 섹션은 건드리지 않고 모델 고정만 병합한다.
.DESCRIPTION
  1. opencode 미설치 시 npm -> choco -> scoop 순으로 설치 시도
  2. 기존 설정 백업(타임스탬프)
  3. model/small_model + agent 17종 + instructions + plugin 병합
  4. oh-my-openagent.jsonc + ~/.omo/omo.jsonc 기록 (agents 14 + categories 8)
     - 구버전(4.x)은 전자를, 신버전은 후자를 정식 위치로 읽는다. 둘 다 써서 버전 무관 고정.
  5. 플러그인 등록 시도 + 검증 출력
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

function Set-NoteProperty {
  param($Object, [string]$Name, $Value)
  $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Set-ModelPins {
  param([string]$Path, [bool]$WithPlugin)
  $obj = New-Object PSObject
  if (Test-Path -LiteralPath $Path) {
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($raw.Trim().Length -gt 0) { $obj = $raw | ConvertFrom-Json }  # -Depth 미사용: PS 5.1 호환
  }
  if ($WithPlugin) {
    $plugins = @()
    if ($obj.plugin) { $plugins = @($obj.plugin) }
    if ($plugins -notcontains $Plugin) { $plugins += $Plugin }
    Set-NoteProperty -Object $obj -Name "plugin" -Value $plugins
  }
  if (-not $obj.'$schema') { Set-NoteProperty -Object $obj -Name '$schema' -Value "https://opencode.ai/config.json" }
  Set-NoteProperty -Object $obj -Name "model" -Value $Model
  Set-NoteProperty -Object $obj -Name "small_model" -Value $Model
  $agents = $obj.agent
  if (-not $agents) { $agents = New-Object PSObject }
  foreach ($name in $AgentNames) {
    $entry = New-Object PSObject
    Set-NoteProperty -Object $entry -Name "model" -Value $Model
    Set-NoteProperty -Object $agents -Name $name -Value $entry
  }
  Set-NoteProperty -Object $obj -Name "agent" -Value $agents
  $instructions = @()
  if ($obj.instructions) { $instructions = @($obj.instructions) }
  if ($instructions -notcontains $Policy) { $instructions += $Policy }
  Set-NoteProperty -Object $obj -Name "instructions" -Value $instructions
  Backup-File -Path $Path
  ($obj | ConvertTo-Json -Depth 30) | Set-Content -LiteralPath $Path -Encoding UTF8
  Write-Host "[pinned] $Path"
}

function New-OmoObject {
  $agents = New-Object PSObject
  foreach ($name in $OmoAgents) {
    $entry = New-Object PSObject
    Set-NoteProperty -Object $entry -Name "model" -Value $Model
    Set-NoteProperty -Object $entry -Name "fallback_models" -Value @($Model)
    Set-NoteProperty -Object $agents -Name $name -Value $entry
  }
  $categories = New-Object PSObject
  foreach ($name in $OmoCategories) {
    $entry = New-Object PSObject
    Set-NoteProperty -Object $entry -Name "model" -Value $Model
    Set-NoteProperty -Object $categories -Name $name -Value $entry
  }
  $omo = New-Object PSObject
  Set-NoteProperty -Object $omo -Name "agents" -Value $agents
  Set-NoteProperty -Object $omo -Name "categories" -Value $categories
  return $omo
}

function Install-Opencode {
  if (Get-Command opencode -ErrorAction SilentlyContinue) {
    Write-Host "[ok] opencode: $((opencode --version 2>$null) -join ' ')"
    return
  }
  Write-Host "[install] opencode not found."
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "[install] trying: npm install -g opencode-ai"
    npm install -g opencode-ai
    return
  }
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "[install] trying: choco install opencode"
    choco install opencode -y
    return
  }
  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "[install] trying: scoop install opencode"
    scoop install opencode
    return
  }
  throw "No installer available (npm/choco/scoop 모두 없음). https://opencode.ai/docs 참조해 수동 설치 후 재실행하라."
}

# 1. opencode 설치 확인
if (-not $SkipInstall) { Install-Opencode }
else { Write-Host "[ok] opencode: $((opencode --version 2>$null) -join ' ')" }

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

# 3. OMO 핀 기록 (구버전 위치 + 신버전 정식 위치 둘 다)
$omo = New-OmoObject
$omoLegacy = Join-Path $ConfigDir "oh-my-openagent.jsonc"
Backup-File -Path $omoLegacy
($omo | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $omoLegacy -Encoding UTF8
Write-Host "[pinned] $omoLegacy"
$omoHome = Join-Path $HOME ".omo"
if (-not (Test-Path -LiteralPath $omoHome)) { New-Item -ItemType Directory -Path $omoHome -Force | Out-Null }
$omoNew = Join-Path $omoHome "omo.jsonc"
Backup-File -Path $omoNew
($omo | ConvertTo-Json -Depth 20) | Set-Content -LiteralPath $omoNew -Encoding UTF8
Write-Host "[pinned] $omoNew"

# 4. 플러그인 등록 (실패해도 중단하지 않음 — 다음 opencode 실행 시 자동 설치됨)
opencode plugin $Plugin -g 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
  Write-Host "[ok] plugin registered: $Plugin"
} else {
  Write-Warning "plugin auto-register returned exit code $LASTEXITCODE. 다음 opencode 실행 시 자동 설치된다."
}

# 5. 검증
Write-Host "--- verify ---"
$models = opencode models 2>$null | Select-String "muse-spark-1.3-contributor-free"
if ($models) { Write-Host "[ok] zen model listed:" ($models -join ", ") }
else {
  Write-Warning "zen model NOT listed. opencode에서 /connect 로 Zen(opencode) 로그인이 필요하다. https://opencode.ai/auth"
}
$debug = opencode debug config 2>$null | Out-String
$spark = ($debug | Select-String -Pattern '"model": "opencode/muse-spark-1.3-contributor-free"' -AllMatches).Matches.Count
$foreign = ($debug | Select-String -Pattern '"model": "openai|"model": "anthropic' -AllMatches).Matches.Count
Write-Host "[ok] spark model fields: $spark / foreign model fields: $foreign"
if ($foreign -ne 0) { Write-Warning "foreign models remain. Re-run installer or check for project-level overrides." }

Write-Host ""
Write-Host "DONE. Restart opencode completely (close TUI/desktop app) to apply."
Write-Host "After restart, footer must read 'Muse Spark 1.3 ...', never Luna/DeepSeek."
