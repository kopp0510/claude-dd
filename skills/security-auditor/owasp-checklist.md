# OWASP Top 10 檢查清單

## A01: Broken Access Control

```javascript
// 不安全：直接物件引用
app.get('/api/users/:id', (req, res) => {
  const user = database.getUser(req.params.id); // 沒有授權檢查！
  res.json(user);
});

// 安全：適當的授權
app.get('/api/users/:id', authenticate, (req, res) => {
  if (req.user.id !== req.params.id && !req.user.hasRole('admin')) {
    return res.status(403).json({ error: 'Access denied' });
  }
  const user = database.getUser(req.params.id);
  res.json(user);
});
```

## A02: Cryptographic Failures

```javascript
// 安全的密碼雜湊
const bcrypt = require('bcrypt');
const saltRounds = 12;

async function hashPassword(password) {
  return await bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}
```

## A03: Injection Attacks

```javascript
// SQL Injection 防護
// 不安全
const query = `SELECT * FROM users WHERE email = '${userEmail}'`;

// 安全：參數化查詢
const query = 'SELECT * FROM users WHERE email = ?';
const result = await database.query(query, [userEmail]);
```

## A04: Insecure Design

- 設計階段納入威脅建模
- 使用安全設計模式
- 實施防禦性程式設計

## A05: Security Misconfiguration

- 移除預設帳號和密碼
- 停用不必要的功能
- 適當設定錯誤處理

## A06: Vulnerable Components

```bash
# 定期檢查依賴漏洞
npm audit
pip-audit
```

## A07: Authentication Failures

- 實施強密碼政策
- 使用多因素認證
- 防止暴力破解攻擊

## A08: Software and Data Integrity

- 驗證所有外部輸入
- 使用程式碼簽名
- 實施 CI/CD 安全

## A09: Security Logging and Monitoring

- 記錄所有安全相關事件
- 實施即時告警
- 定期審查日誌

## A10: Server-Side Request Forgery (SSRF)

- 驗證和清理所有 URL 輸入
- 使用白名單限制外部請求
- 實施網路分區
