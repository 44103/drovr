# delegate

Delegate tasks to other AI agents running in parallel herdr panes, with automatic result collection.

## When to Use

- When the user asks to split work across multiple agents
- When investigating a topic from multiple angles simultaneously
- When the user says "delegate", "parallel", "sub-agent", "split into N parts", "他のエージェントに任せて"
- When a task benefits from a second opinion (e.g., codex for speed, agy for reasoning)

## How It Works

`drovr delegate` starts an AI CLI in a new herdr pane, runs it non-interactively, and sends the result back to the caller pane as a `[RETURN:*]` message.

For multiple delegations, `drovr delegate multi` creates a split layout (main 40% top, agents in bottom 60% equally split) and runs all agents in parallel.

## Usage

### Single delegation

```bash
# Uses default CLI (resolved from $HERDR_AGENT)
drovr delegate "Review this PR for security issues"

# Explicit CLI
drovr delegate "codex:Review this PR for security issues"
drovr delegate "kiro-cli:Investigate the auth flow"
drovr delegate "agy:Analyze error handling patterns"
```

### Multiple parallel delegations

```bash
drovr delegate \
  "kiro-cli:Investigate the auth bug" \
  "codex:Check dependency vulnerabilities" \
  "agy:Analyze error handling patterns"
```

### Cleanup

```bash
drovr delegate clean
```

## Supported CLIs

| CLI | Command | Best for |
|-----|---------|----------|
| `kiro-cli` | `kiro-cli chat --no-interactive --trust-all-tools` | General tasks, tool use |
| `codex` | `codex exec` | Fast code generation, quick answers |
| `agy` | `agy --dangerously-skip-permissions -p` | Reasoning, analysis |

## Result Format

Results arrive as user input in the caller pane with these prefixes:

- `[RETURN:kiro-cli] ...` — from kiro-cli
- `[RETURN:codex] ...` — from codex
- `[RETURN:agy] ...` — from agy

Content uses `|` as line separator (original newlines replaced).

## Post-Delegation Behavior (CRITICAL)

After running `drovr delegate` or `drovr delegate multi`:

1. **Do NOT poll or sleep** — results arrive as queued user messages
2. **End your turn immediately** with a brief message like "エージェントに委譲しました。結果を待ちます。"
3. **When `[RETURN:*]` messages arrive**, collect them
4. **Once all expected results are received**, synthesize and present to the user

### Why This Matters

The main agent is busy while processing tool calls, which blocks the message queue.
Ending the turn quickly allows results to flow in as subsequent user inputs.

## Guidelines

1. Keep prompts concise — instruct delegates to respond in 5-7 lines or fewer
2. Use kiro-cli by default — most reliable for tool use and result delivery
3. Use codex for quick/focused tasks — fastest turnaround
4. Summarize results after all `[RETURN:*]` messages arrive
5. Results are capped at ~1000-1500 characters per agent
6. Results may arrive in any order; track expected count
7. Panes auto-close after the delegate finishes (`&& exit`)

## Limitations

- Results capped at ~1500 chars per agent (use concise prompts)
- Results arrive only after the orchestrator's turn ends
- Requires herdr running and drovr installed
- Each CLI must be independently installed and available in PATH
