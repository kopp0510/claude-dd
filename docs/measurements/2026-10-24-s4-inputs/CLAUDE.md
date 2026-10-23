# docs/measurements/2026-10-24-s4-inputs

裁決審查 S4（`docs/designs/2026-10-23-裁決審查-design.md`）量測用的**凍結實驗輸入**：三組（新做法、haiku 對照、舊做法）
拿到的 prompt、共用的段落內容、產生快照與統計的腳本。結果寫在上一層的 `2026-10-23-reviewer-real-sessions.md`「新做法對照」一節。

## 檔案

- `briefs.txt` —— 每段（G2、G3、G4）的範圍與已跑過的驗證；三組逐字共用，**不帶**舊報告派工節的「重點／點名」提示
- `judge.txt` —— 新做法與 haiku 組的裁決者說明（照部署版全域 §3.9 步驟 4，拿掉「審查者報告逐字寫進 scratchpad 檔」那句，因為允許的工具沒有 Write）；`{REVIEWER}` 決定審查者帶不帶 `model: "haiku"`
- `old-reviewer.txt` —— 舊做法給 `code-reviewer` 的說明（舊報告實際的派工寫法：`git show HEAD:`、最多一次重現實驗）
- `parent.txt` —— headless 父 session 的派工指示（`new` 給新做法與 haiku 組、`old` 給舊做法）
- `prepare.py` —— 每一發建一份快照 repo（`git init`、只有 base 與 change 兩個 commit，拿掉 `docs/reviews/` 底下除了 `CLAUDE.md` 的報告），產生 diff 檔與 prompt 檔
- `run.sh` —— 在快照裡跑一發 `claude -p`，stdout 存 `<s4>/logs/<發代號>.jsonl`
- `stats.py` —— 讀父 log 的全部 `result` 與 `~/.claude/projects/<快照路徑編碼>/` 的子代理紀錄，算耗時、工具次數、模型、費用，並列作廢理由（denials、中止、層數、模型、洩題）
- `test_leaky.py` —— `stats.py` 洩題判定 `leaky()` 的負面測試（該抓的、實跑出現過的誤報各幾則）；改 `leaky()` 後跑 `python3 -I test_leaky.py`，全過 exit 0
- 結果（每發一列的 `stats.jsonl`、每個 agent 最後一則文字）在旁邊的 `2026-10-24-s4-outputs/`

## 約束

- **凍結**：量測文件的數字是用這一版輸入跑出來的；要改實驗就另開新目錄，不要改這裡。唯一的例外：實跑期間 `stats.py` 的 `leaky()` 為了消誤報改過三次（不影響耗時、費用、工具次數，只影響作廢判定），經過記在量測文件「原始數字」底下
- 發代號是 `<段>-<組>-<序>`（例如 `G3-hk-2`），`prepare.py` 與 `stats.py` 都靠它切出段與組
- `stats.py` 只讀各發快照自己的 projects 目錄，不掃整個 `~/.claude/projects`（不會碰到公司專案的紀錄）
