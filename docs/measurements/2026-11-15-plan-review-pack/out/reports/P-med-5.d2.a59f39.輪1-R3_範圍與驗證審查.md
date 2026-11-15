【我查了什麼】
- 讀 `install-dd-pipeline.sh` 的 `backup_before_overwrite`（187–195）、global CLAUDE.md 分支（1185–1235）、`create_commands` 的 deprecated 清理（884–900）、`show_completion`（1241 起）、`validate_skill_hooks`（463，用 `find "$SCRIPT_DIR/skills"`）。`set -e` 在第 8 行，沒有 `set -u`。
- 讀 `tests/test-install.sh` 全 87 行，確認現有 `SANDBOX` 的斷言（第 50–56、85–86 行）與計畫說的一致。
- 讀 `tests/CLAUDE.md`（列表與「此層約束」）與根目錄 `CLAUDE.md` 的「新增 Script／Command／Output Style」段、§「注意事項」。
- 跑的指令與結果：
  - `grep -n '進度以' CLAUDE.md`：無輸出。
  - `grep -n -E '新增|同時改|同批|要一起|同步' CLAUDE.md tests/CLAUDE.md scripts/CLAUDE.md`：命中的規則都與計畫的新增項目對得上，但沒有關於進度表指路的規定。
  - `grep -n -E 'backup_before_overwrite|cp -r|deprecated_dd|...' install-dd-pipeline.sh`：backup 呼叫點共 9 處（528、604、921、957、1006、1046、1194、1216、1227），與事實 F4 一致。
  - `grep -n -E 'runs-on|...' .github/workflows/ci.yml`：`lint` 在 ubuntu-latest，macOS job 在 564 行。
  - `ls docs/ docs/reviews docs/designs`：`docs/reviews/` 存在，裡面有 `S6-a.md`、`S6-b.md`；`docs/designs/` 有 7 份設計文件。
  - `grep -n -E '^set |set -[eu]' install-dd-pipeline.sh`：只有 `set -e`（第 8 行）。
- 沒有跑測試、安裝、容器，也沒上網。

【批評】
輪1-R3-1｜重大｜開表時必須在根目錄 CLAUDE.md 第一個 `##` 前加「進度以 docs/designs/… 為準」指路（全域 §4.4 明文寫「開表的同時」），計畫只用「根目錄沒有這句」來說明不需要。計畫會新開進度表，卻沒把這句列進 S1 或 S2 的文件同步。少了這句，下一個 session 會看不到表，段落起點與 commit 範圍就靜默遺失。計畫的設計文件 `docs/designs/2026-11-14-installer-hardening-design.md` 與 S1 文件同步清單都沒有這一項。
證據：全域 CLAUDE.md §4.4 原文（system-reminder 內）：「開表的同時，在專案根目錄 CLAUDE.md 第一個 `##` 之前加一段指路 …… 少了這句，下一個 session 走 §4.1 那條判斷會看不到這張表」。`grep -n '進度以' CLAUDE.md` 無輸出。計畫「文件同步」清單（S1 節）列了 `tests/CLAUDE.md`、根目錄 CLAUDE.md「只補這次留下的坑」，沒有指路。

輪1-R3-2｜一般｜計畫的兩個段落（S1、S2）都沒排 §3.9 的步驟 3（code-simplifier）、步驟 4（code-review，每段至少 3 個審查者、報告落地成 committed 檔）、步驟 7、步驟 8，也沒寫段落起點（`check-claude-md.sh --start-segment`）。驗收只寫「步驟 5 要看到什麼」。
證據：`docs/reviews/` 存在（`ls docs/reviews` 有 `S6-a.md`、`S6-b.md`），表示 pre-commit gate 的 opt-in 報告檢查已啟用；`tests/CLAUDE.md` 也描述 gate 會擋沒有報告的段落。這一條會被 gate 大聲擋下，所以歸為一般，不是重大。全域 §3.9 的「段落開始前先記起點」也沒有出現在計畫中。

輪1-R3-3｜一般｜S1 的紅與綠只在 macOS 本機驗，ubuntu CI 上的 GNU 行為沒有被計畫要求驗證。`test-install.sh` 只能在 macOS 或 ubuntu 跑；計畫 F5 的 debian 容器裡沒有 node、jq、python3，所以 T2–T9 在 GNU 上跑不起來。計畫的 T1「修之前在 CI ubuntu 上會紅」這個說法沒有被驗證，只靠 docker 手動做的 cp 重現。S1 驗收寫「本機 ci.yml 20 個 step 全過」，但那 20 個 step 是 `lint` job（ubuntu-latest），macOS job（564 行起）的步驟並沒有一一列在計畫中。
證據：`.github/workflows/ci.yml` 第 12 行 `runs-on: ubuntu-latest`，第 564 行 `runs-on: macos-latest`；事實 F14、F15 說 ubuntu job 有 34 個 commit 沒跑過。計畫 S1 驗收沒有要求「推上去看 ubuntu job 綠」或在 GNU 環境跑 test-install。

輪1-R3-4｜一般｜S1-3 的變異測試只寫「把安裝腳本對應的那一行改壞」，沒有指定每組 T3–T7 要改哪一行。`tests/CLAUDE.md` 的「此層約束」明寫：變異改錯地方（例如把整個功能的 gate 改成永遠 return 1）會得到「新情境在測功能」的紅，不能證明斷言有鑑別力，而且有的斷言會變成恆真。計畫沒有要求每組附「哪個變異 → 哪幾個情境變紅」的對照表，所以 T3–T7 有可能全部是空殼而沒人發現。
證據：`tests/CLAUDE.md` 「此層約束」中「⚠️⚠️ 變異測試要選對『變異方向』」與「一個『恆真』的斷言比沒有斷言更糟」兩段。計畫 S1-3「驗證」段只寫「改成每一組各做一次變異…確認那一組變紅、而且紅在斷言而不是載入失敗」。

輪1-R3-5｜一般｜T1 只覆蓋「檔案 symlink」，但 `backup_before_overwrite` 的呼叫點裡 skills（528–530 行）與命名空間指令目錄（957–959 行）會對目錄做 `rm -rf` 再 `cp -r`。計畫的 S1-1 修法是 `[ -L "$target" ]` 時用 `cp -RL`，這一支對目錄 symlink 也會生效，但計畫沒有任何測試覆蓋目錄 symlink 的情境。
證據：`install-dd-pipeline.sh` 第 528–530 行（`backup_before_overwrite "skills"`、`rm -rf`、`cp -r`）與 957–959 行；計畫 S1-1 與 T1 都只寫「`~/.claude/CLAUDE.md` 是指向另一個檔的 symlink」。

【需要外部查證】
輪1-R3-6｜一般｜S1-2 寫「`jq_inplace` 開頭加 `jq -e 'type == "object"'`，空輸入時 jq -e 回 4」。這個退出碼我沒有實跑驗證（任務規定不能跑 jq）。需要在要用的 jq 版本上實跑一次確認：空檔案、只有空白、`null` 各回什麼退出碼，這些結果會直接決定 S1-2 的「兩條路徑結論一致」能不能成立。
為什麼需要：這是計畫判定分支的核心依據，錯了 T2 的代表案例會寫錯預期值。

輪1-R3-7｜一般｜S1 驗收要求 CI ubuntu job 的 `tests/test-install.sh` 全過，但 ubuntu-latest runner 預載的 jq 與 python3 版本我沒有查證。T2 同時依賴兩條路徑存在，若 runner 的 jq 版本與本機不同，「兩條路徑結論一致」的斷言可能在 CI 上行為不同。
為什麼需要：需要到 GitHub runner 的映像清單或實際 CI log 確認 jq、python3 的版本。
