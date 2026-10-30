# S2-judge：主對話的查證

段落 S2（`/dd-init` 蓋章區塊瘦身、跳 rev 13、升級分類腳本）步驟 4。範圍 `git diff f2ab54a`（到 7b8638a，工作目錄乾淨）。

## 派工

- 派 3 個 `code-reviewer`（不帶 model 參數），同一則訊息平行派出。照分工方向派：A 看搬家有沒有掉條件、指標有沒有懸空（設計文件要求的專審方向）；B 看腳本與測試（這段唯一的人工程式碼）；C 看 dd-init 流程與 CI（判斷分支多，CI 有好幾個 step 吃同一份區塊）。三個方向都對應這段的一個風險面，再多派也只是重疊，所以派 3 個
- diff 檔：scratchpad 的 `s2-review/diff.txt`，共 7865 行。內容是 ① 整段 diff；② 步驟 3 的改動（無，code-simplifier 判定不改）；③ 被改到檔案的整檔；④ 已跑過的驗證與預期值，標明不要重跑
- 三份完整報告都收回（各含 Findings、Not reported、What I ran），逐字存進 scratchpad 之後才開始查證

## 發現

逐條讀程式碼或實跑查證，Critical 0，採納的 Important 共 8 條（A 與 C 各有一條指同一件事，合併算一條）：

- **採納｜Important｜S2-a-1 = S2-c-3**：7.3 的步驟重號檢查會掃到區塊外的編號清單。查證：`commands/dd-init.md` 那行的 grep 對象是整份 `CLAUDE.md.dd-upgrade`。12 個已蓋章專案只計數不印內容，9 個的 `^[0-9]+\. ` 超過 8 行
- **採納｜Important｜S2-a-2**：CHANGELOG「見下一條」懸空。查證：那句在 `## 未發布` 最後一條，下一行是 `## 1.6.12`；原本在 S1 條目結尾（`git show f2ab54a:CHANGELOG.md`）
- **採納｜Important｜S2-a-3**：半號段落判準在全域 §4.4 是在「兩者都沒有時」的引言區塊裡，SKILL.md 沒有。查證：`grep -n -E '半號|S2\.5' skills/dd-loop/SKILL.md` 修前 0 筆，全域模板那條在 `>` 區塊裡
- **採納｜Important｜S2-b-1**：降級過的標題第二次升級多一個空標題。查證：讀 awk，清單比對是逐字的，`#### CLAUDE.md 維護` 不在清單裡；修後測試「rental 型第二次升級輸出不變」綠，變異（改回逐字）紅
- **採納｜Important｜S2-b-2**：改寫過的步驟 5 底下的指令錨到步驟 4。查證：錨點只在範本單位更新；修後測試 3b 綠，變異紅 2 則
- **採納｜Important｜S2-b-3**：「步驟 1 之前」錨點沒測試。查證：`add_locals` 修前沒有在步驟 1 前插東西；修後變異（拿掉 pre 插入）紅 8 則
- **採納｜Important｜S2-c-1**：React 片段搬出區塊後改它不必跳 rev、CI 擋不到。查證：rev 跳號 step 的 `stamp()` 停在第一個 ``` 關閉行；修後在拋棄式 clone 打假 tag 實測，只改 React 一行時紅
- **採納｜Important｜S2-c-2**：React 圍欄部分在清單時會兩份並存。查證：腳本把圍欄整塊當一個單位（`partial`），7.2 修前一律補 React 段
- **採納｜Smell｜S2-c-4**：CLI 佔位行兩句矛盾。查證：dd-init.md 的 7.1 前後兩句對 playwright 那行講法不同
- **採納｜Smell｜S2-b-3 附帶**：縮排的在地編號清單被列進「疑似改寫」
- **需要外部查證 → 自己查完**：
  - C 要的「有沒有專案帶兩個標記」：12 個已蓋章專案全是 1 個，不成立
  - A 要的「區塊外有沒有編號清單」：有（見 S2-a-1）
  - B 要的 mawk／gawk：docker 實跑兩種都 40 ✅
- **駁回**：B 的「awk 執行期錯誤回 exit 2 撞號」。Phase 1 對 exit 非 0 一律不升級並照實轉述，撞號不改變行為

## 處置

每條的修法與變異結果寫在 S2-a／b／c 的「處置」節。修完之後的驗證：
- `tests/test-dd-init-upgrade.sh`：macOS bash 3.2＋BWK awk、debian mawk 1.3.4、bash:5＋gawk 5.3.2 都是 40 ✅ / 0 ❌
- 舊變異重跑：空殼 36 ❌、圍欄一律算範本 9 ❌、終點不看清單 10 ❌
- 新變異三個各自紅（1、2、8 ❌），明細記在 `tests/CLAUDE.md`
- ci.yml rev 跳號 step 的負面測試：在拋棄式 clone 打假 tag，內容相同綠；只改 React 一行紅；只改區塊一行紅

## 重疊與獨有項

- 重疊：S2-a-1 與 S2-c-3（7.3 重號檢查範圍）
- A 獨有：CHANGELOG 指標、半號段落
- B 獨有：降級標題、改寫步驟 5 的錨點、pre 錨點沒測試。B 是唯一實際建 fixture 跑腳本的，三條都靠實跑重現
- C 獨有：React 片段的 rev、React 圍欄重複、CLI 矛盾
