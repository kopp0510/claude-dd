# Composition Quality Contract

> Vendored 自 [fireworks-tech-graph](https://github.com/yizhiyanhua-ai/fireworks-tech-graph)（MIT，LICENSE.txt 見上層目錄）。
> **適用範圍**：量化預算表與 layout grammar 供 SKILL.md 第 3 步撰寫時遵循、第 4 步照「產出前檢查清單（Taste Gate）」判定；文末 `validate_svg.py` 驗證指令屬其 Python 管線，不適用本 skill。

This contract applies to every visual style. Style references control color,
typography, material, corner radius, and decorative treatment. They never
weaken geometry or composition quality.

## Official showcase profile

Use `"quality_profile": "showcase"` for official samples and polished delivery
artifacts. The renderer and validator enforce all of these budgets:

| Metric | Showcase limit |
|---|---:|
| Edge crossings | 0 |
| Bridge jumps | 0 |
| Bends on one edge | 2 maximum |
| Bends in the six-node reference topology | 8 maximum |
| Route length / direct Manhattan length | 1.35 maximum |
| Shortest route segment | 16px minimum |
| Node-to-node whitespace | 40px minimum |
| Node-to-container gutter | 20px minimum |
| Edge-label clearance from unrelated geometry | 4px minimum |

The six-node reference topology currently scores 100 with four total bends,
zero crossings, zero bridges, a route-stretch maximum of 1.0, 50px minimum
node spacing, and 20px minimum container gutter.

## 元素數量預算（本 skill 追加，非上游內容）

> 借鏡 [diagram-design](https://github.com/cathrynlavery/diagram-design)（MIT）的 complexity budget。
> 上游 fireworks-tech-graph 只管幾何品質（交叉、折數、間距），不限元素數量；
> 但一張圖塞太多東西時，幾何預算會「達標卻難讀」— 這一節補上數量上限。

| 項目 | 上限 |
|---|---:|
| 節點數 | 9 |
| 連線 / 轉換數 | 12 |
| 強調色（accent）元素 | 2 |
| 分組 / 容器 | 4 |
| 圖上註解框 | 2 |

超過上限時**拆成兩張圖**（總覽 + 細節），不要縮小字級或壓縮間距硬塞。
強調色只給 1–2 個真正的焦點；5 個節點都是重點等於沒有重點。

## 連線可量測規則（本 skill 追加，非上游內容）

> 同上，借鏡 diagram-design（MIT）的 mandatory connector rules。上游 layout grammar
> 第 5、7 條有相同意圖但沒有數字，沒數字就沒法在自檢時判定過或不過。

| 規則 | 數值 |
|---|---:|
| 邊標籤遮罩與其連線之間的**可見**間隙 | 6–10px（遮罩不得碰到線） |
| 同一邊多條連線的相鄰 port 間距 | ≥12px（小節點最低 8px） |
| 平行同向連線的全程間距 | ≥12px |
| N 條線分佈於長度 L 的邊時，第 k 條的位置 | `L * k / (N + 1)` |

另外兩條不帶數字但可直接判定：

1. **標籤遮罩不得被之後才畫的節點蓋住** — 節點在標籤之後上色，重疊處文字會被節點填色切掉，
   看起來像卡在邊框上的碎字。把標籤放在連線行經空白處的那一段。
   （遮罩完全落在節點**內部**是徽章，可接受；落在容器上也可接受，容器先畫。）
2. **連線不得穿過非端點的節點** — 預設繞路。真的無法繞（如橫貫的底部服務列）時：
   該線改虛線 `stroke-dasharray="4,3"` 表示「只是路過、不是互動」，
   標籤移到可見端，箭頭只落在真正的終點。

### 與上表衝突時取嚴

上表「Node-to-node whitespace 40px minimum」是上游 showcase profile 的**不及格線**。
本 skill 的節點間距閘門取嚴用 **80px**（`svg-layout-best-practices.md` 的
Universal Layout Rules「Minimum clearance between components: 80px」）——
SKILL.md 第 3 步與 Taste Gate 只寫 80px，不再出現 40px，避免同一張圖同時判過與不過。

標籤相關的三個數字量的不是同一件事，不可互相取代：遮罩與**自己那條線**的可見間隙 6–10px
（上節）、標籤相對連線的垂直偏移 5–10px（`svg-layout-best-practices.md`）、
邊標籤與**無關幾何**的淨空 ≥4px（上表）。

## Layout grammar

1. Establish containers, their header reservations, and node rows before any
   edge is routed.
2. Keep nodes in a row aligned to the same y coordinate and use consistent
   heights for equivalent semantic roles.
3. Reserve one empty inter-container corridor for cross-layer routes. A route
   may cross a container boundary only through an open gap and must not run on
   top of the border.
4. Route the primary horizontal flow first. Route cross-layer context and
   feedback paths through separate, non-overlapping corridor segments.
5. Use distinct node ports when several edges share a side. Never stack
   multiple arrowheads on one coordinate.
6. Prefer a monotone orthogonal route. If a connection needs more than two
   bends, change the node placement before adding waypoints.
7. Treat every external title, subtitle, tag, side label, edge label, legend,
   footer, and title block as an obstacle with measurable bounds.
8. Keep legends outside business-flow corridors. Use a single horizontal row
   when the canvas has enough width.
9. Fit long single-line node titles to the card width. Do not let text touch or
   cross the node border.
10. If the topology cannot meet the showcase limits, simplify the composition,
    split it into focused diagrams, or explicitly use the standard profile for
    a non-showcase engineering stress artifact.

## Style identity boundary

Styles may vary these properties freely within their own reference:

- background, palette, semantic accent colors;
- font family, title alignment, and typographic hierarchy;
- card fill, border treatment, shadow, glow, and corner radius;
- blueprint title blocks, terminal chrome, or restrained brand details.

Styles must share these structural properties for a direct comparison:

- topology and edge direction;
- row/column alignment;
- port assignment and corridor positions;
- crossing, bridge, bend, stretch, spacing, and gutter budgets;
- semantic SVG roles required by the validator.

Visual effects never create a second business connector. Pencil echoes, rail
casings, critical-path glow, and similar layers use
`data-graph-role="decoration"` with `data-owner`; exactly one ordinary
`data-graph-role="edge"` carries the source, target, route, and arrowhead.

## Validation

Run both gates before delivery:

```bash
python3 scripts/validate_svg.py diagram.svg --check geometry
python3 scripts/validate_svg.py diagram.svg --check composition
```

`scripts/validate-svg.sh` runs both automatically. A successful render without
these gates is still a draft.

Dense legacy diagrams live under `fixtures/stress/`. They preserve routing
pressure cases and are not visual quality references. The public 12-style
showcase keeps a distinct engineering scene for every style. The internal
`fixtures/quality-baseline/` set applies one shared Agent Runtime Architecture
topology to all 11 generator-backed styles; Style 8 remains the static,
AI-authored exception.
