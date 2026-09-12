# 升級指南

各版本的變更摘要見 [CHANGELOG.md](CHANGELOG.md)。日常更新只要：

```bash
git pull && ./install-dd-pipeline.sh --force
```

以下是需要額外處理的三種升級情境。

## 從舊版部署（全量 / 分桶時期）升級

舊版會把 53–54 個 skills / 21 個 agents / 7 個 dd 指令全部裝進 `~/.claude/`
（全量時期 53 個，分桶時期 54 個）。
misc / deprecated 桶已於 2026-08-04 自 repo 刪除，現行腳本已無 `--prune`（單一部署
清單後無桶可清）— 從全量或分桶時期部署升級時，先暫時取回含完整名單與 `--prune` 的
舊版腳本做清理，再換回最新版：

```bash
git pull
git checkout pre-prune-2026-08-04 -- install-dd-pipeline.sh   # 暫取含 deprecated 名單的腳本
./install-dd-pipeline.sh --force --prune                      # 清掉不再部署的舊檔（逐項確認）
git checkout HEAD -- install-dd-pipeline.sh                   # 還原最新版腳本（git status 應乾淨）
./install-dd-pipeline.sh --force
```

**`--prune` 清不到 `templates/`，要自己刪一次：**

```bash
rm -rf ~/.claude/templates/dd    # 1.0.0 起不再部署文件模板；--prune 只掃 skills/agents/commands
```

`prune_retired()` 只走 `ALL_SKILLS` / `ALL_AGENTS` / `ALL_DD_COMMANDS` / `ALL_NS_COMMANDS`
四個陣列，完全沒有 templates 的分支（已讀舊版腳本確認）。不自己刪的話，1.0.0 宣告不再部署的
7 份模板會一直留在那裡。

> **line 22 會印 7 行紅字「源檔案不存在」，那是預期的**：舊版腳本的 `DD_TEMPLATES` 有 7 個項目
> （`CLAUDE.md.template`、`PROJECT_STATE.md.template`、`REQUIREMENTS.md.template`、
> `ARCHITECTURE.md.template`、`API_CONTRACT.md.template`、`EXAMPLES.md.template`、`ADR.md.template`），
> 現在 repo 裡一個都不在了，所以每一個都印一行紅字然後 `continue`。它不會中止安裝 —— 不要被嚇到
> 在下一個 `[y/N]` 提示按 Enter（預設是 N），那樣 prune 就整個沒跑，而全域 CLAUDE.md 已經被覆蓋了。

> `pre-prune-2026-08-04` 是標註在「刪除前最後完整狀態」的 tag，
> 取代先前文件中的裸 commit hash，重新 clone 後同樣可用。

- **上面的指令都帶 `--force`，全域 CLAUDE.md 會直接以 repo 版覆蓋、不出互動 diff**
  （舊版備份到 `~/.claude/backups/pre-install-<時間戳>/`，路徑印在完成訊息裡）。
  全域規則有本地客製想保留的話，**line 22 與 line 24 兩個指令都要拿掉 `--force`**（兩次都會出
  diff 選單，兩次都選 `k`）。只改最後一步是沒用的：line 22 的 `--force` 已經先把
  `~/.claude/CLAUDE.md` 換成 repo 版，等跑到最後一步時兩邊內容已經一致，腳本直接回報
  「與 repo 版本一致」就 return，那個可以選 `k` 的選單**永遠不會出現**（實跑驗證過）。
  `--prune` 與 `--force` 是分開解析的，拿掉 `--force` 不影響清理。
  已經被蓋掉的話，去完成訊息印出的 `~/.claude/backups/pre-install-<時間戳>/global/` 撈回來自己合併。
  **選單出現時只按 `k`，不要按 `s`（顯示完整 diff）** —— 舊版腳本那個分支裡的 `diff` 是裸呼叫，
  在 `set -e` 下會直接中止整個安裝，講好的第二次詢問永遠問不到（此 bug 已在現行版修掉，
  但這一步你跑的是 `git checkout` 取回的舊腳本）
- 被清掉的內容需要時自 git 歷史取回（`git checkout pre-prune-2026-08-04 -- skills/<名字>` 後加回部署陣列）
- `--uninstall` 同樣只認得現行部署清單 — 舊部署請先完成上述清理再解除安裝

## 既有專案升級到 8 步迴圈

> 本節原記錄「舊版 → 6 步」的升級。2026-08-31 迴圈兩次擴充：先加步驟 7（沉澱本輪所學），
> 同日再加步驟 8（評分 & 修正本輪動過的 CLAUDE.md），**現行為 8 步**。
> 已用舊版 `/dd-init` 蓋章過的專案不會自動更新，需依下述步驟重蓋或手改。

已在跑舊版（或手寫 5 步版）開發流程的專案：

1. 到該專案跑一次 `/dd-init` — 會補上缺的部分（pre-commit gate、`.screenshots/`（僅前端專案）、plugin 檢查）
2. **注意**：專案 CLAUDE.md 若已有 `## 開發流程` 區塊，`/dd-init` 會看區塊裡的版本標記 ——
   舊版（`6step` / `7step` / 沒有標記）會列出與現行版的差異並詢問是否升級，同意才改，
   專案自己加的內容會保留；不想讓它改就選拒絕，再自行手動編輯
3. 舊 DD Pipeline 專案的 `claude_docs/`、`PROJECT_STATE.md` 不受影響，可保留或自行清理

## 已是 8 步迴圈的專案：補上「段落起點」

2026-09-11 起，步驟 3、4、8 改從段落起點算整段，gate 也會追查 SKIP 跳過、之後沒補的
CLAUDE.md（原因見 [CHANGELOG.md](CHANGELOG.md)「未發布」）。

1. 先到 claude-dd repo 跑 `git pull && ./install-dd-pipeline.sh --force`。舊版 gate 不認得 `--start-segment`：
   沒有 staged 時什麼都不印；有 staged 程式碼時會照常檢查、印出「commit 已擋下」—— 那不是真的要你補檔，
   不要照著做，先更新 gate
2. 到專案跑 `/dd-init` — 區塊標記是 `8step` 但 rev 比 4 舊的，會被判定為舊版並詢問是否升級。
   **這一步不能省**：專案 CLAUDE.md 的優先序高於全域 CLAUDE.md，舊區塊「只看最後一個 commit」的寫法
   會蓋過全域模板的新寫法
3. **第一個功能段落開始前，自己跑一次 `~/.claude/scripts/check-claude-md.sh --start-segment`。**
   這批專案的起點檔還不存在，不主動跑的話要等第一個 `SKIP_DOC_CHECK=1` commit 才會自動補記，
   起點就落在段落中間，它前面的 commit 步驟 3、4、8 全部看不到 —— 而 gate 印的是「記下段落起點 …」、
   `--segment-base` 也正常 exit 0，兩個訊號都看不出範圍已經縮水
