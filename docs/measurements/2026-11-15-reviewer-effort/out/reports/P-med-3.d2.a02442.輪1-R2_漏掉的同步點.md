【我查了什麼】

- `grep -n '^## ' CLAUDE.md`：第一個 `##` 在第 5 行（`## 安裝 / 更新`）。
- `grep -n -E '進度以|docs/designs' CLAUDE.md`：0 筆。根目錄沒有指路句。
- `grep -rn -E '進度以|指路' --include=CLAUDE.md .`：只命中 `templates/global/CLAUDE.md:446,510,511`。
- `grep -n -E '新增|同時改|同批|要一起|同步|手動' CLAUDE.md`：逐條對照 Skill、Agent、Command、Script、Output Style 步驟，以及 README 同步、CI 不驗的區塊、迴圈步數、dd-loop-rev、CHANGELOG 規則。計畫的 S1、S2 都有覆蓋，唯獨進度表指路句沒有。
- `ls docs/designs`：7 份，與計畫一致。
- `ls docs/CLAUDE.md`：不存在。
- `grep -n -E 'start-segment|SKIP_DOC_CHECK' CLAUDE.md scripts/CLAUDE.md`：CLAUDE.md:194 說 SKIP 只給檢查點 commit；CLAUDE.md:206 說記段落起點用 `--start-segment`。
- `sed -n 50,76p DD_PIPELINE_ARCHITECTURE.md`、`grep -n 'uninstall' README.md README.zh-TW.md` 等：核對 `--uninstall` 的文件說法。
- `sed -n 524,536p install-dd-pipeline.sh`：skills 內容不同時照樣 `backup_before_overwrite` 後 `rm -rf` 再 `cp -r`，不看 `$FORCE`。計畫 S2 第 2 項寫的行為與程式相符。
- `grep -n 'create_commands\|deprecated_dd\|已啟用的 Plugin\|已安裝的內建 Agents'`：與計畫 F9、F10 相符。
- `tests/CLAUDE.md` 第 10 行那列描述 `test-install.sh` 的涵蓋範圍；計畫有列為同步項。

【批評】

輪1-R2-1｜重大｜進度表沒有指路句，後續 session 會看不到進度表。全域 §4.4 規定「開表的同時，在根目錄 CLAUDE.md 第一個 `##` 之前加一段指路」，並寫明缺了這句，下一個 session 會重估段落數、另開第二張表，先前的進度與 commit 範圍靜靜遺失。計畫寫明「根目錄 CLAUDE.md 沒有『進度以…為準』那句」，卻沒有把它列進任何一段的文件同步。S1 的文件同步只列「只補這次留下的坑、不改既有規則」。證據：根目錄 CLAUDE.md 第 5 行即第一個 `##`，全檔 0 筆指路句（`grep -n -E '進度以|docs/designs' CLAUDE.md` 無輸出）；要求原文在 `templates/global/CLAUDE.md:510-511`；計畫「S1 的文件同步」與「進度表草稿」都沒有這一句。

輪1-R2-2｜重大｜計畫漏掉段落起點，進度表的 commits 欄沒有可取的起點。全域 §3.9 規定段落開始前要先跑 `check-claude-md.sh --start-segment` 記起點；根目錄 CLAUDE.md:206 也寫了這個指令。計畫的進度表 S1、S2 的 commits 欄都是空的，計畫全文沒有提到 `--start-segment`。步驟 4 的 `git diff <起點>` 與步驟 8 的範圍都取自這個起點。沒記起點時，範圍會算錯，而且不會報錯，後面的 code-review 與評分都照錯的範圍跑。證據：計畫進度表草稿 commits 欄為空；根目錄 CLAUDE.md:206；計畫全文無 `start-segment`。

輪1-R2-3｜重大｜`DD_PIPELINE_ARCHITECTURE.md` 的同一句會與計畫的新說法矛盾，但計畫只寫「有同一句時一起改」，等於沒列進同步清單。計畫 S2-1 第 1 項要寫「`--uninstall` 會把你自己裝的官方 plugin 也拿掉」。但 `DD_PIPELINE_ARCHITECTURE.md:75` 寫的是「`--uninstall` 只移除本 repo 部署過的項目」，`README.zh-TW.md:71` 寫的是「解除安裝（本 repo 部署過的項目）」，`README.md:70` 寫的是「remove what this repo deployed」。計畫的條件「有同一句」已經成立，DD_ARCH:75 的句子與 README 那句一字相同，所以應該直接列進 S2 的同步清單。沒改的話，DD_ARCH 會留下與程式行為不符的敘述，而且沒有任何 CI 檢查會抓到。

輪1-R2-4｜小｜中間 commit 會被 gate 擋，計畫沒寫 SKIP 的用法。計畫要求 S1-1、S1-2、S1-3 各自 commit，但 `tests/CLAUDE.md` 與根目錄 CLAUDE.md 的更新放在「S1 的文件同步」，要等到最後一個小任務或步驟 6 才一起 commit。根目錄 CLAUDE.md:193-194 說改碼目錄未同批更新就擋 commit，檢查點 commit 才能用 `SKIP_DOC_CHECK=1`。這會報錯，不是靜默通過，所以只算小事。計畫應寫明哪幾次 commit 用 SKIP，並說明之後欠帳要在哪一次清掉。

【需要外部查證】

無。上述批評都能從本地檔案與 grep 結果確認。
