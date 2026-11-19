# auto-memory 資料夾是照哪個路徑取名的（2026-11-20）

問題：self-improving-agent 的五個 skill 用一條公式算 `~/.claude/projects/<編碼後的路徑>/memory`。
公式的輸入該是哪個路徑：cwd、git repo 根目錄，還是別的？submodule 與舊版 git 下公式算得對嗎？

結論：**session 的記憶資料夾跟著「主 checkout 的根目錄」走；submodule 用它自己的根目錄；不在 git repo 裡用 cwd。**
改過的公式在下面五種位置算出的名字，和 session 自己回報的一樣；改之前的公式在 submodule 與 git 2.25.1 下算錯。

## 做法

- Claude Code 2.1.327，`claude-haiku-5-5`，每個位置一發，全新的 session。
- 拋棄式目錄開在 scratchpad 底下：`super`（git repo）、`super/sub`（子目錄）、`wt`（`git worktree add` 出來的）、`super/mod`（`git submodule add` 進來的）、`plain`（不是 git repo）。
- 問法（原文）：「你的 system prompt 裡有一段講 auto memory(持久記憶)的目錄。把那個目錄的完整絕對路徑照貼出來,只回那一行,不要加別的字。system prompt 裡沒有這種路徑就只回「沒有」。」
- 指令：`claude -p "<問法>" --model claude-haiku-5-5 --output-format json --max-budget-usd 0.5 --no-session-persistence --permission-mode dontAsk --settings '{"advisorModel":""}' --disallowedTools "Edit Write NotebookEdit Agent Read Glob Grep WebFetch WebSearch Bash Skill" < /dev/null`
- 五發的 `subtype` 都是 `success`、`permission_denials` 都是空的。
- 這是模型照貼自己 context 裡的路徑，不是從磁碟查的；沒有另外去看那個資料夾有沒有被建立。

## 結果

資料夾名稱只列結尾那一段（前面是 scratchpad 路徑編碼後的字串，五發相同）。

| session 開在哪 | session 回報的結尾 | 改過的公式 | 改之前的公式 |
|---|---|---|---|
| `super` | `…-smprobe-super` | 一樣 | 一樣 |
| `super/sub` | `…-smprobe-super` | 一樣 | 一樣 |
| `wt` | `…-smprobe-super` | 一樣 | 一樣 |
| `super/mod` | `…-smprobe-super-mod` | 一樣 | `…-smprobe-super--git-modules-mod` |
| `plain` | `…-smprobe-plain` | 一樣 | 一樣 |

「改過的公式」（`skills/self-improving-agent/skills/*/SKILL.md`）：

```bash
ROOT=$(g=$(git rev-parse --git-common-dir 2>/dev/null) && cd "$g" >/dev/null 2>&1 && pwd -P)
case $ROOT in */.git) ROOT=${ROOT%/.git} ;; ?*) ROOT=$(git rev-parse --show-toplevel 2>/dev/null) ;; esac
```

「改之前的公式」：`ROOT=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); ROOT=${ROOT%/.git}`。

## 公式本身在三種 shell／git 下的結果

同一支腳本建出 `main`、`main/sub/deep`、`wt`（worktree）、`link`（指到 `main` 的 symlink）、`link/sub/deep`、`plain/x`、`main/mod`（submodule），在每個位置跑公式、比對算出的根目錄：

| 環境 | 改過的公式 | 改之前的公式 |
|---|---|---|
| macOS zsh | 7 個位置都對 | `main/mod` 算成 `main/.git/modules/mod`，其餘對 |
| macOS bash | 7 個位置都對 | 同上 |
| ubuntu:20.04 的 git 2.25.1（docker） | 7 個位置都對 | 只有 `plain/x` 對；其餘 6 個的輸出第一行是 `--path-format=absolute` 這串字（這個選項 git 2.31 才有，舊版原樣印回來、exit 0） |

## 沒量的

- session 開在「放好幾個 repo 的非 git 父目錄」、而 shell 之後 `cd` 進某個子 repo 的情況：公式是照 shell 當下的 cwd 算的，會算成那個子 repo 的資料夾，不是 session 的。這一項沒有改，記在 `skills/self-improving-agent/CLAUDE.md`。
- 每個位置只有一發；Fable、Opus 沒測（路徑是 harness 給的，推論和模型無關，沒驗證）。
- `LC_ALL=C` 下 `sed` 逐 byte 換、非 ASCII 路徑會多出 `-` 的情況（skill 用「資料夾不在就列候選」那一行處理，這次沒重測）。
