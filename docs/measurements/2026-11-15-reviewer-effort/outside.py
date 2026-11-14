# 補充的洩題掃描（2026-11-15 跑完甲之後加的）：stats.py 的 leaky() 只認家目錄、往上爬、根目錄搜尋與工作目錄裡別發的東西，
# 漏掉「工作目錄以外的暫存區絕對路徑」（P-med-3 有個審查者 cd 到工作目錄的上兩層去找計畫提到的探針腳本，leaky() 沒抓到）。
# 這支把每個工具呼叫（Agent 轉達的 prompt 與交回的報告不算）裡自己可以讀的路徑換掉之後，還出現暫存區、/tmp、/private、../ 的都列出來，人工判。
# 用法：python3 -I outside.py <工作目錄> <發代號>...
import glob, json, os, re, sys
w = os.path.realpath(sys.argv[1])
home = os.path.expanduser("~")
PAT = re.compile(r"scratchpad|/tmp/|/private/|\.\./")
for run in sys.argv[2:]:
    g = run.split("-")[0]
    snap = os.path.join(w, run)
    pdir = os.path.join(home, ".claude", "projects", re.sub(r"[^A-Za-z0-9]", "-", snap))
    files = [(json.load(open(m)).get("description", "?"), m.replace(".meta.json", ".jsonl")) for m in glob.glob(pdir + "/*/subagents/agent-*.meta.json")]
    files += [("父", s) for s in glob.glob(pdir + "/*.jsonl")]
    n = 0
    for who, f in files:
        for ln in open(f, errors="ignore"):
            try: r = json.loads(ln)
            except ValueError: continue
            c = (r.get("message") or {}).get("content")
            for b in c if isinstance(c, list) else []:
                if not isinstance(b, dict) or b.get("type") != "tool_use" or b.get("name") in ("Agent", "SubagentHandback"): continue
                j = json.dumps(b.get("input"), ensure_ascii=False).replace(pdir, "<OWN>")
                for p, tag in ((snap + "/", "<SNAP>/"), (snap + '"', '<SNAP>"'), (snap + " ", "<SNAP> "),
                               (snap + "\\n", "<SNAP>\\n"), (os.path.join(w, "prompts", run + "."), "<PROMPT>."), (os.path.join(w, g) + "/", "<DIFF>/")):
                    j = j.replace(p, tag)
                k = PAT.search(j)
                if not k: continue
                n += 1
                print("%s｜%s｜%s｜…%s…" % (run, who, b["name"], j[max(0, k.start() - 100):k.start() + 160].replace(w, "<WORK>").replace(os.path.dirname(os.path.dirname(w)), "<暫存區>").replace(home, "<HOME>")))
    print(run, "列出", n, "筆")
