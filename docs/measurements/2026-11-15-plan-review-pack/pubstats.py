#!/usr/bin/env python3
"""把 stats.py 的輸出整理成可以進 repo 的 out/stats.jsonl。

用法：python3 -I pubstats.py <stats.py 的輸出檔>… > out/stats.jsonl
- 「洩題檢查命中」那一欄的原文（工具輸入的前 200 字元，帶本機路徑，而且會從路徑中間截斷）換成筆數；
  逐筆的判定寫在結果文件（照 ../2026-11-15-reviewer-effort/out/stats.jsonl 的慣例）
- 其餘欄位原樣；整理完還有本機路徑字樣就不輸出、exit 1
"""
import json, os, re, sys

# [U]sers：樣式本身不要被「進 repo 前的本機路徑掃描」當成命中
LOCAL = re.compile(r"/private/|/[U]sers/|-[U]sers-|/tmp/|scratchpad|claude-\d+|" + re.escape(os.path.basename(os.path.expanduser("~"))))
out = []
for path in sys.argv[1:]:
    for line in open(path, encoding="utf-8"):
        if not line.strip(): continue
        d = json.loads(line)
        notes = []
        for n in d.get("notes", []):
            if isinstance(n, dict):
                n = {k: (f"{len(v)} 筆（逐筆判定見結果文件）" if k.startswith("洩題檢查命中") and isinstance(v, list) else v) for k, v in n.items()}
            notes.append(n)
        d["notes"] = notes
        s = json.dumps(d, ensure_ascii=False)
        m = LOCAL.search(s)
        if m: sys.exit(f"{d.get('run')}：整理完還有本機路徑字樣「{m.group()}」，沒有輸出")
        out.append(s)
print("\n".join(out))
