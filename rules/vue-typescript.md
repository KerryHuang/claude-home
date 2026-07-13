# Vue 3 + TypeScript

- 一律 Composition API + `<script setup lang="ts">`；不寫 Options API 新碼。
- 型別從 API schema／既有 types 引用，不重複手刻；避免 `any`，必要時用 `unknown` 收窄。
- 狀態管理依專案既有方案（Pinia 等）：局部狀態用 ref/computed，不自創事件匯流排。
- UI 框架（Quasar 等）優先用內建元件與樣式 token，不手刻同功能元件。
- 套件管理器依專案 lockfile 判斷（bun / pnpm / npm），不混用。
- API 呼叫集中在既有 service／composable 層，元件內不直接 fetch。
