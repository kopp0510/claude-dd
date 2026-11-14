#!/bin/bash
# 用 prompt.txt 產生某一臂的 subagent prompt。用法：mkprompt.sh <臂> <BASE> <dd-init.md 路徑>
set -eu
ARM="$1"; BASE="$2"; DOC="$3"
HERE=$(cd "$(dirname "$0")" && pwd); DD=$(cd "$HERE/../../.." && pwd)   # claude-dd repo 根目錄（本檔在 docs/measurements/<目錄>/）
case "$ARM" in
  A|AO)     TASK='Phase 1 的「用升級腳本升級」，從第 1 步開始。Phase 0 已經做完：純 CLI 專案（Node），補充模式，CLAUDE.md 有 8step 舊區塊。' ;;
  B)        TASK='Phase 2。Phase 0 已經做完：專案有前端 UI（React）。' ;;
  K1|K2)    TASK='Phase 0 第 3 步、Phase 1 與 Phase 2。Phase 0 第 1、2 步已經做完：專案有前端 UI（React），沒有 HTTP API。' ;;
  C|C2|D|Y) TASK='Phase 0 第 3 步與 Phase 1。Phase 0 第 1、2 步已經做完：純 CLI 專案（Node），沒有前端、沒有 HTTP API。' ;;
  Y5|YD)    TASK='Phase 0 第 3 步、Phase 1 與 Phase 5（照文件 commit，這是拋棄式 repo）。Phase 0 第 1、2 步已經做完：純 CLI 專案（Node），沒有前端、沒有 HTTP API；Phase 2、3、4 跳過。' ;;
  *)        TASK='Phase 3。Phase 0–2 已經做完（純 CLI 專案，git repo）。' ;;
esac
case "$ARM" in
  H*) NAME=$(printf 'dd-%s-%s' "$(basename "$BASE")" "$ARM" | tr 'A-Z' 'a-z')
      EXTRA="\\n5. 這個專案的 git hook 工具（pre-commit、husky）裝在 docker 容器 ${NAME} 裡：要跑 pre-commit、npm、npx 時用 \`docker exec -w ${BASE}/${ARM}/repo ${NAME} sh -c '<指令>'\`；讀寫檔照常用你自己的工具" ;;
  O|OI) NAME=$(printf 'dd-%s-%s' "$(basename "$BASE")" "$ARM" | tr 'A-Z' 'a-z')
      EXTRA="\\n5. 這個專案要用 docker 容器 ${NAME} 裡的 git：所有 git 指令一律寫成 \`docker exec -w ${BASE}/${ARM}/repo ${NAME} git <參數>\`，不要用本機的 git；其他指令與讀寫檔照常用你自己的工具" ;;
  *)  EXTRA="" ;;
esac
case "$ARM" in A|AO|D) ANSWERS='升級的「是否升級」答「同意」。' ;; Y|Y5|YD) ANSWERS='「寫檔前：先看目標是不是 symlink」那節的問句答「要」。' ;; *) ANSWERS='' ;; esac
case "$ARM" in AO) UP="$BASE/$ARM/old-upgrade.sh" ;; *) UP="$DD/scripts/dd-init-upgrade.sh" ;; esac   # AO 用沒有 exit 6 的舊腳本
case "$ARM" in Y5|YD) NOCOMMIT='' ;; *) NOCOMMIT='不要 commit、' ;; esac
REPO="$BASE/$ARM/repo"
awk -v R="$REPO" -v D="$DOC" -v T="$TASK" -v UP="$UP" -v NC="$NOCOMMIT" -v AN="$ANSWERS" -v EX="$EXTRA" '{gsub(/\{REPO\}/,R); gsub(/\{DOC\}/,D); gsub(/\{TASK\}/,T); gsub(/\{UP\}/,UP); gsub(/\{NOCOMMIT\}/,NC); gsub(/\{ANSWERS\}/,AN); gsub(/\{EXTRA\}/,EX); print}' "$HERE/prompt.txt"
