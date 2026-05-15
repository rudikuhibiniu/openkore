# Ruflo — Claude Code Configuration

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

---

## Git Setup

### Branch
- **`master`** — upstream OpenKore (jangan dimodif)
- **`ROGUE`** — konfigurasi rogue bot + idROClassic (branch ini)

### Remote
```
https://github.com/rudikuhibiniu/openkore.git
```
SSH tidak bisa (no key) — gunakan HTTPS.

### Identity (set sekali per repo)
```bash
git config user.email "data.rudik@gmail.com"
git config user.name "rudikuhibiniu"
```

### Workflow
```bash
git checkout ROGUE
# ... edit files ...
git add <files>   # jangan "git add ." — ada file garbage di root
git commit -m "pesan"
git push
```

---

## RevoclassicR (idRO Classic) — Verified Working Config

### How to Run
```
C:\strawberry512\perl\bin\perl.exe openkore.pl --interface=Console
```
Or double-click `start-revoclassic.bat`.

### Server Info (reverse-engineered, verified)
- Login: `103.210.209.43:6900` (NOT forums' 202.93.25.134:50001)
- Char: `103.210.209.43:6121`
- serverType: `idROClassic` (custom, see `src/Network/Send/idROClassic.pm`)

### Key Custom Files
| File | Purpose |
|------|---------|
| `src/Network/Send/idROClassic.pm` | Custom packets F020 (login) + C4D9 (char login) |
| `src/Network/Receive/idROClassic.pm` | D3A7 server response handler |
| `tables/idROClassic/recvpackets.txt` | tRO base + D3A7 (-1) + 9291 (6) |

### config.txt Required Settings
```
idroClassicHWID 0045-45FB-FB13-13E2
idroClassicIPv6 2001:448a:20a2:5564:9000:8759:b54a:db01
```

### Perl Dependency
- **Must use** Strawberry Perl 5.12 32-bit at `C:\strawberry512\`
- Newer Perl breaks because XSTools.dll links against `perl512.dll`

### Common Pitfalls
- `addTableFolders` separator = `;` (semicolon), NOT space
- C4D9 game_login: field must be `accountSex` (not `sex`)
- Login server changed from 202.x → 103.x — old configs won't work

---

## Rogue Bot — pay_fild02 Config Notes

### Target Monsters (mon_control.txt)
```
Wolf 2 0 0          # attack=2: always attack, even while sitting
Creamy 2 0 0
Orc Warrior 2 0 0
Orc Lady 2 0 0
Orc Baby 2 0 0
all 1 0 0           # semua monster lain: auto-attack (tidak saat duduk)
```
MVP dan monster berbahaya tetap di-set `-1` (diabaikan).

### Critical Config Settings (config.txt)
| Setting | Value | Why |
|---|---|---|
| `lockMap` | `pay_fild02` | Lock area grinding |
| `route_randomWalk_inLockOnly` | `1` | **Wajib 1** — kalau `0`, random walk bisa masuk portal ke pay_fild03 |
| `attackAuto_followTarget` | `0` | **Wajib 0** — kalau `1`, bot ngejar monster sampai keluar map |
| `attackAuto_outOfLock` | `1` | Tetap serang kalau nyasar, `attackAuto_routeToLock` akan balikin |
| `attackAuto_party` | `1` | Serang balik monster yang menyerang party member |

### EventMacros (control/eventMacros.txt)

**buffcheck** — Trigger: Blessing habis + di lock map + `NoMobNear 1` (tidak ada mob di layar)
- Kondisi `NoMobNear` butuh nilai dummy (`NoMobNear 1`) — parser wajib format `key value`
- Aksi: matikan attack + randomWalk, gerak ke `gef_fild10 156 308`, tunggu 10 detik, lanjut

**statusQuery** — Trigger: Whisper `@status` (PrivMsg condition)
- ⚠️ Saat ini `PrivMsg` di-comment — automacro fire setiap 3 detik tanpa trigger
- Untuk aktifkan: uncomment baris `#    PrivMsg /^\@status$/i`
- Aksi: kirim 4 baris PM berisi info lengkap char ke pengirim whisper

**statusReply** — Konten balasan `@status`:
- Baris 1: `[BOT] Char: NAME | Lv: BASE | Job Lv: JOB`
- Baris 2: `HP: cur/max (%) | SP: cur/max`
- Baris 3: `Weight: cur/max (%) | Zeny: Z z`
- Baris 4: `Map: mapname (x, y)`
- Variabel diakses via `&eval($char->{field})` dan `$field->baseName`

### Support Bot Location
- Buff trip: `gef_fild10 156 308`

### eventMacro Plugin Notes
- Semua condition butuh format `key value` — keyword tanpa nilai menyebabkan error "not a pair"
- `&eval(expr)` bisa akses semua variabel Perl OpenKore (`$char`, `$field`, dll)
- `$.PrivMsgLastName` = nama pengirim whisper terakhir yang memicu automacro
