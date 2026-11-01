# Brief: godot-lsp (HANDOFF row 22, step 5: cf max builds the Godot LSP bridge for the studio plugin)
You are in your own worktree on branch oc/godot-lsp (made from origin/system-v3). Follow the repo rules in .claude/rules/code.md that
apply to Python (no stubs, no TODO, every rule tested). Load the minimal-change-engineer skill (our rules outrank its text).
Timebox: 40 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.
This is a Python-only run (RUN_KIND=py): change no Godot file; the check is `bash tools/check.sh --no-godot`.

## Why
Feras 10-31: Claude should see Godot's own errors after an edit and find references through the language server, not grep.
Claude Code speaks LSP over stdio; Godot's editor speaks it over TCP. Pillar: process (fewer wrong edits, fewer retries).

## Read first
tools/test_godot_lsp.py (the tests to make green; read it all), tools/kill_tree.py (docstring only), tools/builders.conf
(MIN_FREE_MB), tools/slots.sh lines 50-65 (how free memory is read). Read nothing else.
Probe facts (measured with Godot 4.7.2): `Godot_v4.7.2-stable_win64_console.exe --headless --editor --lsp-port <p> --path <dir>`
listens 5-8 s after start; framing is plain Content-Length; Godot pushes unknown notifications (gdscript_client/changeWorkspace)
after initialize, so everything must pass through unchanged; `shutdown` answers -32601 and closing the socket does not stop
Godot, so the bridge kills the editor tree itself; the console exe is a launcher that starts the real editor process;
one server uses ~0.75 GB.

## What to build
1. New file plugins/studio/scripts/godot_lsp.py (Python 3, standard library only, <= 200 lines, docstring first line says what
   it is). `port_for(path) -> int`: stable, in 40000..59999, from a hash (zlib.crc32) of the path normalized to forward
   slashes, lower case, no trailing slash (so "C:\dev\Game\x" and "c:/dev/game/x/" agree).
2. CLI `python godot_lsp.py [--project DIR] [--port N] [--no-spawn] [--wait SECONDS]`. Defaults: project = the current
   directory, port = port_for(project), wait = 120. It relays raw bytes both ways between its own stdin/stdout (binary
   mode) and a TCP socket to 127.0.0.1:port, in two threads, so every framed message and every unknown notification passes
   through unchanged. When stdin reaches end of file it closes the socket, stops what it started, and exits 0.
3. Server start: if the port accepts a connection, use it. Else with --no-spawn: write `port <N> is not open` to stderr, exit 4
   (after waiting up to --wait seconds for it to open). Else spawn the command from env GODOT_LSP_CMD (placeholders {port}
   and {project}), default `<godot console exe> --headless --editor --lsp-port {port} --path {project}` where the exe comes from
   `bash tools/godot.sh` run in the project (fallback: env GODOT_BIN, then `godot` on PATH). Wait up to --wait seconds for the port; on timeout
   stop the child and exit 4 with the same stderr line.
4. Memory floor: before spawning, free memory in MB must be >= MIN_FREE_MB (env, default 3000). Free MB = env GODOT_LSP_FREE_MB
   when set (tests), else available physical memory (Windows: ctypes GlobalMemoryStatusEx; Linux: /proc/meminfo MemAvailable).
   Below the floor: write `memory: <free> MB free < <floor> MB floor, not starting Godot` to stderr, spawn nothing, exit 3.
5. Cleanup: a process this bridge spawned is stopped when the bridge exits (normal end, stdin closed, or an exception): run
   `python <project>/tools/kill_tree.py <pid>` when that file exists, else terminate the process and its children
   (Windows: `taskkill /T /F /PID`). Never stop a server the bridge did not start.
6. New file plugins/studio/.lsp.json: one server `godot` with command `python`, args
   [`${CLAUDE_PLUGIN_ROOT}/scripts/godot_lsp.py`, `--project`, `${CLAUDE_PROJECT_DIR}`], extensionToLanguage {".gd": "gdscript"},
   startupTimeout 130000, restartOnCrash false. No key outside the Claude Code .lsp.json schema (an unknown key stops the plugin loading).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files and new files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_godot_lsp.py`
`plugins/studio/hooks/`
`plugins/studio/agents/`
`.claude/`
`docs/briefs/`

## May edit
`plugins/studio/scripts/godot_lsp.py`
`plugins/studio/.lsp.json`
`docs/MAP.md`

## Ripple
none: new files only; nothing imports them yet. tools/test_plugins.py already validates the plugin manifest with `claude plugin validate`,
which reads .lsp.json (an unknown key fails it). docs/MAP.md: `git add` the new files, then `python tools/map.py`.

## Pre-mortem
1. The relay reframes or drops a notification and Godot's diagnostics vanish -> raw byte relay, no parsing (tested with an unknown notification).
2. The bridge leaves a 0.75 GB Godot editor running after the session -> kill the tree it started when stdin closes (tested with a fake server).
3. Two worktrees fight over one port or start under the memory floor -> port from the worktree path hash; floor check before spawn (tested).

## Tests
tools/test_godot_lsp.py, red on the base, read-only: `python tools/test_godot_lsp.py` must print "test_godot_lsp: 6 tests passed".
Player-visible: none (tools).

## Checklist
- file: plugins/studio/scripts/godot_lsp.py
- has: plugins/studio/scripts/godot_lsp.py :: def port_for
- file: plugins/studio/.lsp.json

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (cf)`.
