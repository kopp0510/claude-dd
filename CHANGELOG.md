# 變更紀錄

記錄影響使用方式的結構性變更。版本號採[語意化版本](https://semver.org/lang/zh-TW/)，
格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，
每個版本對應一個 git tag（`git show v1.0.0`、`git log v0.4.0..v0.5.0` 可看該版完整內容）。
升級步驟見 [UPGRADING.md](UPGRADING.md)。

> 0.2.0 涵蓋專案初始（2025-12-15）到 2026-07-24 的所有變更，但只有 6 步迴圈改造
> 這一項被逐條記錄；更早的細節見 git 歷史。

## 未發布

### Changed

- **開發迴圈由 6 步改為 8 步**（同日兩次擴充）。步驟 8「評分 & 修正本輪動過的
  CLAUDE.md」用 `claude-md-management:claude-md-improver`，補 pre-commit gate 的盲點 —
  gate 只確認改碼目錄的 CLAUDE.md「有寫」、不確認「寫得對」。
  **第一個動作是算範圍**（`git show HEAD` 聯集 `git status`），因為該 skill 的
  Phase 1 是「find 全部」，實測有專案含 87 份 CLAUDE.md，不先算範圍會全 repo 掃。
  步驟 7 跳過不代表步驟 8 跳過。先在 claude-dd dogfood 4 次抓到 2 個真錯誤才推全域
- **開發迴圈由 6 步改為 7 步**：新增步驟 7「沉澱本輪學到的」— 用
  `claude-md-management:revise-claude-md` 把本輪的踩雷/指令/慣例寫進 CLAUDE.md。
  它是唯一可跳過（本輪沒學到就跳）、也是唯一會回問使用者的步驟。
  步驟 1–6 編號與內容不變。全部現行文件、`/dd-init` 蓋章版與當時既有的 4 張 diagrams GIF
  已同步（重製時循環長度由 8s 改為 7.2s，144 幀 20fps）；
  CHANGELOG 舊條目與 UPGRADING 的歷史敘述保留原「6 步」字樣

### Added

- 全域模板 §7.2 觸發表新增 `revise-claude-md` 一列（關鍵字刻意避開 improver 的
  `修`/`改` 與 self-improving-agent 的 `沉澱`/`memory`/`skill`，避免撞列）
- `diagrams/src/` 納入版控 — GIF 的產生器（零依賴 Python 手寫 SVG）與重出流程。
  先前只保存成品 GIF，改一個字就得整張重畫；本次已實際踩到這個坑
- 新增第三張圖表「7 步開發迴圈」（`claude-dd-dev-loop*.gif`，中英各一），
  把七個步驟本身畫出來並嵌進兩份 README — 先前兩張圖只把迴圈壓成一個框裡的一行字
- `tech-diagram-gif` 陷阱表補上 playwright 的工具層與瀏覽器層差異：`browser_navigate`
  擋 `file://` 但 `run_code` 裡的 `page.goto('file://…')` 不受限、`run_code` 裡拿不到 `fs`、
  `page.screenshot({path})` 可寫任意路徑 — 連拍上百幀時走 `run_code` 這條

### Fixed

- `/dd-init` 蓋章版與兩份 README 原本把 `/revise-claude-md` 當成巢狀文件同步的工具，
  與其實際行為（回顧本 session 學到什麼）不符 — 已拆成兩件事分別說明。
  **已用舊版 `/dd-init` 蓋章過的專案不會自動更新**，需重跑 `/dd-init` 或手改該區塊

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
