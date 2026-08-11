# 變更紀錄

記錄影響使用方式的結構性變更。日期為變更進 repo 的日期，細節可在 git 歷史查證。
升級步驟見 [UPGRADING.md](UPGRADING.md)。

## 2026-08-10 — 新增 tech-diagram-gif skill

- 新增自製 skill：技術圖表繪製與 GIF 匯出（流程圖 / 架構圖 / 走向動畫），
  風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT）
- 安裝腳本環境檢查加入 `ffmpeg` 可選項偵測：缺少時該 skill 退化交付 SVG，不中止安裝
- Promoted skills 由 9 個增為 10 個

## 2026-08-04 — 單桶化（刪除 misc / deprecated 桶）

repo 改為單一部署清單，只保留有實證使用紀錄的元件並全數預設部署。

- 刪除 deprecated 桶：全歷史 0 次使用的 34 skills / 17 agents / 6 dd 指令 / 13 NS commands
- 刪除 misc 桶：SRE 備援性質但零實際調用的 11 skills / 5 NS commands
- 安裝腳本移除 `--prune`（單一清單後無桶可清）
- 被刪的 6 個 dd 指令為舊版多階段流程的 `/dd-start`、`/dd-arch`、`/dd-approve`、
  `/dd-dev`、`/dd-test`，加上已停用的 `/dd-dx`；`/dd-init` 保留並改造

被刪內容可自 tag `pre-prune-2026-08-04` 取回，見 UPGRADING.md。

同批曾評估 plugin marketplace 分發路線（`.claude-plugin/marketplace.json`），
實測可行後仍移除、維持單一 clone + bash 安裝：plugin 機制無法部署全域 CLAUDE.md
與 pre-commit gate，只能交付元件子集，與「完整工作法」的定位不符。

## 2026-07-31 — 全域模板依 Claude 5 家族遷移指引調整

規則內容不變，僅語氣平述化（§3.1、§3.9、§7 開頭、§7.2 標題、§7.5），
原 §7.6 的藉口逐條表濃縮為單一原則句。

## 2026-07-23 — 骨幹改為 6 步開發迴圈

- 原多階段 DD Pipeline（`dd-start` → `dd-arch` → `dd-approve` → `dd-dev` → `dd-test`）
  依實際使用率盤點後封存，骨幹改為經實際專案實戰驗證的功能段落迴圈
- `/dd-init` 改造：從產出設計文件骨架，改為蓋章開發迴圈到專案 CLAUDE.md
- 全域模板 §7.2 Skill 觸發表由 21 列瘦身至 8 列，只留預設部署元件對應項。
  被移除列的目標（senior-qa、test-engineer、tdd-guide、test-gen、senior-frontend、
  ui-design-system、ux-researcher-designer、landing-page-generator、senior-backend、
  dx-engineer、senior-fullstack、senior-secops、playwright-pro）已不再預設部署
