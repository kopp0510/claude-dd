# docs/measurements/2026-11-14-dd-init-symlink

`/dd-init` 寫檔前先看目標是不是 symlink（security-audit 收編設計文件的 S1-3）的沙盒實測：
每臂一個拋棄式 repo，派 subagent 照舊／新兩版 `commands/dd-init.md` 做指定的 Phase，用指令核對專案外的檔有沒有被改、有沒有先問。

## 檔案

- `setup.sh <臂> <BASE> <claude-dd 根目錄>` —— 沙盒臂（A AO B C C2 D E F G G2 I）、答「要」的臂（Y Y5 YD）與對照臂（K1 K2 K3）的 fixture；
  專案外的假檔放 `<BASE>/<臂>/outside`，`before.txt`、`links.txt` 給 `check.sh` 比對
- `setup-h.sh <臂> <BASE>` —— docker 臂（H1 pre-commit、H2 husky 8、H3 husky 9）與對照臂（H1K H2K H3K）；
  先 `docker build -t dd-symlink-arms:1 .`（`Dockerfile`）。容器名 `dd-<BASE 的 basename>-<臂小寫>`，留著給 subagent 與 `check.sh` 用，用完自己 `docker rm -f`
- `setup-o.sh <臂> <BASE>` —— git 舊於 2.31 的臂（O、OI），git 在 alpine:3.13 容器裡跑（git 2.30.6）；容器名規則同上
- `mkprompt.sh <臂> <BASE> <dd-init.md 路徑>` —— 用 `prompt.txt` 填出 subagent 的 prompt（Agent 工具，general-purpose，model sonnet）
- `check.sh <臂> <BASE> <回報檔>` —— 判定；H?K 會在容器裡真的 commit 一次（H2K、H3K 先 `npm install`，H1K 先把回報的 YAML 加進設定、`pre-commit install`），同一個臂只能核一次
- `results.txt` —— 2026-11-14 那一次的結果與工具版本（路徑換成 `<BASE>`；subagent 回報原文不進 repo）
- `setup.sh`、`results.txt` 裡的 commit 編號是 2026-11-28 git 歷史改寫（作者身分統一）後的新編號；每個 commit 的內容樹與改寫前相同，`git show <編號>:<檔>` 拿到的內容不變
- 腳本裡的 `stat -f` 是 macOS 版：GNU `stat -f` 印的是檔案系統資訊，在 Linux 上 `before.txt` 會是錯的，只在 macOS 跑（`shasum` 在 node:22-bookworm 也有，不是限制）

## 此層慣例

- prompt 不要叫 subagent「只在專案目錄裡動作」：那句自己就會擋住寫到專案外，第 1、2 輪因此量不到舊文字的錯（見 `results.txt`）
- 舊文字下本來就綠的臂，新文字下也綠時只寫「會停、沒動到檔」，不寫成新文字的功勞；舊文字下紅的臂新文字要跑 3 次
- 回報原文含本機絕對路徑，留在 scratchpad；寫進 `results.txt` 的引文先把路徑換成 `<BASE>`、`<REPO>` 或 `…`
- 判完才改 `check.sh` 時，用新版把存起來的回報全部重判，翻盤的連同原因寫進 `results.txt`；改的那幾行註解寫明是哪一次的回報讓它改的
- 回報格式出錯（例如標題打錯）時不為它放寬 `check.sh`：照實記紅，另用改正格式的副本重判，兩個結果都寫

## 與上層的關係

引用它的是 `docs/designs/2026-11-14-security-audit-intake-design.md` 的 S1-3 與 CHANGELOG `## 未發布`。
