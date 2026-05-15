# OpenKore Priest Bot — Project Context

## About This Project

OpenKore bot untuk karakter **Priest/Acolyte** di server **idRO RevoclassicR (Baphomet)**.

- **Nama karakter**: Jilak-Memet (Acolyte)
- **Mode saat ini**: lockMap `gef_fild10` (156, 308) — bukan follow mode
- **Follow target**: `Veronikako` (diaktifkan lewat `follow 1` bila diperlukan)
- **Peran**: Support/heal party — Blessing, Increase AGI, Heal
- **File deploy Ubuntu**: `Makefile.ubuntu`, `start-ubuntu.sh`

## Key Config Files

| File | Keterangan |
|------|------------|
| `control/config.txt` | Konfigurasi utama (follow, skill, attack, dll) |
| `control/mon_control.txt` | Kontrol monster |
| `control/pickupitems.txt` | Item yang diambil |
| `tables/servers.txt` | Server list |

## Pengaturan Penting

| Setting | Nilai | Keterangan |
|---------|-------|------------|
| `follow` | `0` | Follow off (set `1` untuk aktifkan) |
| `followTarget` | `Veronikako` | Target follow |
| `lockMap` | `gef_fild10` | Map saat ini |
| `attackAuto` | `0` | Tidak menyerang |
| `attackAuto_followTarget` | `0` | Tidak menyerang walau follow |
| `mon_control default` | `-1` | Abaikan semua monster walau diserang |
| `Vagabond Wolf` | `0 1 0` | Teleport saat Vagabond Wolf muncul di layar |
| `teleportAuto_hp` | `50` | Fly Wing saat HP ≤ 50% |
| `teleportAuto_minAggressives` | `2` | Fly Wing saat ≥ 2 monster aggro |
| `teleportAuto_maxDmg` | `100` | Fly Wing saat kena hit > 100 dmg |
| `teleportAuto_useSkill` | `0` | Gunakan Fly Wing (item), bukan skill |
| `teleportAuto_item1` | `601` | ID Fly Wing eksplisit |
| `useSelf_skill Heal` | `lvl 5, hp 1..80, sp >5%` | Self-heal |
| `useSelf_skill_smartHeal` | `0` | SmartHeal off (heal langsung level 5) |
| `partySkill Heal` | `target_hp 1..90` | Heal Veronikako < 90% HP |
| `sitAuto_hp_lower/upper` | `40 / 80` | Duduk <40%, berdiri ≥80% |

## Catatan Debugging

- Bot masih menyerang → pastikan `attackAuto_followTarget 0` dan `default -1` di mon_control (perlu restart bot)
- Heal tidak jalan → cek level Heal di game cocok dengan `lvl` di config; `smartHeal 0` diperlukan
- Teleport disconnect = **normal** (OpenKore reconnect via Account Server setelah Fly Wing)
- Fly Wing tidak jalan → pastikan item ID 601 ada di inventory

---

# Ruflo — Claude Code Configuration

## File Search (fff MCP)

For any file search, grep, or path lookup in this project, use fff MCP tools:
- `mcp__fff__fffind` — find files by name/path pattern
- `mcp__fff__ffgrep` — grep file contents (fast, memory-resident)
- `mcp__fff__fff-multi-grep` — multi-pattern content search

Do NOT use native Grep, Glob, or Bash find/rg when fff tools are available.

## Rules

- Do what has been asked; nothing more, nothing less
- NEVER create files unless absolutely necessary — prefer editing existing files
- NEVER create documentation files unless explicitly requested
- NEVER save working files or tests to root — use `/src`, `/tests`, `/docs`, `/config`, `/scripts`
- ALWAYS read a file before editing it
- NEVER commit secrets, credentials, or .env files
- Keep files under 500 lines
- Validate input at system boundaries

## Agent Comms (SendMessage-First Coordination)

Named agents coordinate via `SendMessage`, not polling or shared state.

```
Lead (you) ←→ architect ←→ developer ←→ tester ←→ reviewer
              (named agents message each other directly)
```

### Spawning a Coordinated Team

```javascript
// ALL agents in ONE message, each knows WHO to message next
Agent({ prompt: "Research the codebase. SendMessage findings to 'architect'.",
  subagent_type: "researcher", name: "researcher", run_in_background: true })
Agent({ prompt: "Wait for 'researcher'. Design solution. SendMessage to 'coder'.",
  subagent_type: "system-architect", name: "architect", run_in_background: true })
Agent({ prompt: "Wait for 'architect'. Implement it. SendMessage to 'tester'.",
  subagent_type: "coder", name: "coder", run_in_background: true })
Agent({ prompt: "Wait for 'coder'. Write tests. SendMessage results to 'reviewer'.",
  subagent_type: "tester", name: "tester", run_in_background: true })
Agent({ prompt: "Wait for 'tester'. Review code quality and security.",
  subagent_type: "reviewer", name: "reviewer", run_in_background: true })

// Kick off the pipeline
SendMessage({ to: "researcher", summary: "Start", message: "[task context]" })
```

### Patterns

| Pattern | Flow | Use When |
|---------|------|----------|
| **Pipeline** | A → B → C → D | Sequential dependencies (feature dev) |
| **Fan-out** | Lead → A, B, C → Lead | Independent parallel work (research) |
| **Supervisor** | Lead ↔ workers | Ongoing coordination (complex refactor) |

### Rules

- ALWAYS name agents — `name: "role"` makes them addressable
- ALWAYS include comms instructions in prompts — who to message, what to send
- Spawn ALL agents in ONE message with `run_in_background: true`
- After spawning: STOP, tell user what's running, wait for results
- NEVER poll status — agents message back or complete automatically

## Swarm & Routing

### Config
- **Topology**: hierarchical-mesh (anti-drift)
- **Max Agents**: 15
- **Memory**: hybrid
- **HNSW**: Enabled
- **Neural**: Enabled

```bash
npx @claude-flow/cli@latest swarm init --topology hierarchical --max-agents 8 --strategy specialized
```

### Agent Routing

| Task | Agents | Topology |
|------|--------|----------|
| Bug Fix | researcher, coder, tester | hierarchical |
| Feature | architect, coder, tester, reviewer | hierarchical |
| Refactor | architect, coder, reviewer | hierarchical |
| Performance | perf-engineer, coder | hierarchical |
| Security | security-architect, auditor | hierarchical |

### When to Swarm
- **YES**: 3+ files, new features, cross-module refactoring, API changes, security, performance
- **NO**: single file edits, 1-2 line fixes, docs updates, config changes, questions

### 3-Tier Model Routing

| Tier | Handler | Use Cases |
|------|---------|-----------|
| 1 | Agent Booster (WASM) | Simple transforms — skip LLM, use Edit directly |
| 2 | Haiku | Simple tasks, low complexity |
| 3 | Sonnet/Opus | Architecture, security, complex reasoning |

## Memory & Learning

### Before Any Task
```bash
npx @claude-flow/cli@latest memory search --query "[task keywords]" --namespace patterns
npx @claude-flow/cli@latest hooks route --task "[task description]"
```

### After Success
```bash
npx @claude-flow/cli@latest memory store --namespace patterns --key "[name]" --value "[what worked]"
npx @claude-flow/cli@latest hooks post-task --task-id "[id]" --success true --store-results true
```

### MCP Tools (use `ToolSearch("keyword")` to discover)

| Category | Key Tools |
|----------|-----------|
| **Memory** | `memory_store`, `memory_search`, `memory_search_unified` |
| **Bridge** | `memory_import_claude`, `memory_bridge_status` |
| **Swarm** | `swarm_init`, `swarm_status`, `swarm_health` |
| **Agents** | `agent_spawn`, `agent_list`, `agent_status` |
| **Hooks** | `hooks_route`, `hooks_post-task`, `hooks_worker-dispatch` |
| **Security** | `aidefence_scan`, `aidefence_is_safe`, `aidefence_has_pii` |
| **Hive-Mind** | `hive-mind_init`, `hive-mind_consensus`, `hive-mind_spawn` |

### Background Workers

| Worker | When |
|--------|------|
| `audit` | After security changes |
| `optimize` | After performance work |
| `testgaps` | After adding features |
| `map` | Every 5+ file changes |
| `document` | After API changes |

```bash
npx @claude-flow/cli@latest hooks worker dispatch --trigger audit
```

## Agents

**Core**: `coder`, `reviewer`, `tester`, `planner`, `researcher`
**Architecture**: `system-architect`, `backend-dev`, `mobile-dev`
**Security**: `security-architect`, `security-auditor`
**Performance**: `performance-engineer`, `perf-analyzer`
**Coordination**: `hierarchical-coordinator`, `mesh-coordinator`, `adaptive-coordinator`
**GitHub**: `pr-manager`, `code-review-swarm`, `issue-tracker`, `release-manager`

Any string works as a custom agent type.

## Build & Test

- ALWAYS run tests after code changes
- ALWAYS verify build succeeds before committing

```bash
npm run build && npm test
```

## CLI Quick Reference

```bash
npx @claude-flow/cli@latest init --wizard           # Setup
npx @claude-flow/cli@latest swarm init --v3-mode     # Start swarm
npx @claude-flow/cli@latest memory search --query "" # Vector search
npx @claude-flow/cli@latest hooks route --task ""    # Route to agent
npx @claude-flow/cli@latest doctor --fix             # Diagnostics
npx @claude-flow/cli@latest security scan            # Security scan
npx @claude-flow/cli@latest performance benchmark    # Benchmarks
```

26 commands, 140+ subcommands. Use `--help` on any command for details.

## Setup

```bash
claude mcp add claude-flow -- npx -y @claude-flow/cli@latest
npx @claude-flow/cli@latest daemon start
npx @claude-flow/cli@latest doctor --fix
```

**Agent tool** handles execution (agents, files, code, git). **MCP tools** handle coordination (swarm, memory, hooks). **CLI** is the same via Bash.
