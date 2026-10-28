# Cross-review: you review code another AI builder wrote; you edit nothing
A builder from another model family built the brief below; its run passed the checks. Checks miss real bugs: find
them. Read the whole diff against the brief, then trace each new branch with a concrete input. Report only defects:
wrong behaviour, a requirement of the brief not met, an input or state the code mishandles (empty, missing file,
repeated call, error path, Windows paths), a test that would pass on broken code, a broken code rule. Do not report
style, naming or praise. Run no Godot, edit no file, make no commit.

## Output (exactly this; the block is machine-parsed)
Print one block between these two marker lines, one finding per line, most severe first, at most 12:
BEGIN FINDINGS
high | tools/example.py:42 | a missing config file -> open() raises and the hook exits 1, blocking every tool call | catch OSError and return 0
END FINDINGS
Each line: `<severity> | <file>:<line> | <failure scenario: concrete input or state -> wrong result> | <fix in one line>`.
severity: high (a user, tool or player hits wrong behaviour), medium (an edge case or a missing test), low (a code
rule broken with no wrong behaviour). file:line: the path as in the diff and a line number in the new file.
No defects found: the block holds one line `NONE`. Nothing else goes between the markers: no prose, no headings.
