---
name: tech-diagram-gif
description: 繪製流程圖、架構圖、走向圖（流量走向動畫），最終交付 GIF。當提到「畫流程圖」「畫架構圖」「走向圖」「流程動畫」「diagram」時自動啟用。不適用於資料視覺化圖表（用 dataviz）或網頁 UI 設計（用 frontend-design）。
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Tech Diagram GIF — 技術圖表繪製與 GIF 匯出

不引入 Python/cairosvg **渲染管線**的技術圖表流程：手寫 SVG（依 vendored 風格規範）→ 瀏覽器渲染自檢 → 匯出無縫循環 GIF。
渲染與匯出全程靠瀏覽器與 ffmpeg，不裝 cairosvg / Pillow 等套件；`scripts/verify-geometry.py`
是唯一的 Python，純標準庫、無 pip 依賴，只做座標算術，缺 python3 時退化為人工計算，不阻擋出圖。
風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT，見 LICENSE.txt）；
只收編其 markdown 規範，不引入其 Python/cairosvg/FFmpeg 管線。

## 硬閘門

1. **先判斷該不該畫** — 動筆前問一句：讀者從這張圖學到的，會比從一段文字或一張表格多嗎？
   不會就別畫，直接寫清楚。純清單、簡單前後對照、單一形狀的「圖」一律退回文字。
   使用者明確指定要圖時跳過此閘門，但仍可提一句更省的做法（提一次，不反覆）。
2. **結構未確認前，不寫任何 SVG** — 先用純文字把節點/分組/連線定案（工作流程第 1 步）。
3. **交付物只有 GIF**（使用者硬規則）。SVG 僅為中間產物：GIF 產出並驗證後**即刪除，
   不留在交付目錄**。唯一例外：環境無 ffmpeg 時依第 5 步退化交付 SVG 並附裝法與資安說明
   （SVG 格式可含 script，收件方有信任成本；本 skill 產的 SVG 零 script，交付前必驗證）。
4. **渲染自檢不可省** — 沒親眼看過渲染結果不得宣稱完成。

## 工作流程

### 1. 結構確認（純文字，不畫圖）

把要畫的內容整理成清單給使用者確認，格式：

```
節點（N）：① 名稱（語意桶）→ ② …
分組（M）：分組名 / 涵蓋節點
連線與語意：A→B 主流程（金）/ C⇢D 條件檢查（虛線）/ 自迴圈…
```

清單交出去前先過下方 Taste Gate 的「**結構清單**」組 —— 數量上限在這一步就數得出來
（節點／連線／分組三個數字見該組，本節不複製），此時超標只要改清單；
等到第 4 步才發現，只能整份重來。
使用者確認或修改 → 定案才進下一步。內容事實（節點名稱、流程順序）不確定時回問，不自行腦補。

### 2. 選風格與動畫模式

| 風格 | 檔案 | 何時用 |
|------|------|--------|
| **Style 8 Dark Luxury（預設）** | `references/style-8-dark-luxury.md` | 架構、流程、資料流、拓撲 — 通用首選 |
| Style 2 Dark Terminal | `references/style-2-dark-terminal.md` | 開發者風格；**UML 類（ER/時序/狀態機/use case）優先用此** — Style 8 深底吃 UML 細節與人形，比較表也不適合 |
| Style 11 Event Transit | `references/style-11-event-transit.md` | 事件流/串流拓撲（Kafka/Pulsar/NATS、消費者群、DLQ）— 提到「事件流」「地鐵圖」「Kafka 拓撲」時用 |
| Style 12 Ops Pulse | `references/style-12-ops-pulse.md` | 事故排查/SLO review（golden signals、critical path、trace 瀑布）— 提到「事故圖」「golden signals」「reliability」時用 |

動畫兩種模式（詳見 `references/motion-narrative.md`）：

- **循環流動（預設）**：小球沿線跑（`animateMotion`）或 dash 脈衝
- **建置 → 營運（敘事）**：開場無連線 → 逐條畫入 → 營運流動 → 淡出循環 — 對外展示/README hero 用

使用者無明示偏好時用預設，不必多問；圖型落在特定風格的甜蜜區時主動建議換風格（一句話，不反覆）。

### 3. 手寫 SVG

- 版面規則照 `references/svg-layout-best-practices.md`（間距 ≥80px、正交轉角、標籤偏移、z-order；
  該檔僅取版面規則，其 cairosvg/PNG 匯出段落不適用本 skill）
- 節點複雜或含 DB/佇列/使用者/決策時，用 `references/icons.md` 的語意圖形
  （DB 圓柱、佇列管、LLM 雙框、Agent 六角形、User 人形、決策菱形、文件摺角）取代一律圓角矩形
- 量化預算三組 —— showcase profile 表（交叉／折數／繞路比／間距）、「元素數量預算」、
  「連線可量測規則」—— **數字全在 `references/composition-quality-contract.md`，本節不複製**。
  撰寫時開那張表照著寫，操作用的逐項版本見下方 Taste Gate；兩處不符一律以 contract 為準。
  超出 → 調節點位置，或拆成總覽 + 細節兩張；不縮字級、不壓間距硬塞
- 節點間距 80px vs 40px、標籤三個間隙數字各量什麼 —— 裁決與說明見 contract
  「與上表衝突時取嚴」節，不要自行挑一個用
- **節點、容器、連線、標籤遮罩一律加 `data-role`**（`node` / `container` / `edge` / `mask`）
  —— `scripts/verify-geometry.py` 優先讀這個標記；沒有標記時它會退化用畫法猜並印警告，
  猜錯就是靜默漏檢（實測踩過：矩形節點被當成菱形而誤報溢出；漸層畫布讓兩項遮罩檢查
  一起空轉卻印「全部通過」）
- 版面順序與走廊：先排容器與列才排線、保留跨層走廊、legend 不進流程走廊
- 色票/節點語意色桶照所選風格檔；畫布建議 `viewBox 0 0 1440 1080` —
  **注意風格檔的字級/間距以 960 寬為基準，用 1440 畫布時需等比放大（約 ×1.5）**
- **字體堆疊必含跨平台 CJK 後備**（以本段為準，覆蓋風格檔的 PingFang SC）：
  襯線 `Georgia,'Times New Roman','Songti TC','Noto Serif CJK TC',serif`、
  無襯線 `-apple-system,'Helvetica Neue','PingFang TC','Noto Sans CJK TC',sans-serif`
  （macOS 已驗證；Linux 走 Noto 後備，未實測）
- 小球規則：核心 r4 + 光暈 r8 opacity 0.22、顏色跟隨箭頭語意、**等速**（dur ∝ 路徑長）、
  長路徑放 2 顆錯開半週期
- **所有動畫 dur 與 begin 必須整除同一個總循環長**（如 7.2s）— GIF 才能無縫循環
- dash 脈衝模式：實線疊亮色 `stroke-dasharray: 7 41` 動 `stroke-dashoffset`；位移量須為 dasharray 週期整數倍

### 4. 渲染自檢迴圈

用 playwright MCP 渲染並親眼檢查，已知陷阱與對策：

| 陷阱 | 對策 |
|------|------|
| `browser_navigate` 擋 `file://`（回 `Access to "file:" protocol is blocked`）、localhost 逾時 | 單張看圖：SVG 包進 HTML 後轉 **base64 data URI** 導航（實測可行）。**多幀連拍改走下一列**，別把整份 HTML 編碼成字串傳來傳去 |
| 逐幀截圖要反覆換頁 / 讀本機檔 | 用 `browser_run_code_unsafe`，裡面的 `page.goto('file://…')` **不受工具層的 file 封鎖**（限制在 MCP 工具層，不在瀏覽器）。同一次呼叫可跑完整個 144 幀迴圈 |
| `run_code` 裡拿不到 `fs` | `require` 回 `require is not defined`，`import('node:fs')` 回 `ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`。要讀本機檔一律靠 `page.goto('file://…')`，不要嘗試在 code 裡讀檔 |
| 無限動畫使 screenshot 逾時 | 先 `svg.pauseAnimations()` 再截圖，並加 `animations: 'disabled'` |
| 換頁後截圖仍逾時 | 瀏覽器殘留狀態所致 — `browser_close` 重開再導航 |
| 動畫是否真的在動 | `setCurrentTime(t)` 定格兩個時間點各截一張，肉眼比對位移 |
| 延遲啟動的球停在畫面左上角 (0,0) | 錯開相位一律用**負值 `begin`**（如 `-3.6s`），不用正延遲 |
| 瀏覽器捲軸被截進畫面（成品出現假捲軸） | 包裝頁 CSS 加 `overflow:hidden`，截圖加 `clip` 限定 SVG 區域，交付前抽查四邊像素應為背景色 |
| 截圖輸出路徑受限 | `browser_take_screenshot` 只能寫入其 allowed roots（通常是專案根/`.playwright-mcp`）；截完移出並清理，勿留在 repo。`run_code` 裡的 `page.screenshot({path})` 可直接寫任意路徑（實測寫進 scratchpad 成功），連拍時用這條 |

檢查項一律走下方「**產出前檢查清單（Taste Gate）**」中標示為第 4 步的兩組，逐項打勾，不憑印象。
**先跑腳本、再看截圖**：

```bash
python3 "$HOME/.claude/skills/tech-diagram-gif/scripts/verify-geometry.py" <diagram.svg> [--cycle 8.0]
```

它涵蓋「版面幾何」組**除了「強調色元素 ≤2、註解框 ≤2」以外的全部項目**
（哪個顏色算 accent 無法通用判定，那一項人工數），並印出實際數值（不只 pass/fail）；
exit 1 表示未通過，結尾會列出它自己沒涵蓋的項目。
腳本過了才進渲染，看截圖只判它算不出來的東西（見「渲染實況」組）。
**改動這支腳本後必須重跑 `scripts/test-verify-geometry.py`** —— 檢查腳本自己會錯，
而且全判通過與全判失敗看起來都像正常結果（細節見 `scripts/CLAUDE.md`）。
發現問題 → 改 SVG 重渲染，迴圈至全部通過為止。

### 5. GIF 匯出

先偵測 `ffmpeg`（`command -v ffmpeg`）：

- **有 ffmpeg**：逐幀定格（`pauseAnimations()` + `setCurrentTime(i*DUR/N)` + 截圖，**20fps** × 總循環長）→
  ```bash
  ffmpeg -framerate 20 -i f%03d.png \
    -vf "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 out.gif
  ```
  - **fps 用 20（或 25），不用 10**：10fps 小球每格跳動明顯，使用者回饋「卡卡的」；GIF 幀延遲單位
    是 1/100 秒，fps 須整除 100，且 50fps 會被多數播放器強制放慢，20/25 是流暢與相容的平衡
  - 幀數多時分兩段 `run_code` 截（單次呼叫有逾時上限）
  - **交付原尺寸，勿為壓檔縮小**（使用者回饋過縮到 1080 寬「有點小張」；1440 寬 144 幀約 700KB 可接受）
- **無 ffmpeg**：退化交付 SVG，明確告知「裝 ffmpeg 後可轉 GIF」（macOS：`brew install ffmpeg`），不硬轉。

### 6. 交付前驗證

- SVG 零 script：`grep -cEi "<script|\bon[a-z]+[[:space:]]*=|javascript:|foreignObject" <svg>` 必須為 0
  （涵蓋事件處理器 on* 與 foreignObject，不只 onload）
- GIF 抽 2 幀（`ffmpeg -fps_mode passthrough -vf "select=eq(n\,K)"`）確認小球位置不同（動畫真的燒進去了）
- 暫存幀目錄與中間產物 SVG 清理乾淨（交付目錄只留 GIF）
- **成品輸出到使用者專案的當下目錄 `./diagrams/`**（使用者硬規則，不放 /tmp 揮發區）；
  目錄不存在時 `mkdir -p ./diagrams` 自動建立；
  該目錄若在 git repo 內且未被追蹤，提醒一句可加入 .gitignore 或自行 commit，不代決定
- 交付訊息附：GIF 路徑與開啟方式（退化交付 SVG 時才附資安說明）

## 產出前檢查清單（Taste Gate）

把散在各步的檢查項收攏成一張表，不是新規則；每項括號指回本文出處。
數字以 `references/composition-quality-contract.md` 為準，下列各項若與該檔不符，以該檔為準。
**每組的打勾時機與判定手段寫在組名後面** —— 一項若要到後面的步驟才有素材可判，它就不屬於前面那組；
反過來，能在第 1 步用文字清單數出來的，不要拖到第 4 步才發現。

**該不該畫**（第 1 步動筆前 · 判斷題）
不過 → 退回文字或表格，不畫。使用者明確指定要圖時此組視為通過。

- [ ] 這張圖比一段文字或一張表格帶給讀者更多？
  （硬閘門 1；使用者已指定要圖時視為通過，可提一次更省的做法，不反覆）

**結構清單**（第 1 步 · 數文字清單即可判定）
不過 → 改清單並重新送使用者確認，不要帶著超標的結構進第 3 步。
（節點刪減兩問借鏡 diagram-design，MIT）

- [ ] 節點 ≤9、連線 ≤12、分組 ≤4？超過即拆成總覽 + 細節兩張
  （composition-quality-contract「元素數量預算」）
- [ ] 有沒有哪個節點可以刪掉，讀者仍看得懂？
- [ ] 有沒有兩個節點總是一起出現，該併成一個？
- [ ] 結構清單已被使用者確認或修改定案？（硬閘門 2）

**版面幾何**（第 4 步 · 跑 `scripts/verify-geometry.py`，**不是用眼睛看**）
不過 → 改 SVG 重渲染，不進 GIF 匯出。這些數值在縮到瀏覽器視窗後肉眼分辨不出來，一律用算的。

- [ ] 0 交叉、每邊 ≤2 折、繞路比 ≤1.35、節點間 ≥80px、容器 gutter ≥20px？
- [ ] 強調色元素 ≤2、註解框 ≤2？
- [ ] 邊標籤遮罩與其連線之間留 **≥6px** 可見間隙，遮罩沒有壓到線？（6 是下限，不是區間）
- [ ] 同一邊多條連線各有自己的 port，相鄰 ≥12px（小節點最低 8px）？
- [ ] 標籤遮罩沒有被之後才畫的節點蓋掉？（z-order：節點在標籤之後上色）
- [ ] 連線沒有穿過非端點的節點（不可避免時改虛線，標籤移到可見端）？
- [ ] 所有動畫 dur 與 begin 整除同一總循環長？（第 3 步）
- [ ] 錯開相位用負值 `begin`，沒有球會停在 (0,0)？
- [ ] 文字沒有溢出節點邊界？**非矩形節點（菱形、六角形）肉眼判不出來** ——
  斜邊上可用寬度隨 y 收窄，腳本用掃描線算實際邊界；臨界時在渲染階段用 `getBBox()` 複驗

**渲染實況**（第 4 步 · 看截圖判定）
不過 → 改 SVG 重渲染，不進 GIF 匯出。
（視覺冗餘兩問借鏡 diagram-design，MIT）

- [ ] 箭頭不穿節點、標籤不壓線、節點內文字沒有擠成兩行黏在一起？
- [ ] legend 在流程走廊外？
- [ ] 定格兩個時間點截圖比對過，小球確實有位移？
- [ ] 四邊像素為背景色（沒有把瀏覽器捲軸截進畫面）？
- [ ] 有沒有哪條連線是版面已經講清楚的、哪個標籤是顏色或形狀已經表達過的，可以刪？
  **只刪視覺元素，不動節點集合**；要增刪節點得回第 1 步重新確認，不自行改定案結構

**交付**（第 5、6 步做完才勾）

- [ ] SVG 零 script 檢查通過？（第 6 步）
  **不過 → 改 SVG 並重出 GIF**，這是交付組唯一會逼你回頭的項目
- [ ] 暫存幀與中間產物已清理、成品在 `./diagrams/`、原尺寸未壓縮？（第 6 步）
  不過 → 補做該步驟，不必改 SVG

---

## 常見錯誤

| 錯誤 | 正確做法 |
|------|---------|
| 跳過結構確認直接畫 | 硬閘門 2：文字清單定案才動筆 |
| 動畫週期隨意設 | 全部整除同一總循環長，GIF 才無縫 |
| 只驗 `getAnimations()` 不看畫面 | 定格截圖親眼比對（API 只證明在跑，不證明可見） |
| 交付 SVG 給外部收件人 | 一律 GIF；SVG 附資安說明留內部 |
| 截圖留在 repo 根目錄 | 移到暫存目錄並清理 |
| 機器特定路徑寫進產出流程 | 用相對/暫存路徑，保持可攜 |
