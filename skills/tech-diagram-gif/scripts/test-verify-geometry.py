#!/usr/bin/env python3
"""verify-geometry.py 的負面測試 —— 純標準庫，無 pip 依賴。

用法：python3 test-verify-geometry.py

檢查腳本自己會錯，而且錯起來像正常結果：它可能什麼都判通過（漏檢），
也可能什麼都判失敗（假陽性）。所以每一項都要有「弄壞就抓得到」的變異案例，
外加一個「原檔必須通過」的正向對照。**改 verify-geometry.py 後務必重跑這支。**

實際踩過的兩個坑，都由此處的案例守住：
- 用「座標字串有沒有出現在 svg 裡」猜形狀 → 矩形節點被當菱形，誤報三處文字溢出
- 第一版漏掉容器 gutter 這項 → 節點改寬後撞到容器邊界，跑完全綠才被人眼發現
"""
import re, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
VERIFY = HERE / 'verify-geometry.py'
FIXTURE = HERE / 'fixtures' / 'sample-flow.svg'

# (案例名, 輸出中應出現的關鍵字, 變異函式)
CASES = [
    ('連線 3 折', '折',
     lambda s: s.replace('d="M 1060,242 L 1060,300 L 850,300 L 850,650"',
                         'd="M 1060,242 L 1060,280 L 950,280 L 950,300 L 850,300 L 850,650"')),
    ('連線交叉', '交叉',
     lambda s: s.replace('<path id="e7" d="M 330,750 L 330,850"',
                         '<path id="e7" d="M 330,750 L 330,860 L 1200,860 L 1200,300"')),
    ('節點間距 < 80px', '節點間距',
     lambda s: s.replace('<rect x="560" y="150" width="340"', '<rect x="450" y="150" width="340"')),
    ('容器 gutter < 20px', 'gutter',
     lambda s: s.replace('<rect x="150" y="600" width="1220"', '<rect x="195" y="600" width="1175"')),
    ('正值 begin（球停在 0,0）', '正值 begin',
     lambda s: s.replace('begin="-4s"', 'begin="4s"', 1)),
    ('dur 不整除總循環', '不整除',
     lambda s: s.replace('dur="2s"', 'dur="3s"', 1)),
    ('文字溢出菱形斜邊', '文字溢出',
     lambda s: s.replace('CLAUDE.md 同批更新？', 'CLAUDE.md 是否已經在同一批裡更新過了呢')),
    ('連線穿過非端點節點', '穿過節點',
     lambda s: s.replace('d="M 720,650 L 720,320 L 270,320 L 270,226"',
                         'd="M 720,650 L 720,188 L 270,188 L 270,226"')),
    ('節點數 > 9', '節點',
     lambda s: s.replace('<!-- ⑧ commit 成功 -->', ''.join(
         f'<rect x="{60 + i * 4}" y="{980 + i}" width="30" height="20" rx="6" '
         f'fill="#111111" stroke="#5a9e6f"/>' for i in range(3)) + '<!-- ⑧ commit 成功 -->')),
]

def run(svg_text):
    t = Path(tempfile.mkstemp(suffix='.svg')[1])
    t.write_text(svg_text, encoding='utf-8')
    try:
        return subprocess.run([sys.executable, str(VERIFY), str(t)],
                              capture_output=True, text=True)
    finally:
        t.unlink()

def tag(s):
    """把 fixture 加上 data-role，用來測標記路徑（非退化路徑）。"""
    s = re.sub(r'(<rect )(x="\d+" y="\d+" width="\d+" height="\d+" rx="6" fill="#111111")',
               r'\1data-role="node" \2', s)
    s = re.sub(r'(<rect )(x="\d+" y="\d+" width="\d+" height="\d+" rx="8" fill="none")',
               r'\1data-role="container" \2', s)
    s = s.replace('<polygon points="330,634', '<polygon data-role="node" points="330,634')
    return re.sub(r'(<path )(id="e\d+")', r'\1data-role="edge" \2', s)

def main():
    if not VERIFY.exists() or not FIXTURE.exists():
        print(f'❌ 找不到 {VERIFY} 或 {FIXTURE}')
        return 2
    src = FIXTURE.read_text(encoding='utf-8')
    bad = []

    print(f'{"變異案例":32} exit  結果')
    print('-' * 60)
    for name, kw, mutate in CASES:
        r = run(mutate(src))
        caught = r.returncode == 1 and kw in r.stdout
        print(f'{name:32} {r.returncode:<5} {"✅ 抓到" if caught else "❌ 沒抓到"}')
        if not caught:
            bad.append((name, r.returncode, r.stdout[-300:]))

    print()
    # 正向對照：沒被弄壞的檔案必須通過，否則「全部判失敗」也會讓上面全綠
    r = run(src)
    ok = r.returncode == 0
    print(f'正向對照（原檔應通過）        exit={r.returncode}  {"✅" if ok else "❌"}')
    if not ok:
        bad.append(('正向對照', r.returncode, r.stdout[-300:]))

    # 標記路徑：加了 data-role 之後不應再出現退化警告，且仍要通過
    r = run(tag(src))
    ok2 = r.returncode == 0 and '無 data-role' not in r.stdout
    print(f'data-role 標記路徑           exit={r.returncode}  {"✅" if ok2 else "❌"}')
    if not ok2:
        bad.append(('data-role 路徑', r.returncode, r.stdout[-300:]))

    print()
    if bad:
        print('❌ 未全過：')
        for name, rc, out in bad:
            print(f'  - {name}（exit={rc}）\n    {out.strip()[:200]}')
        return 1
    print(f'✅ {len(CASES)} 種變異全部抓到，原檔通過，標記路徑正常')
    return 0

if __name__ == '__main__':
    sys.exit(main())
