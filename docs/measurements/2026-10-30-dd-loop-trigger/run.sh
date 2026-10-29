#!/bin/bash
# dd-loop 觸發實測：在拋棄式 repo 跑 claude -p，看段落開始 / 接手 / 步驟 4 前 / 步驟 8 前會不會叫 dd-loop。
# 用法：./run.sh <工作目錄>   產出 <工作目錄>/out/*.jsonl；判定見 check.sh（只抽判定欄位進 repo）
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
W=${1:?工作目錄}
mkdir -p "$W/out"
mkfix() {  # $1 = repo 路徑；建一個有 IN_PROGRESS 段落、小任務都已 commit 的專案
  rm -rf "$1"; mkdir -p "$1/docs/designs"; cd "$1"; git init -q
  printf '#!/bin/sh\necho "hello ${1:-world}"\n' > hello.sh; chmod +x hello.sh
  printf '# hello\n\nhello.sh 印招呼語。\n' > CLAUDE.md
  printf 'helo world 範例\n' > README.md
  git add -A; git -c user.name=t -c user.email=t@t commit -qm 'chore: 初始'
  base=$(git rev-parse --short HEAD)
  printf '# hello\n\n進度以 docs/designs/h-design.md 的「進度表」為準：開工先讀表，照表下方的規則做。\n\n## 說明\n\nhello.sh 印招呼語，可帶名字。\n' > CLAUDE.md
  printf '# hello 帶名字\n\n## 進度表\n\n| ID | 段落 | 狀態 | 依賴 | 驗收 | commits |\n|---|---|---|---|---|---|\n| S1 | hello 帶名字 | IN_PROGRESS | — | ./hello.sh Bob 印 hello Bob | %s.. |\n\n## 段落與小任務\n\n### S1\n\n- S1-1 hello.sh 吃第一個參數（commit 結尾帶（S1-1））\n' "$base" > docs/designs/h-design.md
  git add -A; git -c user.name=t -c user.email=t@t commit -qm 'feat: hello 帶名字（S1-1）'
  cd - >/dev/null
}
run() {  # $1 = 情境名；prompt 取自 $HERE/<情境名>.prompt.txt
  local name=$1 rep
  for rep in ${REPS:-1 2}; do
    mkfix "$W/repo-$name-$rep"
    (cd "$W/repo-$name-$rep" && claude -p "$(cat "$HERE/$name.prompt.txt")" \
      --output-format stream-json --verbose --max-budget-usd 3 --no-session-persistence \
      --permission-mode dontAsk --allowedTools "Skill Read Glob Grep" \
      --disallowedTools "Edit Write NotebookEdit Bash Agent" \
      --settings '{"advisorModel":""}' < /dev/null > "$W/out/$name-$rep.jsonl" 2>&1) || true
  done
}
for n in ${CASES:-p1-start p2-handover p3-step4 p4-step8}; do run "$n"; done
REPS=1 run n1-typo
