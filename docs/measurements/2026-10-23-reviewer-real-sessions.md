# code-reviewer 的時間花在哪（2026-10-23，真實 session 紀錄）

起因：使用者反映每次等 8 步迴圈步驟 4 都超過半小時。2026-10-05 那份（`2026-10-05-reviewer-overhead.md`）
是基準台 n=2；這份改讀**真實 session** 裡每個 code-reviewer subagent 自己的紀錄檔。

## 方法

- 來源：`~/.claude/projects/**/agent-*.meta.json`（`agentType == "code-reviewer"`）與同名 `.jsonl`
- 耗時 = 該 subagent jsonl 裡最晚與最早 `timestamp` 的差；工具 = 其中每個 `tool_use`，**用 id 去重**
  （同一個 tool_use 會在多行重複出現；第一版沒去重，工具數高估約 7%，S1 的 review 抓到）
- 排除公司專案（路徑含 `-SRE`）。紀錄只保留到約 30 天前，所以這是近期樣本、不是全部歷史
- ⚠️ **不要改用父 session 的 `<task-notification>` 裡的 `duration_ms`**：同一天先用那個算，
  只抓到 98 次、中位數 2 分鐘 —— 大部分派工的通知沒被比對到，結論整個相反

引用下面的數字前先重跑（數字是當天的快照，之後的審查也會算進去）：

```bash
python3 -I <下面這支腳本存成的檔> ~/.claude/projects
```

```python
import json, glob, os, re, sys, collections
from datetime import datetime

# 用法：python3 -I reviewer_stats.py ~/.claude/projects
root = sys.argv[1]
def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()

def cat(b):
    n = b["name"]
    if n != "Bash": return n
    c = b.get("input", {}).get("command", "")
    if re.search(r"\bgit (-C \S+ )?(diff|show|log)", c): return "Bash: git diff/show/log"
    if re.search(r"\b(grep|rg)\b", c): return "Bash: grep"
    if re.search(r"\b(sed -n|cat|head|tail|awk)\b", c): return "Bash: 印檔案內容"
    if re.search(r"test|jest|vitest|pytest|npm|node |tsc|bash .*\.sh|docker", c): return "Bash: 跑測試/程式/docker"
    return "Bash: 其他"

runs = []
for m in glob.glob(os.path.join(root, "**/agent-*.meta.json"), recursive=True):
    if "-SRE" in m: continue          # 公司專案不讀
    meta = json.load(open(m))
    if meta.get("agentType") != "code-reviewer": continue
    j = m.replace(".meta.json", ".jsonl")
    if not os.path.exists(j): continue
    t, tools, seen = [], [], set()
    for ln in open(j, errors="ignore"):
        try: o = json.loads(ln)
        except ValueError: continue
        if o.get("timestamp"): t.append(ts(o["timestamp"]))
        for b in ((o.get("message") or {}).get("content") or []):
            # 同一個 tool_use 會在多行重複出現（2026-10-23 實測全部 code-reviewer 紀錄有數百筆重複），用 id 去重
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("id") not in seen:
                seen.add(b.get("id")); tools.append(cat(b))
    if len(t) < 2: continue
    runs.append(((max(t) - min(t)) / 60, tools, meta.get("description", "")))

d = sorted(r[0] for r in runs); n = len(d)
if n == 0: sys.exit("沒有任何 code-reviewer 紀錄")
print(f"code-reviewer 次數={n} 中位={d[n//2]:.1f} 分 第90百分位={d[int(n*.9)]:.1f} 分 >=10分={sum(x>=10 for x in d)}")

print("\n工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）")
B = collections.defaultdict(list)
for dur, tl, _ in runs:
    if dur > 200: continue
    k = len(tl); B["0-10" if k <= 10 else "11-20" if k <= 20 else "21-30" if k <= 30 else "31+"].append(dur)
for k in ["0-10", "11-20", "21-30", "31+"]:
    v = sorted(B[k])
    print(f"  工具 {k:6s} 次數={len(v):3d} 中位={v[len(v)//2]:5.1f} 分" if v else f"  工具 {k:6s} 次數=  0")

C = collections.Counter(x for _, tl, _ in runs for x in tl); tot = sum(C.values())
print(f"\n工具種類（共 {tot} 次）")
for k, v in C.most_common(6): print(f"  {100*v/tot:4.0f}%  {k}")

fast = [r for r in runs if r[0] <= 5]; slow = [r for r in runs if 15 <= r[0] <= 200]
print(f"\n每次平均：快的(<=5分, {len(fast)} 次) vs 慢的(15–200分, {len(slow)} 次)")
for k in ["Bash: git diff/show/log", "Bash: grep", "Bash: 印檔案內容"]:
    if not fast or not slow: print("  （快或慢的樣本是 0，不比）"); break
    f = sum(r[1].count(k) for r in fast) / len(fast); s = sum(r[1].count(k) for r in slow) / len(slow)
    print(f"  {f:5.1f} vs {s:5.1f}  {k}（{s/f if f else float('inf'):.1f} 倍）")
```

## 當天輸出（2026-10-23，含本 repo S1 那兩發新做法的審查）

```
code-reviewer 次數=311 中位=11.8 分 第90百分位=27.7 分 >=10分=167

工具次數 vs 耗時（排除 >200 分的離群值，多半是事後被喚醒續跑）
  工具 0-10   次數=100 中位=  2.4 分
  工具 11-20  次數=102 中位= 12.0 分
  工具 21-30  次數= 73 中位= 17.3 分
  工具 31+    次數= 34 中位= 24.6 分

工具種類（共 5377 次）
    65%  Bash: git diff/show/log
    19%  Bash: grep
     7%  Bash: 印檔案內容
     6%  SubagentHandback
     1%  Read
     1%  Bash: 跑測試/程式/docker

每次平均：快的(<=5分, 114 次) vs 慢的(15–200分, 127 次)
    5.2 vs  16.7  Bash: git diff/show/log（3.2 倍）
    1.9 vs   4.6  Bash: grep（2.5 倍）
    0.6 vs   1.6  Bash: 印檔案內容（2.9 倍）
```

## 結論

1. **時間跟工具次數走**：0–10 次約 2–3 分鐘，31 次以上約 25 分鐘（與 2026-10-05 結論 3 一致，這次樣本大很多）
2. **git 類（`git diff/show/log`）佔全部工具呼叫的大宗**，但慢的審查是**每一類都多好幾倍**（git、grep、印檔案的倍數接近），
   不是只有 git 變多。所以這份數據**證明不了**「慢是因為逐檔撈 diff」—— 也可能只是 diff 大、檔案多，每類都跟著變多。
   指令字串的分類也分不出「逐檔撈」與「整段看一次」
3. 「派工前把整段 diff 準備成一個檔交給它」是根據結論 2 的**推論**（git 類最多，先交 diff 至少省掉撈 diff 那部分），
   效果要等 S4 拿同一批舊 diff 新舊對照才算數。另外，全域 §3.9 步驟 4 的「`git show <commit>:<路徑>` 取檔」
   只在與 simplifier 並行時適用，不是所有審查都會逐檔撈

## 限制

- 耗時是 wall（含模型思考與工具執行），沒有拆出 api 時間；被 SendMessage 喚醒續跑過的審查會把中間閒置算進去，
  分桶只排除 >200 分的，整體中位數與第 90 百分位沒有排除
- 工具分類用指令字串的正規式，`git -c … diff` 這種寫法不會被歸進 git 那類（只會低估）

## 新做法對照（2026-10-24，S4）

計畫在 `docs/designs/2026-10-23-裁決審查-design.md` 的 S4 一節（三輪 plan-review 通過，報告在 `docs/reviews/2026-10-23-裁決審查/plan-S4-r*.md`）。
實驗輸入在 `2026-10-24-s4-inputs/`（凍結），每一發的統計與每個 agent 的最後一則文字在 `2026-10-24-s4-outputs/`。輸出檔裡的工作目錄路徑已換成 `<s4>`。

### 三組

| 組 | 父 session 派什麼 | 審查者 |
|---|---|---|
| 新（new） | 1 個裁決者（general-purpose、opus），照部署版 §3.9 步驟 4，先交 diff 檔 | code-reviewer（opus），裁決者自己決定幾個（≥3） |
| haiku（hk） | 同新 | code-reviewer 帶 `model: "haiku"` |
| 舊（old） | 2 個 code-reviewer，舊報告的派工寫法（`git show HEAD:`、最多一次重現實驗） | code-reviewer（opus）×2 |

每一發一份自己的快照 repo（只有 base、change 兩個 commit，拿掉 `docs/reviews/` 的舊報告），在快照裡跑 `claude -p --model haiku`。
一批同時跑同一段的新、舊、haiku 各一發，跑完才開下一批。

### 原始數字

重跑：`python3 -I 2026-10-24-s4-inputs/stats.py <s4 工作目錄> <發代號>...`（輸出就是 `2026-10-24-s4-outputs/stats.jsonl`）。
整發 = 父 session 紀錄第一個時間戳到所有層最後一個時間戳；審查者層 = 最慢那個審查者自己的耗時；費用 = 父 log 最後一筆 `result.total_cost_usd`（是累計值、含子代理：有多筆 result 的發每筆值都相同，例如 G2-new-2 兩筆都是 3.404、G3-old-2 三筆都是 1.464；父層是 haiku，3 美元多只能來自 opus 子代理）。

| 發 | 整發 | 費用 US$ | 裁決者（秒／工具） | 審查者數 | 審查者層最慢 | 每個審查者的工具次數 |
|---|---|---|---|---|---|---|
| G2-new-1 | 339s | 3.33 | 321／7 | 3 | 179s | 7、6、7 |
| G2-new-2 | 331s | 3.40 | 314／15 | 3 | 164s | 7、5、9 |
| G2-hk-1 | 300s | 1.15 | 286／11 | 3 | 168s | 4、4、5 |
| G2-hk-2 | 326s | 1.08 | 313／11 | 3 | 158s | 7、9、3 |
| G2-old-1 | 120s | 0.96 | — | 2 | 102s | 5、5 |
| G2-old-2 | 104s | 0.89 | — | 2 | 81s | 5、4 |
| G3-new-1 | 359s | 4.60 | 341／9 | 4 | 210s | 6、14、8、11 |
| G3-new-2 | 370s | 3.97 | 352／10 | 3 | 235s | 11、6、18 |
| G3-hk-1 | 455s | 2.67 | 439／11 | 3 | 158s | 10、6、7 |
| G3-hk-2 | 303s | 1.37 | 286／14 | 4 | 106s | 6、5、7、5 |
| G3-old-1 | 205s | 1.92 | — | 2 | 187s | 12、8 |
| G3-old-2 | 185s | 1.46 | — | 2 | 168s | 8、7 |
| G4-new-1 | 332s | 3.50 | 315／11 | 3 | 187s | 10、10、11 |
| G4-new-2 | 351s | 4.36 | 333／12 | 4 | 192s | 11、9、7、11 |

- 作廢：G4 兩發都有 `permission_denials`（3 筆都是在拋棄式 repo 測 gate 時用 `--no-verify` 或 `-n` 跳過 hook；G4-new-1 有一筆是裁決者發的、其餘是審查者，tool_result 是「PreToolUse:Bash hook error: claude-dd gate-guard：git commit 不可用 --no-verify／-n／core.hooksPath 跳過 hook。…」）。規則允許再跑第 3 次，沒跑：兩發都是 agent 自己決定這樣測，再跑也會撞同一道擋。G4 本來就不計命中，表上數字只供參考
- 全部 14 發合計約 US$34.7（不含三輪計畫審查）
- 模型斷言全過：新組裁決者與審查者都是 opus、haiku 組審查者都是 haiku、舊組審查者都是 opus
- 洩題檢查三道都沒有命中：
  - 工具輸入：`stats.py` 的 `leaky()`，負面測試 `test_leaky.py`（11 則全過）。實跑中改過三次判定式，都是誤報：裁決者轉達的禁區那句本身、拋棄式目錄裡的 `../`、`echo` 字串與註解裡的「 / 」。
    ⚠️ 它的範圍比計畫窄：整個 `<s4>` 都放行（讀別發的 log 或快照它看不出來），也不認沒有斜線的 `..`
  - 補這個缺口（步驟 4 審查後補的，`stats.py` 是凍結輸入不改）：`2026-10-24-s4-outputs/extra_checks.py` 的 `cross` 欄，掃所有層的工具輸入有沒有碰別發的快照、別發的 prompt、`logs/`，以及舊組有沒有碰 diff 檔 —— 14 發都是 0 筆（輸出在 `extra_checks.out`）
  - 工具結果：同一支的 `res` 欄（計畫寫的是掃結果，`stats.py` 只掃了輸入），換掉 s4 工作目錄與該發自己的 projects 目錄後剩下的 `/Users/` 路徑，每一發 1–3 筆，全都是派工單裡「不准讀 `/Users/`」那句被讀回來

### 命中（判準跑之前寫死在設計文件：同一個位置、同一個機制才算，級別不論）

答案對到快照裡的程式碼（計畫要求跑前寫，實際是跑後才寫進來）：K1 = G2 終點的 `tests/test-gate.sh` 情境 ⑪（:335–349），`docs` 被刪掉後 `reviews_missing` 那一支沒跑到，`said "找不到共同祖先"` 是被 `owed_dirs` 印的那句滿足的；K4 = G3 終點 `tests/test-gate.sh:337` 繞過② 那則；K5 = 同檔 `:320` 繞過①，那時 HEAD 等於起點，gate 直接放行，證明不了 pre-commit 不查報告。

brief 不含答案：`grep -c` 答案句片段（從未執行到、查不到出處、3 紅、正常流程唯一的覆蓋、pre-commit 不查報告、判準相反）與範圍用詞（繞過、stash、⑪）在 `2026-10-24-s4-inputs/` 的 briefs.txt、judge.txt、old-reviewer.txt、parent.txt 全部 0 筆（步驟 4 審查後補跑的）。

只算 K1、K4、K5；K2、K3、K6 受全域規則污染（見下面「限制」），只當參考。格子寫「審查者原始報告的聯集／裁決者採納」，舊組只有聯集。位置是 `2026-10-24-s4-outputs/reports/` 底下的檔名前綴與行號。

| 已知錯誤 | 新 | haiku | 舊 |
|---|---|---|---|
| K1 ⑪ 沒跑到 `reviews_missing` 的「沒有共同祖先」分支（G2） | 第 1 發 ✓／✓（`G2-new-1.d2.a79b15` :3、judge :12）；第 2 發 ✓／✓（`G2-new-2.d2.adae89` :5、judge :12） | 第 1 發 ✓／✓（`G2-hk-1.d2.a71b72` :3、judge :11）；第 2 發 ✓／✓（`G2-hk-2.d2.a21bd9` :3、judge :12） | 第 1 發 ✓（`G2-old-1.d1.a594bb` :3）；第 2 發 ✓（`G2-old-2.d1.a0166b` :3） |
| K4 繞過② 那則其實是正常流程唯一的覆蓋（G3）；用 `grep -n '繞過②\|:337\|第 337\|by3' G3-*` 不過濾地找，命中的行沒有一行說它跟正常流程的覆蓋重疊（多數是說它的對照組成立） | 兩發都沒抓到 | 兩發都沒抓到（`G3-hk-1.d2.a3d3dc` :18 明寫「沒找到會因錯理由通過的地方」） | 兩發都沒抓到 |
| K5 繞過① 那則測不到「pre-commit 不查報告」（G3） | 第 1 發 ✓／✓（`G3-new-1.d2.ac0356` :3、judge :23）；第 2 發沒抓到（`G3-new-2.d2.aa6177` :12 判它成立） | 第 1 發沒抓到；第 2 發 ✓／✓（`G3-hk-2.d2.abe0ae` :3、judge :11） | 第 1 發沒抓到；第 2 發 ✓（`G3-old-2.d1.a8c1fb` :3） |
| 合計（每組 4 發，最多 6 個命中） | 聯集 3、採納 3 | 聯集 3、採納 3 | 聯集 3 |

參考（受污染，不計分）：

- K6 verification-gate 的 stash 模式跟 §3.5／§3.9 衝突（G3）：審查者聯集新 2/2、haiku 0/2、舊 2/2；haiku 兩發都是裁決者自查補上的（`G3-hk-1` judge :17、`G3-hk-2` judge :15），`G3-hk-1.d2.aad426` :7 的審查者還明寫「不算矛盾」。`G3-new-2.d2.aa6177` :8 的審查者自己寫「本 session 載入的已部署版全域 CLAUDE.md §3.5 後來改成…可見作者後來修過同一個衝突」—— 污染是實際發生的
- K2「S6 的 reviewer 預言過」查不到出處（G2）：新組第 2 發採納（judge :41，降成 Smells）、第 1 發列外部查證；haiku 第 1 發審查者報了（`G2-hk-1.d2.ae62d9` :7）但裁決者列外部查證；舊組沒抓到
- K3 寫死紅數、沒記哪個變異讓哪幾則變紅（G2）：沒有一發算得上命中，只有沾邊 —— `G2-hk-1` judge :19（缺「插在哪一行」，是可重現性，不是 K3 的「紅數不是證據」）、`G2-new-1` judge :22（屬於第 2 條 ⑩ 的連帶影響）、`G2-old-1.d1.a594bb` :8（引用全域 §3.9「要記哪個變異 → 哪幾個情境變紅」，那句是 713038a 在 G2 之後才寫進全域規則的）
- K5 沾邊、判成未命中的：`G3-new-2.d1.a148f0` :37、`G3-hk-1.d2.ae9ad9` :9、`G3-old-1.d1.a2e1e9` :18 都寫了「變異讓繞過① 變紅、從建立 docs/reviews/ 那個 commit 起連鎖」，但沒指出繞過① 那則自己抓不到（K5 的機制）

### 結論

1. **新做法比舊做法慢、也貴**：整發 G2 約 335s 對 112s（3 倍）、G3 約 365s 對 195s（1.9 倍）；費用約 3.6 倍（G2）與 2.5 倍（G3）。
   多出來的主要是裁決者那一層：裁決者耗時 314–352s，其中最慢的審查者只佔 164–235s，剩下的是裁決者自己讀 diff、派工、各審查者開跑時間的落差、逐條查證
2. **這批素材上，三組抓到的已知錯誤一樣多**：6 個可能的命中裡都抓到 3 個。K1 誰都抓得到，K4 誰都抓不到，K5 每組都是兩發中一發抓到。
   n=2、只有 3 個可計分的錯誤，**分不出差異**，也證明不了「新做法抓得比較多」或「haiku 抓得比較少」
3. **計分的 K1、K4、K5 上 haiku 審查者沒有比 Opus 審查者少抓**（6 個裡同樣 3 個），費用約新組的 1/3–1/2（整發含 opus 裁決者）。但參考用的 K6 haiku 審查者兩發都沒報、Opus 審查者兩發都報了。這只是這批的觀察，不改規則
4. **「先交 diff 檔能快多少」這次分不出來**：新組的審查者層（164–235s）反而比舊組（81–187s）慢，但同一格同時變了 diff 檔、探索預算（舊組有「最多一次重現實驗」）、派工指令、多一層裁決者。
   附帶觀察：舊組每個審查者撈 `git diff/show/log` 3–5 次；新組與 haiku 組在 G2、G3 是 0–3 次（`stats.py` 之外另跑的統計，指令見下）
5. **裁決者的實際作用**：在這 8 發新組／haiku 組裡，裁決者把重大項調級（Critical 降 Important、Important 降 Smells）、把審查者丟進 Not reported 的項目撈回來（例如 `G2-new-2` judge :46），
   計分的 K1、K4、K5 沒有一個是裁決者自己補出來的；參考用的 K6 在 haiku 兩發都是裁決者自查補上的（見上面「參考」）

### 大 diff 讀不讀得完（G4，只供參考）

- diff 檔：G2 1010 行、G3 3024 行、G4 1155 行（G4 的 diff 最大，但整檔內容那段比 G3 短，所以 diff 檔反而是 G3 最長）
- 數字來自 `2026-10-24-s4-outputs/extra_checks.py` 的 `read` 欄：配對每個 Read 請求與它的回傳，看實際回到第幾行（只算 Read；用 Bash 讀的不算）
- **Read 不指定範圍時會被截斷，而且沒有錯誤訊息**：G3 的 diff 檔 3024 行，不帶 limit 的 Read 只回到第 544 行（`G3-hk-2` 的 a31c92 就停在 544；a6f231、`G3-hk-1` 的 aad426 再用 offset 補讀，分別到 1773、1700）。
  G2 也有一例：`G2-hk-2` 的 ab8118 請求 1010 行，實得 643。兩次截斷點前的內容都是約 47 KB（`head -544` 與 `head -643` 各 47065、47064 位元組；diff 檔 G2 69 KB、G3 253 KB、G4 66 KB），上限是位元組、字元還是 token 沒查
- G4（判準：有沒有讀到 diff 檔最後一個檔 `scripts/check-claude-md.sh` 的內容，它從 diff 檔第 971 行開始）：第 1 發 3 個審查者都用 Read 讀到最後一行（1155）；
  第 2 發 4 個審查者用 Read 只讀了前段的 diff（約 310 行，第一段 diff 到第 310 行為止），另外各用 git 撈過 2、3、0、4 次，所以只能說「沒用 Read 讀到整檔內容那段」。兩發都作廢，只供參考
- 實用結論：diff 檔超過約 47 KB 時，審查者不分段讀就可能靜靜少看一截。§3.9 步驟 4 要不要加「diff 檔分段讀」，這次沒改規則
- 下面那支舊統計只看 Read 的**請求**範圍、不看回傳，「讀到第幾行」那欄會高估（例如 G3-hk-2 寫 2000，實際 544）；留著是因為結論 4 的「撈 git 幾次」來自它

### 限制

- **全域規則洩題**：每一發都載入部署版 `~/.claude/CLAUDE.md`，裡面有 G2、G3 修正之後才寫進去的教訓（K2 ← db0af00、K3 ← 713038a，a4ed41f 改寫成現在的措辭、K6 ← ee68e72）。
  試過 `--bare`（要 `ANTHROPIC_API_KEY`，本機沒設）與 `CLAUDE_CONFIG_DIR`（回 `Not logged in · Please run /login`），都避不掉。
  K1、K4、K5 只在片語層級查過沒進全域規則；ee68e72 寫進 §3.5 的「那只證明測試沒跑到被測的東西」跟 K5、K1 的機制相近，「沒被啟發」證明不了
- 新舊同時變了四件事（diff 檔、探索預算、派工指令、層數），量的是**舊實務對新實務的整體差異**；新組審查者 3–4 個、舊組 2 個，命中表的「聯集」欄只能部分分開人數效應
- 父層是 `claude -p`，整發時間含 headless 開機；真實路徑是主對話用 Task 派。舊做法主對話自己分流兩份報告的時間沒量
- 命中由主對話判（判準跑前寫死，未命中但沾邊的列在「參考」）；正確答案是當時的審查者找出來的，答案以外的真問題不算分（這次沒有找到「有出處、沒受污染、只有新組抓到」的例子）
- 重跑 `stats.py` 要有 `<s4>/logs/*.jsonl`、每一發的快照目錄、以及 `~/.claude/projects/` 底下各快照的紀錄；這些都在本機 session 的暫存目錄，session 清掉就重跑不了，`2026-10-24-s4-outputs/` 是當時的輸出
- 每格 n=2，只有 3 個可計分的錯誤；同一批三組同時跑，彼此搶 API 速率，時段效應三組相同但絕對時間會偏高

```python
# 審查者撈 git 幾次；「讀到第幾行」只看 Read 的請求範圍、會高估，實際回傳看 extra_checks.py（用法：python3 -I <本段存成的檔> <s4 工作目錄> <發代號>...）
import glob, json, os, re, sys
s4 = sys.argv[1]
for run in sys.argv[2:]:
    total = sum(1 for _ in open(os.path.join(s4, run.split("-")[0], "diff.txt")))
    pdir = os.path.expanduser("~/.claude/projects/") + re.sub(r"[^A-Za-z0-9]", "-", os.path.realpath(os.path.join(s4, run)))
    out = []
    for j in glob.glob(pdir + "/*/subagents/agent-*.jsonl"):
        meta = json.load(open(j.replace(".jsonl", ".meta.json")))
        if run.split("-")[1] != "old" and meta.get("spawnDepth") != 2: continue
        mx = git = 0; seen = set()
        for ln in open(j):
            o = json.loads(ln); c = (o.get("message") or {}).get("content")
            if o.get("type") != "assistant" or not isinstance(c, list): continue
            for b in c:
                if b.get("type") != "tool_use" or b["id"] in seen: continue
                seen.add(b["id"]); i = b["input"]
                if b["name"] == "Read" and "diff.txt" in i.get("file_path", ""):
                    off = i.get("offset") or 1; lim = i.get("limit") or 2000
                    mx = max(mx, min(total, off + lim - 1))
                if b["name"] == "Bash" and re.search(r"\bgit (-C \S+ )?(diff|show|log)", i.get("command", "")): git += 1
        out.append(f"{mx}/{total} git={git}")
    print(run, out)
```

當天輸出：

```
G2-new-1 ['1010/1010 git=0', '210/1010 git=3', '204/1010 git=1']
G2-new-2 ['545/1010 git=2', '1010/1010 git=1', '600/1010 git=0']
G2-hk-1 ['0/1010 git=0', '0/1010 git=0', '0/1010 git=2']
G2-hk-2 ['0/1010 git=0', '1010/1010 git=0', '0/1010 git=3']
G3-new-1 ['2079/3024 git=1', '1718/3024 git=0', '1642/3024 git=0', '3024/3024 git=0']
G3-new-2 ['1700/3024 git=1', '250/3024 git=1', '1701/3024 git=0']
G3-hk-1 ['0/3024 git=0', '2000/3024 git=0', '0/3024 git=0']
G3-hk-2 ['2000/3024 git=0', '2000/3024 git=0', '0/3024 git=0', '0/3024 git=0']
G4-new-1 ['1155/1155 git=3', '1155/1155 git=4', '1155/1155 git=3']
G4-new-2 ['314/1155 git=2', '310/1155 git=3', '310/1155 git=0', '311/1155 git=4']
G2-old-1 ['0/1010 git=4', '0/1010 git=4']
G2-old-2 ['0/1010 git=4', '0/1010 git=3']
G3-old-1 ['0/3024 git=4', '0/3024 git=5']
G3-old-2 ['0/3024 git=5', '0/3024 git=3']
```

haiku 組的 `0/…` 是沒用 Read 讀 diff 檔：它們用 Bash（`cat … | head`、grep、awk 這類）讀，多半只看一段；各用了幾次沒數。

## 拿掉裁決者的對照（2026-10-24，S5）

計畫在 `docs/designs/2026-10-23-裁決審查-design.md` 的 S5 一節。起因：S4 新做法比舊做法慢 1.9–3 倍、命中沒變多，使用者要「精準度與速度兼具」，選了先量再改規則。
實驗輸入在 `2026-10-24-s5-inputs/`（凍結），結果在 `2026-10-24-s5-outputs/`。快照、diff 檔（`cmp` 核過跟 S4 逐位元組相同）、brief 都跟 S4 一樣。

### 兩組

| 組 | 父 session | 審查者 |
|---|---|---|
| A（dir） | `claude -p --model opus`，就是主對話：先派審查者、派完才讀 diff 檔、等全部回來後自己逐條查證，交回格式同 S4 裁決者 | code-reviewer（opus），父 session 自己決定幾個（≥3） |
| B（dhk） | 同 A | code-reviewer 帶 `model: "haiku"` |

兩組都要求 Read 用 `offset`／`limit` 每次 300 行讀到 diff 檔最後一行（S4 實測不指定範圍會在約 47 KB 靜靜截斷）。一批同時跑同組的 G2、G3 兩發（S4 一批是三發）。

### 原始數字

重跑：`python3 -I 2026-10-24-s5-inputs/stats.py <s5 工作目錄> <發代號>...`（輸出是 `2026-10-24-s5-outputs/stats.jsonl`）。整發、費用的算法同 S4；派工前 = 父 session 開始到第一個審查者開始，收尾 = 最後一個審查者結束到整發結束（父 session 查證、寫報告）；「審查者層最慢」是最慢的單一審查者自己的耗時。費用取父 log 最後一筆 result，最後一輪不一定記進去，會偏低（S4 同一種算法）。

| 發 | 整發 | 費用 US$ | 派工前 | 審查者數 | 審查者層最慢 | 收尾 | 每個審查者的工具次數 |
|---|---|---|---|---|---|---|---|
| G2-dir-1 | 235s | 3.95 | 27s | 3 | 142s | 52s | 6、5、5 |
| G2-dir-2 | 221s | 3.89 | 23s | 3 | 139s | 43s | 5、5、6 |
| G3-dir-1 | 293s | 6.89 | 28s | 4 | 171s | 49s | 8、9、10、9 |
| G3-dir-2 | 327s | 5.78 | 34s | 3 | 226s | 38s | 14、9、14 |
| G2-dhk-1 | 503s | 4.11 | 24s | 3 | 289s | 177s | 4、8、8 |
| G2-dhk-2 | 318s | 1.97 | 29s | 3 | 200s | 62s | 6、6、6 |
| G3-dhk-1 | 529s | 6.49 | 26s | 4 | 198s | 304s | 6、13、13、13 |
| G3-dhk-2 | 359s | 3.53 | 29s | 4（第 4 個是補派） | 111s | 43s | 11、9、11、8 |

- 作廢：沒有。`permission_denials` 全空、最後一筆 result 都是 success、模型斷言全過（父 session opus；A 審查者 opus、B 審查者 haiku）
- ⚠️ **B 組有兩發的父 session 叫了 advisor**（`claude-fable-5-1`，步驟 4 審查抓到；`stats.py` 只看 assistant 訊息的 `message.model`，看不到它）。父 log 最後一筆 result 的 `modelUsage`：`G2-dhk-1` fable 2.10（總 4.11）、`G3-dhk-1` fable 2.90（總 6.49），其餘 6 發沒有。父 session jsonl 裡 `server_tool_use` 到 `advisor_tool_result` 的時間：`G2-dhk-1` 收尾 177s 裡有 88s 在等 advisor、`G3-dhk-1` 收尾 304s 裡有 202s。advisor 的回傳是加密的，看不出它有沒有影響父 session 的判定。S4 `G3-hk-1` 的裁決者也叫了（fable 1.41）。下次實驗作廢檢查要讀 `modelUsage` 的鍵
- `G3-dhk-2` 的第 4 個審查者（`a534fa`）是第一波回來後補派的（父報告 `G3-dhk-2.d0.parent` :11：C 只讀到第 1200 行），表上 111s 只是它自己的耗時；這一發的審查者層實際從 29s 跑到 316s
- 洩題：`G2-dhk-2` 被 `leaky()` 抓到 1 筆，是誤報 —— 審查者在快照裡跑的 `echo "== grep: fallback / segment-base descriptions across repo =="`，`ROOT_ARG` 的 grep 分支吃到 `echo` 字串裡的「 / 」（跟 S4 修過的那類同族，凍結輸入沒改）。
  `checks.py` 的 `cross` 8 發都是 0 筆；`res` 每發 1–3 筆，全是派工說明裡「不准讀 `/Users/`」那句被讀回來（`G2-dhk-1` 的 3 筆是審查者讀了父 session 的說明檔，那是父 session 列給它的允許路徑）。brief 跟 S4 相同；`direct.txt` 對答案句片段與範圍用詞（從未執行到、查不到出處、3 紅、正常流程唯一的覆蓋、pre-commit 不查報告、判準相反、繞過、stash、⑪）`grep -c` 全部 0
- `order`：8 發父 session 的最後報告都晚於所有審查者結束
- 有兩發（`G2-dir-1`、`G2-dir-2`）交出最後一筆 success result 之後 `claude -p` 沒有自己結束，被手動或看門狗結束（exit 143；看門狗是 scratchpad 裡的小腳本，只結束「已交 success result、而且父 log 與所有子代理紀錄 300 秒沒動」的程序）；時間是照紀錄檔時間戳算的，不受影響。原因沒查
- 8 發合計約 US$36.6

### 五組並排（S4 三組 + S5 兩組，每組 G2、G3 各 2 發）

| 組 | 整發 G2 | 整發 G3 | 整發平均 | 費用平均 US$ | K1 | K4 | K5 | 合計（最多 6） |
|---|---|---|---|---|---|---|---|---|
| 舊（2 個 opus 審查者，沒有查證那一步） | 120、104s | 205、185s | 154s | 1.31 | 2/2 | 0/2 | 1/2 | 3 |
| S4 新（裁決者＋opus 審查者） | 339、331s | 359、370s | 350s | 3.83 | 2/2 | 0/2 | 1/2 | 3 |
| S4 haiku（裁決者＋haiku 審查者；G3 第 1 發的裁決者叫了 advisor） | 300、326s | 455、303s | 346s | 1.57 | 2/2 | 0/2 | 1/2 | 3 |
| **A（沒有裁決者＋opus 審查者）** | 235、221s | 293、327s | **269s** | 5.13 | 2/2 | 0/2 | **2/2** | **4** |
| B（沒有裁決者＋haiku 審查者；兩發叫了 advisor） | 503、318s | 529、359s | 427s（扣掉等 advisor 約 355s） | 4.03（扣掉 advisor 約 2.78） | 2/2 | 0/2 | 0/2 | 2 |

命中位置（判準同 S4：同一個位置、同一個機制才算；檔名前綴指 `2026-10-24-s5-outputs/reports/`）：

- K1：A 第 1 發 `G2-dir-1.d1.a1598b` :3（另兩個審查者也報了，父報告 :18 採納）；A 第 2 發 `G2-dir-2.d1.aaf983` :5（父報告 :19 採納）；B 第 1 發 `G2-dhk-1.d1.afd6a8` :3（父報告 :14）；B 第 2 發 `G2-dhk-2.d1.a02989` :5（父報告 :12）
- K5：A 第 1 發 `G3-dir-1.d1.afd4a3` :3（父報告 :25）；A 第 2 發 `G3-dir-2.d1.a6bb48` :3（父報告 :12）。B 兩發都沒抓到：`G3-dhk-2.d1.a36742` :6 判繞過①「與文件一致」，`G3-dhk-1.d1.a10a48` :7 判變異表「match」
- K4：兩組都沒抓到（`G3-dir-1.d1.aa2813` :19、`G3-dhk-2.d1.a36742` :8 都判繞過② 的對照成立）
- 參考（受污染）K6：A 審查者 2/2（`G3-dir-1.d1.ae6a8b` :4、`G3-dir-2.d1.ab20a7` :4）；B 審查者 0/2，兩發都是父 session 自己查到的（`G3-dhk-1.d0.parent` :19、`G3-dhk-2.d0.parent` :17）—— 跟 S4 haiku 組一樣。`G3-dhk-1` 的父報告寫在問完 advisor 之後
- B 組沾邊、判成未命中的：K5 `G3-dhk-1.d1.a10a48` :12（變異讓繞過① 變紅，沒指出它自己抓不到）、`G3-dhk-2.d0.parent` :59；K6 `G3-dhk-1.d1.a91315` :3、`G3-dhk-2.d1.a534fa` :3（§3.5 與 §3.9 的落差，但講的是「載入失敗也算紅」，不是 stash 模式）、`G3-dhk-1.d1.a4b5aa` :3（stash 會連新測試一起藏，是另一個問題）、`G3-dhk-2.d1.af3c3f` :3（判一致）

### diff 檔讀了多少

- `sec1.py`（跑完才補）算每個讀者對 diff 檔第一段（`git diff` 本體，G2 1–203 行、G3 1–249 行）缺幾行，輸出在 `2026-10-24-s5-outputs/sec1.out`：
  - S5 兩組：父 session 與每個審查者都缺 0 行（`direct.txt` 要求讀完全檔，第二段多數沒讀完，所以改用第一段當比較基準）
  - S4 新組：每個審查者缺 0 行（S4 那一節說的截斷發生在第二段整檔內容，第一段都讀到了）
  - S4 haiku 組：13 個審查者裡 9 個沒用 Read 讀第一段（缺 203 或 249 行，可能用 Bash 或 git 看，`sec1.py` 算不到）
  - S4 舊組：都沒讀 diff 檔（派工本來就叫它們用 `git show`）
- 第二段（整檔內容）：G3 的 15 個審查者裡 13 個沒讀完（`checks.py` 全檔缺 777–2684 行），2 個讀完（都在 B 組）；父 session 只有 `G3-dir-2` 沒讀完（缺 1700 行）；G2 每個讀者都讀完全檔。`G3-dhk-2` 的父報告說審查者「回報有讀完」，實際沒有

### 結論

速度的比較只看方向：S4 與 S5 不同時段、批次大小不同（見限制），絕對秒數相減有誤差。

1. **A 比 S4 新做法快、也抓得不比較少**：整發平均 269s 對 350s，可計分命中 4 對 3。多出的 1 個是 K5 第 2 發。n=2、3 個可計分錯誤，**差 1 個分不出是不是真的比較準**
2. **A 比舊做法慢約 1.7 倍、貴約 3.9 倍**，但兩者量的東西不一樣：舊做法的整發時間不含「主對話讀報告、查證」那一步（S4 沒量），A 含（收尾 38–52s）。最慢的單一審查者 A 139–226s、舊組 81–187s，同一個量級
3. **A 比裁決者快的地方**：用同一個量法「整發減最慢的單一審查者」比 —— A 82–122s（派工前 23–34s ＋收尾 38–52s ＋審查者依序開跑的錯開時間 14–46s：同一則訊息平行派，實際每隔約 13–15s 起一個），S4 新組與 haiku 組 132–197s（不含叫了 advisor 的 `G3-hk-1` 297s），舊組 17–23s。省下的這一段來自拿掉裁決者加上派工順序對調（S4 裁決者先讀 diff 再派，A 先派再讀），兩者分不開
4. **B 不划算**：命中最少（2/6，K5 兩發都漏）。扣掉等 advisor 的時間與 advisor 的費用（近似：只扣 `server_tool_use` 到回傳那段與 fable 的錢）後，整發平均約 355s、費用約 2.78 —— 比 A 慢、便宜約 46%。`G3-dhk-2` 還補派了一個審查者。S4 的裁決者沒有補出任何計分命中（S4 結論 5），所以 S4 haiku 組 3/6 對這次 2/6 的差別只能來自派工 prompt 不同或運氣
5. **A 比 S4 新做法貴**（5.13 對 3.83），差額的來源沒拆：S4 的費用已含 opus 裁決者讀 diff 與查證的錢；A 的父 session 是 opus、除了 `G3-dir-2` 都讀完整份 diff 檔

### 限制

- 同 S4 的限制（全域規則洩題、n=2、命中由主對話判、`claude -p` 含開機時間）
- A 跟 S4 新做法比同時變了三件事：拿掉裁決者、要求分段讀、派工順序（S4 裁決者先讀 diff 再派工，`s4-inputs/judge.txt`；A 先派工，`direct.txt`）。S4 新組的 opus 審查者本來就讀完第一段，所以命中的差異不太可能來自分段讀，但沒有實驗證明
- S5 一批同時跑兩發、S4 一批三發，搶 API 速率的程度不同，絕對時間不能直接相減
- S5 跟 S4 不是同一時段跑的
