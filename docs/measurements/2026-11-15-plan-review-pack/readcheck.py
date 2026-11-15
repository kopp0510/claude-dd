#!/usr/bin/env python3
"""關卡 ②：裁決者與每個審查者有沒有把審查包從第一行讀到最後一行。

用法：python3 -I readcheck.py <工作目錄> <發代號>…
每個 subagent 一行：對審查包（prompts/<發代號>.pack.md）下的每次 Read 的 offset／limit。兩件事都成立才算「是」：
- 這些 Read 要的行（offset 沒給或 0 當第 1 行，limit 沒給當 2000 行）合起來蓋住第 1 行到最後一行
- 這些 Read 的結果裡有結尾那一行（要了卻被截斷的話就不會有）
限制：
- 只看 Read 的 tool_result（結尾那一行的字樣也出現在 prompt 的讀檔指示裡，掃整份紀錄會誤判成讀到了）
- 不拿審查包的第一行去比結果：範圍句在事實開頭還會再出現一次，從中間讀起也比得到
- 一次 Read 要的行太大、中間被截掉而結尾還在的情況查不出來（2026-11-15 的大檔臂沒遇到）
- 用 Bash 讀檔、或路徑寫成 `~` 的不算 Read 審查包，會印「否」
步驟 4 審查之後改的（2026-11-15）：原本只查「結果裡有結尾那一行」，只讀檔尾也會印「是」。
exit 1 = 有 subagent 沒有從頭讀到尾。讀的是 ~/.claude/projects/ 的 subagent 紀錄檔（不在 repo）。
"""
import glob, json, os, re, sys

END = "<<<審查包結束>>>"

def text(c):
    if isinstance(c, str): return c
    return "".join(b.get("text", "") for b in c if isinstance(b, dict)) if isinstance(c, list) else ""

def blocks(record):
    c = (record.get("message") or {}).get("content")
    return [b for b in c if isinstance(b, dict)] if isinstance(c, list) else []

def is_pack_read(b, pack):
    if b.get("type") != "tool_use" or b.get("name") != "Read": return False
    return os.path.realpath(str((b.get("input") or {}).get("file_path", ""))) == pack

def covered(windows, n):
    """這些 (offset, limit) 要的行合起來有沒有蓋住第 1 到第 n 行。"""
    want = set()
    for o, l in windows:
        start = o if isinstance(o, int) and o > 0 else 1
        want.update(range(start, start + (l if isinstance(l, int) and l > 0 else 2000)))
    return all(i in want for i in range(1, n + 1))

def scan(log, pack):
    """回傳（每次 Read 審查包的 (offset, limit)，照順序；結果裡有沒有結尾那一行）。tool_result 要在對應的 tool_use 之後才算。"""
    reads, windows, got_end = set(), [], False
    for line in open(log, encoding="utf-8", errors="replace"):
        try: r = json.loads(line)
        except ValueError: continue
        for b in blocks(r):
            if is_pack_read(b, pack):
                reads.add(b.get("id"))
                windows.append((b["input"].get("offset"), b["input"].get("limit")))
            if b.get("type") == "tool_result" and b.get("tool_use_id") in reads:
                got_end = got_end or END in text(b.get("content"))
    return windows, got_end

w, runs, bad = os.path.abspath(sys.argv[1]), sys.argv[2:], 0
for run in runs:
    pack = os.path.realpath(os.path.join(w, "prompts", run + ".pack.md"))
    n = sum(1 for _ in open(pack, encoding="utf-8"))
    pdir = os.path.join(os.path.expanduser("~/.claude/projects"), re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(w, run))))
    metas = sorted(glob.glob(os.path.join(pdir, "*", "subagents", "agent-*.meta.json")))
    if not metas: print(run, "找不到 subagent 紀錄"); bad += 1
    for m in metas:
        meta = json.load(open(m))
        windows, got_end = scan(m.replace(".meta.json", ".jsonl"), pack)
        cover = covered(windows, n)
        ok = cover and got_end
        bad += not ok
        wins = "、".join(f"{o if o is not None else '沒給'}／{l if l is not None else '沒給'}" for o, l in windows) or "—"
        print(f"{run}｜第 {meta.get('spawnDepth')} 層｜{meta.get('description')}｜Read 審查包 {len(windows)} 次（offset／limit：{wins}）｜"
              f"要的行蓋住 1–{n}：{'是' if cover else '否'}｜結果裡有結尾那一行：{'有' if got_end else '沒有'}｜從頭讀到尾：{'是' if ok else '否'}")
sys.exit(1 if bad else 0)
