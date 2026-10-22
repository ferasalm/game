#!/usr/bin/env python3
"""GDScript rules Godot itself doesn't enforce (docs/ARCHITECTURE.md, "Code rules"); exit 1 on any break.

Size: <= 200 lines a file, <= 40 lines a function. A "## purpose" line in the first 6 lines (tools/map.py
reads it). No node lookups by path ($, get_node, get_parent, find_child, /root/): use @export or %Unique.
Files under a logic/ folder stay pure: no nodes, scene tree, autoloads, input or await.
"""
import pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAX_FILE, MAX_FUNC = 200, 40
NODE_LOOKUP = re.compile(r"\$[A-Za-z_\"%]|\bget_node(_or_null)?\(|\bget_parent\(|\bfind_child(ren)?\(|\"/root/")
IMPURE = re.compile(r"\bextends\s+Node|\bget_tree\(|\b(EventBus|GameState|ContentDB)\b|\bInput\.|\bawait\b")
STRINGS = re.compile(r"\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'")


def code_only(line: str) -> str:
    """The line without string literals and comments (keeps the quotes of "/root/" paths for NODE_LOOKUP)."""
    kept = STRINGS.sub(lambda m: '"/root/"' if m.group(0).startswith('"/root/') else '""', line)
    return kept.split("#", 1)[0]


def lint(path: pathlib.Path) -> list[str]:
    rel = path.relative_to(ROOT).as_posix()
    lines = path.read_text(encoding="utf-8").splitlines()
    problems = []
    if len(lines) > MAX_FILE:
        problems.append(f"{rel}: {len(lines)} lines (max {MAX_FILE}); split it")
    if not any(l.startswith("## ") for l in lines[:6]):
        problems.append(f"{rel}: no '## purpose' line in the first 6 lines")
    func_start, func_name = None, ""
    for n, line in enumerate(lines + ["<end>"], 1):
        top_level = line and not line[0].isspace() and not line.startswith("#")
        if func_start is not None and top_level:
            body = [l for l in lines[func_start:n - 1] if l.strip()]
            if len(body) > MAX_FUNC:
                problems.append(f"{rel}:{func_start}: func {func_name} has {len(body)} lines (max {MAX_FUNC})")
            func_start = None
        if re.match(r"(static\s+)?func\s", line):
            func_start, func_name = n, line.split("func", 1)[1].split("(")[0].strip()
        code = code_only(line)
        if NODE_LOOKUP.search(code):
            problems.append(f"{rel}:{n}: node lookup by path; use @export or %UniqueName")
        if "/logic/" in rel and IMPURE.search(code):
            problems.append(f"{rel}:{n}: logic/ must stay pure (no nodes, tree, autoloads, input, await)")
    return problems


def main() -> int:
    skip = (".godot", "addons", ".claude")
    files = [p for p in sorted(ROOT.rglob("*.gd")) if not any(part in skip for part in p.relative_to(ROOT).parts)]
    problems = [msg for f in files for msg in lint(f)]
    print("\n".join(problems) if problems else f"lint: {len(files)} GDScript files ok")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
