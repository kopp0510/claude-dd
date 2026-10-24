**Critical 0 / Important 2 / Smells 0**: 審查快照 `git diff HEAD~1 HEAD`（scripts/CLAUDE.md、scripts/check-claude-md.sh、tests/CLAUDE.md、tests/test-gate.sh）。

**[Important]** `tests/test-gate.sh:340,349` 「連共同祖先都沒有」的 `reviews_missing` 放行路徑沒有被測到，目前的斷言由 owed_dirs 的訊息滿足。
- 失敗情境：刪掉 `scripts/check-claude-md.sh:165` 的警告 echo（或改掉 `:167` 的 return），`test-gate.sh` 仍全綠。⑪ 註解自稱這是「唯一允許的放行，必須斷言警告真的印出來」，實際沒有。
- 證據：`test-gate.sh:340` 的 `rm -rf r.js README.md src docs ...` 把 `docs/` 整個刪掉；`check-claude-md.sh:151` 的 `[ -d docs/reviews ] || return 1` 在進入 `resolve_fork_base` 之前就返回。`:349` 的 `said "找不到共同祖先"` 比對到的是 `check-claude-md.sh:108`（owed_dirs 的「也找不到共同祖先」），不是 `:165`。
- 建議：在 `:338` 切到 orphan 後補 `mkdir -p docs/reviews`，並改成斷言「這次跳過 review 報告檢查」。

**[Important]** `tests/test-gate.sh:273-276` 的 ⑦ 標題與說明宣稱涵蓋「起點 commit 被改寫後退到共同祖先」，但測試本體不是這樣。
- 失敗情境：讀者依 ⑦ 以為 fork-point 退化已被釘住，實際上 amend 的只是 HEAD，起點仍是祖先。若拿掉 `resolve_fork_base` 的 fork 段，⑦ 不會紅，只有 ⑩ 會抓到。
- 證據：`test-gate.sh:282` 的 `git commit -q --amend` 改的是段落內的 HEAD；`:283-285` 自己承認「名稱與實際不符」，但 `:273-276` 的原句沒有改。
- 建議：把 `:273-276` 的標題與說明改成與 `:282-285` 一致，或直接刪掉那句「現在退到共同祖先繼續算」。

**What I ran**
- 讀 diff 檔 `diff.txt` 全部 1010 行（分 4 段 Read）→ 完整讀過，四個被改檔的 HEAD 版本都有對照
- `grep` 快照中除四個被改檔外的 `segment-base / 共同祖先 / reviews_missing / resolve_fork_base / test-gate / bash32` 等識別符 → 命中 README.zh-TW.md、templates/global/CLAUDE.md、commands/dd-init.md、skills/code-simplifier/SKILL.md、UPGRADING.md、DD_PIPELINE_ARCHITECTURE.md；讀過這些命中，沒有發現與 HEAD 行為矛盾的敘述
- `grep -n 'git ' scripts/check-claude-md.sh | grep -v gitq` → 只剩 rev-parse、merge-base、cat-file、rev-list、log 等非檔案清單指令，沒有漏掉 gitq 的檔案列舉
- `grep -n 'bash32\|test-gate' .github/workflows/ci.yml` → `:414` 有 bash32 job，`:436` 以 `/bin/bash` 跑 test-gate，與 tests/CLAUDE.md 的 CI 描述一致
- `ls docs/reviews`（快照）→ 只有 `CLAUDE.md`
- `sed -n` 讀 `test-gate.sh:273-276,282-285,338-349` 與 `check-claude-md.sh:151` → 上述兩項發現的證據
- 沒有執行 test-gate、變異測試或任何寫入

**需要外部查證**
- scripts/CLAUDE.md:28-34 與 tests/CLAUDE.md:31-35 的變異紅數（3 / 7 / 2、12 / 5（其中 4 在舊 61 項）/ 2）：需要對改壞的 gate 副本跑 `bash tests/test-gate.sh <副本>` 才能核對。我沒有重跑。
- 「S6 的 review 抓到…」「S6 的 reviewer 預言過…」「S4 實作時確認」：快照的 docs/reviews 沒有 S6 報告，無法核對歸因。需要 `git log --all -- 'docs/reviews/S6*'` 找出報告並附 hash。

**Not reported**
- tests/CLAUDE.md:19-20 的「第 153 行」與 scripts/CLAUDE.md 內的「61 → 73」：都是帶日期的歷史紀錄，不是現行宣稱，依 §3.10 不報。
- DD_PIPELINE_ARCHITECTURE.md:125 的 gate 情境測試列沒有提到 review 報告情境：只描述後果、沒有寫死數字，判斷不算過期。
- 其餘 diff 新增句子（起點解析表、`--segment-base` 硬失敗、`gitq` 規則、`[ -d docs/reviews ]` 的 opt-in 說明）逐句對照 HEAD 程式碼，都成立。