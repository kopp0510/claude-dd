---
name: security-audit
description: 一鍵自動化全面安全審計包裝器，調用 security-audit 命令執行多階段自動掃描。當需要一鍵全面安全審計、自動化安全掃描、完整安全評估報告時自動啟用。不適用於手動逐項審查（用 security-auditor）或特定 CVE 掃描（用 vulnerability-scan）。
allowed-tools: Skill, Read, Grep, Glob
---

# Security Audit

全面安全審計 Skill，透過調用 security-audit 命令執行多階段安全審計。

## Skill 定位

**這是 security-audit:audit 命令的包裝器 (Wrapper)**

- **實作方式**：透過 `Skill(skill="security-audit:audit")` 調用
- **Skill 職責**：提供自動觸發、需求確認、結構化報告產出
- **命令職責**：執行多階段安全審計（自動選擇審計 agent）

## 觸發條件

**關鍵詞：**
- 「全面安全審計」、「security audit」
- 「安全檢查」、「security check」

**場景觸發：**
- 上線前的全面安全審計
- 定期安全檢查
- 合規要求的安全審計

## 工作流程

### Stage 1: 需求確認
詢問使用者要審計的範圍和安全標準。

### Stage 2: 調用 Skill 命令
```
Skill(skill="security-audit:audit")
```

### Stage 3: 結果報告
整理命令輸出，產出安全審計報告。

## 與 security-auditor 的差異

| 特性 | security-audit | security-auditor |
|-----|---------------|-----------------|
| **調用方式** | Skill 命令（多階段編排） | DD 內建 Skill |
| **範圍** | 全面審計（多 agent 協作） | OWASP Top 10 為主 |
| **適用場景** | 上線前全面審計 | 日常安全審查 |
