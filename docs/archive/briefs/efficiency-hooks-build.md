# Brief: efficiency-hooks-build (items 1-2 of docs/briefs/efficiency-hooks.md; <= 60 lines)
You are in your own worktree on branch oc/efficiency-hooks-build (made from origin/claude/friendly-gagarin-0fb38d). Load the
minimal-change-engineer skill. Timebox: 40 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-27: "make the efficiency system clean, easy, consistent and reliable": every rule that held was a tool, every
rule that broke was prose. Pillar served (docs/VISION.md): a small team ships the demo (no wasted chats, no unreviewed renders).

## Read first
tools/pre_spend.py (hook style: stdin JSON, stderr + exit 2 blocks, hookSpecificOutput adds context); the two tests
below in full (they are the contract). Read nothing else.

## What to build
1. tools/hooks/token_handoff.py, a PostToolUse hook. Stdin: {session_id, transcript_path}. Never blocks: exit 0 always,
   also on bad JSON, a missing file or any exception (wrap main in try/except). State: one JSON file per session_id in
   env TOKEN_HANDOFF_STATE_DIR (default: tempfile.gettempdir()/claude_token_handoff) with size, baseline, warned.
   - Throttle: with a state, growth < env TOKEN_HANDOFF_STEP_BYTES (default 40000) since the last parse = exit 0
     unparsed. No state: read the whole file; later parses read the last 512 KB (seek, drop the partial first line).
   - total of a line = usage input_tokens + cache_read_input_tokens + cache_creation_input_tokens, from main-chain
     lines only: type "assistant", isSidechain false, message.usage present. work = last total - baseline.
   - baseline = the first such total after the LAST {"type":"system","subtype":"compact_boundary"} line seen (or the
     first in the file when there is none). A boundary inside a later 512 KB window resets baseline and warned.
   - Fallback when the read finds no usage line at all: work = bytes of the whole file's type user/assistant lines / 5.7.
   - Warn by printing {"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}:
     work >= 100000: "Work tokens ~<N>k (D4): stop at the end of this step and /handoff." once, then again at every
     further +10k (110k, 120k...); else work >= 80000 and not yet warned: "Work tokens ~<N>k (D4): finish the unit,
     then /handoff." once. <N> = work // 1000. Crossing both at once prints only the 100k message.
2. tools/hooks/review_gate.py, a PreToolUse hook. Stdin: {tool_name, tool_input, cwd}. Only SendUserFile and Artifact;
   any other tool, bad JSON or an exception: exit 0. Paths: SendUserFile files[]; Artifact file_path, file_paths[],
   files as a dict (value a string or {"from": p}) or a list of {"path": p}. Relative paths join cwd. Missing file: skip.
   - A render (match on the path with / separators, case-insensitive): it has an "inbox" folder segment, except under
     inbox/flow/ or inbox/neon glitch concept art/ or a basename starting concept_; or a ".bake" folder segment; or a
     basename contact.png, clip.mp4 or f + 8 digits + .png.
   - A render passes only when <stamp dir>/<sha256 of its bytes>.json exists. Stamp dir: env REVIEW_STAMP_DIR, else
     <git common dir>/reviews, where the git common dir = `git rev-parse --git-common-dir` run in this script's folder
     (made absolute; one folder for every worktree). Unstamped: stderr "BLOCKED <path>: a game render needs
     review-player + review-feras first, then python tools/hooks/review_stamp.py <path> --player '<verdict>' --feras
     '<verdict>'" (one line per path) and exit 2.
3. tools/hooks/review_stamp.py: argv = one or more files, --player TEXT, --feras TEXT (argparse). Both required and
   non-blank, else exit 2. Writes <stamp dir>/<sha256>.json with path, player, feras and the UTC date; prints one line per file.
4. Each new .py file opens with a docstring: what it does, which decision it serves (D4; D5/D21).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`.claude/`
`docs/`
`features/`

## May edit
`tools/hooks/`

## Ripple
Nothing in the game; the chat wires .claude/settings.json after review (not you).

## Tests
Red on the base, read-only: python tools/test_token_handoff.py (9) and python tools/test_review_gate.py (9; its
player-visible test: every tools/shot_*.gd output is caught, so no game render reaches Feras unreviewed).

## Checklist
- file: tools/hooks/token_handoff.py
- file: tools/hooks/review_gate.py
- file: tools/hooks/review_stamp.py
- has: tools/hooks/token_handoff.py :: TOKEN_HANDOFF_STEP_BYTES
- has: tools/hooks/review_gate.py :: REVIEW_STAMP_DIR

## Proof
`bash tools/check.sh` raw last 15 lines, plus the two test commands' output; final message ends with
`Built-by: <model> (opencode)`.
