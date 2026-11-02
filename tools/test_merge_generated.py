#!/usr/bin/env python3
"""Row 26 S14 (11-02): every parallel part adds a tool, so every merge of two parts conflicted on the generated files
docs/MAP.md and docs/DOCMAP.md and the head regenerated them by hand five times. merge_run.sh now regenerates exactly those
two files when they are the ONLY conflict, and leaves any other conflict for the head, untouched."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
BASH = "bash"


def sh(cwd, *cmd, env=None):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True, env=env, timeout=120, stdin=subprocess.DEVNULL)


def put(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def git(cwd, *a):
    r = sh(cwd, "git", "-C", cwd, *a)
    assert r.returncode == 0, (a, r.stdout, r.stderr)
    return r.stdout.strip()


def toy(conflict_file=None):
    """A repo with stub generators and check, a run branch oc/job and a diverged main; returns (top, repo)."""
    top = tempfile.mkdtemp().replace("\\", "/")
    g = top + "/repo"
    git(top, "init", "-q", "-b", "main", "repo")
    git(g, "config", "user.email", "t@t")
    git(g, "config", "user.name", "t")
    put(g + "/docs/MAP.md", "base\n")
    put(g + "/docs/DOCMAP.md", "base\n")
    put(g + "/README.md", "base\n")
    put(g + "/tools/map.py", "open('docs/MAP.md', 'w').write('regenerated map\\n')\n")
    put(g + "/tools/doc_graph.py", "open('docs/DOCMAP.md', 'w').write('regenerated docmap\\n')\n")
    put(g + "/tools/check.sh", "#!/usr/bin/env bash\necho all checks passed\n")
    os.chmod(g + "/tools/check.sh", 0o755)
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    wt = top + "/game-wt/job"
    git(g, "worktree", "add", "-q", "-b", "oc/job", wt)
    put(wt + "/docs/MAP.md", "job map\n")
    put(wt + "/docs/DOCMAP.md", "job docmap\n")
    put(wt + "/thing.txt", "built\n")
    if conflict_file:
        put(wt + "/" + conflict_file, "job side\n")
    git(wt, "add", "-A")
    git(wt, "commit", "-qm", "built")
    tip = git(wt, "rev-parse", "HEAD")
    put(g + "/docs/MAP.md", "main map\n")
    put(g + "/docs/DOCMAP.md", "main docmap\n")
    if conflict_file:
        put(g + "/" + conflict_file, "main side\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "main moved")
    put(top + "/game-wt/job.result", f"PASS 10:00 oc/job\nbuilder cf\nkind py\nchecked {tip}\nVERDICT PASS\n")
    return top, g


def merge(top, g):
    env = {**os.environ, "GAME_WT_DIR": top + "/game-wt"}
    return sh(g, BASH, HERE + "/merge_run.sh", "job", env=env)


def test_a_conflict_in_only_the_generated_docs_is_regenerated_and_the_merge_completes():
    top, g = toy()
    r = merge(top, g)
    assert r.returncode == 0, (r.stdout, r.stderr)
    assert open(g + "/docs/MAP.md", encoding="utf-8").read() == "regenerated map\n"
    assert open(g + "/docs/DOCMAP.md", encoding="utf-8").read() == "regenerated docmap\n"
    assert os.path.exists(g + "/thing.txt"), "the run's own work is merged"
    parents = git(g, "rev-list", "--parents", "-n", "1", "HEAD").split()
    assert len(parents) == 3, ("a merge commit with two parents", parents)
    assert git(g, "status", "--porcelain") == "", "nothing left unstaged or in conflict"


def test_any_other_conflict_stops_the_merge_for_the_head_and_names_the_file():
    top, g = toy(conflict_file="README.md")
    r = merge(top, g)
    assert r.returncode != 0 and "README.md" in r.stdout + r.stderr, (r.returncode, r.stdout, r.stderr)
    unmerged = git(g, "diff", "--name-only", "--diff-filter=U").split()
    assert "README.md" in unmerged, ("the head resolves it by hand: the merge stays in progress", unmerged)


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_merge_generated")
