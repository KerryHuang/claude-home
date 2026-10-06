import test from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import { syncUser, installSupport } from '../codex/sync-user.mjs'
import { inspectCommand } from '../codex/tool-policy.mjs'

const fixture = () => {
  const home = mkdtempSync(join(tmpdir(), 'codex-parity-test-'))
  mkdirSync(join(home, '.claude/skills/graphify'), { recursive: true })
  writeFileSync(join(home, '.claude/skills/graphify/SKILL.md'), '---\nname: graphify\ndescription: Query graphs.\n---\nOriginal instructions.\n')
  mkdirSync(join(home, '.claude/agents'), { recursive: true })
  writeFileSync(join(home, '.claude/agents/reviewer.md'), '---\nname: reviewer\ndescription: Review settings.\nmodel: opus\neffort: medium\ntools: ["Read"]\n---\nRead evidence.\n')
  writeFileSync(join(home, '.claude/CLAUDE.md'), '# User\n@shared/rules.md\n')
  mkdirSync(join(home, '.claude/shared'), { recursive: true })
  writeFileSync(join(home, '.claude/shared/rules.md'), 'Use Traditional Chinese.\n')
  return home
}

test('sync produces usable guidance and read-only agents without changing Claude sources', () => {
  const home = fixture()
  try {
    const original = readFileSync(join(home, '.claude/skills/graphify/SKILL.md'), 'utf8')
    assert.ok(syncUser(home, ['example-mcp']).length > 0)
    assert.deepEqual(syncUser(home, ['example-mcp']), [])
    const skill = readFileSync(join(home, '.agents/skills/graphify/SKILL.md'), 'utf8')
    assert.ok(skill.startsWith('---\nname: graphify\n'))
    assert.ok(skill.includes('runtime.md'))
    assert.equal(readFileSync(join(home, '.claude/skills/graphify/SKILL.md'), 'utf8'), original)
    const agent = readFileSync(join(home, '.codex/agents/reviewer.toml'), 'utf8')
    assert.ok(agent.includes('sandbox_mode = "read-only"'))
    assert.ok(agent.includes('[mcp_servers."example-mcp"]\ncommand = "disabled-by-reviewer-policy"\nenabled = false'))
    assert.ok(!agent.includes('model = "opus"'))
    assert.ok(readFileSync(join(home, '.codex/AGENTS.md'), 'utf8').includes('Use Traditional Chinese.'))
  } finally { rmSync(home, { recursive: true, force: true }) }
})

test('foreign files and manual edits are preserved; ownership does not allow silent overwrites', () => {
  const home = fixture()
  try {
    mkdirSync(join(home, '.agents/skills/other'), { recursive: true })
    writeFileSync(join(home, '.agents/skills/other/SKILL.md'), 'foreign')
    syncUser(home, [])
    writeFileSync(join(home, '.codex/agents/reviewer.toml'), 'manual edit')
    assert.throws(() => syncUser(home, []), /手動修改|conflict/)
    assert.equal(readFileSync(join(home, '.codex/agents/reviewer.toml'), 'utf8'), 'manual edit')
    assert.equal(readFileSync(join(home, '.agents/skills/other/SKILL.md'), 'utf8'), 'foreign')
  } finally { rmSync(home, { recursive: true, force: true }) }
})

test('support installation merges hooks, preserves foreign hooks, and is idempotent', () => {
  const home = fixture()
  try {
    mkdirSync(join(home, '.codex'), { recursive: true })
    writeFileSync(join(home, '.codex/hooks.json'), JSON.stringify({ hooks: { Stop: [{ hooks: [{ type: 'command', command: 'foreign-hook' }] }] } }))
    installSupport(home)
    const first = readFileSync(join(home, '.codex/hooks.json'), 'utf8')
    installSupport(home)
    assert.equal(readFileSync(join(home, '.codex/hooks.json'), 'utf8'), first)
    assert.ok(first.includes('foreign-hook'))
    assert.ok(first.includes('tool-policy.mjs'))
  } finally { rmSync(home, { recursive: true, force: true }) }
})

test('Git guard denies dangerous commands without executing them and permits scoped staging', () => {
  for (const command of ['git add -vA', 'git clean -d --force', 'git push -vf origin main', 'git push origin +main', "bash -lc 'git add .'", 'git add .', 'git -C repo add -A', 'git add --all', 'git push origin main --force', 'git --no-pager tag v1', 'git reset --hard', 'git clean -fd', 'git push origin --delete main']) {
    assert.ok(inspectCommand(command), command)
  }
  for (const command of ['git status --short', 'git add file.md', 'git -C repo push origin feature/x', 'git tag --list', 'git log --oneline', 'printf "git add ."', 'echo git add .', "echo ';' git add .", "printf '%s' ';' git add .", "printf '%s\\n' git add ."]) {
    assert.equal(inspectCommand(command), null, command)
  }
})


test('sync removes deleted owned sources and stale policy but preserves manual files', () => {
  const home = fixture()
  try {
    const src = join(home, '.claude/skills/graphify/SKILL.md')
    const original = readFileSync(src, 'utf8')
    writeFileSync(src, original.replace('description:', 'disable-model-invocation: true\ndescription:'))
    syncUser(home, [])
    writeFileSync(src, original)
    syncUser(home, [])
    assert.throws(() => readFileSync(join(home, '.agents/skills/graphify/agents/openai.yaml')), /ENOENT/)
    rmSync(join(home, '.claude/agents/reviewer.md'))
    syncUser(home, [])
    assert.throws(() => readFileSync(join(home, '.codex/agents/reviewer.toml')), /ENOENT/)
    writeFileSync(join(home, '.codex/AGENTS.md'), '')
    assert.throws(() => syncUser(home, []), /conflict/)
  } finally { rmSync(home, { recursive: true, force: true }) }
})

test('installation detects modified hook matcher instead of silently disabling protection', () => {
  const home = fixture()
  try {
    installSupport(home)
    const path = join(home, '.codex/hooks.json')
    const value = JSON.parse(readFileSync(path, 'utf8'))
    value.hooks.PreToolUse[0].matcher = 'NeverMatch'
    writeFileSync(path, JSON.stringify(value))
    assert.throws(() => installSupport(home), /hook conflict/)
  } finally { rmSync(home, { recursive: true, force: true }) }
})

test('installation preserves runtime hook trust appended to the cooperation profile', () => {
  const home = fixture()
  try {
    installSupport(home)
    const path = join(home, '.codex/claude-coop.config.toml')
    const body = readFileSync(path, 'utf8') + '\n[hooks.state]\ntrusted = "fixture"\n'
    writeFileSync(path, body)
    installSupport(home)
    assert.equal(readFileSync(path, 'utf8'), body)
  } finally { rmSync(home, { recursive: true, force: true }) }
})
