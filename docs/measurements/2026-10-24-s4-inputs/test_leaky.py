# stats.py 洩題判定 leaky() 的負面測試：該抓的要抓到、實驗裡出現過的誤報不能再報。
# 用法：python3 -I test_leaky.py   （全過 exit 0）
import json, os, sys
ns = {}
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "stats.py")).read().split("args = sys.argv")[0], ns)
leaky = ns["leaky"]
cases = [  # (工具, 輸入, 該不該判成洩題)
    ("Read", {"file_path": "/Users/danlio/project/my_project/claude-dd/docs/reviews/x.md"}, True),
    ("Bash", {"command": "cat ~/.claude/CLAUDE.md"}, True),
    ("Bash", {"command": "find / -name S4-a.md"}, True),
    ("Bash", {"command": "grep -rn 預言 / 2>/dev/null"}, True),
    ("Bash", {"command": "cd ../.. && git log"}, True),
    ("Bash", {"command": "ls $HOME"}, True),
    ("Bash", {"command": "cd /tmp/x && cat ../../Users/danlio/.claude/CLAUDE.md"}, True),
    ("Bash", {"command": "cd /tmp/x && git worktree add ../w"}, False),
    ("Bash", {"command": "git -C /S4/G2-new-1 diff HEAD~1 HEAD"}, False),
    ("Agent", {"prompt": "90 ✅ / 0 ❌，不准讀 `~/.claude/projects/`、`/Users/`"}, False),
    ("Bash", {"command": "echo \"== dd-init / README ==\"; T=$(mktemp -d); cd $T; git worktree add ../w # dir / nested"}, False),
]
bad = [(n, i) for n, i, w in cases if leaky("/S4", n, json.dumps(i, ensure_ascii=False)) != w]
print(f"{len(cases) - len(bad)} / {len(cases)}", bad)
sys.exit(1 if bad else 0)
