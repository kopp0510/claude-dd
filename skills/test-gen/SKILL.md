---
name: test-gen
description: 測試產生器包裝器，調用 testing-test-gen 命令。當提到自動產生測試、generate tests、test harness、批量產生測試案例時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Test Gen

測試產生器 Skill，透過調用 testing-test-gen 命令自動產生測試程式碼。

## Skill 定位

**這是 testing-test-gen:test-gen 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="testing-test-gen:test-gen")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行測試程式碼產生（含 test harness 建置）

## 觸發條件

**關鍵詞：**
- 「產生測試」、「generate tests」
- 「測試覆蓋」、「test coverage」
- 「test harness」、「測試工具」

**場景觸發：**
- 為現有程式碼自動產生測試
- 提高測試覆蓋率
- 建立測試基礎設施

## 工作流程

### Stage 1: 需求確認
詢問使用者要產生測試的目標檔案和測試框架。

### Stage 2: 調用 Skill 命令
```
Skill(skill="testing-test-gen:test-gen")
```

### Stage 3: 結果報告
整理命令輸出，產出測試產生報告。
