# drovr

Agent-agnostic bridge between AI coding agents and [herdr](https://herdr.dev).

herdr provides a Socket API for pane management and agent state reporting, but each AI tool's native integration only handles passive session registration. drovr gives **any** agent the ability to actively operate herdr — split panes, run commands, read output, spawn other agents, and report state.

## Supported Agents

| Agent | Passive (hook) | Active (CLI) |
|-------|:-:|:-:|
| kiro-cli | hook auto-installed | `drovr agent spawn --cli kiro-cli` |
| Codex | hook auto-installed | `drovr agent spawn --cli codex` |
| Claude Code | hook auto-installed | `drovr agent spawn --cli claude` |
| Any CLI | manual | `drovr agent start <name> -- <cmd>` |

## Features

- **Pane operations**: split / run / read / send / close
- **Agent state report**: idle / working / blocked → herdr status bar
- **Cross-agent spawn**: launch any AI CLI in a new herdr pane
- **Auto-detect**: picks available CLI automatically (`$DROVR_CLI` override)
- **Agent-agnostic core**: no hardcoded agent names; reads `$HERDR_AGENT`

## Requirements

- bash 4+
- python3
- [herdr](https://herdr.dev) running
- At least one AI agent CLI (kiro-cli, codex, claude, or any)

## Install

```bash
git clone <this-repo> ~/workspace/drovr
cd ~/workspace/drovr
./install.sh
```

This will:
1. Place `drovr` wrapper in `~/.local/bin/`
2. Install hooks for detected agents (kiro-cli, codex, claude)

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
├── bin/drovr           # Main CLI entry point
├── lib/herdr-core.sh    # Core library (socket, pane discovery)
├── hooks/               # Reference hook implementations
├── install.sh           # Multi-agent installer
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

Skills are placed in `~/.kiro/skills/herdr-subagents/`.

## License

MIT
