# DD Pipeline 平台工程設計 (DX Engineer)

呼叫 `dx-engineer` agent 設計本專案的 **golden path**:本機/容器環境一致性、跨語言 lock file 治理、Dockerfile/CI gate/onboarding。

對 `/dd-init` Phase 4 之外可獨立重跑;當技術棧改變、新增前後端、或想 refine onboarding 流程時呼叫。

---

## Plan 模式

此指令在 Plan 模式下執行,所有產出寫入 plan file,正式檔案落地待 `/dd-approve`。

如果尚未在 Plan 模式中,先調用 `EnterPlanMode`。

---

## 參數

```
/dd-dx [--scope=env|lock|docker|all]
```

- `--scope=env` — 只跑維度 1(本機/容器環境一致性)
- `--scope=lock` — 只跑維度 2(lock file 治理)
- `--scope=docker` — 只跑維度 3(Dockerfile + CI gate + onboarding)
- `--scope=all`(預設) — 三維度全跑

---

## 執行步驟

### Phase 1:技術棧偵測

使用 **Glob** + **Read** 偵測:

- Lock files:`uv.lock` / `pnpm-lock.yaml` / `package-lock.json` / `yarn.lock` / `go.sum` / `Cargo.lock` / `composer.lock`
- 套件 manifest:`pyproject.toml` / `package.json` / `go.mod` / `Cargo.toml` / `composer.json`
- 既有容器設定:`Dockerfile` / `docker-compose.yml` / `.devcontainer/`
- 既有 CI:`.github/workflows/` / `.gitlab-ci.yml` / `.circleci/config.yml`
- 既有 onboarding:`README.md` / `docs/onboarding.md` / `CONTRIBUTING.md` 的「Getting Started」段落

偵測結果整理為 JSON-like 結構,寫入 plan file 作為後續決策依據。

### Phase 2:讀取既有 CLAUDE.md 與 claude_docs

- 讀 `./CLAUDE.md` 取得專案類型、技術棧設定
- 讀 `claude_docs/06_platform/`(若存在)確認既有決策
- 若 CLAUDE.md 沒有「## 平台工程 (Platform / DX)」章節,標記為「首次跑 DX」

### Phase 3:呼叫 dx-engineer agent

使用 **Task** 工具(`subagent_type: dx-engineer:dx-engineer`,fallback `dx-engineer`):

```
依照 --scope=<value>,為本專案設計 golden path:

1. 根據 Phase 1 偵測結果決定啟用哪些維度(graceful degrade)
2. 對啟用的維度,產出具體交付物的內容草稿:
   - 維度 1:.devcontainer/devcontainer.json、.env.example、工具版本鎖檔
   - 維度 2:lock 更新 SOP、CI gate 指令
   - 維度 3:Dockerfile 內容、CI workflow 內容、docs/onboarding.md 內容
3. 對跳過的維度,寫一段「為什麼跳過」的 rationale
4. 產出格式參照 agent 自身的「交付格式」章節
```

### Phase 4:把產出寫進 plan file

**不要直接 Write 任何實體檔案**(Dockerfile / devcontainer.json 等)。整合產出為:

```markdown
# 專案名稱 - 平台工程設計

## 偵測結果
（Phase 1 結果摘要）

## 啟用維度與跳過維度
- 啟用:[1/2/3 的子集]
- 跳過:[原因 1] / [原因 2]

## 維度 1:本機/容器環境一致性
### .devcontainer/devcontainer.json
\`\`\`json
（內容草稿）
\`\`\`

### .env.example
\`\`\`
（內容草稿）
\`\`\`

## 維度 2:Lock File 治理
### Lock 更新 SOP(將寫進 claude_docs/06_platform/lock-update-sop.md)
（內容草稿）

### CI gate 指令片段(將寫進 .github/workflows/lock-gate.yml)
\`\`\`yaml
（內容草稿）
\`\`\`

## 維度 3:Dockerfile + CI Gate + Onboarding
### Dockerfile
\`\`\`dockerfile
（內容草稿)
\`\`\`

### .github/workflows/lock-gate.yml
\`\`\`yaml
（內容草稿）
\`\`\`

### docs/onboarding.md
（內容草稿）

## CLAUDE.md「## 平台工程 (Platform / DX)」章節更新
（填入路徑與摘要的 markdown）

## 降級理由(若有)
（為什麼跳過某些維度)
```

### Phase 5:調用 ExitPlanMode 等待用戶審閱

```
═══════════════════════════════════════════════════════════════════
⏸️ 平台工程設計完成,等待確認
═══════════════════════════════════════════════════════════════════

所有 golden path 設計已寫入 plan file,請審閱。

⚠️ 此時尚未建立任何實體檔案(Dockerfile / devcontainer / workflow 都還沒寫)。

📌 下一步:
├── /dd-approve        確認設計,落地實體檔案 + 更新 CLAUDE.md
└── 需修改時:直接編輯 plan file(例如改 base image)後重跑 /dd-approve
═══════════════════════════════════════════════════════════════════
```

---

## 與 /dd-init Phase 4 的關係

`/dd-init` 預設會在 Phase 4 詢問是否跑 DX Engineer。`/dd-dx` 是讓使用者**在 init 之後**重跑這個流程的入口 — 例如:

- 技術棧改變(新增前端、改用 uv 取代 poetry)
- 想升級 base image 或調整 layer cache 策略
- onboarding 文件需要更新
- 第一次 init 時 opt-out 過,現在想補

---

## 使用的 Agent / 工具

| 類型 | 名稱 | 用途 |
|------|------|------|
| Agent | `dx-engineer` | 三維度 golden path 設計 |
| Tool | `Glob` / `Read` | 偵測技術棧、lock files、既有容器/CI 設定 |
| Tool | `AskUserQuestion` | 偵測失敗時讓使用者選維度 |
| Tool | `EnterPlanMode` / `ExitPlanMode` | Plan 階段框架 |

---

## 不做的事

- **不寫實體檔案**:Plan 階段只動 plan file,實體檔案在 `/dd-approve` 階段才落地
- **不改 K8s manifest / 部署策略**:那是 `senior-devops` 範圍
- **不做 IaC**:由 `senior-devops` / `aws-solution-architect` 負責
