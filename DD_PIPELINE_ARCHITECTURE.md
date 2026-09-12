# claude-dd 架構 — Portable Claude Code Profile

> 本文件描述現行架構（2026-08-04 重寫，取代舊多階段 DD Pipeline 版本；
> 舊版流程圖、agent/命令表與對應實作均見 git 歷史）。

## 定位

這個 repo 有兩個目標：

1. **跨機恢復**：換電腦時 `git clone` + 一支腳本，完整重建 `~/.claude/` 的
   skills / agents / commands / scripts / 全域 CLAUDE.md。
   注意：全新機器上全域 CLAUDE.md 那步是詢問制且**預設不安裝**（`[y/N]` 預設 N，
   非互動同樣採 N）— 要一次到位須帶 `--force` 或互動時答 `y`。
2. **分享用法**：別人 clone 後跑同一支腳本，就能取得同一套工作法
   （8 步開發迴圈 + CLAUDE.md gate + 使用率盤點後的精選元件）。

兩個目標共用**同一條安裝路線**（曾評估 plugin marketplace 分發，因無法交付
全域 CLAUDE.md 與 gate、只能給元件子集而不採用，維持單一路線；見 git 歷史）。

設計約束由此而來：**冪等**（重跑結果一致）、**跨平台**（macOS bash 3.2 與
ubuntu CI 都要過）、**不塞二進制 / 不加 runtime 依賴**（只用 bash + jq 或
python3 擇一）、**設定與狀態分離**（repo 只放設定，執行期產物不進版控）。

## 三層架構

```
┌────────────────────────────────────────────────────────┐
│  claude-dd repo（source of truth，git 版控）             │
│  skills/  agents/  commands/  templates/  scripts/      │
│  diagrams/（成品 GIF）  diagrams/src/（產生器）           │
└───────────────────────┬────────────────────────────────┘
                        │  ./install-dd-pipeline.sh
                        │  （依部署清單複製，非 symlink）
                        ▼
┌────────────────────────────────────────────────────────┐
│  ~/.claude/（部署目標，可隨時由 repo 重建）               │
│  skills/  agents/  commands/  scripts/                  │
│  CLAUDE.md（全域，互動比對安裝）  settings.json（plugin） │
│  backups/pre-install-*/（覆蓋前自動備份）                │
└───────────────────────┬────────────────────────────────┘
                        │  /dd-init（逐專案蓋章）
                        ▼
┌────────────────────────────────────────────────────────┐
│  各專案（專案 CLAUDE.md + pre-commit gate*）             │
└────────────────────────────────────────────────────────┘
```

\* gate 掛載點：`.git/hooks/pre-commit`；專案設有 `git config core.hooksPath` 時
git 會忽略 `.git/hooks/`，`/dd-init` 改掛到該目錄下的 `pre-commit`（本 repo 自身即此情況）。

修改一律改 repo 再重新部署；直接改 `~/.claude/` 的 skills / agents / commands /
scripts 會在下次安裝時被覆蓋（覆蓋前自動備份到 `~/.claude/backups/`）。
**全域 CLAUDE.md 是例外**：不帶 `--force` 時互動選單預設 `k)` 保留本地版本，
本地改動不會被覆蓋；帶 `--force` 才直接覆蓋（同樣先備份）。

## 安裝腳本（install-dd-pipeline.sh）

7 個編號步驟（`1/7`…`7/7`）：環境檢查 → Skills → Agents → MCP 檢查 →
官方 Plugins → Commands → 全域 CLAUDE.md（互動比對；`--force` 直接覆蓋）。
另有兩個不佔編號的步驟：hook 路徑驗證（「前置」，在 Skills 之前）與
輔助腳本部署（「附加步驟」，在 Commands 之後）。

行為保證：

- **冪等**：所有部署點（skills / agents / commands / scripts / 全域 CLAUDE.md）
  內容相同報「已是最新」不重寫（含 `--force`）；重跑不產生備份。
- **非互動安全**：無 TTY（CI、`curl | bash`）時互動詢問一律採預設值，
  不會中止；破壞性操作（`--uninstall`）預設取消，自動化用 `--yes`。
- **失敗不半套**：JSON 讀寫失敗（settings.json 損毀等）警告後跳過該項，
  不在 `set -e` 下炸掉整個安裝；JSON 就地改寫保留 inode / symlink / 權限
  （`jq_inplace` / `py_inplace` / `json_edit`，jq 優先、python3 後備）。
- **可回復**：覆蓋差異檔前備份到 `~/.claude/backups/pre-install-<時間>/`，
  完成訊息顯示位置；`--uninstall` 只移除本 repo 部署過的項目。

## 部署清單（使用率盤點制）

依全 transcript 使用率盤點，repo 只保留有實證使用紀錄的元件並全數預設部署
（清單 = 腳本頂部 `PROMOTED_*` 陣列：10 個 promoted Skills、4 個 promoted Agents、dd-init、workflow-review；
2026-08-04 盤點留存 9 skills，2026-08-10 新增自製 tech-diagram-gif）。
零使用的 misc 桶與 deprecated 桶已於 2026-08-04 刪除，git 歷史可回溯。

目的：控制每個 session 的 context 稅（skill 清單載入 system prompt 有
預算上限）；需要時自 git 歷史取回並加回陣列即可重新部署。

## 核心工作法：8 步開發迴圈

```
實作+測試 → commit → code-simplifier → code-review → 再測 → commit → 沉澱 → 評分&修正
```

步驟 7「沉澱」可跳過（本輪沒學到就跳），且會先列建議等使用者同意才寫檔；
它與下方 gate 強制的文件同步是兩件事。

定義於 `templates/global/CLAUDE.md` §3.9，專案具體版由 `/dd-init` 蓋章。
配套：巢狀 CLAUDE.md 堆疊維護，由 **pre-commit gate**
（`scripts/check-claude-md.sh`）強制 — 改碼目錄缺 CLAUDE.md 或未同批更新
即擋 commit；檢查點 commit 逃生口 `SKIP_DOC_CHECK=1`，但 SKIP 不是豁免：
段落起點以來跳過、還沒補 CLAUDE.md 的目錄，之後的正常 commit 一樣擋。

要跨好幾段的工作由 `task-planner` 拆成段落（一段一圈）與小任務（只走步驟 1、2，
全部 commit 完，整段才跑 3–8），進度表寫進專案 `docs/designs/` 的設計文件，換 session 照表接手。

本 repo 自身也掛同一個 gate（dogfood），啟用方式見根目錄 CLAUDE.md
「開發本 repo」一節。

## CI 防線（.github/workflows/ci.yml）

| 檢查 | 防什麼 |
|---|---|
| bash -n（安裝腳本）+ shellcheck（warning 級，5 支腳本） | 語法與常見 bash 陷阱 |
| `--help` smoke test | 腳本連起碼的執行都掛掉 |
| Skill hook 路徑驗證（`validate_skill_hooks`） | vendored skill 帶相對路徑 hook 混進部署 |
| tech-diagram-gif 幾何閘門自我測試（`test-verify-geometry.py`） | 檢查腳本自己壞掉而不自知 —— 全判通過（漏檢）與全判失敗（假陽性）外觀上都像正常結果 |
| error-capture hook 行為測試（`test-error-capture.sh`） | 逐行比對的語意迴歸（exclusion 一票否決、只讀 stderr、回報最後一行、Context 空白或截斷、jq/python3 單分支）—— 這類失效都是零輸出 exit 0，shellcheck 驗不出來。pattern／exclusion 清單只有情境用到的那幾項受保護，非系統性涵蓋 |
| 陣列 ↔ 目錄一致性（`ALL_*` 四組 + `DD_SCRIPTS ↔ scripts/*.sh`） | 陣列漏列 / 目錄改名未同步 / 新腳本沒進部署清單 |
| 數字宣稱 ↔ 陣列（README 英/繁中兩份 + 根目錄 CLAUDE.md + **本文件**） | 文件數字過期。本文件涵蓋元件數、安裝編號步驟數、shellcheck 腳本數 |
| 安裝 flag 三方對照（case 分支 ↔ `--help` ↔ 兩份 README） | flag 名稱三方漂移（只驗名稱，語意描述仍手動維護） |
| §7.2 觸發目標部署驗證（含抓不到與漏反引號兩道護欄） | 全域模板指向未部署元件；章節重編號或某列漏反引號讓這道檢查靜默失效 |
| 迴圈步數四方一致（模板 §3.9 ↔ 蓋章版 ↔ 兩份 README ↔ 版本標記） | 編號清單的步數漂移；另驗 `dd-loop-rev` 的標記格式與檔內唯一性 |
| 迴圈步數第五方（安裝腳本輸出字串 ↔ 一行式箭頭摘要） | 四方看不到的非編號文案漂移 |
| gate 情境測試（段落起點、SKIP 欠帳） | SKIP 跳過的目錄之後被放過；中文、根目錄路徑漏查 |
| Sandbox 端到端非互動安裝 | 只有執行期才會出現的安裝 bug |

> 這張表是 CI 覆蓋範圍的單一入口，**新增 CI step 時要同步補一列**（沒有任何檢查會擋它過期）。

CI 直接 `source` 安裝腳本取用陣列（腳本尾端有 source guard）。

## 授權

Root MIT（LICENSE）。vendored 內容各自附上游授權，共 4 份
（`skills/writing-great-skills/LICENSE.txt`、`skills/frontend-design/LICENSE.txt`（Apache-2.0，有歸屬要求）、
`skills/tech-diagram-gif/LICENSE.txt`、`skills/self-improving-agent/LICENSE`），
收編規則見根目錄 CLAUDE.md「第三方 Skill / Agent 收編檢查清單」。
**新增 vendored 元件時，這裡與兩份 README 的授權段落要同批更新**（沒有任何 CI 檢查會擋）。
