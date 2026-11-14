# S1 步驟 4：查證（主對話）

## 派工

- 範圍：`git diff 28663da HEAD`（4 個 commit：89dd118、4995b0d、61585a4、1a05146）。步驟 3 的 code-simplifier 與這次審查同時跑，所以審查者讀的是 HEAD 的版本
- 派 3 個（下限）：這段的 diff 約 850 行，分三個不重疊的方向 —— A 安裝腳本的邏輯、B 測試、C 文件與註解的宣稱。沒有再加第四個：三份回來的發現互相對得上（見下方重疊項），沒有哪一塊只有一個人看
- 派工 prompt 只交事實（改了哪些函式、已跑過的驗證與預期值），沒有寫我對哪裡可能有錯的判斷
- 步驟 3 的結果：code-simplifier 只合併了 `show_completion` 裡兩個相鄰、條件相同的 `if`（淨刪 2 行），其餘判斷不值得改。我讀了它的 diff、重跑測試；合併後那個 `if` 的註解原本只講 agent 與 plugin 兩段，補上 output style

## 發現

三份都完整回來（各有分級、證據、What I ran、Not reported）。Critical 0；Important：A 2 條、B 4 條、C 3 條。

**重疊項**
- 「檔案裡不只一個 JSON 值時兩條路徑結論不同」：A、B、C 三份都報了（A 給 `{} {}`，B 多給 `null {}`，C 多給 BOM 與 `mcp_scope` 的情況）。三份各自寫了重現腳本，結果一致
- 「先寫 settings、後寫 installed 留下半套狀態」：A 列為 Important（因為這段新加的完成訊息會講出相反的話），B 列在 Not reported（既有問題）。讀程式碼判定：順序是既有的，但「完成訊息說沒啟用、設定檔卻寫了啟用」這個矛盾是這段新造的，照 A 的級別處理

**獨有項**
- A：無其他
- B：`p-entry-valid` 分不出更新與新建；`plugin_enabled_state` 的 `none`；`TEST_ONLY` 打錯
- C：全稱宣稱；T3 註解的理由；`plain` 的機制

**逐條查證**（都是自己重跑或重讀程式碼，不照報告的說法）
- 多個 JSON 值：實跑 `jq -e 'type == "object"'` 對 `{} {}`、`[] {}` 都回 0 → 屬實，採納
- BOM：實跑 jq 對 BOM 開頭的檔 rc=0、python3 預設讀法報 `Unexpected UTF-8 BOM` → 屬實，採納
- 登記與啟用的順序：讀 `install_plugins`，settings 的 `json_edit` 在 installed 的之前、後者失敗只 `continue` → 屬實，採納
- `p-entry-valid`：把兩條登記敘述都改成一律新建實跑 → 修測試之前全綠（屬實），修測試之後這一例紅
- `plugin_enabled_state`：讀 18e8522 的 commit 訊息與現在的註解 → 審查者說的不一致屬實；文件（根目錄 CLAUDE.md 的鐵則）寫明了該選哪一邊，所以不交使用者決定，直接改
- `TEST_ONLY`：讀 `want()` → 屬實，採納
- T3 註解：`grep backup_before_overwrite` 的呼叫點不含 `install_plugins` → 屬實，採納
- `plain`：實跑 BSD sed → 印出壞位元組之前的行後 rc=1 → 屬實，採納

**駁回**：無

**需使用者決定**：無

**需要外部查證**：macOS runner 的 jq 1.8.2 對 BOM 的行為（本機驗不了；push 之後 macOS job 的 T2 會跑到，行為不同的話是紅燈、不是靜默）

## 處置

- 9 條 Important 全部採納、全部修掉，各條怎麼修寫在 `S1-a.md`、`S1-b.md`、`S1-c.md` 的處置
- 修完之後重跑（步驟 5）：`/bin/bash tests/test-install.sh` rc=0（macOS，bash 3.2），T2 是 109 例；Ubuntu 24.04 容器（bash 5.2.21、jq 1.7、Python 3.12.3、GNU coreutils 9.4）整支 rc=0；
  14 個變異重跑都紅在各自的斷言上；本機照 ci.yml 逐 step 跑 20 個全過；`shellcheck -S warning` 無輸出
- 另外在同一個 Ubuntu 容器跑了 `tests/test-gate.sh`（120 個 ✅）、`tests/test-dd-init-upgrade.sh`（48 個 ✅）與兩支 hook 測試（99、30 個情境），都過 —— 這些 commit 還沒 push，GitHub 的 runner 沒跑過
- 沒處理、照實記下的三件：懸空 symlink 時 GNU `cp` 會中止（既有）、互動選單測不到、jq 與 python3 對大整數與 NaN 的寫回格式沒比過
