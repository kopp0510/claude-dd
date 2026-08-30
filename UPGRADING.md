# 升級指南

各版本的變更摘要見 [CHANGELOG.md](CHANGELOG.md)。日常更新只要：

```bash
git pull && ./install-dd-pipeline.sh --force
```

以下是需要額外處理的兩種升級情境。

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

> `pre-prune-2026-08-04` 是標註在「刪除前最後完整狀態」的 tag，
> 取代先前文件中的裸 commit hash，重新 clone 後同樣可用。

- **上面的指令都帶 `--force`，全域 CLAUDE.md 會直接以 repo 版覆蓋、不出互動 diff**
  （舊版備份到 `~/.claude/backups/pre-install-<時間戳>/`，路徑印在完成訊息裡）。
  全域規則有本地客製想保留的話，最後一步改成不帶 `--force` 跑，才會出 diff 選單讓你選 `k`（保留本地）
- 被清掉的內容需要時自 git 歷史取回（`git checkout pre-prune-2026-08-04 -- skills/<名字>` 後加回部署陣列）
- `--uninstall` 同樣只認得現行部署清單 — 舊部署請先完成上述清理再解除安裝

## 既有專案升級到 7 步迴圈

> 本節原記錄「舊版 → 6 步」的升級；2026-08-31 迴圈新增步驟 7（沉澱本輪學到的），
> 現行為 7 步。已用舊版 `/dd-init` 蓋章過的專案不會自動更新，需依下述步驟重蓋或手改。

已在跑舊版（或手寫 5 步版）開發流程的專案：

1. 到該專案跑一次 `/dd-init` — 會補上缺的部分（pre-commit gate、`.screenshots/`（僅前端專案）、plugin 檢查）
2. **注意**：專案 CLAUDE.md 若已有 `## 開發流程` 區塊，`/dd-init` 會跳過不覆蓋 —
   要升級成 7 步版（新增 code-review 步驟、顯性化首輪測試、收尾沉澱），請手動編輯該區塊，
   或刪掉舊區塊後重跑 `/dd-init` 重蓋
3. 舊 DD Pipeline 專案的 `claude_docs/`、`PROJECT_STATE.md` 不受影響，可保留或自行清理
