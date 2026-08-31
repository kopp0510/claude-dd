# diagrams/src — 圖表產生器

上層 `diagrams/` 的 6 張 GIF 由這裡的三支腳本產出；改圖一律改腳本再重跑，不要手改 GIF。

## 檔案

| 檔案 | 產出 |
|---|---|
| `gen_usage.py` | `usage-zh-TW.svg`、`usage-en.svg` — claude-dd 使用流程（7 步迴圈在框 ⑤） |
| `gen_arch.py` | `arch-zh-TW.svg`、`arch-en.svg` — 三層架構（L1 repo → L2 `~/.claude/` → L3 各專案） |
| `gen_loop.py` | `loop-zh-TW.svg`、`loop-en.svg` — 7 步開發迴圈本身（A 做出來 / B 整理它 / C 留下來） |

三支都是零依賴的純標準函式庫 Python，SVG 全部手寫字串組出來，不引入繪圖套件。
中英兩版共用同一份版面座標，只換 `ZH` / `EN` 兩個 dict 的字串。

## 慣例與約束

- **輸出到 cwd**：腳本把 `.svg` 與 `.html` 寫在當下工作目錄，不寫死路徑。
  請在暫存目錄執行，不要在 repo 內跑（產物不進版控，只有 GIF 進）
- **三支的輸出介面一致**：每支都同時產 `.svg` 與同名 `.html`（包裝頁，給 playwright 開）。
  新增腳本照這個形狀 — 只產 `.svg` 會讓下方重出流程第 2 步找不到檔案（2026-08-31 踩過）
- **總循環 7.2 秒**：所有 `animateMotion` 的 `dur` 與 `begin` 必須整除 7.2，
  否則 GIF 接不回去會跳一下。錯開相位一律用**負值** `begin`（正延遲會讓小球停在左上角）
- **風格是 Style 8 Dark Luxury**：色票與字級跟隨
  `~/.claude/skills/tech-diagram-gif/references/style-8-dark-luxury.md`。
  畫布 1440×1080，字級已按該檔的 960 基準 ×1.5 放大
- **字體堆疊含 CJK 後備**（`Songti TC` / `Noto Serif CJK TC` 等），改字體要兩版一起改
- **legend 與實際連線一一對應**：畫面上沒有的線就不要留在 legend

## 完整重出 GIF 的流程

1. 在暫存目錄跑三支腳本 → 得到 6 份 `.svg` 與 `.html`
2. playwright 開 `file://<暫存>/xxx.html`，`pauseAnimations()` 後
   `setCurrentTime(i*7.2/144)` 逐幀截圖，144 幀
3. `ffmpeg -framerate 20 -i f%03d.png -vf "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" -loop 0 out.gif`
4. 抽第 0 幀與第 40 幀比雜湊確認不同（證明動畫真的燒進去），再覆蓋 `../*.gif`

細節見 `tech-diagram-gif` skill；本目錄只保存 claude-dd 自己這 6 張的來源。

## 與上層的關係

`../` 只放成品 GIF（兩份 README 直接嵌）。圖上的文字宣稱（元件數量、迴圈步數、
目錄用途）來自 repo 根目錄的 `DD_PIPELINE_ARCHITECTURE.md` 與 `README`；
那些數字改了，這裡的字串要跟著改並重出 GIF —— **CI 不驗圖片內容，只能靠人記得**。
