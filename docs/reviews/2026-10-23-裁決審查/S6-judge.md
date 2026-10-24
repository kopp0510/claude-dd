# S6-judge — 步驟 4 改成 A（主對話的查證）

第一次照新步驟 4 跑：沒有裁決者，主對話自己派審查者、自己查證。

## 派工

- 派 3 個 `code-reviewer`（下限 3），同一則訊息平行派出，派完主對話自己讀 diff 檔第 1–361 行。
  數量理由：這段只有規則文字與兩行 echo，分三個方向就涵蓋了改動的三類檔 —— a 模板與蓋章版、b 跨檔一致與殘留（gate、`docs/reviews/CLAUDE.md`、兩份 README、全 repo 掃描）、c rev 跳號、CHANGELOG、設計文件
- diff 檔：`<scratchpad>/S6-review-diff.txt`（4517 行）。① 第 1–323 行 `git diff fb6f816`（含工作目錄，未追蹤新檔 0 個）② 第 324–360 行 步驟 3 code-simplifier 的改動（`git diff HEAD`，2 檔 3 句）③ 第 361 行起 被改到檔案的整檔內容（工作目錄版本，帶行號）④ 第 4511 行起 已跑過的驗證與預期值
- 三份報告回來後都從 subagent 紀錄檔的交回訊息逐字取出，存進 `<scratchpad>/S6-review/a.md`、`b.md`、`c.md`；派工 prompt 同樣取出存成 `prompt-*.txt`

## 發現

**讀檔檢查**：三份都引用了 diff 檔行號與 repo 檔案行，抽查各一處 —— a 的「模板 :291 對 :296」、c 的「`git show v1.6.5:commands/dd-init.md` 是 rev 9」、b 的「dd-init.md:46 兩句」，自己讀過都對得上。

**採納**（全部 Important，沒有調級）：

1. a-1＝c-2｜同一節對「審查者缺報告、補不了」給了兩種結局（:291 照實寫後續行、:296 不續行）。查證：`sed -n 288,300p templates/global/CLAUDE.md` 兩句都在；舊版「不續行」是對裁決者講的（diff 檔第 278 行）
2. a-2＝c-3｜S6 驗收「只剩 `-judge.md` 檔名」照字面不成立，刻意加的「為什麼不另派裁決者」會命中；英文 README 用 `adjudicator`，grep `judge` 永遠 0 筆。查證：`git grep -n -i -E '裁決|judge|adjudicat'` 命中模板 :298–301、dd-init :86、README.zh-TW :130、README.md :125
3. a-3｜蓋章版少了費用（US$5.13 對 3.83）與「預設這條可能是錯的」。查證：diff 檔第 113–114 行對模板第 293、298 行
4. a-4｜舊規則要裁決者連派工 prompt 一起交回，新規則只存審查者報告，`-a/-b/-c.md` 的「派工」節沒有來源。查證：diff 檔第 110、277 行對新版模板 §3.9
5. b-1＝c-1｜dd-init:46 差異串的 rev 5、rev 9 仍把裁決者寫成現行；v1.6.5 發布的是 rev 9，會走升級的正是這些專案。查證：`sed -n 46p commands/dd-init.md`、`git show v1.6.5:commands/dd-init.md | grep -n dd-loop-rev`
6. b-2｜兩份 README 把「另派裁決者比較慢、沒有多抓到錯」寫成定論、沒提費用；模板與 CHANGELOG 都寫了「三件事分不開、只是方向」。查證：diff 檔第 43、56 行對第 290 行與第 16 行

**駁回**：無。

**需使用者決定**：無。採納 1 的統一寫法（補不了照實寫、完整報告少於 3 份才不續行）沿用既有的「最少 3 個」下限，不是新的語意選擇。

**需要外部查證**：無。

## 處置

- 6 條都改了，見各審查者那份的「處置」。改完重跑：CI 三個 step 本機照跑 exit 0、`bash tests/test-gate.sh` exit 0、shellcheck 通過、模板 §3.9 編號項 8、`同時打兩發` 1；`git grep -n -i -E '裁決|judge|adjudicat'` 在模板、蓋章版、兩份 README 只剩白名單（理由句、歷史句、`-judge.md` 檔名、plan-review 列）

## 重疊與獨有項

- **重疊**：a-1＝c-2（補不了的矛盾）、a-2＝c-3（驗收照字面不成立）、b-1＝c-1（dd-init 差異串過期）—— 三組各被兩個人獨立抓到
- **獨有**：a-3（蓋章版少費用與自我查證那句）、a-4（派工 prompt 沒人保存）、b-2（README 講成定論）、c-3 裡的「英文 README 用 adjudicator、grep judge 永遠 0 筆」
- 三個獨有項都是「拿掉裁決者後，原本由它承擔或由它附帶的東西」—— 單發 reviewer 只順著自己的方向看，看不到另一個方向那一格
