# S1 步驟 4：查證（主對話）

## 派工

- 範圍：`git diff 60239e7 HEAD`（S1-1 `08948f7`、S1-2 `ded7c0b`）。安裝腳本有新的判斷邏輯，文件每一句都在講設定怎麼運作或引量測數字，所以全量派
- 派 3 個（下限），照改動的三種性質分：A 安裝腳本的邏輯（兩條路徑、shell 判斷、印出的句子）；B 測試（斷言會不會空通過、清單有沒有做完）；C 文件裡的宣稱（README、量測檔、CHANGELOG 對程式與量測輸出）
- 步驟 3 與審查同時跑，所以審查者讀的是 diff 檔裡 HEAD 那一份，不讀工作目錄
- 派工 prompt 只交範圍、材料位置與已跑過的驗證，沒有寫我對哪裡可能有錯的判斷

## 發現

三份都完整回來。Critical 0；Important：A 2 條、B 1 條、C 3 條；Smell：A 1 條、B 1 條、C 4 條。

**重疊項**
- 「`none` 只讀一個檔卻印成確定的沒設」：A、C 都列 Important
- 「換到沒設過的模型就回到預設」少了前提：C 列在 Important 第 3 條，A 寫在 Not reported 的順帶一提
- 「不合法的 UTF-8 位元組兩臂結論不同」：A 實測列 Important，B 列在需要外部查證（推測）

**獨有項**
- A：字面值精度、小寫 `nan`、大整數、深巢狀的兩臂差異；`NaN` 該不該算解析失敗
- B：清單以外的測試；「或管線」沒有佐證
- C：CHANGELOG 對個別模型無效值的說法；`/autocompact` 的版本條件；設定檔的讀取時點；兩種算法寫在同一句；日期；「報設在哪一層」

**逐條查證**（自己重跑或重讀，不照報告的說法）
- 兩臂差異：`jq -r "<valid 的定義> .v | valid"` 對 18 個值各跑舊寫法、新寫法與 python3；舊寫法只有 `99999.99999999999999999`、`1000000.0000000000000001` 兩個值跟 python3 不同（另一個是小寫 `nan`，python3 解析失敗）。
  jq 1.8.1（docker `ghcr.io/jqlang/jq:1.8.1`）同樣。新寫法在這 18 個值上除了小寫 `nan` 都跟 python3 相同
- 不合法的 UTF-8：`printf '{"t":"caf\xe9","autoCompactWindow":400000}'` → jq rc=0 印 400000；python3 `UnicodeDecodeError`。加 `errors="replace"` 之後印 400000
- 大整數：`{"x":1 後面 5000 個 0,…}` → jq 印 400000；python 3.13 加了 `set_int_max_str_digits(0)` 之後印 400000
- 深巢狀：3000 層 → jq rc=5「Exceeds depth limit for parsing」；python3 印 400000。沒有修
- 清單以外的測試：對設計文件「要新增的測試清單」逐項比，B 列的都不在清單上 → 屬實
- 管線：見 B 的處置
- `none` 的句子：呼叫點只傳 `$CLAUDE_DIR/settings.json`；F15 的原文是「in a settings file, such as」→ 屬實
- CHANGELOG：T2 的 `a-pm-5` 預期 `none` → 屬實
- 版本條件：F15 有「Before v2.1.288, the command saved one window for every model」→ 屬實
- 讀取時點：transcript 裡印出 `modelSettings` 而且 `claude-fable-5-2` 只有 `effortLevel` 的那筆工具結果，時間是 `2026-11-14T16:20:44.774Z`
- 兩種算法、日期、「報設在哪一層」：對量測檔的「當天輸出」與程式 → 屬實

**駁回**：無。**需使用者決定**：B 的第 1 條（清單以外的測試留不留）。

**需要外部查證（沒有查）**
- Claude Code 讀 settings.json 是不是嚴格的 JSON 解析（`NaN`、`Infinity` 會不會讓整份檔失效）
- 最上層的鍵是範圍外的值時，Claude Code 只忽略那個鍵還是整份設定驗證失敗
- 專案層與 managed 的設定檔能不能設 `autoCompactWindow`、與 `~/.claude/settings.json` 的優先順序
- 個別模型的值在範圍外時 Claude Code 怎麼處理

**派工材料裡後來不成立的**：diff 檔第 4 部分第 3 點貼的 `none` 那兩行輸出是修正前的句子。

## 處置

- 步驟 3（code-simplifier）的交回摘要：

  > 步驟 3（code-simplifier）交回摘要：tests/test-install.sh 改 3 處，install-dd-pipeline.sh 沒改。
  > 1. t10_check 跑 --check 的 if/else 兩支併成一個子 shell（依 $2 export 或 unset），錯誤處理只寫一次
  > 2. t10_check 找 shell 錯誤的 grep 樣式原本寫兩次，改成先存進 local shell_err
  > 3. 檔尾 nojson 三組 state 檢查抽成 t10_nojson_state <目錄名> <應回的狀態> <說明>；失敗訊息措辭小改，比對的字串沒動
  > 它回報的驗證：TEST_ONLY=T2 rc=0（142 例）、TEST_ONLY=T10 rc=0、shellcheck -S warning rc=0；把 n1 的預期改成 none 的變異副本 rc=1（跑完已刪）。
  > 實際 diff 存在同目錄 step3.diff（63 行）。
  我讀過它的 diff：三處都只動測試的寫法，比對的字串沒變；`tests/CLAUDE.md` 變異對照引的斷言字樣（「應該回 unknown」）還在
- 採納的都改了（各條見 `S1-a.md`、`S1-b.md`、`S1-c.md` 的處置）：安裝腳本的兩條路徑對齊三類輸入、`none` 與 `outofrange` 的句子、T2 四列、T10 兩格的比對字串、兩份 README、CHANGELOG、量測檔、設計文件 F4、`tests/CLAUDE.md`
- 步驟 5 重測（修正之後）：
  - macOS `/bin/bash tests/test-install.sh`（bash 3.2）rc=0，20 行 ✅，T2 是 146 例
  - ubuntu:24.04 容器（jq 1.7、python 3.12.3、bash 5.2.21、沒有 ffmpeg）：`test-install.sh` rc=0（20 ✅）、`test-gate.sh` rc=0（120 ✅）、`test-dd-init-upgrade.sh` rc=0（48 ✅）
  - `shellcheck -S warning install-dd-pipeline.sh tests/test-install.sh` rc=0；本機照 `.github/workflows/ci.yml` 逐 step 跑，20 個都 rc=0
  - 沙盒 HOME 真的跑 `./install-dd-pipeline.sh --check`，七種情況（最上層有設、最上層範圍外、只設在個別模型、都沒設、檔案壞掉、環境變數 400000、環境變數 5）都 rc=0，各印各的那一行
- 沒做的：上面四條外部查證；`plugin_enabled_state`、`mcp_scope` 等既有函式對「不合法的 UTF-8、大整數」的兩臂差異（不在這一段的範圍，只記在 `tests/CLAUDE.md`）
