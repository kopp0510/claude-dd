# S4-judge — 驗證加速與抓錯數

## 派工

主對話給裁決者的派工 prompt 見本 session 紀錄；要點：範圍 `ac8fcfe..HEAD`、diff 檔排除 `2026-10-24-s4-outputs/reports/`、附已確認的驗證輸出與預期值（`test_leaky.py` 11 / 11、CI 第五方 8 ✅、simplifier 沒改檔）、審查者 `code-reviewer` 不帶 model 最少 3 個。

## 發現

裁決者報告原文（逐字）：

````text
## 派工
4 個 code-reviewer（不帶 model），平行：A 程式碼（prepare/stats/run/test_leaky、讀行數腳本）、B 量測數字對 stats.jsonl、C 命中表與參考段引用逐條、D 文件宣稱與計畫落差。
理由：這段的承重在「數字、引用、宣稱」，51 份報告的引用核對量大，獨立一人；程式與文件各一；比最低 3 個多 1 個。
派工 prompt：S4-rev-common.txt + S4-rev-{A,B,C,D}.focus.txt（各報告檔頭有全文）。四個都回來了。

## 裁決者自己的查證（實驗資料其實還在）
s4 工作目錄與 ~/.claude/projects 的紀錄仍在本機（scratchpad/s4/），所以審查者列的外部查證多數我直接查了：
- judge_readcheck2.py（scratchpad）：配對 Read 的 tool_use 與 tool_result，比「請求範圍」與「實際回到第幾行」：
  - G3 不帶 limit 的 Read 實際只回 1–544 行（29136 字元，is_error 為空，沒有錯誤訊息）—— G3-hk-1 aad426、G3-hk-2 a31c92、a6f231 都是 req=2000 got=544；它們後來再用 offset 讀到 1700、1773
  - G2-hk-2 ab8118：請求整檔 1010，實際回 643 行（文件記成 1010/1010）
  - G4-new-1 三個審查者確實讀到檔尾（got 1156）；G4-new-2 四個請求 310–314、回的也是 310–314
  - 同一批紀錄裡別次 Read 存了 40847 字元（G4-new-2 a047f4），所以 544 不是紀錄檔截斷，是工具實際回的
  - offset 是 1-based（offset 1559 回的第一行是 1559），腳本的 off+lim-1 沒差一行
- 洩題掃描（scratchpad 內聯腳本）：14 發所有層的工具輸入，找 `<s4>/` 底下「不是自己快照、不是 prompts/<該發>、不是 <段>/diff.txt（舊組不算）」的路徑與 Bash 裡的裸 `..` —— 0 筆讀別發 log／快照／prompt；命中的 `<s4>/G2`、`<s4>/G3` 都是 `cd …/G3 && … diff.txt`；`..` 全在 mktemp／/tmp 拋棄式目錄裡。舊組 0 次碰 diff.txt
- 3 筆 denial 的發出者（以 tool_use_id 對 meta）：G4-new-1 xzW1pm = spawnDepth 1 general-purpose「G4-new-1-judge」；G4-new-1 pFEo4S = Reviewer A；G4-new-2 uzFDbt = Reviewer D
- total_cost_usd：有多筆 result 的三發（G2-new-2、G3-old-2、G4-new-1）每一筆值都相同（例 3.4035…×2、1.4640…×3），是累計值；duration_ms 各筆不同（6385／11800）
- `git log -S '要記「哪個變異' -- templates/global/CLAUDE.md` → 713038a（10-07）；`'「紅數」本身不是證據'` → a4ed41f（10-09）；713038a 在 b66d8ae 之後
- `git log -S '新功能還沒寫' -- templates/global/CLAUDE.md` → ee68e72；S4-a.md:59 就有 ⑩ 那條；G2-old-1 a594bb:21、G2-old-2 a0166b:16 Not reported 也提 ⑩
- G3-hk-2 judge K6 在 :15（C 寫 :14，差一行）；G3-hk-1、G3-hk-2 的審查者都沒報 K6（aad426:7「不算矛盾」、a31c92:9「未發現矛盾」）
- G2-new-1 judge :22 在第 2 條（:20 ⑩）底下；K1 是 :12
- K5 沾邊原句抽查 G3-new-2 judge:37、G3-hk-1 ae9ad9:9、G3-old-1 a2e1e9:18 都是「從建立 docs/reviews/ 那個 commit 起連鎖紅（含繞過①）」
- 量測文件找 brief 洩題 grep 結果、答案對程式碼位置：`grep -n 'brief\|答案先對\|答案片段'` 0 筆

## 採納
1. A3＋B2＋B3＋D4｜Important｜「讀到第幾行」量的是請求範圍，文件的結論是錯的
   - 量測文件「大 diff 讀不讀得完」段（repo :200–203）、當天輸出（:246–262）、設計文件開放問題第 2 條（:118）
   - 查證：見上，G3 不帶 limit 的 Read 實際回 544 行而不是 2000；G2-hk-2 ab8118 只回 643／1010。「Read 不指定範圍時最多讀 2000 行」「3 個停在第 2000 行」在這批資料裡不成立；G4 第 1 發讀到檔尾成立；G4 第 2 發「4 個只讀前段」只對 Read 成立（他們 git 撈了 2、3、0、4 次）
   - 改法：腳本改成配對 tool_result 取實際最大行號（或附 judge_readcheck2.py 的邏輯），當天輸出重跑；文字改成「不帶 limit 的 Read 對 3024 行／25 萬位元組的檔只回前 544 行、沒有錯誤訊息」；G4 第 2 發改「沒用 Read 讀到整檔內容那段（git／sed 沒算）」；設計文件開放問題同批改
   - 不採納其中的機制推測：D、A 說「超過 token 上限會整次報錯、0 行」——實際是截斷、無錯誤
2. A2＋D3b｜Important｜量測文件 :165「工具結果另外掃 /Users/…每一發只剩 1–2 筆」沒有程式；設計文件 :69 計畫寫掃「結果」、r2 處置寫「輸入」、stats.py 只掃輸入
   - 改法：把那段掃描附進文件（像讀行數那支），或改寫成「另跑、未保存」；設計文件 S4 節標「實跑時改的」
3. A1＋D1｜Important｜leaky() 把整個 `<s4>` 放行、LEAK 不認裸 `..`，與派工單禁「{S4} 底下別的東西」不一致；r3 第 4 條採納了「別發 log 會被放行」，處置說全部寫進設計文件，但檢查沒做
   - 查證：我的補掃 0 筆越界（見上），所以「沒有洩題」的結論這次站得住，但文件的檢查涵蓋範圍說過頭
   - 改法：inputs/ 是凍結的，不改 stats.py；量測文件寫明 leaky() 的涵蓋缺口，並附補掃腳本與結果（0 筆）
   - 駁回其中一句：A 說「舊組讀了 diff.txt」——補掃舊組 0 次碰 diff.txt
4. D3（a,c,d,e,f,g）＋C4｜Important｜設計文件 S4 節「跑之前寫死」的做法，實跑偏離或沒做的沒有標
   - a 整發改用時間戳（stats.py 註解有理由，設計文件 :334 沒改）；c G4 計畫 1 發、實跑 2 發；d brief 洩題 grep 結果沒附進量測文件（0 筆）；e 「答案先對到程式碼」沒寫；f G4 判準只用了 Read 範圍；g total_cost_usd 涵蓋沒附核對（我查了：多筆 result 值相同，是累計）
   - C4：量測文件限制段「未命中但沾邊的列在『參考』」與設計文件 :345 要求列原句，但 K5 三格（G3-new-2、G3-hk-1、G3-old-1）的沾邊原句沒列；C 給的原句我抽查 3 處屬實
   - 改法：S4 節逐條加「（實跑時改的：…）」或「沒做」；參考段補 K5 沾邊原句
5. C2｜Important｜K6 參考段「6 發每一發都有人抓到」與結論 5「K6 在 G3-hk-1 是裁決者自查補上的」—— haiku 組兩發的審查者都沒報 K6，兩發都是裁決者自查（G3-hk-1 judge :17、G3-hk-2 judge :15）
   - 影響結論 3（haiku 審查者沒少抓）與結論 5（裁決者作用）的敘述，雖然 K6 不計分
   - 改法：K6 寫「審查者聯集：新 2/2、haiku 0/2、舊 2/2；haiku 兩發都由裁決者自查補上」；結論 3、5 同批補
6. C1（含 C5）｜Important｜限制段「新做法多抓到的真問題（G2 的 ⑩、G3 的 §3.5 對新功能沒有判準）」兩例都不成立：⑩ 在當時的正確答案 S4-a.md:59 就有、舊組也看到；§3.5 新功能那句源自 ee68e72（污染），G3-new-2 ae16a9:11 審查者自己承認
   - 改法：刪掉這個括號，或換成查得到出處、沒污染、只有新組抓到的例子並附位置
7. B1＋D2｜Smells（兩人標 Important，我降級：G4 本來就作廢、不計命中，「不重跑」的決定在兩層都會這樣測的情況下仍成立）｜:162「3 筆都是審查者」錯，1 筆是 G4-new-1 裁決者
   - 改法：「2 筆審查者、1 筆裁決者查證時」
8. C3＋D7｜Smells（兩人標 Important，我降級：參考列不計分，沒有結論依賴它）｜K3 參考：G2-new-1 judge :22 屬第 2 條 ⑩ 不是 K1；G2-hk-1 judge :19 的機制是「沒寫插在哪一行」，G2-old-1 a594bb:8 是「沒記哪個變異」，都不是 K3 原句（S4-a.md:40，寫死紅數、耦合斷言數）的機制；另 G2-new-2 ab6459:32、G2-hk-2 a21bd9:17 在 Not reported 也沾到
   - 改法：K3 照原句描述，這幾處改列「沾邊」，引用改 judge :20–22
9. D5｜Smells（D 標 Important，我降級：污染結論不變，a4ed41f 確實是文件引的那句片語的來源）｜K3 最早寫進全域規則是 713038a，a4ed41f 是改寫
   - 改法：「K3 ← 713038a（a4ed41f 改寫成現在的措辭）」，設計文件 :313 與量測文件 :208 同批
10. D6｜Smells（D 標 Important，降級：「主要」在數字上成立，只是措辭）｜結論 1「剩下的是…派工、等待、逐條查證」—— rev_max_s 是單一審查者自己的耗時，剩下的含審查者沒同時開跑的空檔
    - 改法：刪「等待」，寫「剩下的含裁決者自己的工作，以及審查者開跑時間的空檔（沒拆）」
11. D4 末項｜Smells｜:262「haiku 組的 0/… 多半是用 Bash 的 sed／cat 讀」—— 實查是 `cat … | head`、grep、awk，多半只看一段，「多半」也沒數
    - 改法：列實際指令型態，或寫「沒統計」

## 駁回
- A1 子項「舊組讀了 diff.txt、檢查抓不到」：補掃舊組 0 次碰 diff.txt
- A4／D4 的機制推測「超過 token 上限整次報錯、0 行」：tool_result 是截斷內容、is_error 空
- B Not reported／A 外部查證「total_cost_usd 是否累計」：查了，多筆 result 值相同，不是問題（但文件沒附，併入採納 4g）
- A 外部查證「offset 0/1-based」：1-based，腳本正確

## 需使用者決定
無（inputs/ 凍結不改，依 inputs/CLAUDE.md「要改實驗就另開新目錄」，修正走文件＋附補充腳本）

## 需要外部查證
- 父 session 紀錄第一個時間戳在 headless 開機前或後（影響「整發含 headless 開機」那句；沒查）
- 544 行截斷的成因（字元或 token 上限）：推論，未查文件

## 結論
Critical 0 / Important 6 / Smells 5
````

## 處置

- 採納 1–6（Important）全部修掉，7–11（Smells）照改，都在 1e209ef；不需使用者決定
- 主對話另外核過：Read 配對腳本重跑結果相同（G3 截斷在 544 行、G2-hk-2 在 643 行）；被擋那筆 xzW1pm 的 meta 是 general-purpose（裁決者）；費用在多筆 result 間相同；K5 三條沾邊原句與 K6 haiku 審查者沒報都用 sed／grep 印過
- 需要外部查證的兩項（父 session 第一個時間戳在 headless 開機前或後、截斷上限的單位）沒查，量測文件已寫「沒查」

## 重疊與獨有項

- 讀行數錯：A3、B2、B3、D4 都報
- 洩題範圍窄：A1、D1；工具結果掃描沒程式：A2、D3b
- denial 不全是審查者：B1、D2；K3 參考列：C3、D7
- 獨有：C1、C2、C4、C5（命中表引用，只有 C 逐條核）；D3、D5、D6（計畫與實跑落差，只有 D 對計畫）
