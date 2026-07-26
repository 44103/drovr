# review

Retrieve and act on human review comments from hunk-review.nvim running in the review pane.

## When to Use

- When the user says "review check", "check review comments", "fix review comments", "address review feedback"
- After a coding session where `drovr review start` opened a review pane and the user added comments
- When the user asks you to address feedback from a code review
- Periodically during long implementation sessions if the user is reviewing in parallel

## How It Works

`drovr review check` connects to the nvim instance in the review pane via `--server` RPC, triggers `:HunkReviewExport`, and reads the structured JSON export buffer. The JSON contains all hunks that have comments, with file paths, line numbers, diff context, and the user's comment text.

The review pane is opened by `drovr review start` (often auto-triggered on file save via the `live-diff` hook). The user navigates the diff in hunk-review.nvim, adds comments with `c` (block), `c` in line mode (per-line), or visual-select + `c` (range), then signals they're ready for you to act.

## Usage

### Check for review comments

```bash
# JSON format (structured, machine-readable)
drovr review check

# Text format (markdown, easier to read inline)
drovr review check --format text
```

### Full workflow

```bash
# 1. Ensure review pane is open (idempotent)
drovr review start

# 2. ... user reviews and adds comments in nvim ...

# 3. Retrieve comments
drovr review check --format text

# 4. Act on comments (fix code, answer questions, etc.)

# 5. Refresh review pane after fixes (user sees updated diff)
drovr review refresh
```

## JSON Export Format

```json
{
  "plugin": "hunk-review.nvim",
  "repo_root": "/path/to/repo",
  "generated_at": "2026-07-27T10:00:00Z",
  "instructions": "Review each hunk with its user comment...",
  "hunks": [
    {
      "file": "src/auth.ts",
      "header": "@@ -10,5 +10,8 @@",
      "line": 10,
      "diff": ["+import { hash } from './utils'", " ", "+export function login() {", "..."],
      "changes": [
        {
          "diff_start": 1,
          "diff_end": 3,
          "kind": "add",
          "line": 10,
          "lines": ["+import { hash } from './utils'", "+", "+export function login() {"],
          "comment": "This should validate the input before hashing"
        }
      ],
      "range_comments": [
        {
          "diff_start": 5,
          "diff_end": 8,
          "line": 14,
          "comment": "Why not use bcrypt here?"
        }
      ]
    }
  ]
}
```

## Comment Types

The user can leave different kinds of comments:

| Type | How user adds it | Meaning |
|------|-----------------|---------|
| **Block comment** | `c` on a change block | Applies to the entire add/delete block |
| **Line comment** | `<Space>` (line mode) then `c` | Applies to a single diff line |
| **Range comment** | Visual select + `c` | Applies to a range of lines |

## Acting on Comments

When you receive review comments:

1. **Action requests** (e.g., "fix this", "add validation", "refactor"): Modify the code accordingly
2. **Questions** (e.g., "why?", "is this safe?"): Respond with an explanation — either inline as a code comment or verbally to the user
3. **Observations** (e.g., "typo", "wrong variable"): Fix the issue directly

After making changes, call `drovr review refresh` so the user sees the updated diff in nvim.

## Guidelines

1. Prefer `--format text` for quick human-readable overview; use plain `json` when you need structured data (e.g., to parse file paths programmatically)
2. If `drovr review check` returns "No review comments found", the user hasn't added comments yet — wait or ask
3. After fixing code based on comments, always run `drovr review refresh` so the user can verify
4. Do NOT modify the review pane itself — it's read-only from the agent's perspective
5. One `check` retrieves ALL current comments at once — no need to poll repeatedly
6. Comments persist in the nvim session until `:HunkReviewReset` or the review pane closes

## Limitations

- Requires `drovr review start` to have been run (review pane must be open with nvim)
- nvim must have hunk-review.nvim loaded and a review session active
- Comments are session-only (not persisted to disk by hunk-review.nvim)
- The export contains diff context but not the full file — read target files separately if needed for broader context
