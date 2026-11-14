# 從存下的 stats（out/stats.jsonl，一行一發，stats.py 的輸出去識別後的樣子）印出結果表與判準要比的數字。
# 用法：python3 -I table.py out/stats.jsonl P        （甲）
#       python3 -I table.py out/stats.jsonl G2 G3    （乙）
# 作廢的發不在 stats.jsonl 裡（它們的數字寫在結果文件的「作廢」那一節）。
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
for g in sys.argv[2:]:
    sel = [r for r in rows if r["run"].split("-")[0] == g]
    key = "judge_s" if g == "P" else "rev_max_s"
    print(f"## {g}（比的秒數：{key}）")
    print("| 發 | 整發 s | 裁決者整發 s | 最慢審查者 s | 每個審查者 s | 審查者數 | 工具次數 | 輸出 token | 其中思考 | effort | 費用 US$ |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for r in sel:
        print("| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | %.2f |" % (
            r["run"], r["whole_s"], r.get("judge_s", "—"), r["rev_max_s"], "、".join(map(str, r["rev_s"])), r["n_rev"],
            "、".join(map(str, r["rev_tools"])), sum(r["rev_out"]), sum(r["rev_think"]), "／".join(r["rev_effort"]), r["cost"]))
    arm = {a: [r[key] for r in sel if r["run"].split("-")[1] == a] for a in ("med", "low")}
    if all(arm.values()):
        m, l = (sum(arm[a]) / len(arm[a]) for a in ("med", "low"))
        print(f"\nmedium {arm['med']} 平均 {m:.1f}；low {arm['low']} 平均 {l:.1f}；low／medium = {l / m:.3f}（要 ≤ 0.75）；"
              f"不重疊（low 最大 < medium 最小）：{max(arm['low']) < min(arm['med'])}；每臂發數 {len(arm['med'])}／{len(arm['low'])}\n")
