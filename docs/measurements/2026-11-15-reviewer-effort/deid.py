# 用法：python3 -I deid.py <dump 目錄> <repo 的 reports 目錄> <工作目錄>
# 把 stats.py --dump 存下的報告去識別後複製進 repo：工作目錄換成 <WORK>，家目錄與帳號字樣換掉；最後掃一次，有殘留就不寫
import os, re, sys
src, dst, w = sys.argv[1:4]
home = os.path.expanduser("~"); user = os.path.basename(home)
os.makedirs(dst, exist_ok=True)
bad = 0
for f in sorted(os.listdir(src)):
    s = open(os.path.join(src, f), encoding="utf-8").read()
    for a, b in ((os.path.realpath(w), "<WORK>"), (w, "<WORK>"), (w.replace("/private", ""), "<WORK>"), (home, "<HOME>"),
                 (re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(w)), "<WORK-ENC>"), (re.sub(r"[^A-Za-z0-9]", "-", home), "<HOME-ENC>")):
        s = s.replace(a, b)
    s = re.sub(r"[^\s`'\"（(「]*scratchpad/s2/work", "<WORK>", s)  # 報告裡只寫了後半段路徑的
    s = re.sub(r"[^\s`'\"（(「]*scratchpad/", "<暫存區>/", s)
    s = re.sub(r"/Users/[A-Za-z0-9._-]+", "/Users/<USER>", s)
    s = re.sub(r"-Users-[A-Za-z0-9]+", "-Users-<USER>", s)
    s = s.replace(user, "<USER>")
    s = re.sub(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}", lambda m: m.group() if m.group().endswith(("example.invalid", "anthropic.com", "example.com")) else "<EMAIL>", s)
    left = re.findall(r"claude-501|-private-tmp-|scratchpad/|/tmp/claude|" + re.escape(user), s)
    if left: bad += 1; print("殘留", f, sorted(set(left))); continue
    open(os.path.join(dst, f), "w", encoding="utf-8").write(s if s.endswith("\n") else s + "\n")
print("處理", len(os.listdir(src)), "份；有殘留沒寫的", bad)
