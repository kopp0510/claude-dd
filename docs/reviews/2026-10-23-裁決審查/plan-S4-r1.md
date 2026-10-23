# S4 計畫審查 第 1 輪（plan-review）

檔名不用 `S` 開頭的理由同 `plan-S2-r2.md`。

## 派工

- 派工單：scratchpad 的 `judge_S4_r1.txt`（由 `judge_S3_r1.txt` 改出：審查範圍換成 S4 一段、計畫 = S4 一節＋設計決策表＋開放問題＋進度表 S4 列、事實換成 S4 的素材與已讀檔）
- 派工單送出後補了一段：使用者 2026-10-24 決定多量一組「審查者用 haiku」
- 裁決者：`general-purpose`、`model: opus`，背景執行；約 9.2 分鐘（`duration_ms` 553994）、10 次工具；4 個 haiku 審查者（前提、量測方法、同步點與收尾、實驗公平性與洩題）

## 發現（裁決者報告重點）

**結論：`不通過（3 條重大）`**；需使用者決定：無

- 【採納（重大）】
  1. 輪1-R1-2、輪1-R4-1、輪1-R2-3：快照擋不住洩題。被派出的 agent 預設工作目錄是 claude-dd，`docs/reviews/…`、`git log`（3f474dc 的訊息直接寫出 Critical）都拿得到答案；計畫沒規定工作目錄。要明寫快照路徑、`git -C`，跑完 grep 紀錄檔，命中就作廢重跑
  2. 輪1-R1-1、輪1-R4-2：舊報告的「派工」節帶了「重點／點名」提示（pstack-gaps `S1-a.md` 的「重點：」、review-followups `S4-a.md` 的「兩個空洞斷言…還有沒有第三個」），幾乎就是答案；計畫沒要求三組拿到的內容相同。要三組逐字相同、都不帶提示，存成一個共用檔；表上舊命中是帶提示跑的，不能直接比
  3. 輪1-R2-6 等：用 description 認發會錯配（審查者的 description 由裁決者取，同 session 已見重複）；既有腳本只收 `code-reviewer`、會靜默 `continue`、沒繼承 `-SRE` 排除。要唯一前綴、`parentAgentId` 掛層、斷言發數、找不到就報錯
- 【採納（小事）】8 條：新舊審查者人數不同要分欄（原始聯集／裁決採納）；耗時分層列；G2 當時不是 rev 9，改稱「舊報告實際的派工寫法」；快照 hash 不同；K1–K6 代號在原報告不存在，改引行號；G4 不在 n≥2 驗收內、要定義「讀得完」；命中判準跑前寫死；開放問題收尾回填；費用粗估
- 【駁回】10 條（`git show` 那句是當時實際寫法、IN_PROGRESS／步驟 3–8 已由規則區塊規定、測試清單是整份文件的、驗收本來就不設及格線、G4 名單還原只能靠猜等）
- 【需要外部查證】小事 2 條：巢狀帶 `model: "haiku"` 有沒有生效（建議先試 1 發）；每發實際費用

（完整原文在本 session 的 subagent 紀錄檔。）

## 處置

- 重大 1：改成每一發在自己的快照裡用 `claude -p` 跑（cwd = 快照），快照也拿掉 `docs/reviews/` 的報告 —— 實測 `git ls-tree -r --name-only 8514fb2` 帶著 G2 的答案 `docs/reviews/2026-10-07-review-followups/S4-a.md`、`S4-b.md`（裁決者只查了 b66d8ae，這個是我補查到的）；跑完 grep 工具呼叫的輸入
- 重大 2：每段一個共用檔 `s4/G<n>-brief.txt`，三組逐字相同、不帶提示；舊命中改成「只當參考，不拿來比」
- 重大 3：一發一份快照、一個 `claude -p` → 紀錄檔各自落在自己的 `~/.claude/projects/<快照路徑編碼>/`，不靠 description 認發；腳本只讀這些目錄（不碰公司專案），用 `spawnDepth`／`parentAgentId` 認層，斷言發數，找不到就報錯
- 小事 8 條：全部寫進設計文件 S4 一節
- 外部查證「haiku 有沒有生效」：實測成立。scratchpad `s4probe/` 用 `claude -p` 派 `code-reviewer` 帶 `model: "haiku"`：meta 的 `model` 是 `haiku`，assistant 訊息的 `message.model` 是 `claude-haiku-5-5`，花 US$0.017
- 外部查證「實際費用」：留給實跑
- 送第 2 輪
