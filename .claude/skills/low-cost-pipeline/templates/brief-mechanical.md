# Brief: <task> (DeepSeek non-reasoning, `fast`; RUN_KIND=py)
You are in your own worktree on branch oc/<task> (made from origin/<base>; pushed). Follow GEMINI.md. Do exactly the edits below and nothing else.
Pattern: <one real file showing the house style>
Timebox: 20 min. First commit within 10 min.

## Why
<one line: why this mechanical change is wanted>.

## Edits
1. `<file>` | anchor `<exact unique text>` | replace with `<exact text>`
2. `<file>` | action: <rename X to Y everywhere in this file; exact words>
(Every item is literal. If an anchor is missing or not unique, STOP and report BLOCKED with the item number; never improvise.)

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Anything not in the Edits list.

## May edit
<exactly the files in the Edits list, one backticked path per line>

## Ripple
none: <reason>, or the files that name the changed text (checked with grep before launch).

## Pre-mortem
- An anchor matches twice: the list says unique; the check below counts occurrences.
- The worker "also fixes" a neighbour: the diff is compared with this list and any extra line is a defect.

## Tests
- <locked test or grep assertion that counts the new text per edit> (red on the base)

## Checklist
- file: <each edited file>

## Proof
`git diff` equals the Edits list; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
