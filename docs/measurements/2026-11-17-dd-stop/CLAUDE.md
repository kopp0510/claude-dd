# docs/measurements/2026-11-17-dd-stop

`/dd-stop`（暫停與恢復 8 步迴圈的指令）的實測。設計、使用者的決定與進度表在 `docs/designs/2026-11-17-dd-stop-design.md`。

## 檔案

- `probe-local.sh` —— 開工前提 P1：專案根目錄的 `CLAUDE.local.md` 會不會被全新的 session 載入。兩臂只差有沒有這個檔，各 1 發、haiku，每發上限 1 美元。
  有檔那一臂照 `dd-stop.sh on` 的做法把它列進 `.git/info/exclude`。判定寫在檔頭、跑之前就定好：有檔的回覆第一行是 `ZEBRA-7`、沒有檔的整則沒有 `ZEBRA-7`
- `out/probe-local.prompt.txt` —— 兩臂共用的 prompt 原文
- `out/probe-local-with.jsonl`、`out/probe-local-without.jsonl` —— 每臂一行精簡過的 result（`num_turns`、`total_cost_usd`、`models`、`permission_denials`、`result`）。原始 stream-json 沒有留
- `run-model.sh` —— 模型層實測（設計文件 S1-4 的 ②）：暫停聲明能不能讓全新的 session 停下步驟 3–8、沒暫停時迴圈有沒有照跑、`dd-stop.sh off` 之後有沒有恢復。
  三臂（`stopped`／`control`／`resume`）各 2 發、`claude-fable-5-2`；拋棄式專案、prompt、旗標、花費上限都寫在檔頭與檔內。
  `probe`（權限探針）與 `smoke`（haiku 跑一遍流程）不算進判定，輸出留在工作目錄、不進 repo
- `check-model.sh` —— 上面那支的判定。判準寫在檔頭：每一發是通過／沒通過（模型的行為不符）／無效（實驗沒跑成：權限被擋、叫了 advisor、超時、暫停臂沒跑到自己結束、恢復臂沒跑成 `off`）；
  每一臂兩發都通過才算通過。第二個參數給補跑那一批的目錄時，只有第一批判成無效的那幾發改看補跑的
- `selftest-model.sh` —— `check-model.sh` 的自測：手造一組該全過的輸出，再一次改壞一處（每一種沒通過與無效各一則，另有補跑與缺檔），確認結果與理由對得上。不呼叫 claude
- `out/model-<批次>/` —— 正式那一批的輸出（跑了才有）：每發一個 `<臂>-<n>.json`（最上層的工具呼叫、那幾次 Bash 的輸出前 1500 字、result 的幾個欄位、結束時專案的狀態；
  家目錄與工作目錄換成 `<home>`、`<work>`），兩份 prompt 原文、`repo-head.txt`、`claude-version.txt`、`check.out`

## 結果

- P1（2026-11-17，Claude Code 2.1.326）：成立。有檔那一臂回 `ZEBRA-7` 加一句答案，對照只有答案；兩發 `permission_denials` 都是 0、`models` 只有 haiku
- 它只證明「檔會載入、模型照著多寫了一行」。暫停聲明壓不壓得過專案 CLAUDE.md 與全域 §3.9 的迴圈是另一件事，P1 沒有測
- 模型層第 1 批（2026-11-17，Claude Code 2.1.326，`claude-fable-5-2`，判準是 `7efdfa7` 那一版的 `check-model.sh`）：三臂都通過，`out/model-1/check.out` 是判定原文。
  - `stopped` 兩發：各 1 個新 commit、Bash 輸出有「gate 暫停中」、沒有 `Skill dd-loop`、沒有 `--start-segment`、沒有派 agent，結束時旗標與標記段都還在；
    6 與 10 個回合、1.06 與 1.13 美元、`models` 只有 `claude-fable-5-2`、`permission_denials` 0
  - `control` 兩發：第一個工具呼叫就是 `Skill dd-loop`（第 2 發接著發出了 `--start-segment` 的指令；那次 Bash 的輸出是空的、結束時沒有起點檔，指令還沒跑完那一發就被停掉了）
  - `resume` 兩發：先跑 `.git/dd/dd-stop.sh off`（輸出有「8 步迴圈已恢復」），下一個工具呼叫是 `Skill dd-loop`
- 這一批證明不了的：
  - 每臂只有 2 發、一個專案（單檔 Python CLI）、一段 prompt、一個模型
  - `control`、`resume` 一出現判定要的工具呼叫就被停掉：只看得到「迴圈開始跑了」，看不到它把 8 步跑完；被停掉的那四發沒有 result，
    所以它們的費用、`permission_denials`、`modelUsage` 都沒有值（advisor 有沒有被關掉，只有 `stopped` 兩發的 `models` 佐證；六發用的是同一組旗標）
  - 受測的是全新的 session。已經開著的對話、跑很久被壓縮過的對話會不會照聲明做，沒有測
  - 全域 CLAUDE.md §3.9 與 dd-loop skill 是這台機器當時部署的那一版，不是 repo 這份（`skills/dd-loop/SKILL.md` 新加的「迴圈暫停中」那一句不在裡面）
  - `stopped` 只看工具呼叫與結束時的狀態，沒有看回覆的文字有沒有告訴使用者「這次沒跑步驟 3–8」
  - 受測的 `dd-stop.sh` 與 gate 是 `7efdfa7` 那一版（`out/model-1/repo-head.txt`）。之後 `dd-stop.sh` 改過兩次（步驟 3 的簡化；步驟 4 修的寫檔失敗那幾處，`on` 改成最後才設旗標），模型層沒有重跑
  - 設計文件寫的骨架「每一發的 `permission_denials` 都是 0」只查得到 `stopped` 兩發：另外四發被停掉、沒有 result，`check-model.sh` 對它們沒有查這一項就判通過
- 判準已知的洞（2026-11-17 步驟 4 的審查找到；審查原文在 `docs/reviews/2026-11-17-dd-stop/S1-d.md`，查證在同一個目錄的 `S1-judge.md`）。
  下面前五條與「 -n 」、`.json` 壞掉那兩項，查證時各手造一份 `.json` 餵 `check-model.sh` 重現過；其餘是讀 `run-model.sh`、`selftest-model.sh` 對出來的，沒有另外跑。
  `check-model.sh` 沒有跟著改（`git diff 7efdfa7 -- check-model.sh` 是空的）：改了就是改判準，第 1 批不算新判準的。**要跑第 2 批，先補這幾條、補自測、commit，再跑**。
  第 1 批對得出來的：前三條沒有踩到（`stopped` 兩發 `permission_denials` 0、沒有用到補跑；「gate 暫停中」都出自 `git commit` 那一次的輸出、結束時起點檔在；`control`、`resume` 四發都是靠 `Skill dd-loop` 通過，不是靠 Bash 那一半）。
  對不出來的：第四條在 `stopped-2`（那兩次 Read、三次 Edit 的對象沒有留）；第五條在被停掉的四發（沒有 result）：
  - 「無效」排在各臂的行為判準之前，而無效的那一發改看補跑：暫停臂真的跑了迴圈、同一發又有一次權限被擋（例如試 `--no-verify` 被 gate-guard 擋下）時，先判成無效，補跑通過就整臂通過
  - 「經過暫停中的 gate」只看有沒有任何一次 Bash 的輸出含「gate 暫停中」，不管是不是 commit 印的：暫停聲明本身就有這幾個字，`cat CLAUDE.local.md` 加一個繞過 hook 的 commit 也會過。
    `final.base_file` 有記、判定沒有用它
  - 「迴圈呼叫」的 Bash 那一半是子字串比對：`grep -- --start-segment CLAUDE.md` 也算（蓋章區塊裡就有這串字）。`run-model.sh` 的 `criterion_met` 用同一個定義，會當場停掉那一發
  - 暫停臂只認點名的幾個入口（`Skill dd-loop`、`--start-segment`、派 `code-simplifier`／`code-reviewer`、兩個 claude-md skill）。別的入口都不算違規：用 Read 讀 `dd-loop` 的 `SKILL.md`、
    派 `general-purpose` 去審查、內建的 `simplify`、跑 `--segment-base`、用變數拼出 `--start-segment`、子 agent 自己發出的呼叫。`reduce` 沒有留 Read／Edit 的參數：`stopped-2` 有兩次 Read、三次 Edit，資料看不出讀寫了哪個檔
    （`stopped-1` 全是 Bash、指令都留著；兩發最上層都沒有 Agent 或 Skill 呼叫）
  - 「叫了 advisor → 無效」只看最上層有沒有名字是 `advisor` 的工具呼叫，沒有讀 `result.models`；`docs/measurements/CLAUDE.md`「已知的坑」寫的是 advisor 只出現在 result 的 `modelUsage`。
    實際的 stream-json 裡它長什麼樣沒有查
  - 會誤判成沒通過或無效的（不會漏放）：commit 訊息內文有「 -n 」；判定要的那串字落在 Bash 輸出的 1500 字之後
  - `selftest-model.sh` 沒有測到上面前兩種，也沒有測 `Task` 這個工具名、`Skill code-review`、`dd-stop.sh on`、`revise-claude-md`、不認得的臂；`.json` 壞掉時 `check-model.sh` 以 jq 的 exit 碼結束，不在檔頭寫的 0／1／2 裡
  - `run-model.sh` 的去識別把路徑與帳號當正規式用（路徑有 `+`、`(`、`.` 時可能換錯）、`final.subjects` 沒有經過替換；第 1 批的 `out/` 用 `grep -rl` 查過帳號名稱、`/Users/`、`/Volumes/`、`/private/tmp`、編碼過的專案路徑 都是 0 個檔
- 第 1 批的六個 `.json` 跑完之後補做了一次替換：`ls -la` 的輸出帶著系統帳號名稱，換成 `<user>`（`run-model.sh` 的 `reduce` 當時還沒有這個替換，之後補上了）。
  換完重跑 `check-model.sh`，輸出與 `check.out` 逐位元組相同

## 跑之前

- 先 Read `docs/measurements/CLAUDE.md` 整份（「已知的坑」每一條）
- `probe-local.sh` 的參數是拋棄式工作目錄，要放在 repo 與家目錄的 CLAUDE.md 鏈之外（scratchpad）；目錄已存在而不是它自己建的（沒有 `.dd-stop-probe-work`）就拒跑，因為每發之前會整個刪掉它
- 重跑 `probe-local.sh` 會蓋掉 `out/` 的那三個檔。它們是設計文件引用的證據，要重跑就先把舊的另存
- `run-model.sh` 的工作目錄同樣放 scratchpad、要給絕對路徑；不是它自己建的（沒有 `.dd-stop-model-work`）就拒跑。`out/model-<批次>/` 已經存在也拒跑，要再跑就換批次編號
- 受測 session 載入的是這台機器部署的 `~/.claude/`（全域 CLAUDE.md §3.9、dd-loop skill、它照 §3.9 跑的 `~/.claude/scripts/check-claude-md.sh`），不是 repo 這份；
  repo 版的 `dd-stop.sh` 與 gate 由 `run-model.sh` 複製到拋棄式專案的 `.git/dd/`，pre-commit 與恢復臂的 `off` 用的是那一份。
  所以這個實測量的是「暫停聲明 + repo 版 gate」配「部署版的全域規則」；`commands/dd-stop.md` 不在裡面（它由乾跑的 subagent 另外驗）
- 正式一批最壞 22 美元（暫停臂每發上限 5、另兩臂每發 3；另兩臂一看到判定要的工具呼叫就停掉那一發，實際會低很多）。判準改了字，之前那一批就不算它的
- 改了 `check-model.sh` 先跑 `selftest-model.sh`
