#!/usr/bin/env python3
"""verify-geometry.py 的負面測試 —— 純標準庫，無 pip 依賴。

用法：python3 test-verify-geometry.py

檢查腳本自己會錯，而且錯起來像正常結果：它可能什麼都判通過（漏檢），
也可能什麼都判失敗（假陽性）。所以每一項都要有「弄壞就抓得到」的變異案例，
外加「不該被判失敗」的回歸案例。**改 verify-geometry.py 後務必重跑這支。**

**斷言比對的是 fail 清單，不是整份 stdout。** 早期版本用 `關鍵字 in stdout`，
而 `折` `交叉` `節點` 這些字在「全部通過」的輸出裡也有（它們是區段標題），
於是 `kw in stdout` 恆真 —— 一個根本沒造成交叉的變異，靠別項的連帶失敗
也顯示「✅ 抓到」，掩蓋了「交叉檢查沒有任何有效案例」這個缺口。

實際踩過的坑，都由此處的案例守住：
- 用「座標字串有沒有出現在 svg 裡」猜形狀 → 矩形節點被當菱形，誤報文字溢出
- 第一版漏掉容器 gutter → 節點改寬撞到容器邊界，跑完全綠
- gutter 只算「完全被包住」的節點 → 節點戳出容器反而從 fail 變 pass（越壞越通過）
- 退化猜法寫死 rx="6" / 畫布底色 → 換個風格畫法，節點與遮罩靜默消失，仍印「全部通過」
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
VERIFY = HERE / 'verify-geometry.py'
FIXTURE = HERE / 'fixtures' / 'sample-flow.svg'

# (案例名, fail 清單中應出現的片段, 變異函式)
CASES = [
    ('連線 3 折', '4 折',
     lambda s: s.replace('d="M 1060,242 L 1060,300 L 850,300 L 850,650"',
                         'd="M 1060,242 L 1060,280 L 950,280 L 950,300 L 850,300 L 850,650"')),
    ('繞路比 > 1.35', '繞路比',
     lambda s: s.replace('d="M 330,634 L 330,580 L 650,580 L 650,650"',
                         'd="M 330,634 L 330,500 L 650,500 L 650,650"')),
    ('連線真的交叉', '交叉 [',
     lambda s: s.replace('<!-- ===== 邊標籤',
                         '<path id="e11" d="M 1100,300 L 1300,300" fill="none" '
                         'stroke="#d4a574"/>\n<!-- ===== 邊標籤')),
    ('連線數 > 12', '連線 1',
     lambda s: s.replace('<!-- ===== 邊標籤', ''.join(
         f'<path id="e{20 + i}" d="M {40 + i * 6},960 L {40 + i * 6},1000" '
         f'fill="none" stroke="#d4a574"/>' for i in range(4)) + '<!-- ===== 邊標籤')),
    ('容器數 > 4', '容器/分組',
     lambda s: s.replace('<!-- ===== 連線', ''.join(
         f'<rect x="{20 + i * 8}" y="1030" width="10" height="10" rx="8" fill="none" '
         f'stroke="#d4a574"/>' for i in range(2)) + '<!-- ===== 連線')),
    ('節點間距 < 80px', '節點間距',
     lambda s: s.replace('<rect x="560" y="150" width="340"', '<rect x="450" y="150" width="340"')),
    # 容器左邊界從 150 移到 165：菱形（x1=180）仍在容器內，但 gutter 只剩 15px。
    # 不能移到 195 —— 那會讓菱形越界，報的是越界而不是 gutter，測不到這一項。
    ('容器 gutter < 20px', 'gutter',
     lambda s: s.replace('<rect x="150" y="600" width="1220"', '<rect x="165" y="600" width="1205"')),
    ('節點戳出容器邊界（越壞越通過的回歸）', '越界',
     lambda s: s.replace('<rect x="150" y="600" width="1220"', '<rect x="205" y="600" width="1165"')),
    ('同邊 port 間距 < 12px', 'port',
     lambda s: s.replace('d="M 1060,242 L 1060,300 L 850,300 L 850,650"',
                         'd="M 1060,242 L 1060,300 L 728,300 L 728,650"')),
    ('平行同向連線太近', '平行線',
     lambda s: s.replace('<!-- ===== 邊標籤',
                         '<path id="e12" d="M 430,196 L 560,196" fill="none" '
                         'stroke="#d4a574"/>\n<!-- ===== 邊標籤')),
    ('正值 begin（球停在 0,0）', '正值 begin',
     lambda s: s.replace('begin="-4s"', 'begin="4s"', 1)),
    ('dur 不整除總循環', '不整除',
     lambda s: s.replace('dur="2s"', 'dur="3s"', 1)),
    ('文字溢出菱形斜邊', '文字溢出',
     lambda s: s.replace('CLAUDE.md 同批更新？', 'CLAUDE.md 是否已經在同一批裡更新過了呢')),
    ('連線穿過非端點節點', '穿過節點',
     lambda s: s.replace('d="M 720,650 L 720,320 L 270,320 L 270,226"',
                         'd="M 720,650 L 720,188 L 270,188 L 270,226"')),
    ('標籤遮罩與線的間隙 < 6px', '間隙 4px',
     lambda s: s.replace('<rect x="437" y="152" width="116" height="24"',
                         '<rect x="437" y="160" width="116" height="24"')),
    ('標籤遮罩壓在線上', '壓線',
     lambda s: s.replace('<rect x="437" y="152" width="116" height="24"',
                         '<rect x="437" y="180" width="116" height="24"')),
    ('遮罩被之後才畫的節點蓋掉', '蓋掉',
     lambda s: s.replace('<rect x="452" y="656" width="131" height="24"',
                         '<rect x="560" y="656" width="131" height="24"')),
    # 正規式不在乎 XML 合不合法：重複屬性的檔案照樣能跑完所有幾何檢查印「全部通過」，
    # 而瀏覽器會靜默取後者。實測踩過：虛線連線被第二個 stroke-dasharray 蓋成實線。
    ('重複屬性（XML 不合法）', '重複屬性',
     lambda s: s.replace('<path id="e1" d="M 430,188 L 560,188" fill="none" stroke="#d4a574"',
                         '<path id="e1" d="M 430,188 L 560,188" fill="none" stroke="#d4a574" stroke="#000"')),
    ('未閉合標籤（XML 解析失敗）', 'XML 不合法',
     lambda s: s.replace('</svg>', '<g><rect x="1" y="1" width="2" height="2"/></svg>')),
    ('節點數 > 9', '節點 1',
     lambda s: s.replace('<!-- ⑧ commit 成功 -->', ''.join(
         f'<rect x="{60 + i * 4}" y="{980 + i}" width="30" height="20" rx="6" '
         f'fill="#111111" stroke="#5a9e6f"/>' for i in range(3)) + '<!-- ⑧ commit 成功 -->')),
]

# (案例名, 變異函式, stdout 必須出現的片段)
# 這些是「看起來像壞、其實沒壞」或「換個合法畫法」的情況：必須 exit 0，
# 而且要確認元素數量沒有靜默掉 —— 光看 exit 0 分不出「通過」與「什麼都沒驗到」。
POSITIVE_CASES = [
    ('菱形外框內、形狀外的遮罩（z-order 假陽性回歸）',
     lambda s: s.replace('<!-- ===== 節點',
                         '<rect x="190" y="636" width="100" height="20" '
                         'fill="#0a0a0a" opacity="0.92"/>\n<!-- ===== 節點'),
     '節點 8'),
    ('節點用 rx="10"（icons.md 的語意圖形慣例）',
     lambda s: s.replace('rx="6"', 'rx="10"'),
     '節點 8'),
    ('rect 屬性順序重排（SVG 規格上無意義）',
     lambda s: s.replace('<rect x="200" y="850" width="260" height="68" rx="6"',
                         '<rect height="68" width="260" rx="6" y="850" x="200"'),
     '節點 8'),
    ('漸層畫布（遮罩偵測不得綁底色）',
     lambda s: s.replace('<rect width="1440" height="1060" fill="#0a0a0a"/>',
                         '<rect width="1440" height="1060" fill="url(#glow)"/>'),
     '9 個遮罩'),
    ('節點文字用 <tspan> 包住',
     lambda s: s.replace('>claude-dd repo<', '><tspan>claude-dd</tspan> repo<'),
     '文字 37'),
    # circle/ellipse 節點：Style 11 的 junction 就是 <circle>。先前只認 rect 與
    # polygon，圓形節點整個不算節點，它的間距/溢出/穿越全都沒驗到卻印「全部通過」。
    # 必須先 tag() 再加：只要 SVG 裡出現任何一個 data-role，整份就切換成標記模式，
    # 其餘沒標的元素會全部落空 —— 在未標記的 fixture 上直接插一個帶 role 的節點，
    # 測到的會是「節點 1」而不是圓形有沒有被認得。
    ('圓形節點（Style 11 junction 的畫法）',
     lambda s: tag(s).replace('<!-- ⑧ commit 成功 -->',
                              '<circle data-role="node" cx="700" cy="900" r="30" '
                              'fill="#111111" stroke="#5a9e6f"/>\n<!-- ⑧ commit 成功 -->'),
     '節點 9'),
]

# 只該產生警告、不該判失敗的情況
WARN_CASES = [
    ('斜線段（正交判定不適用）',
     lambda s: s.replace('d="M 430,188 L 560,188"', 'd="M 430,188 L 560,200"'),
     '非正交線段'),
    ('曲線連線（略過但要出聲）',
     lambda s: s.replace('d="M 430,188 L 560,188"', 'd="M 430,188 C 480,160 520,160 560,188"'),
     '略過'),
    # 部分標記比完全不標更危險：只要出現一個 data-role，沒標的元素會被整批略過，
    # 而且是靜默的。實測踩過 —— 在敘事動畫版插了帶 role 的箭頭，節點與容器全歸零。
    ('部分標記（其餘元素被整批略過）',
     lambda s: s.replace('<!-- ===== 節點',
                         '<path data-role="decoration" d="M 10,10 L 20,20"/>\n<!-- ===== 節點'),
     '沒標 data-role'),
]


def run(svg_text):
    tmp = Path(tempfile.mkstemp(suffix='.svg')[1])
    tmp.write_text(svg_text, encoding='utf-8')
    try:
        return subprocess.run([sys.executable, str(VERIFY), str(tmp)],
                              capture_output=True, text=True)
    finally:
        tmp.unlink()


def fail_lines(stdout):
    """只取結尾 fail 清單那幾行 —— 區段標題與通過訊息不算數。"""
    marker = '版面幾何組未通過：'
    if marker not in stdout:
        return []
    tail = stdout.split(marker, 1)[1]
    return [line.strip()[2:] for line in tail.splitlines() if line.strip().startswith('- ')]


def tag(svg):
    """加上 data-role，用來測標記路徑（非退化路徑）。"""
    svg = re.sub(r'(<rect )(x="\d+" y="\d+" width="\d+" height="\d+" rx="6" fill="#111111")',
                 r'\1data-role="node" \2', svg)
    svg = re.sub(r'(<rect )(x="\d+" y="\d+" width="\d+" height="\d+" rx="8" fill="none")',
                 r'\1data-role="container" \2', svg)
    svg = svg.replace('<polygon points="330,634', '<polygon data-role="node" points="330,634')
    svg = re.sub(r'(<rect )(x="\d+" y="\d+" width="\d+" height="24" fill="#0a0a0a")',
                 r'\1data-role="mask" \2', svg)
    return re.sub(r'(<path )(id="e\d+")', r'\1data-role="edge" \2', svg)


def main():
    if not VERIFY.exists() or not FIXTURE.exists():
        print(f'❌ 找不到 {VERIFY} 或 {FIXTURE}')
        return 2
    src = FIXTURE.read_text(encoding='utf-8')
    bad = []

    print(f'{"變異案例（斷言比對 fail 清單）":44} exit  結果')
    print('-' * 72)
    for name, expected, mutate in CASES:
        result = run(mutate(src))
        fails = fail_lines(result.stdout)
        caught = result.returncode == 1 and any(expected in f for f in fails)
        print(f'{name:44} {result.returncode:<5} {"✅ 抓到" if caught else "❌ 沒抓到"}')
        if not caught:
            bad.append((name, result.returncode, f'fails={fails}'))

    print()
    print(f'{"回歸案例（必須通過，且元素沒有靜默消失）":44} exit  結果')
    print('-' * 72)
    for name, mutate, must_have in POSITIVE_CASES:
        result = run(mutate(src))
        ok = result.returncode == 0 and must_have in result.stdout
        print(f'{name:44} {result.returncode:<5} '
              f'{"✅ 未誤報且有驗到" if ok else "❌ 誤報或元素消失"}')
        if not ok:
            bad.append((name, result.returncode,
                        f'缺「{must_have}」；fails={fail_lines(result.stdout)}'))

    print()
    print(f'{"警告案例（不判失敗，但必須出聲）":44} exit  結果')
    print('-' * 72)
    for name, mutate, must_have in WARN_CASES:
        result = run(mutate(src))
        ok = result.returncode == 0 and must_have in result.stdout
        print(f'{name:44} {result.returncode:<5} {"✅ 有出聲" if ok else "❌ 沒出聲"}')
        if not ok:
            bad.append((name, result.returncode, f'stdout 缺「{must_have}」'))

    print()
    # 正向對照：沒被弄壞的檔案必須通過，否則「全部判失敗」也會讓上面全綠
    result = run(src)
    ok = result.returncode == 0
    print(f'正向對照（原檔應通過）              exit={result.returncode}  {"✅" if ok else "❌"}')
    if not ok:
        bad.append(('正向對照', result.returncode, f'fails={fail_lines(result.stdout)}'))

    # 標記路徑：加了 data-role 之後不應再出現退化警告，且仍要通過
    result = run(tag(src))
    ok = result.returncode == 0 and '無 data-role' not in result.stdout
    print(f'data-role 標記路徑                 exit={result.returncode}  {"✅" if ok else "❌"}')
    if not ok:
        bad.append(('data-role 路徑', result.returncode, f'fails={fail_lines(result.stdout)}'))

    print()
    if bad:
        print('❌ 未全過：')
        for name, code, detail in bad:
            print(f'  - {name}（exit={code}）\n    {detail[:220]}')
        return 1
    print(f'✅ {len(CASES)} 種變異全部抓到，{len(POSITIVE_CASES)} 個回歸案例未誤報，'
          f'{len(WARN_CASES)} 個警告案例有出聲，原檔通過，標記路徑正常')
    return 0


if __name__ == '__main__':
    sys.exit(main())
