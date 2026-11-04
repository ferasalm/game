# Brief: row28-d-preflight (Opus writes it: pipeline machinery; shell + Python, RUN_KIND=py)
You are in your own worktree on branch worktree-row28-d (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/nv_build.sh, tools/test_nv_build.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: the nv lane read keys from opencode's default dir while the pipeline uses oc-v2 (lib.sh oc_run, --standalone), so smoke tests passed and a real build would fail to log in; an auth error is not in NV_FALLBACK_RE. Pillar served: none directly (pipeline reliability).

## Read first
tools/nv_build.sh, tools/lib.sh (oc_run), tools/builders.conf (OC_BIN, NV_CHAIN), tools/test_nv_build.py (how it stubs opencode), tools/free_providers.txt.

## What to build
1. In nv_build.sh, before the model loop: for each model in the chain take its provider (text before the first slash). Run `oc_run auth list --standalone` once (the same data dir as builds) and keep the provider names it prints.
2. A chain model whose provider is missing is SKIPPED with a stderr line `nv_build: skipping <model>: <Provider> is not logged in to oc-v2 (PowerShell: $env:XDG_DATA_HOME="$HOME\.local\share\oc-v2"; & <OC_BIN> auth login --standalone)`. Match provider names case-insensitively; opencode is the always-present free provider and never needs a login.
3. If every model is skipped, or a pinned 4th-arg model has no login: exit 3 (REFUSED) with that same line, no build.
4. If `auth list` itself fails or prints nothing parseable: warn and run the chain unchanged (never block on the check).
5. A new tools/test_nv_preflight.py with a stub opencode (the pattern in test_nv_build.py): provider missing is skipped and the next runs; all missing exits 3; pinned and missing exits 3; auth list failing runs the chain; matching is case-insensitive.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`tools/nv_build.sh`

## Ripple
nv_build.sh is called by the nv lane and the night queue (part j) and read by test_nv_build.py (its stub must keep passing: the stub prints a provider list or the preflight stays quiet). Editing it while two runs use it crashed both (LESSONS 10-30): launch nothing while editing.

## Pre-mortem
- The auth list format differs from the guess: test with the real captured output (Cerebras 2, Google 2, Nvidia 2, OpenRouter, API key); an entry named API key carries no provider, so a name match must use the first column (provider).
- A false skip empties the chain: rule 3 refuses loudly, with the login line.
- The stub differs from real opencode: one live run after merge (checklist of row 28 acceptance).

## Tests
- tools/test_nv_preflight.py :: every test (red on the base: no preflight exists). Player-visible: not applicable (tooling); the visible output is the refusal line.

## Checklist
- file: tools/test_nv_preflight.py
- has: tools/nv_build.sh :: auth list
- test: tools/test_nv_preflight.py :: test_missing_provider_is_skipped_and_chain_continues

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
