#!/usr/bin/env python3
"""關卡 ②：裁決者與每個審查者有沒有把審查包讀到最後一行。

用法：python3 -I readcheck.py <工作目錄> <發代號>…
每個 subagent 一行：對審查包（prompts/<發代號>.pack.md）下了幾次 Read、這些 Read 的結果裡有沒有結尾那一行。
只看 Read 的 tool_result（結尾那一行的字樣也出現在 prompt 的讀檔指示裡，掃整份紀錄會誤判成讀到了）。
exit 1 = 有 subagent 沒讀到結尾。讀的是 ~/.claude/projects/ 的 subagent 紀錄檔（不在 repo）。
"""
import glob, json, os, re, sys

END = "<<<審查包結束>>>"

def text(c):
    if isinstance(c, str): return c
    return "".join(b.get("text", "") for b in c if isinstance(b, dict)) if isinstance(c, list) else ""

w, runs, bad = os.path.abspath(sys.argv[1]), sys.argv[2:], 0
for run in runs:
    pack = os.path.realpath(os.path.join(w, "prompts", run + ".pack.md"))
    pdir = os.path.join(os.path.expanduser("~/.claude/projects"), re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(w, run))))
    metas = sorted(glob.glob(os.path.join(pdir, "*", "subagents", "agent-*.meta.json")))
    if not metas: print(run, "找不到 subagent 紀錄"); bad += 1
    for m in metas:
        meta = json.load(open(m))
        reads, seen = set(), False
        for line in open(m.replace(".meta.json", ".jsonl"), encoding="utf-8", errors="replace"):
            try: r = json.loads(line)
            except ValueError: continue
            c = (r.get("message") or {}).get("content")
            for b in c if isinstance(c, list) else []:
                if not isinstance(b, dict): continue
                if b.get("type") == "tool_use" and b.get("name") == "Read" and os.path.realpath(str((b.get("input") or {}).get("file_path", ""))) == pack:
                    reads.add(b.get("id"))
                if b.get("type") == "tool_result" and b.get("tool_use_id") in reads and END in text(b.get("content")):
                    seen = True
        ok = bool(reads) and seen
        bad += not ok
        print(f"{run}｜第 {meta.get('spawnDepth')} 層｜{meta.get('description')}｜Read 審查包 {len(reads)} 次｜讀到結尾：{'是' if ok else '否'}")
sys.exit(1 if bad else 0)
