# drovr

High-level agent collaboration patterns on [herdr](https://herdr.dev).

drovr is **not** a herdr wrapper. herdr (and hunk) provide their own CLIs and skills for low-level operations. drovr sits above them, providing **orchestrated behaviors** — combining multiple tools with decision logic, state management, and idempotency guarantees.

## Design Principle

Each drovr verb encapsulates:
- **Decision logic** (e.g., which direction to split a pane)
- **Tool orchestration** (e.g., herdr + hunk working together)
- **State management** (e.g., idempotent start/stop lifecycle)

If something can be done with a single `herdr` or `hunk` command, drovr doesn't wrap it.

## Requirements

- bash 4+
- python3
- [herdr](https://herdr.dev) running
- [hunk](https://hunk.dev) (for `drovr diff`)
- At least one AI agent CLI for `drovr delegate` (kiro-cli, codex, or agy)

## Install

```bash
git clone <this-repo> ~/workspace/drovr
cd ~/workspace/drovr
./install.sh
```

This will:
1. Place `drovr` wrapper in `~/.local/bin/`
2. Install kiro-cli hooks to `~/.kiro/hooks/`

Add to PATH if needed:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Uninstall

```bash
./uninstall.sh
```

## Verbs

### `diff` — Live diff view

Opens a `hunk diff --watch` pane that auto-reloads on file changes. Split direction is determined automatically from the current pane dimensions.

```bash
# Start (idempotent — safe to call multiple times)
drovr diff start

# With a specific target
drovr diff start main

# Staged changes
drovr diff start --staged

# Specific files
drovr diff start -- src/app.ts src/utils.ts

# Check status
drovr diff status

# Stop
drovr diff stop
```

### `delegate` — Task delegation to other agents

Delegate work to AI agents running in parallel herdr panes. Results are sent back automatically.

```bash
# Single delegation (uses default CLI based on $HERDR_AGENT)
drovr delegate "Review this PR"

# Single delegation with explicit CLI
drovr delegate "codex:Review this PR"

# Multiple parallel delegations (auto-layout)
drovr delegate \
  "kiro-cli:Investigate the auth bug" \
  "codex:Check dependency vulnerabilities" \
  "agy:Analyze error handling patterns"

# Cleanup leftover panes
drovr delegate clean
```

**CLI resolution order:**
1. `cli:` prefix in the argument (explicit)
2. `$DROVR_CLI` environment variable
3. `$HERDR_AGENT` mapping (kiro→kiro-cli, codex→codex, claude/agy→agy)
4. First available CLI in PATH

**Supported CLIs:**

| CLI | Command | Best for |
|-----|---------|----------|
| `kiro-cli` | `kiro-cli chat --no-interactive --trust-all-tools` | General tasks, tool use |
| `codex` | `codex exec` | Fast code generation |
| `agy` | `agy --dangerously-skip-permissions -p` | Reasoning, analysis |

**Result delivery:**

Results arrive as `[RETURN:cli-name]` messages in the caller pane after the agent finishes.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HERDR_SOCKET_PATH` | Override herdr socket path | Auto-detect |
| `HERDR_PANE_ID` | Override current pane ID | `herdr pane current` |
| `HERDR_AGENT` | Agent label (set by herdr) | Auto |
| `DROVR_CLI` | Default CLI for delegate | Auto-detect |
| `DROVR_INSTALL_DIR` | Install directory | `~/.local/bin` |

## File Structure

```
drovr/
├── bin/drovr              # Entry point (verb dispatcher)
├── lib/
│   ├── herdr-core.sh      # Internal: socket API, pane discovery
│   ├── delegate-kiro-cli.sh  # Internal: kiro-cli delegate wrapper
│   ├── delegate-codex.sh     # Internal: codex delegate wrapper
│   └── delegate-agy.sh       # Internal: agy delegate wrapper
├── hooks/
│   └── kiro/              # kiro-cli hooks (→ ~/.kiro/hooks/)
│       └── live-diff.json
├── skills/
│   ├── delegate/          # Delegation skill
│   └── live-diff/         # Live diff skill
├── notes/                 # Design notes (ephemeral)
├── install.sh
├── uninstall.sh
├── LICENSE
└── README.md
```

## Skills

Install drovr skills for agent guidance:

```bash
gh skill install 44103/drovr
```

Available skills:
- **delegate** — Parallel task delegation to other AI agents
- **live-diff** — Idempotent live diff view management

## Hooks

Agent-specific hooks are installed globally by `install.sh`.

### kiro-cli

| Hook | Trigger | Description |
|------|---------|-------------|
| `live-diff.json` | PostFileSave | Automatically start live diff pane on file save |

## How It Differs from herdr/hunk

| Tool | Role |
|------|------|
| **herdr** | Terminal multiplexer + agent state protocol |
| **hunk** | Diff viewer with watch mode |
| **drovr** | Orchestrates herdr + hunk + AI CLIs into reusable collaboration patterns |

Use `herdr` directly for pane/agent operations. Use `hunk` directly for one-off diff viewing. Use `drovr` when you need **combined behaviors with lifecycle management**.

## License

MIT
