---
name: compliance-check
description: 合規檢查包裝器，調用 security-compliance-check 命令。當提到 GDPR、SOC2、HIPAA、PCI-DSS、合規時自動啟用。
allowed-tools: Skill, Read, Grep, Glob
---

# Compliance Check

合規檢查 Skill，透過調用 security-compliance-check 命令驗證法規合規性。

## Skill 定位

**這是 security-compliance-check:compliance-check 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="security-compliance-check:compliance-check")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行法規合規驗證（GDPR、SOC2、HIPAA、PCI-DSS 等）

## 觸發條件

**關鍵詞：**
- 「GDPR」、「SOC2」、「HIPAA」、「PCI-DSS」
- 「合規」、「compliance」
- 「法規遵循」、「regulatory」

**場景觸發：**
- 檢查專案是否符合特定法規
- 合規差距分析
- 上線前合規驗證

## 工作流程

### Stage 1: 需求確認
詢問使用者要檢查的合規框架和範圍。

### Stage 2: 調用 Skill 命令
```
Skill(skill="security-compliance-check:compliance-check")
```

### Stage 3: 結果報告
整理命令輸出，產出合規檢查報告。
