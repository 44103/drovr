# live-diff

Show a live diff view alongside the working pane so the user can see file changes in real time.

## When to Use

- After editing files, to let the user visually review diffs as they happen
- When the user says "diff", "差分表示", "変更見せて", "live diff", "watch diff"
- At the start of a coding session to provide continuous visual feedback
- When making multiple file edits and want the user to track progress

## How It Works

The `drovr diff start` command:

1. Checks if a diff pane is already running (idempotent — won't open duplicates)
2. Gets the current pane dimensions via herdr
3. Auto-determines split direction (right if wide, down if tall)
4. Splits the pane and launches `hunk diff --watch` in the new pane
5. Labels the pane as `drovr:diff` for identification

The hunk watch session auto-reloads whenever files in the working tree change.

## Usage

### Start live diff (idempotent)

```bash
drovr diff start
```

### Start with specific target

```bash
drovr diff start main
```

### Start with staged changes

```bash
drovr diff start --staged
```

### Start with specific files

```bash
drovr diff start -- src/app.ts src/utils.ts
```

### Check if running

```bash
drovr diff status
```

### Stop and close the diff pane

```bash
drovr diff stop
```

## Guidelines

1. Call `drovr diff start` early in a session — it's idempotent, so calling it multiple times is safe
2. The diff pane does NOT take focus; the agent keeps working in its own pane
3. Do not call `drovr diff stop` unless the user asks to close it or the session is ending
4. One diff pane per session is sufficient — `--watch` auto-updates on file changes
5. Requires `herdr` running (HERDR_ENV=1) and `drovr` installed

## Limitations

- Requires herdr to be running
- Only one diff pane is active at a time (by design)
- Shows diffs relative to the git working tree (or staged area with --staged)
- If the pane is accidentally closed externally, `drovr diff start` will create a new one
