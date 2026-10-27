#!/usr/bin/env bash
## InstructionsLoaded hook: logs each loaded instruction file and its size (start cost, P3.9); never blocks.
log="$PWD/.claude/logs/instructions.tsv"  # $PWD = this worktree ($CLAUDE_PROJECT_DIR can be the main checkout)
mkdir -p "$(dirname "$log")"
python -c 'import json, os, sys, datetime
d = json.load(sys.stdin); p = d.get("file_path", "")
s = os.path.getsize(p) if p and os.path.exists(p) else -1
print("\t".join([datetime.datetime.now().isoformat(timespec="seconds"), d.get("session_id", ""), d.get("load_reason", ""), str(s), p]))' >> "$log" 2> /dev/null
exit 0
