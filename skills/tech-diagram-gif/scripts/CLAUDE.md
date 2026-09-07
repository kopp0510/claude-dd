# tech-diagram-gif / scripts

Taste Gate「版面幾何」組的判定工具。這一層存在的理由：那組檢查項的判定手段是
**讀座標算術**，不是看截圖 —— 6–10px 的間隙、1.35 的繞路比、菱形斜邊上的文字溢出，
縮到瀏覽器視窗後肉眼都分辨不出來，憑印象打勾等於沒有閘門。

## 關鍵檔案

| 檔案 | 用途 |
|---|---|
| `verify-geometry.py` | 讀一份 SVG，驗數量預算、折數、繞路比、交叉、穿越節點、節點間距、容器 gutter、同邊 port 間距、動畫週期、文字溢出。exit 1 表示未通過 |
| `test-verify-geometry.py` | 上者的負面測試：9 種變異各自弄壞一項，確認都抓得到；外加正向對照與 data-role 路徑 |
| `fixtures/sample-flow.svg` | 測試用的真實圖（claude-dd 傳播路徑圖的中間產物），8 節點 / 10 連線 / 3 容器，含一個菱形節點與 SMIL 動畫 |

## 此層約束

- **純標準庫，不得引入 pip 依賴**。SKILL.md 承諾「不引入 Python/cairosvg 渲染管線」，
  這裡是唯一的 Python，只做座標算術；一旦需要 `pip install` 就違反了 claude-dd
  「不塞 runtime 依賴」的原則（見 repo 根目錄 CLAUDE.md 的收編檢查清單第 4 項）
- **改 `verify-geometry.py` 後必須重跑 `test-verify-geometry.py`**。檢查腳本自己會錯，
  而且錯起來像正常結果 —— 可能全判通過（漏檢），也可能全判失敗（假陽性）。
  實際踩過兩次：用「座標字串有沒有出現在 svg 裡」猜形狀，把矩形節點當成菱形而誤報
  三處文字溢出；第一版整個漏掉容器 gutter 這項，跑完全綠，是節點改寬撞到邊界才被人眼發現
- **新增檢查項時，同批補一個變異案例進 `CASES`**。沒有負面測試的檢查項等於沒寫
- 辨識元素優先讀 `data-role`（`node` / `container` / `edge`）；無標記時退化用畫法猜
  並印警告 —— 猜錯是靜默漏檢，所以 SKILL.md 第 3 步要求新圖一律標 `data-role`

## 與上層的關係

`../SKILL.md` 第 4 步呼叫本目錄的 `verify-geometry.py`，**先跑腳本再看截圖**；
腳本涵蓋「版面幾何」組全部項目，截圖只判它算不出來的（文字擠行、假捲軸、小球位移）。
數值上限的唯一來源是 `../references/composition-quality-contract.md`，
本目錄的 `LIMITS` 是那張表的程式化副本 —— 改上限要兩邊同步，contract 為準。
