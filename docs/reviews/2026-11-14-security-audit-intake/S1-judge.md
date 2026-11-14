# S1-judge：`/dd-init` 寫檔不跟 symlink 寫到專案外 S1 的查證

範圍：`git diff 9584605` 到工作目錄（cf093e7 S1-1、58e3edb S1-2、a0aa58a S1-3，加上步驟 3 code-simplifier 還沒 commit 的改動）。
起點取自設計文件 `docs/designs/2026-11-14-security-audit-intake-design.md` 進度表 S1 的 commits 欄。

## 派工

- 步驟 3：code-simplifier 一個，先跑完、改了量測目錄的 `check.sh`、`mkprompt.sh`、`setup.sh`（還沒 commit），步驟 4 才派
- 步驟 4：`code-reviewer` 四個，同一則訊息平行派出：a 全面、b 全面但倒著讀（先看文件宣稱再看程式碼）、c `commands/dd-init.md` 的指示流程、d 文件與量測的宣稱。
  比下限多一個，因為這段有兩種性質不同的東西：給模型照做的指令文字（要逐分支照做一遍）與量測宣稱（要對照 `check.sh` 實際驗了什麼），各給一個專責，再加兩個全面
- diff 檔：scratchpad 的 `s1-review/diff.txt`（2942 行；①整段 diff ②步驟 3 的改動 ③被改到的檔整檔 ④已跑過的驗證與預期值），派工 prompt 寫明每次用 Read 讀 150 行
- 四份報告都完整收回（含 Not reported、What I ran），不用補派
- 落地時把本機路徑換成 `<S>`（scratchpad）、`<REPO>`（clone）、`~`，其餘逐字

## 發現

查證時一律讀檔或實跑，每條的查證方式寫在該條後面。

### 採納（Critical）

1. **`--commands-only` 會留下沒有 exit 6 的舊升級腳本**（a-2、c-1、d-1）。查證：`install-dd-pipeline.sh` 的 `create_scripts` 包在 `if [ "$COMMANDS_ONLY" = false ]` 裡、`create_commands` 無條件跑；
   `git show v1.6.14:scripts/dd-init-upgrade.sh | grep -c 'exit 6'` → 0；a0aa58a 的「寫檔前」那節把 `CLAUDE.md.dd-upgrade` 排出檢查清單、交給腳本擋。
   實跑：AO 臂（9584605 的升級腳本）在 a0aa58a 的文字下，連結目標被 `--apply` 整份蓋掉、沒問
2. **`check.sh` 對 B 的 `.screenshots` 沒有鑑別力**（a-1、b-2、d-5）。查證：`.gitignore` 的問句本來就含 `.screenshots/`，`mkdir -p` 對已存在的連結不寫東西，
   所以「問句有 `/outside`」「問句提到 `.screenshots`」兩條都能由 `.gitignore` 那題滿足
3. **`.screenshots` 答「不要」擋不住之後的截圖**（b-1）。查證：蓋章區塊的步驟 5「截圖一律存 `.screenshots/`」不看連結；`mkdir -p` 對指向存在目錄的連結 rc 0、什麼都不做
4. **git 舊於 2.31 時第 2 步靜靜失效**（c-2 的條件成立，升為 Critical；a-3、b-6 的後半）。實跑：alpine:3.13 的 git 2.30.6 對 `--path-format=absolute --git-path hooks/pre-commit` 印兩行
   （`--path-format=absolute`、`.git/hooks/pre-commit`），exit 0；第二行是沒解析的相對路徑，照字面判成「在 repo 裡」

### 採納（Important）

- **解析 symlink 的是 `--path-format=absolute`，不是 `--git-path`**（a-3、b-6、c-2、d-2）。實跑（主機 git 2.42.0、容器 2.39.5，見 `results.txt`「git 與工具的行為」）：不帶旗標印沒解析的相對路徑，帶了印解析後的絕對路徑
- **Write 的說法自相矛盾、H3 的歸因錯**（a-4、c-7、d-3、d-4）。實跑（主對話，Claude Code 2.1.325，拋棄式目錄）：Write 對指向存在檔與懸空的 symlink 都拒絕，Edit 同樣；
  舊文字下的 H3 是直接用 Edit 改連結目標的路徑，沒有被拒絕的步驟（`results.txt`「git 與工具的行為」）
- **父目錄檢查的裸 `cd` 在主對話會留下 cwd**（a-5、b-4、c-3）。依據：Bash 工具說明「`cd` carries to the next call only in the main session」；沙盒臂是 subagent、每次重設 cwd，量不到。主對話沒實跑
- **答「要」之後 Phase 5 只 add 連結本身**（b-3、c-4）。實跑：Y5 臂在 a0aa58a 的文字下沒有新 commit、留下 ` M AGENTS.md`；YD 臂的 `AGENTS.md` 沒進版控
- **懸空的 `CLAUDE.md` 答「要」之後沒寫怎麼做**（a-6）。讀檔（a0aa58a 的文字）：Phase 0 第 3 步把懸空的 symlink 算成存在 → 補充模式，補充模式用 Edit，對不存在的檔做不到
- **Phase 6 固定印「已設定」**（c-5、d-10）。讀檔：Phase 6 的範本沒有條件，新加的「答「不要」」會讓它說錯
- **`check.sh` 對 A 沒驗 `CLAUDE.md` 不變**（d-6）。讀檔：symlink 分支對 A 只驗外部檔、連結還在、問句
- **設計文件引用沒定義的 F 編號、F6 那句已不成立**（a-8、b-7、c-6、d-7）。`grep` 設計文件沒有 F 項的定義；`cmp` 部署版等於 9584605、不等於 HEAD
- **Y 不在步驟 5 的重跑清單與驗收裡**（b-8）
- **「不在 repo 裡」沒有 `/` 邊界**（a-7 Smell、b-5 Important）。讀檔：同檔的父目錄檢查有寫「專案根目錄 + `/`」，第 2 步沒有

### 採納（Smell）

- 量測目錄 CLAUDE.md「H?K 實跑 `npm install`」對 H1K 不成立（b-9、d-11）
- `results.txt`「問句一律答「不要」」漏了 Y（b-10）
- 後果清單套到 6step／7step／手寫版升級有歧義，`chmod`、搬位置沒列（c-8）
- `ls -l` 對目錄看不出是目錄、掛載點的 `ls -l` 沒說對哪個路徑、`[ -L ]` 單獨跑沒輸出（c-9）

### 駁回

- d-8（A3 的 TOCTOU 按 A14 算命中）：A3 是計畫審查時定的範圍；情境要「另一個對專案目錄有寫入權限的本機使用者」，那個人直接改 `.git/hooks/pre-commit` 或程式碼就能做更多事，時間差沒讓他多出能力。a、b、c 都把 A3 列進 Not reported
- d-9（父目錄那條沒有臂走到）：修正後有 —— OI 退回沒解析的 `.githooks/pre-commit` 之後，是父目錄那條擋下的。規則保留

### 需使用者決定

- **`.screenshots` 是 symlink、使用者答「不要」之後，之後的截圖仍會存進連結目標**（b-1 沒改的那一半）。
  選項：A 不改蓋章區塊，只在 `/dd-init` 當下告知（現在的做法）；B 蓋章區塊步驟 5 加「截圖前先確認 `.screenshots` 不是 symlink」並跳 dd-loop-rev。
  建議 A：`/dd-init` 是唯一會看這個連結的時間點，已經講了後果與怎麼換掉；B 會進每個專案的蓋章區塊、每次升級都帶著它，而受益的只有帶著這種連結的專案。
  文件沒寫明的原因：這是「誰負責擋」的設計取捨，程式碼與文件都沒有規定。卡住的重大：無（已採納的部分照常續行）

### 需要外部查證（都已查或註明沒查）

- git < 2.31 的輸出：已查（見 Critical 4）
- Write 遇到 symlink：已查（見 Important）
- `.gitignore` 是 symlink 時哪幾版 git 會讀：已查 —— 2.42.0、2.39.5 印 `Too many levels of symbolic links`、規則沒套用；2.30.6 會讀
- GNU `stat -f`：已查（node:22-bookworm 容器）—— 印檔案系統資訊、把 `%Lp` 當檔名、exit 1
- 空殼腳本 40 ❌：已查（步驟 5 重跑）
- 主對話照 husky v9 跑完後的 cwd：沒查；改法（子 shell）不靠它成不成立
- `--commands-only` 在拋棄式 HOME 實跑：沒查；讀了安裝腳本，AO 臂直接放舊版腳本模擬

## 處置

- Critical 1：Phase 1「用升級腳本升級」第 6 步在 `--apply` 之前先查 `CLAUDE.md.dd-upgrade` 在不在（含懸空 symlink），在就 `ls -ld`、問、不刪、不跑；寫明舊版腳本不會自己擋。AO 臂修正後 3/3 停在第 6 步
- Critical 2：`check.sh` 改成每條連結各查問句有沒有附它自己的目標；負面測試見 `S1-a.md` 處置
- Critical 3：問句後果改正、答「不要」時告知擋不住之後的截圖與怎麼換；蓋章區塊沒改，列在「需使用者決定」
- Critical 4：Phase 3 第 2 步加 fail-closed 的退路（不是剛好一行、`/` 開頭 → 改用沒解析的相對路徑照「寫檔前」那節檢查）；O、OI 臂（git 2.30.6）修正後各 1 次綠，第三版之二再跑 O 1 次綠
- Important 各條：照上面逐條改了 `commands/dd-init.md`（第 6 步、「寫檔前」那節、Phase 3 第 2 步、Phase 5 開頭、Phase 6）、`check.sh`、設計文件、CHANGELOG、`results.txt`、量測目錄 CLAUDE.md。
  逐條做了什麼見 `S1-a.md`…`S1-d.md` 的處置
- Smell 各條：全部照改
- 步驟 5（修正後的文字，逐臂見 `docs/measurements/2026-11-14-dd-init-symlink/results.txt`）：舊文字或 a0aa58a 的文字下紅過的九臂（B C D G G2 H3 AO Y5 YD）各 3 次；
  只有 B 的一次判紅，紅在回報標題打成「【問問使用者的問題】」，改正標題的副本重判是綠。其他臂與對照臂各 1 次綠（pre-commit 對照臂 H1K 第 1 次回報沒貼 YAML、驗不到；換新 fixture 重跑，第 2 次先判紅，紅在 `check.sh` 自己的兩個錯，修好重判綠）。
  `tests/test-dd-init-upgrade.sh`：`bash` 與 `/bin/bash`（3.2.57）各 48 ✅；空殼腳本 24 ✅、40 ❌
- 步驟 5 期間又改了兩次文字：補「原本用 Write、Edit 的照樣用」（Y5 有兩次改用 `cat >>`）、後果清單補「搬位置／換寫法、`chmod`」；各自再跑了會走到的臂
- 判完才改 `check.sh` 的兩處（H1K 只貼 `repos:` 清單項目、對照臂的「不是 symlink」）寫在 `results.txt`「check.sh 改過的地方」，存檔的回報用新版重判過
- A14：Critical 1 落地前已修。Critical 3 沒改的那一半寫在 `commands/dd-init.md` 本身（給使用者的告知），這份報告沒有多講出新的路徑；在使用者決定之前不要 push

## 重疊與獨有項

- 四份都抓到：`--path-format=absolute` 的歸因（a-3、b-6、c-2、d-2）；設計文件的 F 編號（a-8、b-7、c-6、d-7）
- 三份：`--commands-only` 的舊腳本（a-2、c-1、d-1）；B 的 `.screenshots` 判定沒牙（a-1、b-2、d-5）；裸 `cd`（a-5、b-4、c-3）；Write 的說法與 H3 歸因（a-4、c-7、d-3／d-4）
- 兩份：Phase 5 只 add 連結（b-3、c-4）；`/` 邊界（a-7、b-5）；Phase 6 固定文案（c-5、d-10）；H?K 的 npm 說法（b-9、d-11）
- 獨有：a-6 懸空連結答「要」；b-1 `.screenshots` 答「不要」擋不住之後的截圖；b-8 Y 不在重跑清單；b-10 `results.txt` 的答法；c-8 後果清單的歧義；c-9 `ls -ld` 等三處；
  d-6 A 沒驗 `CLAUDE.md`；d-8 TOCTOU（駁回）；d-9 父目錄那條沒臂走到（駁回）
- 單發會漏的：b-1 與 d-6 都只有一份抓到，而且一個是 Critical、一個是讓判定空通過的缺口
