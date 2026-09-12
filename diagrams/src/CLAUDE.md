# diagrams/src — 圖表產生器

上層 `diagrams/` 每一張 GIF 在這裡都有可重出的來源；**改圖一律改來源再重出，不要手改 GIF**。
來源分兩類 —— 腳本產生的，與手寫的 SVG。

## 檔案

### 腳本產生（產物不進版控）

| 檔案 | 產出 |
|---|---|
| `gen_usage.py` | `usage-zh-TW.svg`、`usage-en.svg` — claude-dd 使用流程（8 步迴圈在框 ⑤；大工作先用 task-planner 拆段落，寫在右側第 3 則註解） |
| `gen_loop.py` | `loop-zh-TW.svg`、`loop-en.svg` — 8 步開發迴圈本身（A 做出來 / B 整理它 / C 留下來；② 回 ① 的虛線是大工作還有小任務） |
| `gen_planner.py` | `planner-zh-TW.svg`、`planner-en.svg` — 大工作怎麼跑（估段落數 → task-planner 出草稿 → 進度表 → 每一段：小任務、整段 3–8、標 DONE；換 session 照表接手） |

### 手寫 SVG（**來源本身就是 `.svg`，要進版控**）

用 `tech-diagram-gif` skill 畫的，沒有產生器 —— 這裡的 `.svg` 刪掉圖就再也改不了。
檔名與上層 GIF 一一對應。

| 檔案 | 類型 |
|---|---|
| `dd-pipeline-propagation.style-2.svg` | Style 2 Dark Terminal · 循環流動 |
| `style-11-event-transit.svg` | Style 11 Event Transit · 事件流地鐵圖（示範情境） |
| `style-12-ops-pulse.svg` | Style 12 Ops Pulse · 事故排查（示範情境） |
| `motion-build-to-operate.svg` | Style 8 · 建置→營運五幕敘事動畫 |

`dd-pipeline-propagation.gif`（Style 8 · 循環流動）的來源另在
`skills/tech-diagram-gif/scripts/fixtures/sample-flow.svg` —— 它同時是幾何檢查的
測試 fixture，不在此重複一份，改它要一併重跑該 skill 的測試。

三支都是零依賴的純標準函式庫 Python，SVG 全部手寫字串組出來，不引入繪圖套件。
中英兩版共用同一份版面座標，只換 `ZH` / `EN` 兩個 dict 的字串。

## 慣例與約束

- **輸出到 cwd**：腳本把 `.svg` 與 `.html` 寫在當下工作目錄，不寫死路徑。
  請在暫存目錄執行，不要在 repo 內跑（**腳本的**產物不進版控，只有 GIF 進；
  手寫 SVG 是來源不是產物，要進）
- **手寫 SVG 改完要重跑幾何檢查**：
  `python3 ../../skills/tech-diagram-gif/scripts/verify-geometry.py <檔案> --cycle 8.0`。
  這四張的總循環是 8s（`dur` 只有 2s / 4s / 8s），剛好等於腳本預設值，但**還是要明寫** ——
  不寫就等於預設值幫你猜對了，下一張改成別的總循環時不會有任何訊號。
  四份現況皆通過；沒過就不要重出 GIF
- **三支產生器也要跑幾何檢查**：`python3 ../../skills/tech-diagram-gif/scripts/verify-geometry.py <產出的 .svg> --cycle 7.2`。
  連線要畫在 `<defs>` 外、標 `data-role="edge"`、座標只用 M/L（`poly()` 產生），小球的 `<mpath>` 直接指向它 ——
  腳本會先剝掉 `<defs>`、也不認 H/V 簡寫。2026-09-11 以前放在 defs 用 `<use>` 引用，連線數算成 0，
  交叉、折數、穿越檢查全部空轉，輸出卻看不出來
- **`gen_loop.py`、`gen_usage.py` 有 8/31 畫圖時就在的未通過項**（規則多數 8/10 就在 contract 裡，9/7 才有 verify-geometry.py 去量）：
  loop 的框距 32px、容器 gutter 12px、`next` 3 折，usage 的 `p65` 繞路比 1.35、⑦ 在容器外，以及文字溢出。改這兩張只看有沒有**新增**失敗項。
  文字溢出是腳本估算；以渲染後 `getBBox()` 量到的字尾與框右緣距離為準（2026-09-11 四張都 ≥12px）。
  **2026-09-12 起誤報少很多**：腳本改成會讀 SVG 自己 `<style>` 裡的字級，不再把 `.nm` 一律當 20、`.sm` 一律當 15
  （這兩支實際是 15 與 11.5–12，全部高估）。實測 `loop-zh-TW` 的溢出失敗項因此從 1 降到 0
- **`gen_planner.py` 是照檢查腳本畫的，兩版都 0 項不過，改它要維持全過**。三個做法是為了過檢查：
  節點文字的字級只寫在 `font-size` 屬性、CSS 不設（**2026-09-12 之後這條只剩「別兩邊都寫」的意義**：
  腳本已經會讀 `<style>`，優先序跟瀏覽器一樣是 CSS > 屬性 > 內建預設表，所以只寫一邊就不會估錯。
  兩邊都寫時腳本取 CSS、瀏覽器也取 CSS，仍然一致，但人容易改錯邊）；
  九個節點都放進容器（容器外的節點算未通過）；邊標籤底下墊 `data-role="mask"` 的底色塊（沒有的話標籤間隙沒量到，只印警告）。
  分組標題靠右是因為有連線從容器上緣左半邊進來 —— 文字壓線腳本量不到，只能看截圖
- **loop 的 `task`（② 回 ①）與 `next`（⑧ 回 ①）同色同虛線**，legend 合併成一項；再加回 ① 的線要一起改那項文字
- **三支的輸出介面一致**：每支都同時產 `.svg` 與同名 `.html`（包裝頁，給 playwright 開）。
  新增腳本照這個形狀 — 只產 `.svg` 會讓下方重出流程第 2 步找不到檔案（2026-08-31 踩過）
- **總循環 7.2 秒**：所有 `animateMotion` 的 `dur` 必須整除 7.2，否則 GIF 接不回去。
  錯開相位一律用**負值** `begin`（正延遲會讓小球停在左上角）
- **`begin` 不可是該球 `dur` 的整數倍**：球跑完一圈會瞬間跳回起點，若 `begin` 對齊
  `dur`，那個跳躍剛好落在 GIF 的循環接點上，每次循環都看得到「跳一下」。
  驗法：抽第 142、143、0 幀比 PSNR，接點與相鄰幀的差距應 ≤1.5dB
  （2026-08-31 dev-loop 差 2.9、architecture 差 2.94，都是這個原因）
- **路徑短於 ~40px 就不要放球**：球是核心 r4 + 光暈 r8（直徑 16px），框間連線只有
  20px 時球會蓋住箭頭、看起來像「圖被覆蓋」。`gen_loop.py` 的 5 條框間連線因此只留
  箭頭，動畫交給跨組長路徑
- **風格是 Style 8 Dark Luxury**：色票與字級跟隨
  `~/.claude/skills/tech-diagram-gif/references/style-8-dark-luxury.md`。
  畫布 1440×1080，字級已按該檔的 960 基準 ×1.5 放大
- **字體堆疊含 CJK 後備**（`Songti TC` / `Noto Serif CJK TC` 等），改字體要兩版一起改
- **legend 與實際連線一一對應**：畫面上沒有的線就不要留在 legend
- **`gen_usage.py` 框② 的「安裝 7 個步驟」不是迴圈步數**：那是 `install-dd-pipeline.sh`
  自己的步驟數，與 8 步開發迴圈無關。同一張圖上並存兩個數字，改迴圈文案時
  **不要連它一起替換**（2026-08-31 推 8 步時差點誤改）
- **`gen_loop.py` 的 C 組有兩框**（⑦ 沉澱、⑧ 評分）：加減步驟要同時改 `c` 陣列、
  `paths` 的連線與小球 `begin`，並確認 `next` 回起點的線是從最後一框出發

## 完整重出 GIF 的流程

1. 在暫存目錄跑三支腳本 → 得到 6 份 `.svg` 與 `.html`
2. playwright 開 `file://<暫存>/xxx.html`，`pauseAnimations()` 後
   `setCurrentTime(i*7.2/144)` 逐幀截圖，144 幀
3. `ffmpeg -framerate 20 -i f%03d.png -vf "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" -loop 0 out.gif`
4. 抽第 0 幀與第 40 幀比雜湊確認不同（證明動畫真的燒進去），再**照下表逐張覆蓋這 6 個檔名**
   （不要用 `../*.gif` —— 上層有 11 張，其中 5 張是手寫 SVG 出的，不由這個流程產生）：

   | 產出的 SVG | 覆蓋到 |
   |---|---|
   | `usage-en.svg` | `../claude-dd-usage-flow.gif` |
   | `usage-zh-TW.svg` | `../claude-dd-usage-flow.zh-TW.gif` |
   | `loop-en.svg` | `../claude-dd-dev-loop.gif` |
   | `loop-zh-TW.svg` | `../claude-dd-dev-loop.zh-TW.gif` |
   | `planner-en.svg` | `../claude-dd-task-planner.gif` |
   | `planner-zh-TW.svg` | `../claude-dd-task-planner.zh-TW.gif` |

   命名慣例：英文版用無後綴檔名、繁中版加 `.zh-TW`（與 README 同一套）；
   字根對照 usage→usage-flow、loop→dev-loop、planner→task-planner

細節見 `tech-diagram-gif` skill；上面四步是三支腳本那 6 張的做法，手寫 SVG 的圖照該 skill 重出。

## 與上層的關係

`../` 只放成品 GIF（兩份 README 直接嵌）。圖上的文字宣稱（元件數量、迴圈步數、
目錄用途、段落與小任務的規則）來自 repo 根目錄的 `DD_PIPELINE_ARCHITECTURE.md`、`README`、
`templates/global/CLAUDE.md`（§3.9 迴圈、§4.1 估段落數）與 `skills/task-planner/SKILL.md`；那些內容改了，這裡的字串要跟著改並重出 GIF —— **CI 不驗圖片內容，只能靠人記得**。
