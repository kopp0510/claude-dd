---
name: i18n-expert
description: 國際化專家，專注多語言架構、翻譯管理、日期時間格式、RTL 支援。當需要實作多語言、本地化功能時自動啟用。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# i18n Expert

專注於國際化（Internationalization）與本地化（Localization）的專家技能。

## 核心概念

- **i18n** - Internationalization（國際化），讓應用程式能支援多語言
- **L10n** - Localization（本地化），針對特定地區的適配
- **Locale** - 語言+地區組合（如 zh-TW、en-US）

## 核心能力

### 翻譯架構設計

#### 檔案結構
```
locales/
├── zh-TW/
│   ├── common.json
│   ├── auth.json
│   └── errors.json
├── en-US/
│   ├── common.json
│   ├── auth.json
│   └── errors.json
└── ja-JP/
    └── ...
```

#### Key 命名規範
```json
{
  "auth": {
    "login": {
      "title": "登入",
      "button": "登入",
      "forgot_password": "忘記密碼？"
    },
    "register": {
      "title": "註冊"
    }
  },
  "errors": {
    "required": "此欄位為必填",
    "invalid_email": "電子郵件格式不正確"
  }
}
```

### 字串插值

#### 變數插入
```json
{
  "greeting": "你好，{{name}}！",
  "items_in_cart": "購物車有 {{count}} 件商品"
}
```

```typescript
t('greeting', { name: '小明' })  // → "你好，小明！"
```

#### HTML 內嵌
```json
{
  "terms": "我同意 <link>服務條款</link>"
}
```

```jsx
<Trans i18nKey="terms" components={{ link: <a href="/terms" /> }} />
```

### 複數形式

#### 基本複數
```json
{
  "items_zero": "沒有項目",
  "items_one": "{{count}} 個項目",
  "items_other": "{{count}} 個項目"
}
```

#### 語言特殊規則
```json
// 俄語有更多複數形式
{
  "items_one": "{{count}} элемент",
  "items_few": "{{count}} элемента",
  "items_many": "{{count}} элементов"
}
```

### 日期時間格式

#### 地區差異
| 地區 | 日期格式 | 時間格式 |
|------|----------|----------|
| zh-TW | 2024年1月15日 | 下午 3:30 |
| en-US | January 15, 2024 | 3:30 PM |
| en-GB | 15 January 2024 | 15:30 |
| ja-JP | 2024年1月15日 | 15:30 |

#### 使用 Intl API
```typescript
const date = new Date();

// 日期
new Intl.DateTimeFormat('zh-TW').format(date)
// → "2024/1/15"

// 相對時間
new Intl.RelativeTimeFormat('zh-TW').format(-1, 'day')
// → "1 天前"
```

### 數字貨幣格式

#### 數字格式
| 地區 | 格式 |
|------|------|
| en-US | 1,234.56 |
| de-DE | 1.234,56 |
| zh-TW | 1,234.56 |

```typescript
new Intl.NumberFormat('zh-TW').format(1234.56)
// → "1,234.56"
```

#### 貨幣格式
```typescript
new Intl.NumberFormat('zh-TW', {
  style: 'currency',
  currency: 'TWD'
}).format(1234)
// → "NT$1,234"

new Intl.NumberFormat('ja-JP', {
  style: 'currency',
  currency: 'JPY'
}).format(1234)
// → "￥1,234"
```

### RTL 支援（右到左）

#### CSS 邏輯屬性
```css
/* 舊寫法 */
margin-left: 10px;
padding-right: 20px;
text-align: left;

/* RTL 友善寫法 */
margin-inline-start: 10px;
padding-inline-end: 20px;
text-align: start;
```

#### HTML 設定
```html
<html lang="ar" dir="rtl">
```

#### React 處理
```jsx
const { dir } = useTranslation();
return <div dir={dir}>{children}</div>;
```

### 語言偵測

#### 偵測優先順序
1. URL 參數（?lang=zh-TW）
2. Cookie 儲存
3. localStorage
4. 瀏覽器語言（navigator.language）
5. 預設語言

```typescript
function detectLanguage(): string {
  return (
    getFromUrl() ||
    getFromCookie() ||
    getFromStorage() ||
    navigator.language ||
    'zh-TW'
  );
}
```

### 動態載入

#### 按需載入翻譯
```typescript
// Next.js 範例
export async function getStaticProps({ locale }) {
  return {
    props: {
      messages: (await import(`../locales/${locale}.json`)).default
    }
  };
}
```

#### 命名空間分割
```typescript
// 只載入需要的命名空間
const { t } = useTranslation(['common', 'auth']);
```

## 框架整合

### React (react-i18next)
```typescript
import { useTranslation } from 'react-i18next';

function Component() {
  const { t, i18n } = useTranslation();

  return (
    <div>
      <p>{t('greeting')}</p>
      <button onClick={() => i18n.changeLanguage('en')}>
        English
      </button>
    </div>
  );
}
```

### Next.js (next-intl)
```typescript
import { useTranslations } from 'next-intl';

export default function Page() {
  const t = useTranslations('HomePage');
  return <h1>{t('title')}</h1>;
}
```

### Vue (vue-i18n)
```vue
<template>
  <p>{{ $t('greeting') }}</p>
</template>

<script setup>
import { useI18n } from 'vue-i18n';
const { t, locale } = useI18n();
</script>
```

## 最佳實踐

### 開發原則
- 所有使用者可見文字都要 i18n
- 使用有意義的 key 命名
- 避免字串拼接
- 預留文字長度彈性（德文通常比英文長 30%）

### 翻譯管理
- 使用翻譯管理平台（Crowdin、Lokalise）
- 導出/導入自動化
- 翻譯記憶體
- 上下文截圖

### 測試
- 偽本地化測試（pseudo-localization）
- RTL 視覺測試
- 長文字溢出測試
- 特殊字元測試
