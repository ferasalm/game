#!/usr/bin/env python3
"""What does the game actually use? Walks res:// paths, class_name references and glTF side files from roots and sorts
every tracked file into: game (reachable from the main scene and autoloads), tools (only from tools/*.tscn|gd and
feature harnesses), tests (only from tests), unused (from nothing). A content/**/*.json counts only when a reached
script names its "kind" in quotes (ContentDB loads every JSON by directory, which is not a real use).

--check fails on any unused file under features/ core/ content/ assets/ that the allowlist does not cover. Paths built
at runtime are invisible to a static graph: they go in RUNTIME_DIRS with the reason, never deleted on its say-so.

Usage: python tools/res_graph.py [--list unused|tests|tools|game] [--prefix features/] [--check] [--root DIR]
"""
import argparse, pathlib, re, subprocess, sys

TEXT = {".gd", ".tscn", ".tres", ".json", ".gdshader", ".godot", ".cfg", ".csv", ".gltf"}
RES = re.compile(r"res://([^\"'\s)\]]+)")
URI = re.compile(r'"uri"\s*:\s*"([^"]+)"')  # a .gltf names its .bin and textures relative to itself
CLASS = re.compile(r"^class_name\s+(\w+)", re.M)
WORD = re.compile(r"\b[A-Z]\w+\b")
SKIP_EDGES = {"core/content_db.gd"}  # its KINDS table preloads every Def: a use only when content of that kind is used
CHECKED = ("features/", "core/", "content/", "assets/")
# Loaded by a path built at runtime, so no static edge reaches them.
RUNTIME_DIRS = {
    "assets/portraits/": "speaker portraits: res://assets/portraits/<sprite>_<expression>.png (dialogue, menus)",
    "assets/textures/ui_bg/": "menu backdrops read by Image.load_webp_from_buffer (.gdignore folder)",
    "assets/textures/painted/": "painted skins read from a .gdignore folder",
}
# Not resources: licences, notes, the asset manifest and Godot's ignore markers.
NOT_RESOURCES = re.compile(r"(\.txt|\.md|/\.gdignore|^assets/manifest\.json)$")


def tracked(root: pathlib.Path) -> list[str]:
    git = subprocess.run(["git", "-C", str(root), "ls-files"], capture_output=True, text=True)
    out = git.stdout.splitlines() if git.returncode == 0 else \
        [p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()]
    return [p for p in out if not p.endswith((".uid", ".import")) and (root / p).exists()]


def build(root: pathlib.Path, files: list[str]):
    text = {p: (root / p).read_text(encoding="utf-8", errors="replace") for p in files if pathlib.Path(p).suffix in TEXT}
    classes = {m: p for p, t in text.items() if p.endswith(".gd") for m in CLASS.findall(t)}
    kinds = {}
    for p, t in text.items():
        if p.startswith("content/") and p.endswith(".json"):
            m = re.search(r'"kind"\s*:\s*"(\w+)"', t)
            if m:
                kinds.setdefault(m.group(1), []).append(p)
    known = set(files)
    edges = {}
    for p, t in text.items():
        out = set()
        for r in RES.findall(t):
            r = r.rstrip(",;")
            if r in known:
                out.add(r)
            elif r.endswith("/"):  # a folder path (a scanner such as ContentDB or a sprite set): every file in it
                out |= {f for f in known if f.startswith(r)}
        if p.endswith(".gltf"):
            base = p.rsplit("/", 1)[0] + "/" if "/" in p else ""
            out |= {base + u for u in URI.findall(t) if base + u in known}
        if p.endswith(".gd"):
            out |= {classes[w] for w in set(WORD.findall(t)) if w in classes and classes[w] != p}
            out |= {j for k, js in kinds.items() if f'"{k}"' in t for j in js}
        if p in SKIP_EDGES:
            out = {o for o in out if not o.endswith("_def.gd")}
        edges[p] = out
    return edges


def reach(roots, edges) -> set[str]:
    seen, todo = set(), list(roots)
    while todo:
        p = todo.pop()
        if p in seen:
            continue
        seen.add(p)
        todo.extend(edges.get(p, ()))
        if p.endswith(".tscn") or p.endswith(".gd"):  # a scene's script sits beside it; .gd beside .tscn of same name
            twin = p[:-5] + ".gd" if p.endswith(".tscn") else p[:-3] + ".tscn"
            if twin in edges:
                todo.append(twin)
    return seen


def classify(root: pathlib.Path, files: list[str]) -> dict[str, str]:
    edges = build(root, files)
    proj = (root / "project.godot").read_text(encoding="utf-8")
    game_roots = ["project.godot"] + [r for r in RES.findall(proj) if r in edges]
    edges["project.godot"] = set(game_roots[1:])
    game = reach(game_roots, edges)
    tool_roots = [f for f in files if (f.startswith("tools/") or "/harness/" in f) and f.endswith((".tscn", ".gd"))]
    tools = reach(tool_roots, edges) - game
    tests = reach([f for f in files if "/tests/" in f or f.startswith("tests/")], edges) - game - tools
    return {f: "game" if f in game else "tools" if f in tools else "tests" if f in tests else "unused" for f in files}


def dead(cls: dict[str, str]) -> list[str]:
    """Unused files under CHECKED that neither allowlist covers."""
    return sorted(f for f, c in cls.items() if c == "unused" and f.startswith(CHECKED)
                  and not NOT_RESOURCES.search(f) and not f.startswith(tuple(RUNTIME_DIRS)))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", choices=["unused", "tests", "tools", "game"])
    ap.add_argument("--prefix", default="")
    ap.add_argument("--check", action="store_true", help="exit 1 when a file nothing uses is not allowlisted")
    ap.add_argument("--root", default=str(pathlib.Path(__file__).resolve().parent.parent))
    a = ap.parse_args()
    root = pathlib.Path(a.root)
    cls = classify(root, tracked(root))
    if a.check:
        bad = dead(cls)
        for f in bad:
            print(f"unused: {f} (archive it, or add its runtime path to RUNTIME_DIRS in tools/res_graph.py)")
        print(f"res_graph: {len(bad)} unused file(s)")
        return 1 if bad else 0
    if a.list:
        print("\n".join(sorted(f for f, c in cls.items() if c == a.list and f.startswith(a.prefix))))
        return 0
    by = {}
    for f, c in cls.items():
        if f.startswith(CHECKED):
            top = "/".join(f.split("/")[:2])
            by.setdefault(top, {}).setdefault(c, 0)
            by[top][c] += 1
    for top in sorted(by):
        print(f"{top:28} " + "  ".join(f"{k}={v}" for k, v in sorted(by[top].items())))
    return 0


if __name__ == "__main__":
    sys.exit(main())
