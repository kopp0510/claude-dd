# docs/measurements/2026-11-17-dd-stop

`/dd-stop`（暫停與恢復 8 步迴圈的指令）的實測。設計、使用者的決定與進度表在 `docs/designs/2026-11-17-dd-stop-design.md`。

## 檔案

- `probe-local.sh` —— 開工前提 P1：專案根目錄的 `CLAUDE.local.md` 會不會被全新的 session 載入。兩臂只差有沒有這個檔，各 1 發、haiku，每發上限 1 美元。
  有檔那一臂照 `dd-stop.sh on` 的做法把它列進 `.git/info/exclude`。判定寫在檔頭、跑之前就定好：有檔的回覆第一行是 `ZEBRA-7`、沒有檔的整則沒有 `ZEBRA-7`
- `out/probe-local.prompt.txt` —— 兩臂共用的 prompt 原文
- `out/probe-local-with.jsonl`、`out/probe-local-without.jsonl` —— 每臂一行精簡過的 result（`num_turns`、`total_cost_usd`、`models`、`permission_denials`、`result`）。原始 stream-json 沒有留

## 結果

- P1（2026-11-17，Claude Code 2.1.326）：成立。有檔那一臂回 `ZEBRA-7` 加一句答案，對照只有答案；兩發 `permission_denials` 都是 0、`models` 只有 haiku
- 它只證明「檔會載入、模型照著多寫了一行」。暫停聲明壓不壓得過專案 CLAUDE.md 與全域 §3.9 的迴圈是另一件事，P1 沒有測

## 跑之前

- 先 Read `docs/measurements/CLAUDE.md` 整份（「已知的坑」每一條）
- `probe-local.sh` 的參數是拋棄式工作目錄，要放在 repo 與家目錄的 CLAUDE.md 鏈之外（scratchpad）；目錄已存在而不是它自己建的（沒有 `.dd-stop-probe-work`）就拒跑，因為每發之前會整個刪掉它
- 重跑會蓋掉 `out/` 的三個檔。它們是設計文件引用的證據，要重跑就先把舊的另存
