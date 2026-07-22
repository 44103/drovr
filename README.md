# drovr

Agent-agnostic bridge between AI coding agents and [herdr](https://herdr.dev).

herdr provides a Socket API for pane management and agent state reporting, but each AI tool's native integration only handles passive session registration. drovr gives **any** agent the ability to actively operate herdr — split panes, run commands, read output, spawn other agents, and report state.

## Supported Agents

| Agent | Active (CLI) |
|-------|:---|
| kiro-cli | `drovr agent spawn --cli kiro-cli` |
| Codex | `drovr agent spawn --cli codex` |
| Claude Code | `drovr agent spawn --cli claude` |
| Any CLI | `drovr agent start <name> -- <cmd>` |

## Features

- **Pane operations**: split / run / read / send / close
- **Live diff**: auto-open `hunk diff --watch` pane for real-time change visibility
- **Agent state report**: idle / working / blocked → herdr status bar
- **Cross-agent spawn**: launch any AI CLI in a new herdr pane
- **Auto-detect**: picks available CLI automatically (`$DROVR_CLI` override)
- **Agent-agnostic core**: no hardcoded agent names; reads `$HERDR_AGENT`

## Requirements

- bash 4+
- python3
- [herdr](https://herdr.dev) running
- [hunk](https://hunk.dev) (for `drovr diff`)
- At least one AI agent CLI (kiro-cli, codex, claude, or any)

## Install

```bash
git clone <this-repo> ~/workspace/drovr
cd ~/workspace/drovr
./install.sh
```

This will:
1. Place `drovr` wrapper in `~/.local/bin/`
2. Install sub-agent wrappers (`kiro-cli-sub`, `codex-sub`, `agy-sub`, `drovr-spawn-multi`)
3. Install agent-specific hooks (e.g., kiro-cli hooks to `~/.kiro/hooks/`)

Add to PATH if needed:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Uninstall

```bash
./uninstall.sh
```

## Usage

### Check connection

```bash
drovr status
```

### Live diff

Open a `hunk diff --watch` pane that auto-reloads on file changes. Split direction (right or down) is determined automatically from the current pane dimensions.

```bash
# Start (idempotent — safe to call multiple times)
drovr diff start

# Start with a specific target
drovr diff start main

# Start with staged changes
drovr diff start --staged

# Start with specific files
drovr diff start -- src/app.ts src/utils.ts

# Check if running
drovr diff status

# Stop and close the diff pane
drovr diff stop
```

### Pane operations

```bash
drovr pane list
drovr pane split --direction right --cwd ~/project
drovr pane run <pane_id> "make test"
drovr pane read <pane_id> --lines 50
drovr pane send <pane_id> "yes"
drovr pane close <pane_id>
```

### Agent state reporting

```bash
drovr agent report working --message "Implementing feature"
drovr agent report idle
drovr agent report blocked --message "Waiting for user"
```

### Spawn AI agents in new panes

```bash
# Auto-detect CLI
drovr agent spawn researcher -- "Investigate the auth bug"

# Specific CLI
drovr agent spawn reviewer --cli codex -- "Review this PR"
drovr agent spawn frontend --cli kiro-cli --agent frontend -- "Fix responsive"
drovr agent spawn analyst --cli claude -- "Analyze dependencies"

# Monitor spawned agents
drovr agent list
drovr agent read researcher
drovr agent wait researcher --status idle --timeout 300000
```

### Start arbitrary processes

```bash
drovr agent start dev-server --split down -- npm run dev
drovr agent start tests --split right -- pytest -v
```

### Cross-agent collaboration

```bash
# Kiro delegates research to Codex
drovr agent spawn codex-research --cli codex -- "Investigate herdr API docs"

# Wait for Codex to finish, then read result
drovr agent wait codex-research --status idle --timeout 120000
drovr pane read $(drovr agent list | grep codex-research | awk '{print $1}') --lines 100
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HERDR_SOCKET_PATH` | Override herdr socket path | Auto-detect |
| `HERDR_PANE_ID` | Override current pane ID | `herdr pane current` |
| `HERDR_AGENT` | Agent label (set by herdr) | Auto |
| `DROVR_CLI` | Default CLI for `agent spawn` | Auto-detect |
| `DROVR_INSTALL_DIR` | Install directory | `~/.local/bin` |

## Architecture

```
┌─────────────────────────────────────────────────┐
│ herdr (multiplexer)                              │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ pane: kiro│  │pane:codex│  │pane:claude│     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │              │              │            │
└───────┼──────────────┼──────────────┼────────────┘
        │              │              │
        ▼              ▼              ▼
   ┌─────────────────────────────────────────┐
   │ drovr (bridge)                          │
   │                                          │
   │  ┌────────────┐  ┌───────────────────┐  │
   │  │ herdr-core │  │ CLI adapters      │  │
   │  │ (socket)   │  │ kiro/codex/claude │  │
   │  └────────────┘  └───────────────────┘  │
   └─────────────────────────────────────────┘
```

## File Structure

```
drovr/
├── bin/drovr            # Main CLI entry point
├── lib/herdr-core.sh    # Core library (socket, pane discovery)
├── hooks/               # Agent-specific hooks (installed globally)
│   └── kiro/            #   kiro-cli hooks (→ ~/.kiro/hooks/)
├── skills/              # Agent skills (install via gh skill install)
│   ├── herdr-subagents/ #   Parallel sub-agent spawning
│   └── live-diff/       #   Live diff viewing
├── install.sh           # Installer
├── uninstall.sh         # Clean uninstaller
├── LICENSE              # MIT
└── README.md
```

## How It Differs from herdr Integrations

herdr's built-in integrations (e.g., `herdr integration install codex`) are **passive** — they report session existence at startup. drovr is **active** — it lets agents:

- Open new panes and run commands in them
- Read output from other panes
- Spawn other AI agents for parallel work
- Dynamically update their state (working/idle/blocked)

Think of herdr integrations as "hello, I exist" and drovr as "I can operate the workspace."

## Skills

drovr includes skills for herdr integration. Install them per agent as follows.

### Kiro CLI

```bash
# Install directly from the GitHub repository
gh skill install 44103/drovr
```

Available skills:
- **herdr-subagents** — Spawn parallel sub-agents in herdr terminal panes
- **live-diff** — Show a live diff view alongside the working pane

## Hooks

drovr ships agent-specific hooks in the `hooks/` directory. These are installed globally by `install.sh`.

### kiro-cli

| Hook | Trigger | Description |
|------|---------|-------------|
| `live-diff.json` | PostFileSave | Automatically start hunk diff --watch pane on file save |

Hooks are installed to `~/.kiro/hooks/` and activate on the next session start.

## License

MIT
