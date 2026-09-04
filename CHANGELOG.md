# 變更紀錄

記錄影響使用方式的結構性變更。版本號採[語意化版本](https://semver.org/lang/zh-TW/)，
格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，
每個版本對應一個 git tag（`git show v1.0.0`、`git log v0.4.0..v0.5.0` 可看該版完整內容）。
升級步驟見 [UPGRADING.md](UPGRADING.md)。

> 0.2.0 涵蓋專案初始（2025-12-15）到 2026-07-24 的所有變更，但只有 6 步迴圈改造
> 這一項被逐條記錄；更早的細節見 git 歷史。

## 未發布

### Added

- **CI 迴圈步數第五方檢查**：既有的四方一致只數**編號清單**，使用者實際看到的兩類
  文案不在範圍 — 安裝腳本印出的「N 步開發迴圈」，以及散落各處的一行式箭頭摘要。
  第五方補上這兩類：箭頭摘要先合併續行，箭頭 ≥3 且同時含 `commit` 與 `review`
  才認定為迴圈摘要；腳本部分排除註解行（那裡是有日期的歷史敘述），CHANGELOG 與
  UPGRADING 同理排除。上線當下就抓到人工逐檔翻仍漏掉的一處

### Fixed

- 六張 GIF 的循環接點會跳：球的 `begin` 是 `dur` 的整數倍時，「跑完一圈跳回起點」
  剛好落在 GIF 循環接點上。另外 `dev-loop` 的框間連線只有 20px，而球含光暈直徑 16px，
  停在終點時整個箭頭被蓋住 — 那 5 條短連線改為只留箭頭
- **8 步迴圈的文案殘留 9 處**：2026-08-31 迴圈擴充到 8 步時三類文字沒跟上 —
  安裝腳本印給使用者的訊息仍寫「6 步」（2 處）、標題宣稱 8 步但箭頭只列到第 6 步
  （6 處，含 `DD_PIPELINE_ARCHITECTURE.md` 停在 7 段）、`README.zh-TW.md` 把安裝腳本
  **自身進度**的 7 步誤寫為 8 步而括號內仍是 `1/7 … 7/7`（英文版同段本就正確）。
  本檔與 UPGRADING 的歷史敘述、`/dd-init` 的 `6step`／`7step` 版本標記均不動 —
  後者是舊專案升級偵測的判斷依據

### Removed

- **移除三層架構圖**（`claude-dd-architecture*.gif` 與 `gen_arch.py`）：它畫的是目錄
  清單而不是架構，13 個框寫的都是 `DD_PIPELINE_ARCHITECTURE.md` 已有的文字，
  卻多一份圖要隨每次改動重畫。README 保留 `usage-flow` 與 `dev-loop` 兩張

## 1.1.0 — 2026-08-31

### Changed

- **開發迴圈由 6 步改為 8 步**（同日兩階段擴充）：
  - **步驟 7「沉澱本輪所學」**（`claude-md-management:revise-claude-md`）— 本輪學到的
    踩雷／指令／慣例寫進 CLAUDE.md，會先列建議等使用者同意才寫檔；沒學到就跳過
  - **步驟 8「評分 & 修正本輪動過的 CLAUDE.md」**（`claude-md-improver`）— 補 pre-commit
    gate 的盲點：gate 只確認改碼目錄的 CLAUDE.md「有寫」、**不確認「寫得對」**。
    **第一個動作是算範圍**（`git show HEAD` 聯集 `git status`），因為該 skill 的 Phase 1
    是「find 全部」，實測有專案含 87 份 CLAUDE.md，不先算範圍會全 repo 掃。
    **步驟 7 跳過不代表步驟 8 跳過** — gate 逼出來的那些改動一樣要審
  - 步驟 1–6 編號與內容不變。先在 claude-dd dogfood 4 次抓到 2 個真錯誤才推全域。
    已用舊版 `/dd-init` 蓋章過的專案不會自動更新，重跑 `/dd-init` 會偵測舊版並提議升級
- 全域模板收緊回應風格與 task 粒度；巢狀 CLAUDE.md 的代價改寫為
  「代價 → 對策 → 殘餘風險」三段式
- 全域模板 §3.4 砍掉 `/goal` 的操作手冊（官方文件轉述，非行為規則），留一行指路
- `claude-mem` 由必要 MCP 改列「推薦第三方 Plugin」— 它走 hooks + plugin 系統，
  MCP 檢查對它永遠誤報未安裝

### Added

- 全域模板 **§2.6 動手前範圍盤點與佐證要求**：改既有介面前先 Grep 呼叫端並列出受影響
  檔案；病因要有第一手證據；結果只報實際跑過的
- 全域模板 **§4.1 停等語規則**：使用者說「先告訴我」「不要直接改」時，該輪只出計畫
- 全域模板 **§2.5 擴充**：skill / agent / 工具的 description 也算「名稱層級」資訊，
  要拿它的行為下判斷前先讀 SKILL.md 本體
- 全域模板 §7.2 觸發表新增 `revise-claude-md`（關鍵字刻意避開 improver 與
  self-improving-agent，避免撞列）
- **第三張圖表「8 步開發迴圈」**（`claude-dd-dev-loop*.gif`，中英各一）並嵌進兩份
  README — 先前兩張圖只把迴圈壓成一個框裡的一行字
- **`diagrams/src/` 納入版控** — 6 張 GIF 的產生器（零依賴 Python 手寫 SVG）與重出流程。
  先前只保存成品 GIF，改一個字就得整張重畫
- `tech-diagram-gif` 陷阱表補上 playwright 的工具層與瀏覽器層差異：`browser_navigate`
  擋 `file://` 但 `run_code` 裡的 `page.goto('file://…')` 不受限、`run_code` 裡拿不到 `fs`、
  `page.screenshot({path})` 可寫任意路徑
- **CI 新增兩道防線**：安裝 flag 三方對照（腳本 case 分支 ↔ `--help` ↔ 兩份 README）、
  迴圈步數四方一致（全域模板 §3.9 ↔ `/dd-init` 蓋章版 ↔ 兩份 README ↔ `dd-loop-version` 標記）

### Fixed

- **`/dd-init` 的版本標記停在 `6step`** — 判斷邏輯是「含 `6step` → 已是現行版」，
  導致已蓋章的專案永遠不會被提議升級。**靜默失效、不報錯**
- 兩份 README 的迴圈清單只列到第 7 步，與「8 步」標題自相矛盾
- `/dd-init` 蓋章版與兩份 README 原本把 `/revise-claude-md` 當成巢狀文件同步的工具，
  與其實際行為（回顧本 session 學到什麼）不符 — 已拆成兩件事分別說明
- `diagrams/src/gen_usage.py` 只產 `.svg` 不產 `.html`，與該目錄 CLAUDE.md 寫的
  「6 份 .svg 與 .html」不符，照文件做會在重出流程第 2 步斷掉
- README 與 CLAUDE.md 事實查核：13 處與實作對齊的修正

### Removed

- 可選 MCP 移除 `cipher` — 上游已 deprecated 改名 byterover-cli，本機使用紀錄已斷

## 1.0.0 — 2026-08-11

首次對外發布。版本號自本版起生效，`install-dd-pipeline.sh` 的 CLI flags 與
`~/.claude/` 佈局視為穩定介面，日後破壞性變更走 2.0.0。

### Added

- 雙語 README：`README.md`（英文，GitHub 預設顯示）與 `README.zh-TW.md`（繁體中文），
  兩份頂部各有一行語言切換列。英文版含 language note，說明規則本文仍是繁中
- 專案架構圖與使用流程圖（`diagrams/*.gif`，Style 8 Dark Luxury、8 秒循環、20fps），
  由 tech-diagram-gif skill 產出並納入版控，兩份 README 皆嵌入。雙語出圖：
  英文用原檔名（與 README 同一套慣例），繁中版加 `.zh-TW` 後綴
- 可選 MCP 新增 `context7` — 取版本正確的官方文件，支撐全域 CLAUDE.md §2.5
  「禁止從名稱推論 API」
- CHANGELOG 改採 semver，回溯補上 v0.2.0–v1.0.0 的 git tag

### Changed

- MCP 檢查改為真正解析 JSON 判斷 scope（jq → python3 → 退化標示），區分官方
  `user` 與 `local`；`~/.claude.json` 同時存放所有專案的設定，字串 grep 會把
  別的專案的設定誤判為已安裝
- 對外整備：清除客戶代號、升級指南與變更紀錄自 README 拆出為 UPGRADING.md / CHANGELOG.md
- CI 數字宣稱檢查改語言無關正規式，並同時驗兩份 README

### Removed

- `templates/*.template` 7 個文件模板（REQUIREMENTS / ARCHITECTURE / API_CONTRACT /
  EXAMPLES / ADR / PROJECT_STATE / CLAUDE.md）— 舊多階段流程的產出物，其消費者
  （`/dd-start` 等）已於 0.4.0 刪除，現行 `/dd-init` 直接生成內容，全 repo 無讀取路徑
  - 安裝步驟由 8 步減為 7 步，不再部署 `~/.claude/templates/dd/`
  - **既有安裝的 `~/.claude/templates/dd/` 不會被自動刪除**，需要時手動 `rm -rf` 或跑 `--uninstall`
  - 取回：`git checkout pre-prune-2026-08-04 -- templates/`

### Fixed

- MCP 檢查的假陽性；`~/.claude.json` 損毀時回報「無法判定」而非誤報未安裝；
  jq 與 python3 兩條路徑的型別護欄對齊，同一台機器裝不裝 jq 得到相同結論
- 文件死連結與 tag 目標錯誤

## 0.5.0 — 2026-08-10

### Added

- 自製 skill `tech-diagram-gif`：技術圖表繪製與 GIF 匯出（流程圖 / 架構圖 / 走向動畫），
  風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT）
- 安裝腳本環境檢查加入 `ffmpeg` 可選項偵測：缺少時該 skill 退化交付 SVG，不中止安裝

### Changed

- Promoted skills 由 9 個增為 10 個

## 0.4.0 — 2026-08-04

單桶化：repo 改為單一部署清單，只保留有實證使用紀錄的元件並全數預設部署。
被刪內容可自 tag `pre-prune-2026-08-04` 取回（該 tag 落在本版範圍內），見 UPGRADING.md。

### Removed

- deprecated 桶：全歷史 0 次使用的 34 skills / 17 agents / 6 dd 指令 / 13 NS commands
- misc 桶：SRE 備援性質但零實際調用的 11 skills / 5 NS commands
- 安裝腳本的 `--prune`（單一清單後無桶可清）
- plugin marketplace 分發路線（`.claude-plugin/marketplace.json`）— 同批評估、實測可行後
  仍移除：plugin 機制無法部署全域 CLAUDE.md 與 pre-commit gate，只能交付元件子集，
  與「完整工作法」的定位不符，為維持單一安裝路線而不採用

### Changed

- 被刪的 6 個 dd 指令為舊版多階段流程的 `/dd-start`、`/dd-arch`、`/dd-approve`、
  `/dd-dev`、`/dd-test`，加上已停用的 `/dd-dx`；`/dd-init` 保留並改造

## 0.3.0 — 2026-07-31

### Changed

- 全域模板依 Claude 5 家族遷移指引調整：規則內容不變，僅語氣平述化
  （§3.1、§3.9、§7 開頭、§7.2 標題、§7.5），原 §7.6 的藉口逐條表濃縮為單一原則句

## 0.2.0 — 2026-07-23

### Changed

- 骨幹改為 6 步開發迴圈：原多階段 DD Pipeline（`dd-start` → `dd-arch` → `dd-approve`
  → `dd-dev` → `dd-test`）依實際使用率盤點後封存，改為經實際專案實戰驗證的功能段落迴圈
- `/dd-init` 改造：從產出設計文件骨架，改為蓋章開發迴圈到專案 CLAUDE.md
- 全域模板 §7.2 Skill 觸發表由 21 列瘦身至 8 列，只留預設部署元件對應項

### Removed

- §7.2 被移除列的目標已不再預設部署：senior-qa、test-engineer、tdd-guide、test-gen、
  senior-frontend、ui-design-system、ux-researcher-designer、landing-page-generator、
  senior-backend、dx-engineer、senior-fullstack、senior-secops、playwright-pro
