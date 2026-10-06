#!/usr/bin/env node
// Claude user 層是來源；Codex 副本由 manifest 管理，不覆盖使用者的其他檔案。
import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync, unlinkSync } from 'node:fs'
import { join, dirname, relative } from 'node:path'
import { homedir } from 'node:os'
import { createHash } from 'node:crypto'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { execFileSync } from 'node:child_process'

const here = dirname(fileURLToPath(import.meta.url))
const digest = body => createHash('sha256').update(body).digest('hex')
const read = path => existsSync(path) ? readFileSync(path, 'utf8') : ''
const split = raw => {
  const text = raw.replace(/\r\n/g, '\n')
  const end = text.startsWith('---\n') ? text.indexOf('\n---\n', 4) : -1
  if (end < 0) throw new Error('缺少有效 frontmatter')
  return { header: text.slice(0, end + 5), body: text.slice(end + 5), meta: text.slice(4, end) }
}
const field = (meta, name) => meta.match(new RegExp(`^${name}:\\s*(.+)$`, 'm'))?.[1].trim()
const walk = path => existsSync(path) ? readdirSync(path, { withFileTypes: true }).flatMap(e => {
  if (e.name === '__pycache__' || e.name.endsWith('.pyc')) return []
  const p = join(path, e.name)
  return e.isDirectory() ? walk(p) : e.isFile() ? [p] : []
}) : []

function ownership(home) {
  const path = join(home, '.codex/claude-home-manifest.json')
  const state = read(path) ? JSON.parse(read(path)) : { files: {}, mcpNames: [] }
  const changed = []
  const desired = new Set()
  return {
    state, changed,
    put(to, body) {
      const rel = relative(home, to)
      desired.add(rel)
      const current = existsSync(to) ? readFileSync(to) : null
      const expected = Buffer.from(body)
      if (current?.equals(expected)) { state.files[rel] = digest(expected); return }
      if (current !== null && state.files[rel] !== digest(current)) throw new Error(`conflict：${rel} 已有未受管理內容或手動修改，未覆寫`)
      mkdirSync(dirname(to), { recursive: true })
      writeFileSync(to, expected)
      state.files[rel] = digest(expected)
      changed.push(rel)
      mkdirSync(dirname(path), { recursive: true })
      writeFileSync(path, JSON.stringify(state, null, 2) + '\n')
    },
    prune() {
      for (const [rel, hash] of Object.entries(state.files)) {
        if (!rel.startsWith('.agents/skills/') && !rel.startsWith('.codex/agents/')) continue
        if (desired.has(rel)) continue
        const target = join(home, rel)
        if (existsSync(target)) {
          if (digest(readFileSync(target)) !== hash) throw new Error(`conflict：${rel} 已手動修改，未刪除`)
          unlinkSync(target)
          changed.push(rel)
        }
        delete state.files[rel]
      }
    },
    save() {
      mkdirSync(dirname(path), { recursive: true })
      writeFileSync(path, JSON.stringify(state, null, 2) + '\n')
    },
  }
}

export function syncUser(home = homedir(), mcpNames) {
  const owned = ownership(home)
  if (mcpNames) owned.state.mcpNames = mcpNames
  const runtime = join(home, '.codex/support/claude-home/runtime.md')
  const preface = `\n## Codex runtime 適配（優先於下方 Claude 專用操作）\n\n先讀 ${runtime}。執行 runtime 與分析對象分開判斷；Claude 路徑／transcript 不可機械替換成 Codex。腳本位置以本 SKILL.md 的實際目錄解析，不依賴 CLAUDE_SKILL_DIR。\n\n`
  const skills = join(home, '.claude/skills')
  for (const e of existsSync(skills) ? readdirSync(skills, { withFileTypes: true }) : []) {
    if (!e.isDirectory() || e.name === 'synced' || !existsSync(join(skills, e.name, 'SKILL.md'))) continue
    const src = join(skills, e.name)
    for (const p of walk(src)) {
      let body = readFileSync(p)
      if (relative(src, p) === 'SKILL.md') {
        const parts = split(body.toString('utf8'))
        body = parts.header + preface + parts.body
      }
      owned.put(join(home, '.agents/skills', e.name, relative(src, p)), body)
    }
    if (/^disable-model-invocation:\s*true\s*$/m.test(read(join(src, 'SKILL.md'))) && !existsSync(join(src, 'agents/openai.yaml'))) {
      owned.put(join(home, '.agents/skills', e.name, 'agents/openai.yaml'), 'policy:\n  allow_implicit_invocation: false\n')
    }
  }
  const reviewerPrefix = `你正在 Codex 執行唯讀審查。先讀 ${runtime} 的 reviewer 適配。若下文說 rules 已載入且禁止重讀，但實際只有索引，必須讀取相關來源再下結論。受審檔若是 Codex，使用 Codex schema，不用 Claude frontmatter／模型值判錯。缺乏證據時標未驗證。不得改檔、執行受審 hook、派工或呼叫 MCP。\n\n`
  const agents = join(home, '.claude/agents')
  for (const p of walk(agents).filter(p => p.endsWith('.md'))) {
    const { meta, body } = split(read(p))
    const name = field(meta, 'name'), description = field(meta, 'description')
    if (!name || !description) throw new Error(`agent 缺 name/description：${p}`)
    const toml = [
      `name = ${JSON.stringify(name)}`, `description = ${JSON.stringify(description)}`,
      'sandbox_mode = "read-only"',
      `developer_instructions = ${JSON.stringify(reviewerPrefix + body.trim())}`,
      // agent TOML 先驗 transport 才合併 parent；disabled server 仍須提供合法 transport。
      ...(owned.state.mcpNames ?? []).map(n => `\n[mcp_servers.${JSON.stringify(n)}]\ncommand = "disabled-by-reviewer-policy"\nenabled = false`), '',
    ].join('\n')
    owned.put(join(home, '.codex/agents', `${name}.toml`), toml)
  }
  let root = read(join(home, '.claude/CLAUDE.md'))
  root = root.replace(/^@(\S+\.md)\s*$/gm, (_, path) => {
    const value = read(join(home, '.claude', path))
    if (!value) throw new Error(`找不到 user root 匯入：${path}`)
    return value.trim()
  })
  const rules = []
  const scoped = []
  for (const p of walk(join(home, '.claude/rules')).filter(p => p.endsWith('.md'))) {
    const text = read(p)
    if (/^---\r?\n/.test(text)) {
      const { meta, body } = split(text)
      if (/^paths:/m.test(meta)) { scoped.push(`- ${p}\n${meta}`); continue }
      rules.push(`\n## ${p}\n\n${body}`)
    } else rules.push(`\n## ${p}\n\n${text}`)
  }
  owned.put(join(home, '.codex/AGENTS.md'), `<!-- claude-home:generated -->\n${root}\n${rules.join('\n')}\n## 條件式規則：工作前按 paths 讀取原檔\n\n${scoped.join('\n')}\n\n## 雙工具適配\n\n涉及 user skill、reviewer 或跨工具交接時，先讀 ${runtime}。\n`)
  owned.prune()
  owned.save()
  return owned.changed
}

export function installSupport(home = homedir()) {
  const owned = ownership(home)
  const dest = join(home, '.codex/support/claude-home')
  for (const name of ['sync-user.mjs', 'session-start.mjs', 'tool-policy.mjs', 'runtime.md']) owned.put(join(dest, name), readFileSync(join(here, name)))
  // Codex /hooks 會在目前 profile 追加信任狀態；保留 runtime 的狀態區塊。
  const profile = join(home, '.codex/claude-coop.config.toml')
  const base = readFileSync(join(here, 'claude-coop.config.toml'), 'utf8')
  const currentProfile = read(profile)
  const stateAt = currentProfile.indexOf('\n[hooks.state]')
  if (stateAt >= 0 && currentProfile.slice(0, stateAt).trimEnd() === base.trimEnd()) {
    owned.state.files[relative(home, profile)] = digest(currentProfile)
    owned.put(profile, currentProfile)
  } else owned.put(profile, base)
  const hookPath = join(home, '.codex/hooks.json')
  const hooks = read(hookPath) ? JSON.parse(read(hookPath)) : { hooks: {} }
  const quote = value => process.platform === 'win32' ? `"${value}"` : `'${value.replace(/'/g, "'\\''")}'`
  for (const [event, script, matcher] of [['SessionStart', 'session-start.mjs', undefined], ['PreToolUse', 'tool-policy.mjs', '^Bash$']]) {
    const command = `${quote(process.execPath)} ${quote(join(dest, script))}`
    const groups = hooks.hooks ??= {}
    const entries = groups[event] ??= []
    const mine = entries.filter(g => g.hooks?.some(h => h.command?.includes(`/claude-home/${script}`) || h.command?.includes(`\\claude-home\\${script}`)))
    if (mine.length === 0) entries.push({ ...(matcher ? { matcher } : {}), hooks: [{ type: 'command', command, timeout: 10 }] })
    else if (mine.length !== 1 || mine[0].hooks.length !== 1 || mine[0].hooks[0].command !== command || mine[0].matcher !== matcher || mine[0].hooks[0].type !== 'command' || mine[0].hooks[0].timeout !== 10) throw new Error(`hook conflict：${event}，保留手動設定`)
  }
  // hooks.json 包含別人的設定，僅合併自己的 entries；不接管整份檔案。
  mkdirSync(dirname(hookPath), { recursive: true })
  writeFileSync(hookPath, JSON.stringify(hooks, null, 2) + '\n')
  owned.save()
  return owned.changed
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const install = process.argv.includes('--install')
    if (install) installSupport()
    const mcp = install ? JSON.parse(execFileSync('codex', ['mcp', 'list', '--json'], { encoding: 'utf8' })).map(x => x.name) : undefined
    const changed = syncUser(homedir(), mcp)
    if (!process.argv.includes('--quiet')) console.log(`Codex user 副本已同步：${changed.length} 個檔案。`)
  } catch (error) { console.error(error.message); process.exitCode = 1 }
}
