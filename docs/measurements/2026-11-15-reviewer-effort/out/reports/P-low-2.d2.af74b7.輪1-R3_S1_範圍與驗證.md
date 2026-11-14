【我查了什麼】

- 讀 `install-dd-pipeline.sh`：`backup_before_overwrite` 187–196（`[ -e "$target" ] || return 0`，然後 `cp -r`）；`jq_inplace` 209–220、`py_inplace` 228–243、`json_edit` 245 起；`validate_skill_hooks` 463–496；`command_exists` 156；`SCRIPT_DIR` 26；`PLUGINS_MARKETPLACE` 120；`install_plugins` 的「Plugin 檔案不存在」788；`mcp_scope` 的「僅 N 個專案設定」「無法判定」683–685；`create_commands` 的 `deprecated_dd` 889–896；`show_completion` 1241 起。
- `cp "$source" "$target"` 與 `backup_before_overwrite` 的全部呼叫點：523–530、599–605、916–922、946–959、1001–1007、1041–1047、1171–1228。global 的三處（1194、1216、1227）都走同一個函式，所以 S1-1 只改函式內就能覆蓋。
- 讀 `tests/test-install.sh` 全檔（87 行）：沙盒與 `[ ! -d backups ]` 斷言在 50、55 行；沒有任何 symlink、`settings.json`、`.claude.json` 相關的測試。
- 讀 `.github/workflows/ci.yml`：`lint`（ubuntu-latest）與 `bash32`（macos-latest，`/bin/bash` 3.2）兩個 job 都會跑 `tests/test-install.sh`（594 行）；ci.yml 沒有安裝 jq 或 python3 的 step。
- 讀 `CLAUDE.md` 的「新增 … 步驟」「同批」「同步」段，以及 `scripts/CLAUDE.md`、`tests/CLAUDE.md` 的同類字樣（grep 指令：`grep -rn '新增\|同時改\|同批\|要一起\|手動同步' CLAUDE.md scripts/CLAUDE.md tests/CLAUDE.md`）。計畫沒有動的 `commands/dd-init.md` 蓋章區塊不在 S1 範圍內，不算漏做。
- 計畫的前提大多成立：symlink 備份的 `cp -r`、`deprecated_dd` 直接 `rm`、`show_completion` 無條件印兩段、`SCRIPT_DIR` 與 `validate_skill_hooks` 的 exit 1 都對得上。

【批評】

輪1-R3-1｜小事｜S1-1 的理由寫錯。計畫說「不對所有情況都加 `-L`：GNU `cp -RL` 遇到懸空連結回 1，腳本有 `set -e`」。但懸空連結在 `[ -e "$target" ] || return 0`（install-dd-pipeline.sh:189）就已經 return 0，根本進不到 `cp`。所以「不全加 -L」的真正理由是別的（例如非 symlink 的目錄不需要解參照），計畫寫的理由會誤導後人。證據：install-dd-pipeline.sh:187–196。

輪1-R3-2｜小事｜S1-1 修好之後，全域 `CLAUDE.md` 若是指向 dotfiles 的 symlink，安裝仍會把 `cp "$source" "$target"`（1195、1217、1228）寫進連結指到的那個檔，也就是專案之外的檔案。計畫只修了備份，沒寫這件事，也沒寫它是否要依 §4.2「修改目前專案以外的檔案」先問。備份修好後這個寫入是可以救回來的，所以不算無聲錯誤。證據：install-dd-pipeline.sh:1194–1195、1216–1217、1227–1228。

輪1-R3-3｜小事｜S1-2 把 `jq_inplace` 開頭加 `jq -e 'type == "object"'` 的檢查，但 `jq_inplace` 是通用函式，呼叫時帶 `--arg` 等參數，計畫沒說這個檢查怎麼同時吃那些參數、要不要讀同一個檔兩次。這是實作細節，做的時候一定會撞到，會報錯，不算重大。證據：install-dd-pipeline.sh:209–220。

輪1-R3-4｜小事｜S1 的四個小任務有四個 commit，其中 S1-2 會改使用者的 `settings.json`（可能放 token）與 `installed_plugins.json` 的讀寫路徑，S1-4 會刪使用者的舊指令檔。它們跟只改 `tests/` 的 S1-3 放在同一段，用同一輪 code-review 審。這不是 §4.1 點名的高風險類別（帳款、權限規則、批次刪除），所以不算違規。但 S1-2 與 S1-4 都碰使用者資料，段落內的審查範圍偏寬。證據：計畫 S1-2、S1-4 的檔案清單；CLAUDE.md §4.1 高風險清單。

【需要外部查證】

輪1-R3-5｜小事｜S1-2 寫「jq_inplace 開頭加 `jq -e 'type == "object"'` 的檢查（空輸入時 jq -e 回 4）」。這個退出碼是計畫的前提，我沒有驗證。在 jq 的實際版本（macOS 的 jq 與 ubuntu-latest 預裝的 jq）上，空輸入經 `-e` 是否真的回 4，要實跑確認。為什麼需要外部查證：我的權限不允許跑 jq。

輪1-R3-6｜小事｜S1-1 的「修之前紅、修之後綠」在 GNU 上取得，計畫用 `debian:bullseye` 的 GNU coreutils 8.32（F5 已有實跑結果）。但 ubuntu-latest 的 coreutils 版本可能不同，`cp -r` 對 symlink 的行為是否一致，計畫沒有在 ubuntu-latest 上驗。為什麼需要外部查證：需要真的 CI 或該映像檔實跑。

【結論】

以三條標準（常走、照做會錯、後面關卡抓不到）來看，我沒有找到符合三條的重大缺失。主要的問題是 S1-1 的理由寫錯、symlink 寫入會穿透到專案外的檔案而計畫沒寫、以及 jq 退出碼的前提沒驗證。
