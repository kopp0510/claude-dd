# S1-a — 審查者 A（dd-loop-rev 跳號檢查）

## 派工

> 你是 code-reviewer，代號 A。審查範圍：git diff 2bd0014 848ea70（claude-dd repo，/Users/danlio/project/my_project/claude-dd）。新增一個 CI step：改了 commands/dd-init.md 的蓋章區塊卻沒跳 dd-loop-rev 就紅燈；同批把根 CLAUDE.md 那段說明縮短、補 DD_PIPELINE_ARCHITECTURE.md CI 防線表與 CHANGELOG、開進度表。
> 
> 材料：/private/tmp/claude-501/-Users-danlio-project-my-project-claude-dd/4056f6e9-426e-4bea-be36-fac245081ed4/scratchpad/rb-diff.txt。用 Read 的 offset/limit 每次 300 行讀到最後一行（一次讀太多會靜靜截斷）。被改到的檔用 git show 848ea70:<路徑> 讀（工作目錄可能正被別人改），沒改到的檔讀 repo。材料 ④ 的驗證已確認，不要重跑。
> 
> 你的方向：新 CI step 的 bash 邏輯：抓不到 tag／區塊／rev 時會不會誤綠；比對前把 rev 換成 N 的做法有沒有漏洞（例如區塊裡別處也寫了 dd-loop-rev）；GitHub Actions 跑 run 時用的 shell 與 set -e 行為下，有沒有指令回非 0 讓 step 提早中止且不印訊息；awk 抓圍欄的條件在 ```markdown 前後有空白、CRLF、區塊裡又有 ``` 時會怎樣；這個 step 在 ci.yml 哪個 job、macOS job 有沒有跑；與 ci.yml 既有慣例（例如 CHANGELOG step 取 tag 的方式、quotePath）一致嗎
> 
> 職責：找漏洞，每條附證據（路徑:行號、原文、或指令與輸出），沒證據不算。只用手上的資料判斷；需要外部查證的列出來交回。不要改檔、不要 commit。
> 
> 輸出格式：第一行「Critical N / Important N / Smells N」；## Findings（每條 [級別] 路徑:行｜一句話；證據；失敗情境）；## Not reported（看到但不報的與理由）；## What I ran；## 需要外部查證。

## 發現

Critical 0 / Important 3 / Smells 0 — 範圍：git diff 2bd0014 848ea70（ci.yml 新 step、根 CLAUDE.md、DD_PIPELINE_ARCHITECTURE.md、CHANGELOG、設計文件）

## Findings

[Important] .github/workflows/ci.yml:383-384（848ea70）｜跟最新 tag 比，同一個發版週期裡蓋章區塊第二次改動就算沒跳號也會過。根 CLAUDE.md 新寫的「同一次發版改好幾次區塊，只要跳一次號」把舊規則放寬了。
- 證據：判定式是 `elif [ "$new_rev" -gt "$old_rev" ]` → ✅，old_rev 取自最新 tag。可是安裝讀的是 main 的工作目錄，不是 tag：根 CLAUDE.md「開發本 repo」寫「驗證完 commit 後再重跑，其他專案才會用到新版」。前例：v1.6.5 是 rev 9，到 v1.6.6 之間跳了兩次（1299d45 跳到 rev 10、0233de6 跳到 rev 11）。也就是說，以往的做法是每改一次就跳一次。
- 失敗情境：main 上 rev 先從 12 跳到 13，跑 `--force` 安裝後專案 X 蓋章成 rev 13。之後再改一次區塊、沒跳號，CI 仍是綠的（13 > tag 的 12）。專案 X 跑 `/dd-init` 會被告知「已是現行版」，拿不到第二次修正。這正是這道檢查要擋的情境。

[Important] ci.yml:383-388｜`old_rev=$(rev_of …)` 在 `bash -e` 底下，grep 零命中時整個 step 會直接中止，一個字都不印。`[ -z "$old_rev" ]` 那段護欄和它的訊息永遠跑不到。
- 證據：這個 step 沒設 `shell:`，GitHub Actions 預設用 `bash -e {0}`（通用知識，不確定，建議驗證）。我在 scratchpad 實跑 `bash -e -c 'rev_of(){ grep -E "^<!-- dd-loop-version: " "$1" | head -1 | grep -oE … | grep -oE "[0-9]+"; }; old_rev=$(rev_of nomark.md); echo reached'`，結果是 exit=1，「reached」沒有印出來。根 CLAUDE.md「set -e」那條點名的就是 `n=$(grep …)` 這個形狀。
- 失敗情境：標記格式改了（例如全形分號換掉），step 紅燈，但 log 裡沒有任何 ❌ 訊息，看不出原因。結果還是紅燈、不會誤綠，但註解宣稱的「抓不到就印原因」不成立。④ 的 7 種變異都沒有走到這條路徑。修法：rev_of 結尾加 `|| true`。

[Important] CLAUDE.md（848ea70，新段落最後一句「③、④ CI 不驗」）｜④ 的「`UPGRADING.md` 寫死的 rev 值」其實就是 ② 那條判定線，CI 有驗，這句是錯的。
- 證據：`git show 848ea70:UPGRADING.md | grep -n rev` 只命中一行，82 行「…但 rev 比 12 舊的，會被判定為舊版…」。四方一致 step（ci.yml 的 `for spec in … "UPGRADING.md:判定為舊版"`）會比對這一行的 rev 等不等於 cur_rev。
- 失敗情境：照新文字讀的人以為 UPGRADING 的 rev 要自己記得改、CI 不擋，或者反過來把 ② 和 ④ 當成兩處去找。舊文也把它列了兩次，但「CI 不驗」這個宣稱是這次 diff 新寫的。

## Not reported
- 圍欄邊界情境，都讀過了，都是寧可紅燈、不會誤綠：`^```markdown$` 前後有空白或 CRLF 時兩邊抓到空的，非空護欄會擋下。區塊裡的巢狀圍欄（117、120、198、209、215、220 行）都有縮排，`^```$` 不會提早收尾。沒有收尾圍欄時 awk 會一路印到檔尾，結果偏紅不偏綠。
- sed 把 rev 換成 N 的範圍：848ea70 的區塊裡只有 54 行一處 `dd-loop-rev`，沒有別的號碼被一起換掉。
- 這個 step 只在 lint job（ubuntu）跑，macOS job 沒跑。這跟其他讀文件的 step 一致，④ 也已經用 /bin/bash 3.2 本機跑過，不算缺陷。
- 取 tag 的方式（`--sort=-v:refname | head -1`）、找不到 tag 時的訊息、fetch-depth: 0，都跟 CHANGELOG step 一致。這個 step 沒有列檔案的 git 指令，不需要 quotePath。
- `/tmp` 的檔名沒有跟其他 step 撞名。

## What I ran
- `wc -l rb-diff.txt; git diff 2bd0014 848ea70 --stat` → 211 行；5 個檔
- Read rb-diff.txt 1-300 → 全部讀完（211 行）
- `git show 848ea70:.github/workflows/ci.yml` + grep job/name/fetch-depth/shell → 新 step 在 357 行、lint job（ubuntu），沒有 `shell:`，fetch-depth: 0
- `git show 848ea70:commands/dd-init.md | grep -n '^ *```\|dd-loop'` → 蓋章區塊 52–149 行，巢狀圍欄都有縮排，rev 在 39 行（區塊外）和 54 行
- `git show v1.6.11:commands/dd-init.md` 同樣的 grep → 結構相同，rev 12
- `sed -n 302,356p ci.yml`（四方一致 step）→ 有比對 UPGRADING.md「判定為舊版」那行的 rev
- `git show 848ea70:UPGRADING.md | grep -n rev` → 只有 82 行
- `git log -G'dd-loop-rev: [0-9]+；' -- commands/dd-init.md` 加上逐 commit 取 rev → v1.6.5 是 9，1299d45 是 10，0233de6 是 11，v1.6.6 是 11
- scratchpad 實跑 `bash -e` 的 rev_of 零命中 → exit=1，沒有印出任何字

## 需要外部查證
- 沒設 `shell:` 時 GitHub Actions 的預設是不是 `bash -e {0}`（沒有 pipefail）→ 查 GitHub 文件 "jobs.<job_id>.steps[*].shell"，可以確認第 2 條在 CI 上的實際行為。
- 這個 repo 實際上有沒有專案在兩個 tag 之間從 main 蓋章（例如 lawdesk-ai 的 CLAUDE.md 標記 rev 是不是不等於任何 tag 的 rev）→ 可以確認第 1 條情境的實際影響。

## 處置

見 `S1-judge.md` 的「處置」。
