# AGENTS.md — OMO (OPENCODE ZEN / MUSE SPARK 1.3 FREE) project template

> 이 프로젝트의 모든 에이전트(메인 + 서브에이전트)는 **오직 `opencode/muse-spark-1.3-contributor-free`** 만 사용한다.
> OPENCODE ZEN 내부 모델이다. 외부 모델로 폴백하지 마라.

## 1. Model Policy (Hard Rule)

- Default model: `opencode/muse-spark-1.3-contributor-free`
- Small model: `opencode/muse-spark-1.3-contributor-free`
- 전 에이전트 오버라이드 대상:
  `Sisyphus - ultraworker`, `Hephaestus - Deep Agent`, `Prometheus - Plan Builder`,
  `Atlas - Plan Executor`, `build`, `explore`, `librarian`,
  `Metis - Plan Consultant`, `Momus - Plan Critic`, `multimodal-looker`,
  `oracle`, `plan`, `general`, `compaction`, `summary`, `title`, `Sisyphus-Junior`
- 금지 모델: `openai/gpt-5.6-luna-fast`, `openai/gpt-5.6-sol`, `openai/gpt-5.6-terra`,
  `anthropic/claude-opus-5`, 기타 모든 Zen 외 모델
- 플러그인(oh-my-openagent) 기본값이 다른 모델을 지정해도 글로벌 오버라이드가 우선한다.
- OMO 전용 설정 `~/.config/opencode/oh-my-openagent.jsonc`에 `agents.*.model` 14개 +
  `categories.*.model` 8개 고정 — OMO 내부 fallbackChain이 Zen을 몰라 EOL 모델
  (deepseek-v4-flash)으로 떨어지는 것을 차단. 이 파일이 진짜 서브에이전트 모델을 결정한다.
- `task()` / 서브에이전트 호출 시 모델을 생략하거나, 생략 불가능하면 명시적으로
  `opencode/muse-spark-1.3-contributor-free`를 지정하라.
- 푸터에 `Explore · GPT-5.6 Luna Fast` / `Explore · DeepSeek V4 Flash` 같은 표기가
  나타나면 설정 회귀로 간주하고 즉시 중단·보고하라.

## 2. OMO Workflow

1. Intent Gate: 매 턴 현재 메시지만으로 의도 재분류. 구현 동사 없으면 조사·답변만.
2. Todo-first: 2단계 이상 작업은 즉시 `todowrite` 원자적 분해.
3. Delegation: 병렬 `task()` 기본. explore/librarian은 `run_in_background=true`로 2~5개 병렬.
4. Anti-duplication: 백그라운드 탐색과 동일한 검색을 직접 반복하지 마라.
5. Verification: 파일 수정 후 `lsp_diagnostics`, 빌드·테스트, `opencode debug config`로 모델 고정 확인.
6. Failure recovery: 3회 연속 실패 시 중단 → 원복 → Oracle(동일 Spark 모델) 자문 → 사용자에게 확인.

## 3. Verification Commands

```powershell
opencode models | Select-String "muse-spark-1.3"
opencode debug config 2>$null | Select-String '"model": "opencode/muse-spark-1.3-contributor-free"' | Measure-Object
opencode debug agent explore 2>&1 | Select-String "muse-spark-1.3-contributor-free"
```
