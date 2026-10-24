# S8 查證

## 派工

3 個 code-reviewer 平行派（a 全面；b 偏重 rev 12 同步點；c 偏重 gate 宣稱、其他只寫 trailer 處、進度表）。
範圍 `git diff efb7931 HEAD`（dbf4a2f），diff 檔附 CI 四個 step 的本機輸出（預期都 exit 0）。
diff 只有文件，但新句子對 gate 行為下了宣稱，所以照派（全域 §3.9：判準是「有沒有引別處」）。三份都完整回來。

## 發現

| 項目 | a | b | c | 判定 |
|---|---|---|---|---|
| 設計文件 S8「起點」段說「S7 與 S8 報告補齊 gate 才放行」——錯：`reviews_missing` 只要範圍內新增任一 `S[0-9]*.md` 就放行，起點仍是 3332730，S8 的報告會把 S7 的要求頂掉 | ✔ | ✔ | ✔ | 採納 Important。讀 `scripts/check-claude-md.sh` 的 `reviews_missing` 判斷式與 `dd-segment-base`（3332730）屬實 |
| 蓋章版 :91 新句「gate 認的是這個檔…照樣被擋」與同條 :96-97「gate 不會強制它存在」互相矛盾（後者其實只講 pre-commit） | ✔ | — | ✔ | 採納 Important。讀 `commands/dd-init.md:89-97` 屬實 |
| 「不派 agent」那條跳過路徑（模板 :268-270、蓋章版 :77-78）只寫「理由寫進設計文件」，沒提 SKIP.md，照做一樣被擋 | — | ✔（獨有） | — | 採納 Important。gate 不讀設計文件，屬實 |
| 新句沒寫「只在有 `docs/reviews/` 時」「gate 認任何 `S<數字>…md`」兩個前提 | Not reported | Not reported | 併在第 2 條 | 採納為 Smell，順手改 |

駁回：無。需使用者決定：無。外部查證：三份都建議在拋棄式 repo 實跑「只加一份 S8-a.md 就放行」——
gate 判斷式是單一 grep、讀碼已足以確定，未另跑。

## 處置

- 設計文件 S8 起點段改寫成「gate 擋不住 S7 漏報告，回頭做 S7 要自己附 `S7-*.md`」，S7 那列狀態格同步註明
- 蓋章版 :96-97 改為「pre-commit 不會強制它存在（只在開下一段時查，而且只查有沒有新增任何一份）」
- 模板與蓋章版「不派 agent」那條補「有 `docs/reviews/` 時另建 `docs/reviews/S<段落>-SKIP.md`」
- 兩處新句改成「有 `docs/reviews/` 時 `--start-segment` 要範圍裡新增一份 `S<數字>…md`，只加 trailer 開下一段時會被擋」
- 改完重跑 CI 四個 step（CHANGELOG 已發布區塊、四方一致、第五方、gate 情境測試）全 rc=0
