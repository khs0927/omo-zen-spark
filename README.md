# omo-zen-spark

OMO 설치부터 **OPENCODE ZEN `MUSE SPARK 1.3 FREE`** 반영까지 한 번에 끝내는 논스톱 설치 프로젝트.

서브에이전트 푸터가 `GPT-5.6 Luna Fast` / `DeepSeek V4 Flash`로 뜨거나,
`deepseek-v4-flash ... end of life (410)` 에러가 나는 환경이 대상이다.

## 논스톱 설치 (관리자 권한 불필요)

Windows:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.ps1 | iex"
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.sh | bash
# 또는 클론 후 실행 (옵션: --config-dir DIR / --skip-install / --verify-only)
./install.sh
```

자세한 Mac 안내는 [`docs/INSTALL-macos.md`](docs/INSTALL-macos.md).

끝나면 **opencode를 완전히 재시작**(TUI/데스크톱 앱 종료 후 재실행)해야 적용된다.

## 하는 일

1. `opencode` 미설치 시 npm → brew → choco → scoop 순으로 설치 시도 (플랫폼별)
2. 기존 설정 타임스탬프 백업 (`opencode.json.*.bak` 등)
3. `opencode.json` / `opencode.jsonc` 병합 — **mcp/provider 섹션은 그대로 보존**하고 아래만 고정
   - `model` / `small_model` = `opencode/muse-spark-1.3-contributor-free`
   - `agent.{17종}.model` 전수 고정 (Sisyphus, Hephaestus, Prometheus, Atlas, build,
     explore, librarian, Metis, Momus, multimodal-looker, oracle, plan,
     general, compaction, summary, title, Sisyphus-Junior)
   - `instructions`에 Zen 모델 정책 추가, `plugin: oh-my-openagent@latest` 보장
4. OMO 핀 기록 — 정식 위치 `~/.omo/omo.jsonc` only, canonical `'model'` 형식
   (`agents.*` 14종 + `categories.*` 8종 Spark 고정).
   OMO 4.19.4의 explore/librarian 하드코딩 체인에는 Zen 항목이 없어서,
   이 파일 없이는 EOL 모델(deepseek-v4-flash)로 떨어진다. **진짜 서브에이전트 모델은 이 파일이 결정한다.**
   구버전 위치(`~/.config/opencode/oh-my-openagent.jsonc`)는 unified chain 경고를
   내므로 작성하지 않고, 기존 파일이 있으면 백업 후 제거한다.
   플러그인 등록(`opencode plugin oh-my-openagent@latest -g`)도 시도한다.
5. 검증 출력: `opencode models` Zen 노출 여부, spark/foreign `model` 필드 카운트,
   `bunx oh-my-openagent doctor` 요약

> 주의: `fallback_models` 키는 OMO 4.19.4 unified-config 검증에서
> `Invalid omo config` 에러를 내고 doctor 에서 deprecated 경고를 띄우므로
> 의도적으로 사용하지 않는다 (`model` 단일 형식으로 고정).

## 설치 후 확인 (새 컴퓨터 필수)

1. Zen 로그인: opencode 실행 후 `/connect` → opencode 선택 → https://opencode.ai/auth
   (`opencode models`에 `muse-spark-1.3`이 안 뜨면 이 단계가 빠진 것이다)
2. ```bash
   opencode models | grep "muse-spark-1.3"
   opencode debug agent explore 2>&1 | grep "muse-spark-1.3-contributor-free"
   # 또는: ./install.sh --verify-only
   ```
3. 추가 진단: `bunx oh-my-openagent doctor` (플러그인·설정·모델·환경 점검)

서브에이전트 스모크 테스트가 이 repo 검증에 사용됐다:

> `C:\tmp\opencode` 리스트업 → 19개 항목 정상 반환, API 빌링 에러 없음.

Mac 실측에서는 `explore`가 stock 프롬프트(`<analysis>` 선행 요구) 때문에
Spark에서 도구 호출 없이 멈추는 버그를 확인 → `configs/omo.jsonc`의 explore에
Spark 호환 `prompt`(tools-first)로 교체 후 정상화. 상세 기록은
[`docs/INSTALL-macos.md`](docs/INSTALL-macos.md) 5단계.

푸터가 `Muse Spark 1.3 ...`으로 뜨면 성공이다.

## 되돌리기

Windows:

```powershell
.\uninstall.ps1   # 최신 타임스탬프 백업으로 복원
```

macOS / Linux:

```bash
./uninstall.sh   # 최신 타임스탬프 백업으로 복원 (opencode.json/jsonc + ~/.omo/omo.jsonc)
```

## 파일 구성

| 파일 | 역할 |
|---|---|
| `install.ps1` | 논스톱 인스톨러 (Windows, 외부 의존 없음, PS 5.1/7 지원) |
| `install.sh` | 논스톱 인스톨러 (macOS/Linux, `python3`만 필요, `--verify-only` 지원) |
| `uninstall.ps1` | 백업 복원 (Windows) |
| `uninstall.sh` | 백업 복원 (macOS/Linux) |
| `configs/oh-my-openagent.jsonc` | OMO 핀 템플릿 (인스톨러가 동일 내용 생성, canonical `model` 형식) |
| `configs/omo.jsonc` | 신버전 정식 위치용 동일 템플릿 (`~/.omo/omo.jsonc`) |
| `configs/AGENTS.template.md` | 프로젝트용 `AGENTS.md` 템플릿 |
| `docs/INSTALL-macos.md` | macOS 상세 가이드 (설치·검증·문제 해결) |
| `versions.txt` | 검증된 버전 기록 |

## 검증된 버전

- `versions.txt` 참조 (opencode 1.18.29 / oh-my-openagent 4.19.4 / model `opencode/muse-spark-1.3-contributor-free`)
- macOS 14.4.1 arm64 실측: opencode 1.14.39 / OMO 4.19.4 / bun 1.3.14 —
  `install.sh` 멱등성(재실행 시 설정 불변) + `uninstall.sh` 최신 백업 복원 + `doctor` 정상 확인
