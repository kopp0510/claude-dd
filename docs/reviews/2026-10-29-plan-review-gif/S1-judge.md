# S1-judge（主對話查證）— plan-review 流程圖

段落：使用者問「README 有附上 plan review 這圖片流程圖嗎」，答沒有後說「加」。進度表在 `docs/designs/2026-10-29-plan-review-gif-design.md`，段落起點 `f46b73b`，S1-1 是 `6a2bdd3`。計畫經 plan-review 2 輪（第 1 輪不通過 1 條重大：步驟 3、4 改到產生器要重出 GIF；第 2 輪通過）。

## 派工

- 審查範圍：`git diff f46b73b 6a2bdd3`。diff 檔放 session 暫存目錄，組成：整段 diff（GIF 只列 stat）、步驟 3 與審查並行的說明（審 HEAD，被改到的檔用 `git show 6a2bdd3:<路徑>` 讀）、已跑過的驗證與預期值、圖上文字 ↔ `skills/plan-review/SKILL.md` 的對照表
- 步驟 3 的 code-simplifier 與審查並行：只改了 legend 挑箭頭那行（巢狀三元 → 對照表），兩份 SVG sha256 與修改前相同
- 派 3 個 `code-reviewer`（下限）：A 圖上文字 ↔ SKILL.md 原文、B 產生器程式碼與 `diagrams/src/CLAUDE.md` 慣例、C 同步點與文件。圖上每句話都是在「縮短 SKILL.md」，正是 §3.10 說條件最容易被改掉的地方，所以 A 單獨一個方向

## 發現

| 項 | 查證 | 判定 |
|---|---|---|
| A1 「有效審查者不足 3 個」漏了補派 | `sed -n 194,195p skills/plan-review/SKILL.md`：先補派，補完還少於 3 個才「無法判定」 | 採納 Important |
| A2 「什麼算重大」漏 ① 的例外與 ② 的分支 | `sed -n 173,174p`：「金額、權限、刪資料不管多少見都算」「或會跳過使用者的決定」 | 採納 Important |
| A3 讀檔檢查漏「至少」與「最多重派一次」；legend 漏「回錯誤」 | `sed -n 189p`、`sed -n 192p` | 採納 Important |
| A4 通過框「不再問」說成絕對 | `sed -n 100p`：使用者的 CLAUDE.md 要批准時照那邊問 | 採納 Important |
| B1 third 68px 卻用 1.2，與註解的 68px→1.44 不符 | 讀 `gen_review.py` 的 `paths["third"]`：`(mid[3], YS[2]+BH)`→`(mid[3], YS[3]-12)` = 726→794，68px | 採納 Important |
| B2 short 線金色、球灰色，灰色在 legend 是重派 | 讀 `ball("short", GRAY, …)` 與 legend | 採納 Important |
| C Not reported 1：S1-1 缺驗證方式、commit 訊息 | 讀設計文件「段落與小任務」 | 採納 Smell |
| C Not reported 2：摘要把「無法判定」寫在逐條查證之後 | 讀 `diagrams/src/CLAUDE.md` 新列與 CHANGELOG | 採納 Smell |
| 主對話自己 | B 算出 again 1518px／7.2s = 210.8 px/s，其他線約 47–57 px/s；註解寫「dur 大致與路徑長成正比」沒提這條例外 | 採納 Smell |

駁回：無。

需要外部查證：B 問灰球在 GIF 上會不會被讀成重派 —— 球已改金色，問題不存在了。

### 圖上文字 ↔ SKILL.md 對照（修正後）

| 位置 | ZH | EN | SKILL.md 原文行 |
|---|---|---|---|
| 副標 | 腦袋全新的裁決者派人猛攻，再逐條查證 | a fresh adjudicator sends reviewers to attack it | :9 |
| 組名 | 裁決者（Opus，腦袋全新）· 全程唯讀 | Adjudicator (Opus, fresh context) · read-only | :126 |
| ① | 附查到的事實／推測要標明是推測 | with the facts found／guesses marked as guesses | :34 |
| ② | haiku，同一則訊息平行派／可分工，也可都做全面 | haiku, all in one message／split angles or all-round | :141、:142、:144 |
| ③ | 每人至少抽一處它引用的行來讀／對不上就重派，最多一次 | at least one cited line each／mismatch: resend, once at most | :189、:192 |
| ④ | 預設「這條批評可能是錯的」／採納／駁回／需使用者決定 | assume it may be wrong／adopt / reject / ask the user | :197 起 |
| ⑤ | 只問「需使用者決定」的題／你的規則要批准時照樣問 | asks only user-decision items／approval only if your rules ask | :96、:100 |
| ⑥ | 照採納的重大缺失逐條改／改好的全文再送一輪 | fix each adopted major issue／send the full plan again | :63、:66 |
| ⑦ | 改好計畫後停下回報／你選確認輪／繼續／停下 | revise, then stop and report／you pick: confirm / go on / stop | :68、:72 |
| ⑧ | 照實告訴你／問要重跑還是不審直接交 | you are told plainly／rerun, or hand over unreviewed | :117、:118 |
| ③→⑧ | 補派後仍不足 3 個 | still under 3 after backfill | :194–195 |
| ⑥⇢① | 再送一輪（最多 3 輪） | next round (max 3) | :68 |
| ⑥→⑦ | 已是第 3 輪 | already round 3 | :68 |
| ③⇢② legend | 重派：讀檔檢查沒過或回錯誤的審查者 | send again: a reviewer failed the check or errored | :192 |
| 註解 | 複雜任務的計畫…／design-brainstorm 的設計（不論大小） | — | :22 |
| 註解 | 常走的路（金額、權限、刪資料一律算）、照做會錯或跳過你的決定、後面的關卡也抓不到 | — | :172–175 |

行號在 `6a2bdd3` 的 `skills/plan-review/SKILL.md`（這段沒改它）；用 `grep -n -F '<原句>'` 重找。

## 處置

- A1–A4、C 的兩項：照各審查者報告的「處置」節改了 `gen_review.py` 的 ZH／EN 字串、`diagrams/src/CLAUDE.md`、CHANGELOG、設計文件
- B1：third 改 1.44；B2：short 的球改 GOLD
- 主對話那項：註解改成「dur 與路徑長成正比（68px→1.44、88px→1.8、128px→2.4、383px→7.2）」，另寫明 again 約 1518px、dur 上限 7.2 所以球快約 4 倍
- 順手清掉 simplifier 之後 Pyright 報的沒用到的 `c3`
- 改完重跑整條管線：verify-geometry 兩版 exit 0、0 警告、連線 9；getBBox 框內字尾離右緣最小 zh 70px／en 69px、註解右緣最大 344px（< 容器左緣 406）；截圖看過；GIF 各 144 幀、f000≠f040、PSNR 41.09／40.93；零 script grep 0；新 GIF 已覆蓋兩個檔名
- 步驟 6 前重產 SVG，與做 GIF 那份 sha256 比對（結果記在 commit 前的驗證）

## 重疊與獨有項

- 三個審查者沒有重疊項：方向分得開，A 管字、B 管程式、C 管同步點
- A 獨有、也是最重要的：4 處都是「把 SKILL.md 縮短時條件掉了」，正好是 `f46b73b` 剛寫進全域 §3.10 的那條。我自己寫的對照表只對「這句話有沒有出處」，對不出「出處那句還有條件被拿掉」—— 對照表是有出處的檢查，不是條件完整的檢查
- B 獨有：球色與 legend 的對應，幾何檢查與 legend 規則都管不到（只管線）
- C 獨有：摘要文字與圖的結構不一致（只在 Not reported）
