# herdr-subagents

Spawn parallel sub-agents in herdr terminal panes with automatic layout and result collection.

## When to Use

- When the user asks to split work into multiple sub-agents or parallel tasks
- When investigating a topic from multiple angles simultaneously
- When the user says "sub-agent", "parallel", "split into N parts", or similar
- When the orchestrator decides that a task benefits from parallel investigation

## How It Works

The `drovr-spawn-multi` command creates a split-pane layout in herdr:

- Main pane (top 40%) stays with the orchestrator
- Sub panes (bottom 60%) are equally split horizontally for each sub-agent

Each sub-agent runs a CLI wrapper (`kiro-cli-sub`, `codex-sub`, or `agy-sub`) that:

1. Reports `working` status to herdr
2. Runs the AI CLI in non-interactive mode with `tee` (visible in pane)
3. Captures output, strips ANSI codes and noise
4. Sends the result back to the main pane via `herdr pane send-text`
5. Pane auto-closes after completion

## Usage

### Command

```bash
drovr-spawn-multi \
  "<wrapper>:<prompt>" \
  "<wrapper>:<prompt>" \
  ...
```

### Available Wrappers

| Wrapper        | CLI      | Non-interactive Mode                      |
| :------------- | :------- | :---------------------------------------- |
| `kiro-cli-sub` | kiro-cli | `chat --no-interactive --trust-all-tools` |
| `codex-sub`    | codex    | `exec`                                    |
| `agy-sub`      | agy      | `--dangerously-skip-permissions -p`       |

### Example

```bash
drovr-spawn-multi \
  "kiro-cli-sub:What is the weather forecast for Tokyo this weekend?" \
  "kiro-cli-sub:Suggest 2 walking courses near Tokyo for July" \
  "kiro-cli-sub:List essential items for a 20km summer walk"
```

### Cleanup (usually not needed - panes auto-close)

```bash
drovr-spawn-multi clean
```

## Result Format

Results arrive as user input in the main pane with these prefixes:

- `[RETURN] ...` — from kiro-cli-sub
- `[RETURN:codex] ...` — from codex-sub
- `[RETURN:agy] ...` — from agy-sub

Content uses `|` as line separator (original newlines replaced).

## Post-Spawn Behavior (CRITICAL)

After running `drovr-spawn-multi`, the orchestrator MUST follow this protocol:

1. **Do NOT poll, sleep, or read sub panes** — results arrive as queued user messages (`[RETURN]` prefix)
2. **Immediately end your turn** with a brief message like "サブエージェントを起動しました。結果を待ちます。"
3. **When `[RETURN]` messages arrive** (as new user inputs), collect them one by one
4. **Once all expected results are received** (count matches the number of spawned agents), synthesize and present to the user

### Why This Matters

The main agent is **busy** while processing tool calls, which **blocks the Kiro queue**.
If the orchestrator keeps calling tools (sleep, herdr read, etc.) after spawn, `[RETURN]`
messages pile up in the queue and cannot be delivered until the turn ends.
Ending the turn quickly allows results to flow in as subsequent user inputs.

### Anti-Patterns (DO NOT)

- `sleep N && herdr agent read ...` — wastes time and context
- Polling pane status in a loop — panes auto-close, results come via queue
- Trying to `herdr pane read` the main pane for `[RETURN]` — it's your own pane

## Guidelines for the Orchestrator

1. **Keep prompts concise** — instruct sub-agents to respond in 5-7 lines or fewer
2. **Avoid web search when possible** — simpler prompts complete faster and fit in the result buffer
3. **Use kiro-cli-sub by default** — most reliable status reporting and result delivery
4. **Summarize results** — after all `[RETURN]` messages arrive, synthesize them for the user
5. **Result limit** — each result is capped at ~1000 characters (1 line). Very long responses get truncated
6. **Concurrent delivery** — results may arrive simultaneously and merge into one message; parse by `[RETURN` prefix
7. **Track expected count** — remember how many agents you spawned; wait for that many `[RETURN]` messages before summarizing

## Limitations

- Results capped at ~1000 chars per agent (use concise prompts)
- If main pane is busy (tool calls in progress), results queue and deliver only after the turn ends
- Sub panes auto-close after completion (no manual cleanup needed)
- Requires `herdr` running and `drovr` installed
- Results may arrive in any order regardless of spawn order
