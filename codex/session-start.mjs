#!/usr/bin/env node
import { syncUser } from './sync-user.mjs'
import { homedir } from 'node:os'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'

try {
  const changed = syncUser()
  if (changed.length) {
    const root = changed.includes('.codex/AGENTS.md') ? readFileSync(join(homedir(), '.codex/AGENTS.md'), 'utf8') : ''
    process.stdout.write(JSON.stringify({ hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: `Claude user 來源已更新，Codex 同步 ${changed.length} 個檔。skill／agent catalog 變更需新 session 才能完整驗收。\n${root}` } }))
  }
} catch (error) { console.error(`[claude-home sync] ${error.message}`); process.exitCode = 1 }
