"""Which paths exist for tools/doc_graph.py: the files a git checkout holds, so a reference resolves the same here and in CI.

A local-only or ignored file (.claude/settings.local.json) and a Windows case-insensitive hit (Content/ for content/) must not
resolve on this PC and dangle in CI (row 27, 2026-11-01: CI failed on main for exactly that). Outside git it falls back to disk."""
import pathlib
import subprocess


def repo_paths(root: pathlib.Path):
    """(files, folders) of a git checkout: tracked plus untracked-not-ignored, exact case; None outside a git repo."""
    if not (root / ".git").exists():
        return None
    done = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard"], cwd=root,
                          capture_output=True, text=True, encoding="utf-8")
    if done.returncode != 0:
        return None
    files = {line for line in done.stdout.splitlines() if line}
    folders = {p.as_posix() for f in files for p in pathlib.PurePosixPath(f).parents if p.as_posix() != "."}
    return files, folders


def resolve(root: pathlib.Path, node: str, tok: str, known=None) -> str:
    """The token as a repo path when it exists from the root or the node's folder, else ''; build artifacts never count."""
    here = pathlib.PurePosixPath(node).parent
    for cand in (tok, (here / tok).as_posix()):
        cand = cand.rstrip("/")
        if cand.split("/")[0] in (".check", ".godot", ".git"):
            continue
        if (cand in known[0] or cand in known[1]) if known else (root / cand).exists():
            return cand
    return ""
