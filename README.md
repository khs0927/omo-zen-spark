# omo-zen-spark

OMO 설치부터 **OPENCODE ZEN `MUSE SPARK 1.3 FREE`** 반영까지 한 번에 끝내는 논스톱 설치 프로젝트.

서브에이전트 푸터가 `GPT-5.6 Luna Fast` / `DeepSeek V4 Flash`로 뜨거나,
`deepseek-v4-flash ... end of life (410)` 에러가 나는 환경이 대상이다.

## 논스톱 설치 (관리자 권한 불필요)

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.ps1 | iex"
```

끝나면 **opencode를 완전히 재시작**(TUI/데스크톱 앱 종료 후 재실행)해야 적용된다.

## 하는 일

1. `opencode` 미설치 시 공식 인스톨러(`opencode.ai/install.ps1`)로 설치
2. 기존 설정 타임스탬프 백업 (`opencode.json.*.bak` 등)
3. `opencode.json` / `opencode.jsonc` 병합 — **mcp/provider 섹션은 그대로 보존**하고 아래만 고정
   - `model` / `small_model` = `opencode/muse-spark-1.3-contributor-free`
   - `agent.{17종}.model` 전수 고정 (Sisyphus, Hephaestus, Prometheus, Atlas, build,
     explore, librarian, Metis, Momus, multimodal-looker, oracle, plan,
     general, compaction, summary, title, Sisyphus-Junior)
   - `instructions`에 Zen 모델 정책 추가, `plugin: oh-my-openagent@latest` 보장
4. `oh-my-openagent.jsonc` 기록 — `agents.*` 14종 + `categories.*` 8종 Spark 고정.
   OMO 4.19.4의 explore/librarian 하드코딩 체인에는 Zen 항목이 없어서,
   이 파일 없이는 EOL 모델(deepseek-v4-flash)로 떨어진다. **진짜 서브에이전트 모델은 이 파일이 결정한다.**
5. 검증 출력: `opencode models` Zen 노출 여부, spark/foreign `model` 필드 카운트

## 설치 후 확인

```powershell
opencode models | Select-String "muse-spark-1.3"
opencode debug agent explore 2>&1 | Select-String "muse-spark-1.3-contributor-free"
```

서브에이전트 스모크 테스트가 이 repo 검증에 사용됐다:

> `C:\tmp\opencode` 리스트업 → 19개 항목 정상 반환, API 빌링 에러 없음.

푸터가 `Muse Spark 1.3 ...`으로 뜨면 성공이다.

## 되돌리기

```powershell
.\uninstall.ps1   # 최신 타임스탬프 백업으로 복원
```

## 파일 구성

| 파일 | 역할 |
|---|---|
| `install.ps1` | 논스톱 인스톨러 (단일 파일, 외부 의존 없음) |
| `uninstall.ps1` | 백업 복원 |
| `configs/oh-my-openagent.jsonc` | OMO 핀 템플릿 (인스톨러가 동일 내용 생성) |
| `configs/AGENTS.template.md` | 프로젝트용 `AGENTS.md` 템플릿 |
| `versions.txt` | 검증된 버전 기록 |

## 검증된 버전

- `versions.txt` 참조 (opencode 1.18.29 / oh-my-openagent 4.19.4 / model `opencode/muse-spark-1.3-contributor-free`)
