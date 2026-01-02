---
name: i18n-expert
description: 國際化專家，專注多語言架構、翻譯管理、日期時間格式、RTL 支援。當需要實作多語言、本地化功能時自動啟用。透過結構化工作流程引導完成國際化設計與實作。
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# i18n Expert

專注於國際化（Internationalization）與本地化（Localization）的專家技能，透過結構化工作流程協助設計可擴展的多語言架構。

## 核心概念

- **i18n** - Internationalization（國際化），讓應用程式能支援多語言
- **L10n** - Localization（本地化），針對特定地區的適配
- **Locale** - 語言+地區組合（如 zh-TW、en-US）

## 觸發條件

**自動觸發時機：**
- 使用者提到多語言：「多國語言」、「i18n」、「國際化」
- 使用者提到翻譯：「翻譯」、「本地化」、「L10n」
- 使用者提到格式化：「日期格式」、「貨幣格式」、「數字格式」
- 使用者提到 RTL：「阿拉伯語」、「希伯來語」、「右到左」
- 使用者提到語言切換功能

**初始互動：**
詢問專案技術棧和目標語言，提供對應的解決方案流程。

## 工作流程

### 情境 A: 新專案 i18n 架構設計

#### Stage 1: 需求分析

**初始問題：**
1. 使用什麼前端框架？（React / Vue / Next.js / Nuxt）
2. 需要支援哪些語言/地區？
3. 有沒有 RTL 語言需求？（阿拉伯語、希伯來語）
4. 預期的翻譯量級？（小型 <100 key / 中型 / 大型 >1000 key）
5. 翻譯由誰負責？（內部團隊 / 專業翻譯 / 機器翻譯）

#### Stage 2: 技術選型

**框架對照表：**

| 框架 | 推薦方案 | 特點 |
|------|----------|------|
| React | react-i18next | 成熟穩定、生態豐富 |
| Next.js | next-intl | App Router 原生支援 |
| Vue | vue-i18n | 官方推薦 |
| Nuxt | @nuxtjs/i18n | SSR 友善 |

**決策點：**
- 選擇命名空間策略（單檔案 vs 多檔案）
- 選擇 Key 命名規範（平面 vs 巢狀）
- 選擇語言偵測策略

#### Stage 3: 目錄結構設計

**推薦結構：**
```
locales/
├── zh-TW/
│   ├── common.json      # 共用翻譯
│   ├── auth.json        # 認證相關
│   ├── errors.json      # 錯誤訊息
│   └── validation.json  # 表單驗證
├── en-US/
│   ├── common.json
│   ├── auth.json
│   ├── errors.json
│   └── validation.json
└── ja-JP/
    └── ...
```

**Key 命名規範：**
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

#### Stage 4: 實作指南

**React + react-i18next 設定：**
```typescript
// i18n.config.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      'zh-TW': { translation: zhTW },
      'en-US': { translation: enUS },
    },
    fallbackLng: 'zh-TW',
    interpolation: {
      escapeValue: false,
    },
  });

export default i18n;
```

**Next.js + next-intl 設定：**
```typescript
// next.config.js
const withNextIntl = require('next-intl/plugin')();

module.exports = withNextIntl({
  // ...other config
});

// middleware.ts
import createMiddleware from 'next-intl/middleware';

export default createMiddleware({
  locales: ['zh-TW', 'en-US', 'ja-JP'],
  defaultLocale: 'zh-TW',
});
```

---

### 情境 B: 現有專案國際化

#### Stage 1: 現況評估

**收集資訊：**
1. 請提供專案技術棧
2. 目前硬編碼字串大約有多少？
3. 有沒有已經使用任何 i18n 方案？
4. 有沒有緊迫的上線時程？

#### Stage 2: 遷移策略

**漸進式遷移步驟：**

1. **安裝 i18n 框架**
```bash
# React
npm install i18next react-i18next i18next-browser-languagedetector

# Next.js
npm install next-intl
```

2. **建立翻譯基礎架構**
   - 建立 locales 目錄結構
   - 設定 i18n 初始化
   - 建立語言切換元件

3. **漸進式提取**
   - 從共用元件開始
   - 優先處理使用者可見文字
   - 保持向後相容

#### Stage 3: 字串提取

**提取清單：**
- [ ] 按鈕文字
- [ ] 標題和標籤
- [ ] 表單驗證訊息
- [ ] 錯誤訊息
- [ ] 提示訊息
- [ ] 選單項目
- [ ] Alt 文字

**提取原則：**
```typescript
// ❌ 硬編碼
<button>登入</button>

// ✅ 國際化
<button>{t('auth.login.button')}</button>
```

#### Stage 4: 驗證與測試

**驗證清單：**
- [ ] 所有語言正確顯示
- [ ] 語言切換正常運作
- [ ] 日期時間格式正確
- [ ] 數字貨幣格式正確
- [ ] RTL 佈局正確（如適用）
- [ ] 長文字不會溢出

---

### 情境 C: 格式化處理

#### Stage 1: 日期時間格式

**地區差異：**
| 地區 | 日期格式 | 時間格式 |
|------|----------|----------|
| zh-TW | 2024年1月15日 | 下午 3:30 |
| en-US | January 15, 2024 | 3:30 PM |
| en-GB | 15 January 2024 | 15:30 |
| ja-JP | 2024年1月15日 | 15:30 |

**使用 Intl API：**
```typescript
const date = new Date();

// 日期格式化
new Intl.DateTimeFormat('zh-TW').format(date)
// → "2024/1/15"

// 完整日期時間
new Intl.DateTimeFormat('zh-TW', {
  dateStyle: 'full',
  timeStyle: 'short',
}).format(date)
// → "2024年1月15日 星期一 下午3:30"

// 相對時間
new Intl.RelativeTimeFormat('zh-TW').format(-1, 'day')
// → "1 天前"
```

#### Stage 2: 數字貨幣格式

**數字格式差異：**
| 地區 | 格式 |
|------|------|
| en-US | 1,234.56 |
| de-DE | 1.234,56 |
| zh-TW | 1,234.56 |

```typescript
// 數字格式化
new Intl.NumberFormat('zh-TW').format(1234.56)
// → "1,234.56"

// 貨幣格式化
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

// 百分比
new Intl.NumberFormat('zh-TW', {
  style: 'percent',
  maximumFractionDigits: 1
}).format(0.1234)
// → "12.3%"
```

#### Stage 3: 複數形式

**基本複數：**
```json
{
  "items_zero": "沒有項目",
  "items_one": "{{count}} 個項目",
  "items_other": "{{count}} 個項目"
}
```

**語言特殊規則（俄語）：**
```json
{
  "items_one": "{{count}} элемент",
  "items_few": "{{count}} элемента",
  "items_many": "{{count}} элементов"
}
```

**使用範例：**
```typescript
t('items', { count: 0 })  // → "沒有項目"
t('items', { count: 1 })  // → "1 個項目"
t('items', { count: 5 })  // → "5 個項目"
```

---

### 情境 D: RTL 支援

#### Stage 1: RTL 評估

**需要 RTL 的語言：**
- 阿拉伯語（ar）
- 希伯來語（he）
- 波斯語（fa）
- 烏爾都語（ur）

**初始問題：**
1. 有哪些 RTL 語言需求？
2. 現有 CSS 使用什麼佈局？（Flexbox / Grid / 傳統）
3. 有沒有使用 CSS-in-JS？

#### Stage 2: CSS 重構

**邏輯屬性轉換：**
```css
/* ❌ 物理屬性（不支援 RTL） */
margin-left: 10px;
padding-right: 20px;
text-align: left;
border-left: 1px solid;

/* ✅ 邏輯屬性（自動 RTL） */
margin-inline-start: 10px;
padding-inline-end: 20px;
text-align: start;
border-inline-start: 1px solid;
```

**屬性對照表：**
| 物理屬性 | 邏輯屬性 |
|----------|----------|
| left | inline-start |
| right | inline-end |
| top | block-start |
| bottom | block-end |
| margin-left | margin-inline-start |
| padding-right | padding-inline-end |
| border-left | border-inline-start |

#### Stage 3: HTML 與框架設定

**HTML 設定：**
```html
<html lang="ar" dir="rtl">
```

**React 動態處理：**
```jsx
import { useTranslation } from 'react-i18next';

function App() {
  const { i18n } = useTranslation();
  const dir = i18n.dir(); // 'ltr' 或 'rtl'

  return (
    <div dir={dir}>
      {children}
    </div>
  );
}
```

**Tailwind CSS 支援：**
```jsx
// 使用 rtl: 前綴
<div className="ml-4 rtl:mr-4 rtl:ml-0">
  內容
</div>
```

#### Stage 4: RTL 測試

**測試清單：**
- [ ] 文字方向正確
- [ ] 圖標位置正確
- [ ] 表單元素對齊正確
- [ ] 表格方向正確
- [ ] 動畫方向正確
- [ ] 輪播方向正確

---

### 情境 E: 翻譯管理

#### Stage 1: 翻譯流程設計

**流程選項：**

| 方式 | 適用場景 | 優點 | 缺點 |
|------|----------|------|------|
| Git 管理 | 小型專案 | 簡單、版本控制 | 翻譯者需懂 Git |
| 翻譯平台 | 中大型專案 | 協作、上下文 | 成本 |
| 混合模式 | 需要審核 | 兼顧兩者 | 流程複雜 |

#### Stage 2: 翻譯平台選擇

**平台比較：**

| 平台 | 價格 | 特點 |
|------|------|------|
| Crowdin | 免費/付費 | 功能完整、GitHub 整合 |
| Lokalise | 付費 | 專業、OTA 更新 |
| Phrase | 付費 | 企業級、TMS |
| Tolgee | 開源 | 自架、Context 翻譯 |

#### Stage 3: 自動化整合

**CI/CD 整合範例：**
```yaml
# .github/workflows/i18n-sync.yml
name: Sync Translations

on:
  push:
    paths:
      - 'locales/**'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Upload to Crowdin
        uses: crowdin/github-action@v1
        with:
          upload_sources: true
          upload_translations: true
```

#### Stage 4: 品質保證

**翻譯審核清單：**
- [ ] 術語一致性
- [ ] 上下文正確
- [ ] 長度適當
- [ ] 無遺漏變數
- [ ] 無 HTML 標籤錯誤

**自動檢查工具：**
```typescript
// 檢查遺漏的 Key
function findMissingKeys(source: object, target: object): string[] {
  const missing: string[] = [];

  function check(src: any, tgt: any, path = '') {
    for (const key of Object.keys(src)) {
      const newPath = path ? `${path}.${key}` : key;
      if (typeof src[key] === 'object') {
        check(src[key], tgt?.[key] || {}, newPath);
      } else if (!(key in (tgt || {}))) {
        missing.push(newPath);
      }
    }
  }

  check(source, target);
  return missing;
}
```

---

## 字串插值

### 變數插入
```json
{
  "greeting": "你好，{{name}}！",
  "items_in_cart": "購物車有 {{count}} 件商品"
}
```

```typescript
t('greeting', { name: '小明' })  // → "你好，小明！"
```

### HTML 內嵌
```json
{
  "terms": "我同意 <link>服務條款</link>"
}
```

```jsx
<Trans i18nKey="terms" components={{ link: <a href="/terms" /> }} />
```

## 語言偵測

### 偵測優先順序
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

## 動態載入

### 按需載入翻譯
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

### 命名空間分割
```typescript
// 只載入需要的命名空間
const { t } = useTranslation(['common', 'auth']);
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

### 測試策略
- 偽本地化測試（pseudo-localization）
- RTL 視覺測試
- 長文字溢出測試
- 特殊字元測試

## 互動原則

- 先理解專案需求和限制
- 提供多個技術選項並說明權衡
- 逐步引導完成架構設計
- 解釋每個建議的理由
- 提供可執行的程式碼範例
