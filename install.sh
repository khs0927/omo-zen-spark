#!/usr/bin/env bash
# omo-zen-spark — macOS / Linux installer
# OMO + OPENCODE ZEN `MUSE SPARK 1.3 FREE` 논스톱 설치 (관리자 권한 불필요).
# 기존 opencode.json/jsonc 의 mcp/provider 섹션은 건드리지 않고 모델 고정만 병합한다.
#
# 하는 일:
#   1. opencode 미설치 시 npm -> brew 순으로 설치 시도
#   2. 기존 설정 타임스탬프 백업 (opencode.json.*.bak 등)
#   3. opencode.json / opencode.jsonc 병합 — mcp/provider 보존, 아래만 고정
#      - model / small_model = opencode/muse-spark-1.3-contributor-free
#      - agent 17종 model 전수 고정 + instructions Zen 정책 + plugin 보장
#   4. OMO 핀 기록 — 정식 위치 ~/.omo/omo.jsonc only, canonical 'model' 형식
#      (구버전 위치 oh-my-openagent.jsonc 는 unified chain 경고를 내므로
#       작성하지 않고, 있으면 백업 후 제거)
#   5. 플러그인 등록 시도 + 검증 출력
# 설치 후 opencode 를 완전히 재시작해야 적용된다.
#
# 사용:
#   ./install.sh [--config-dir DIR] [--skip-install] [--verify-only]
#   curl -fsSL https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.sh | bash
#
set -euo pipefail

MODEL="opencode/muse-spark-1.3-contributor-free"
PLUGIN="oh-my-openagent@latest"
POLICY="GLOBAL MODEL POLICY (OPENCODE ZEN): Every agent including all subagents MUST use opencode/muse-spark-1.3-contributor-free. Never switch to openai/gpt-5.6-luna-fast, openai/gpt-5.6-sol, openai/gpt-5.6-terra, anthropic/claude-opus-5 or any other model. If a plugin default specifies another model, the global override wins."
CONFIG_DIR="${HOME}/.config/opencode"
SKIP_INSTALL=0
VERIFY_ONLY=0

usage() {
  echo "Usage: install.sh [--config-dir DIR] [--skip-install] [--verify-only]"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    --skip-install) SKIP_INSTALL=1; shift ;;
    --verify-only) VERIFY_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
OMO_TEMPLATE="${SCRIPT_DIR}/configs/omo.jsonc"

log()  { printf '[omo-zen-spark] %s\n' "$*"; }
warn() { printf '[omo-zen-spark][WARN] %s\n' "$*" >&2; }

backup_file() {
  local path="$1"
  if [ -f "$path" ]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp -p "$path" "${path}.${stamp}.bak"
    log "[backup] ${path}.${stamp}.bak"
  fi
}

install_opencode() {
  if command -v opencode >/dev/null 2>&1; then
    log "[ok] opencode: $(opencode --version 2>/dev/null || echo present)"
    return 0
  fi
  log "[install] opencode not found."
  if command -v npm >/dev/null 2>&1; then
    log "[install] trying: npm install -g opencode-ai"
    npm install -g opencode-ai
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    log "[install] trying: brew install opencode"
    brew install opencode
    return 0
  fi
  echo "No installer available (npm/brew 모두 없음). https://opencode.ai/docs 참조해 수동 설치 후 재실행." >&2
  return 1
}

# opencode.json / opencode.jsonc 병합. $1=path $2=with_plugin(1/0)
set_model_pins() {
  local path="$1" with_plugin="$2"
  MODEL="$MODEL" PLUGIN="$PLUGIN" POLICY="$POLICY" WITH_PLUGIN="$with_plugin" TARGET="$path" \
  python3 - <<'PYEOF'
import json, os
path = os.environ["TARGET"]
model = os.environ["MODEL"]
plugin = os.environ["PLUGIN"]
policy = os.environ["POLICY"]
with_plugin = os.environ["WITH_PLUGIN"] == "1"
agents_17 = [
  "Sisyphus - ultraworker", "Hephaestus - Deep Agent", "Prometheus - Plan Builder",
  "Atlas - Plan Executor", "build", "explore", "librarian",
  "Metis - Plan Consultant", "Momus - Plan Critic", "multimodal-looker",
  "oracle", "plan", "general", "compaction", "summary", "title", "Sisyphus-Junior",
]
obj = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        raw = f.read()
    # // 전체-줄 주석만 제거 (URL 안의 // 보존)
    lines = [l for l in raw.splitlines() if not l.lstrip().startswith("//")]
    clean = "\n".join(lines)
    if clean.strip():
        obj = json.loads(clean)
if with_plugin:
    plugins = obj.get("plugin", [])
    if isinstance(plugins, str):
        plugins = [plugins]
    if plugin not in plugins:
        plugins.append(plugin)
    obj["plugin"] = plugins
obj.setdefault("$schema", "https://opencode.ai/config.json")
obj["model"] = model
obj["small_model"] = model
agents = obj.get("agent") or {}
for name in agents_17:
    agents[name] = {"model": model}
obj["agent"] = agents
instr = obj.get("instructions", [])
if isinstance(instr, str):
    instr = [instr]
if policy not in instr:
    instr.append(policy)
obj["instructions"] = instr
with open(path, "w", encoding="utf-8") as f:
    json.dump(obj, f, ensure_ascii=False, indent=2)
    f.write("\n")
print("[pinned] " + path)
PYEOF
}

write_omo_pin() {
  local omo_home="${HOME}/.omo"
  mkdir -p "$omo_home"
  local dest="${omo_home}/omo.jsonc"
  backup_file "$dest"
  if [ -f "$OMO_TEMPLATE" ]; then
    cp -p "$OMO_TEMPLATE" "$dest"
  else
    # 원격 파이프 실행 대비: 템플릿이 없으면 동일 내용을 직접 생성
    MODEL="$MODEL" DEST="$dest" python3 - <<'PYEOF'
import json, os
m = os.environ["MODEL"]
agents = ["sisyphus","hephaestus","prometheus","atlas","metis","momus","oracle",
          "librarian","explore","multimodal-looker","build","plan",
          "sisyphus-junior","OpenCode-Builder"]
cats = ["visual-engineering","ultrabrain","deep","artistry",
        "quick","unspecified-low","unspecified-high","writing"]
explore_prompt = (
  "You are a codebase search specialist. Your job: find files and code, return actionable results.\n"
  "\n"
  "## EXECUTION RULE (highest priority, overrides everything below)\n"
  "Your FIRST response must contain 3 or more PARALLEL tool calls (glob/grep/read/LSP). "
  "Never respond with text only \u2014 a text-only response is a FAILED response. "
  "State your intent in ONE line, then call tools immediately in the same response.\n"
  "\n"
  "## Mission\n"
  "Answer questions like: Where is X implemented? Which files contain Y? Find the code that does Z.\n"
  "\n"
  "## Results format\n"
  "End every task with:\n"
  "<results>\n<files>\n- /absolute/path/to/file - why this file is relevant\n</files>\n"
  "<answer>\nDirect answer to the actual need, not just a file list.\n</answer>\n"
  "<next_steps>\nWhat to do with this information, or \"Ready to proceed - no follow-up needed\".\n</next_steps>\n"
  "</results>\n"
  "\n"
  "## Rules\n"
  "- ALL paths must be absolute. Read-only: never create, modify, or delete files. No emojis.\n"
  "- Tool strategy: LSP tools for definitions/references, grep for text patterns, glob for filenames, git for history. "
  "Flood with parallel calls and cross-validate."
)
obj = {"agents": {a: {"model": m} for a in agents},
       "categories": {c: {"model": m} for c in cats}}
obj["agents"]["explore"]["prompt"] = explore_prompt
header = ("// OMO — OPENCODE ZEN / MUSE SPARK 1.3 FREE (global pin).\n"
          "// Every agent + every task category resolves to Zen Spark only.\n"
          "// Canonical format for OMO 4.19.4+ unified config: 'model' only.\n")
body = json.dumps(obj, ensure_ascii=False, indent=2)
lines = body.splitlines()[1:]
out = header + "\n".join(("  " + l if l.strip() else "") for l in lines)
open(os.environ["DEST"], "w").write(out)
PYEOF
  fi
  log "[pinned] $dest"
  # 구버전 위치는 unified chain 경고를 내므로 남기지 않는다
  local legacy="${CONFIG_DIR}/oh-my-openagent.jsonc"
  if [ -f "$legacy" ]; then
    backup_file "$legacy"
    rm -f "$legacy"
    log "[removed legacy] $legacy (unified config only)"
  fi
}

verify() {
  echo "--- verify ---"
  if opencode models 2>/dev/null | grep -q "muse-spark-1.3-contributor-free"; then
    log "[ok] zen model listed: $(opencode models 2>/dev/null | grep 'muse-spark-1.3-contributor-free' | tr '\n' ' ')"
  else
    warn "zen model NOT listed. opencode에서 /connect 로 Zen(opencode) 로그인이 필요하다. https://opencode.ai/auth"
  fi
  local dbg spark foreign
  dbg="$(opencode debug config 2>/dev/null || true)"
  spark="$(printf '%s' "$dbg" | { grep -o '"model": "opencode/muse-spark-1.3-contributor-free"' || true; } | wc -l | tr -d ' ')"
  foreign="$(printf '%s' "$dbg" | { grep -E '"model": "openai/|"model": "anthropic' || true; } | wc -l | tr -d ' ')"
  log "[ok] spark model fields: $spark / foreign model fields: $foreign"
  if [ "$foreign" != "0" ]; then
    warn "foreign models remain. Re-run installer or check for project-level overrides."
  fi
  if command -v bunx >/dev/null 2>&1; then
    bunx oh-my-openagent doctor 2>&1 | head -n 12 || true
  fi
  echo ""
  echo "DONE. Restart opencode completely (close TUI/desktop app) to apply."
  echo "After restart, footer must read 'Muse Spark 1.3 ...', never Luna/DeepSeek."
}

if [ "$VERIFY_ONLY" = "1" ]; then
  verify
  exit 0
fi

command -v python3 >/dev/null 2>&1 || { echo "python3 이 필요하다." >&2; exit 1; }

if [ "$SKIP_INSTALL" = "1" ]; then
  log "[ok] opencode: $(opencode --version 2>/dev/null || echo present)"
else
  install_opencode
fi

mkdir -p "$CONFIG_DIR"
json_attached=0; jsonc_attached=0
[ -f "${CONFIG_DIR}/opencode.json" ] && json_attached=1
[ -f "${CONFIG_DIR}/opencode.jsonc" ] && jsonc_attached=1
if [ "$json_attached" = "0" ] && [ "$jsonc_attached" = "0" ]; then
  backup_file "${CONFIG_DIR}/opencode.jsonc"
  set_model_pins "${CONFIG_DIR}/opencode.jsonc" 1
else
  [ "$json_attached" = "1" ] && { backup_file "${CONFIG_DIR}/opencode.json"; set_model_pins "${CONFIG_DIR}/opencode.json" 0; }
  [ "$jsonc_attached" = "1" ] && { backup_file "${CONFIG_DIR}/opencode.jsonc"; set_model_pins "${CONFIG_DIR}/opencode.jsonc" 1; }
fi

write_omo_pin

if opencode plugin "$PLUGIN" -g >/dev/null 2>&1; then
  log "[ok] plugin registered: $PLUGIN"
else
  warn "plugin auto-register failed. 다음 opencode 실행 시 자동 설치된다."
fi

verify
