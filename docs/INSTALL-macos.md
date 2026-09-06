# omo-zen-spark — macOS 가이드

Windows용 `install.ps1`과 동일한 고정을 macOS/Linux에 적용하는 `install.sh` 안내서.
macOS 14.4.1 arm64 + opencode 1.14.39 + OMO 4.19.4에서 실측 검증됨.

## 0. 준비물

- `opencode` (없으면 인스톨러가 npm → brew 순으로 설치 시도)
- `python3` (macOS 기본 포함, 설정 병합용)
- OPENCODE ZEN 로그인 (아래 2단계)
- 선택: `brew install ast-grep` (OMO ast-grep 스킬용 `sg`. 없어도 설치는 됨)

## 1. 논스톱 설치 (관리자 권한 불필요)

```bash
curl -fsSL https://raw.githubusercontent.com/khs0927/omo-zen-spark/main/install.sh | bash
```

로컬 클론에서 실행해도 된다:

```bash
git clone https://github.com/khs0927/omo-zen-spark.git
cd omo-zen-spark
./install.sh
```

옵션: `--config-dir DIR` (커스텀 설정 경로), `--skip-install` (opencode 설치 생략),
`--verify-only` (검증만).

끝나면 **opencode를 완전히 재시작**해야 적용된다.

## 2. 하는 일

1. 기존 설정 타임스탬프 백업 (`opencode.jsonc.YYYYMMDD-HHMMSS.bak` 등)
2. `~/.config/opencode/opencode.jsonc` 병합 — **mcp/provider는 보존**하고 아래만 고정
   - `model` / `small_model` = `opencode/muse-spark-1.3-contributor-free`
   - agent 17종 `model` 전수 고정 + Zen 정책 `instructions` + `plugin: oh-my-openagent@latest`
3. `~/.omo/omo.jsonc` 기록 — `configs/omo.jsonc` 템플릿 복사
   (`agents` 14종 + `categories` 8종 Spark 고정, canonical `model` 형식).
   구위치 `oh-my-openagent.jsonc`는 unified-config 경고를 내므로 백업 후 제거.
   - `explore`에는 Spark 호환 `prompt`(tools-first) 포함 → stock 프롬프트는
     `<analysis>` 선행 요구 때문에 Spark가 도구 호출 없이 멈추는 버그가 있다.
     근본원인·검증 기록은 아래 5단계 참조.
4. 플러그인 등록 시도 + 검증 출력.

## 3. 설치 후 확인 (새 맥 필수)

```bash
# 1. Zen 로그인: opencode 실행 후 /connect → opencode 선택 → https://opencode.ai/auth
#    (아래에 muse-spark-1.3이 안 뜨면 이 단계가 빠진 것이다)
opencode models | grep "muse-spark-1.3"
opencode debug agent explore 2>&1 | grep "muse-spark-1.3-contributor-free"

# 2. 플러그인·설정·모델 점검 (exit 0이어야 정상)
bunx oh-my-openagent doctor
```

푸터가 `Muse Spark 1.3 ...`으로 뜨면 성공이다.

## 4. 되돌리기

```bash
./uninstall.sh   # 최신 타임스탬프 백업으로 복원
```

## 5. 실측 검증 기록 (2026-09-06, 이 머신)

- `doctor` → exit 0 (경고 1건만: 로컬 모델 메타데이터에 spark 미등록 — 무해, `opencode models`에는 live 노출)
- `debug config` → spark 5건, 외부(openai/anthropic) 모델 0건
- 서브에이전트 스모크 (모두 spark, 빌링 에러 없음)
  - librarian: 모델 자가 보고 + 정상 답변
  - quick(Sisyphus-Junior): 실제 `glob`+`read` 실행, `versions.txt` 정확히 반환
  - explore: 수정 전 `<analysis>`만 출력하고 도구 0회로 3회 실패 →
    `prompt` 교체(tools-first) 후 첫 응답에서 도구 3개 병렬 호출 + `<results>` 정상 반환

## 6. 알려진 사항

- **Hephaestus 자동 전환**: spark 고정에도 OMO의 `no-hephaestus-non-gpt` 훅이
  Hephaestus 호출을 Sisyphus(spark)로 돌린다. 과금은 spark-only로 유지되므로
  기본값 유지를 권장. 문자 그대로 Hephaestus-on-spark를 원하면
  `~/.omo/omo.jsonc`에 `"disabled_hooks": ["no-hephaestus-non-gpt"]` 추가
  (단, OMO 4.19.4 검증기가 `agents` 아래 `disabled_hooks` 키를 거부하므로
  동작 미보장 — 수동 검증 필요).
- **opencode 버전**: 검증된 버전은 1.18.29, 이 머신은 1.14.39에서도 정상 동작.
  업그레이드하려면 `npm i -g opencode-ai@latest` 후 opencode 재시작.
- **스키마 주의**: OMO 4.19.4 검증기는 `agents`/`categories`에
  `model`(·`prompt`)만 허용. `fallback_models`·`models`·`prompt_append`를 넣으면
  `Invalid omo config`로 전체 블록이 무효가 되니 넣지 말 것.
