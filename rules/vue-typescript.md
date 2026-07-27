---
paths:
  - "**/*.vue"
  - "**/*.ts"
  - "**/*.tsx"
---

# Vue 3 + TypeScript

- 套件管理器認 lockfile（bun / pnpm / npm），不混用——混用會裝出不一致的依賴樹。
- 型別從 API schema／既有 types 引用，不重複手刻一份。
- UI 框架（Quasar 等）有的元件與樣式 token 就直接用，不手刻同功能的。
- API 呼叫走既有 service／composable 層，元件內不直接 fetch。
