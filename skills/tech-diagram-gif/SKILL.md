---
name: tech-diagram-gif
description: 繪製流程圖、架構圖、走向圖（流量走向動畫），最終交付 GIF。當提到「畫流程圖」「畫架構圖」「走向圖」「流程動畫」「diagram」時自動啟用。不適用於資料視覺化圖表（用 dataviz）或網頁 UI 設計（用 frontend-design）。
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Tech Diagram GIF — 技術圖表繪製與 GIF 匯出

不引入 Python/cairosvg 管線的技術圖表流程：手寫 SVG（依 vendored 風格規範）→ 瀏覽器渲染自檢 → 匯出無縫循環 GIF。
風格規範 vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT，見 LICENSE.txt）；
只收編其 markdown 規範，不引入其 Python/cairosvg/FFmpeg 管線。

## 硬閘門

1. **結構未確認前，不寫任何 SVG** — 先用純文字把節點/分組/連線定案（工作流程第 1 步）。
2. **交付一律 GIF**（使用者硬規則；唯一例外：環境無 ffmpeg 時依第 5 步退化交付 SVG 並附裝法）。
   SVG 是內部原稿：可一併提供，但須說明「對外分享用 GIF」
   （SVG 格式可含 script，收件方有信任成本；本 skill 產的 SVG 零 script，交付前必驗證）。
3. **渲染自檢不可省** — 沒親眼看過渲染結果不得宣稱完成。

## 工作流程

### 1. 結構確認（純文字，不畫圖）

把要畫的內容整理成清單給使用者確認，格式：

```
節點（N）：① 名稱（語意桶）→ ② …
分組（M）：分組名 / 涵蓋節點
連線與語意：A→B 主流程（金）/ C⇢D 條件檢查（虛線）/ 自迴圈…
```

使用者確認或修改 → 定案才進下一步。內容事實（節點名稱、流程順序）不確定時回問，不自行腦補。

### 2. 選風格與動畫模式

| 預設 | 選項 |
|------|------|
| 風格：Style 8 Dark Luxury（`references/style-8-dark-luxury.md`） | Style 2 Dark Terminal（`references/style-2-dark-terminal.md`） |
| 動畫：小球沿線跑（`animateMotion`） | dash 脈衝（`stroke-dashoffset`） |

使用者無明示偏好時用預設，不必多問。

### 3. 手寫 SVG

- 版面規則照 `references/svg-layout-best-practices.md`（間距 ≥80px、正交轉角、標籤偏移、z-order；
  該檔僅取版面規則，其 cairosvg/PNG 匯出段落不適用本 skill）
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
| `file://` 被擋、localhost 逾時 | SVG 包進 HTML 後轉 **base64 data URI** 導航 |
| 無限動畫使 screenshot 逾時 | 先 `svg.pauseAnimations()` 再截圖，並加 `animations: 'disabled'` |
| 換頁後截圖仍逾時 | 瀏覽器殘留狀態所致 — `browser_close` 重開再導航 |
| 動畫是否真的在動 | `setCurrentTime(t)` 定格兩個時間點各截一張，肉眼比對位移 |
| 延遲啟動的球停在畫面左上角 (0,0) | 錯開相位一律用**負值 `begin`**（如 `-3.6s`），不用正延遲 |
| 瀏覽器捲軸被截進畫面（成品出現假捲軸） | 包裝頁 CSS 加 `overflow:hidden`，截圖加 `clip` 限定 SVG 區域，交付前抽查四邊像素應為背景色 |
| 截圖輸出路徑受限 | playwright 只能寫入其 allowed roots（通常是專案根/.playwright-mcp）；截完移出並清理，勿留在 repo |

檢查項：文字無溢出、箭頭不穿節點、標籤不壓線、小球在路徑上且有位移。發現問題 → 改 SVG 重渲染,迴圈至乾淨。

### 5. GIF 匯出

先偵測 `ffmpeg`（`command -v ffmpeg`）：

- **有 ffmpeg**：逐幀定格（`pauseAnimations()` + `setCurrentTime(i*DUR/N)` + 截圖，10fps × 總循環長）→
  ```bash
  ffmpeg -framerate 10 -i f%03d.png \
    -vf "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 out.gif
  ```
  **交付原尺寸，勿為壓檔縮小**（使用者回饋過縮到 1080 寬「有點小張」；1440 寬 72 幀約 400KB 可接受）
- **無 ffmpeg**：退化交付 SVG，明確告知「裝 ffmpeg 後可轉 GIF」（macOS：`brew install ffmpeg`），不硬轉。

### 6. 交付前驗證

- SVG 零 script：`grep -cEi "<script|\bon[a-z]+[[:space:]]*=|javascript:|foreignObject" <svg>` 必須為 0
  （涵蓋事件處理器 on* 與 foreignObject，不只 onload）
- GIF 抽 2 幀（`ffmpeg -fps_mode passthrough -vf "select=eq(n\,K)"`）確認小球位置不同（動畫真的燒進去了）
- 暫存幀目錄清理乾淨
- 交付訊息附：GIF 路徑、開啟方式、SVG 原稿路徑與資安說明一句

## 常見錯誤

| 錯誤 | 正確做法 |
|------|---------|
| 跳過結構確認直接畫 | 硬閘門 1：文字清單定案才動筆 |
| 動畫週期隨意設 | 全部整除同一總循環長，GIF 才無縫 |
| 只驗 `getAnimations()` 不看畫面 | 定格截圖親眼比對（API 只證明在跑，不證明可見） |
| 交付 SVG 給外部收件人 | 一律 GIF；SVG 附資安說明留內部 |
| 截圖留在 repo 根目錄 | 移到暫存目錄並清理 |
| 機器特定路徑寫進產出流程 | 用相對/暫存路徑，保持可攜 |
