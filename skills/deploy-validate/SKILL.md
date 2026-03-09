---
name: deploy-validate
description: 部署驗證包裝器，調用 operations-deploy-validate 命令。當提到部署驗證、上線前檢查、pre-deploy 時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Deploy Validate

部署驗證 Skill，透過調用 operations-deploy-validate 命令執行上線前驗證。

## Skill 定位

**這是 operations-deploy-validate:deploy-validate 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="operations-deploy-validate:deploy-validate")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行測試、安全檢查、配置安全、環境就緒驗證

## 觸發條件

**關鍵詞：**
- 「部署驗證」、「deploy validation」
- 「上線前檢查」、「pre-deploy check」
- 「pre-deploy」、「部署就緒」

**場景觸發：**
- 部署前的最終驗證
- 上線前環境檢查
- 發布前的安全與品質確認

## 工作流程

### Stage 1: 需求確認
詢問使用者部署目標環境和檢查項目。

### Stage 2: 調用 Skill 命令
```
Skill(skill="operations-deploy-validate:deploy-validate")
```

### Stage 3: 結果報告
整理命令輸出，產出部署驗證報告。
