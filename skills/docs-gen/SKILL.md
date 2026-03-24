---
name: docs-gen
description: 自動文件產生包裝器，調用 documentation-docs-gen 命令。當提到自動產生文件、generate docs、批量產生 API 文件、JSDoc 產生時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Docs Gen

自動文件產生 Skill，透過調用 documentation-docs-gen 命令自動產生技術文件。

## Skill 定位

**這是 documentation-docs-gen:docs-gen 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="documentation-docs-gen:docs-gen")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：自動產生 API 文件、使用手冊等技術文件

## 觸發條件

**關鍵詞：**
- 「自動產生文件」、「auto generate docs」
- 「generate docs」、「文件產生」
- 「API 文件產生」、「API documentation generation」

**場景觸發：**
- 為專案自動產生技術文件
- 產生 API 參考文件
- 批次產生多種文件

## 工作流程

### Stage 1: 需求確認
詢問使用者要產生的文件類型和範圍。

### Stage 2: 調用 Skill 命令
```
Skill(skill="documentation-docs-gen:docs-gen")
```

### Stage 3: 結果報告
整理命令輸出，產出文件產生報告。

## 與 docs-writer 的差異

| 特性 | docs-gen | docs-writer |
|-----|---------|------------|
| **重點** | 自動批次產生 | 互動式引導撰寫 |
| **適用場景** | 快速產生大量文件 | 精心撰寫單篇文件 |
