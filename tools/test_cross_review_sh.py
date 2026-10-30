#!/usr/bin/env python3
"""Self-test for the cross-review runner tools/cross_review.sh (row 12 A, 2026-10-29): python tools/test_cross_review_sh.py.
Stub agy/opencode on PATH. The race (10-28) got 0/2 blocks: agy denied its own tools without the skip flag, DeepSeek
explored for 9 min and wrote nothing, and colour codes hid the markers. So: the reviewer reads a packet file from an
empty box, agy gets --dangerously-skip-permissions --sandbox, DeepSeek gets bash/edit denied, no block -> one forced
round, and a reviewer that never writes a block reads INVALID, never a clean review."""
import os
import shutil
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
ROOT = os.path.dirname(TOOLS)
# Stub reviewer: logs its args, cwd files and config env; prints per STUB_MODE (block | late | never)
STUB = r"""#!/usr/bin/env bash
top="$STUB_TOP"; n=$(cat "$top/calls" 2> /dev/null || echo 0); n=$((n + 1)); echo $n > "$top/calls"
{ echo "ARGS $*"; echo "FILES $(ls)"; echo "CONFIG ${OPENCODE_CONFIG:-none}"; } >> "$top/stub.txt"
if [ "$STUB_MODE" = block ] || { [ "$STUB_MODE" = late ] && [ $n -ge 2 ]; }; then
  printf '\033[1;32mBEGIN FINDINGS\033[0m\r\nhigh | tools/x.py:3 | an empty name -> crash | refuse it\r\nEND FINDINGS\r\n'
else
  echo "Let me look around the repository first."
fi
"""


def git(cwd, *a):
    subprocess.run(["git", "-C", cwd, *a], check=True, capture_output=True)


def toy():
    top = tempfile.mkdtemp().replace("\\", "/")
    g = top + "/game"
    for rel in (".agents/skills/code-reviewer/SKILL.md", ".claude/rules/code.md"):
        os.makedirs(os.path.dirname(f"{g}/{rel}"), exist_ok=True)
        shutil.copy(f"{ROOT}/{rel}", f"{g}/{rel}")
    git(top, "init", "-q", "-b", "main", "game")
    git(g, "config", "user.email", "t@t")
    git(g, "config", "user.name", "t")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    git(g, "checkout", "-qb", "oc/job")
    with open(g + "/x.py", "w", newline="\n") as f:
        f.write("def f(name):\n    return name[0]\n")
    os.makedirs(g + "/docs")
    with open(g + "/docs/MAP.md", "w", newline="\n") as f:
        f.write("GENERATED MAP LINE\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "built")
    git(g, "checkout", "-q", "main")
    with open(g + "/main_only.txt", "w", newline="\n") as f:
        f.write("NEWER MAIN WORK\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "main moved on")
    with open(top + "/brief.md", "w", newline="\n") as f:
        f.write("# Brief: f returns the first letter\n")
    os.makedirs(top + "/bin")
    for n in ("agy", "opencode"):
        with open(f"{top}/bin/{n}", "w", newline="\n") as f:
            f.write(STUB)
        os.chmod(f"{top}/bin/{n}", 0o755)
    return top, g


def review(top, g, *extra, mode="block"):
    env = {**os.environ, "PATH": f"{top}/bin{os.pathsep}" + os.environ["PATH"], "STUB_TOP": top, "STUB_MODE": mode,
           "GAME_WT_DIR": top + "/game-wt", "CLOUDFLARE_ACCOUNT_ID": "test", "REVIEW_TIMEOUT": "60s", "OC_BIN": "opencode"}
    r = subprocess.run(["bash", f"{TOOLS}/cross_review.sh", "job", top + "/brief.md", "main", *extra], cwd=g, env=env,
                       capture_output=True, text=True, stdin=subprocess.DEVNULL)
    stub = open(top + "/stub.txt", encoding="utf-8").read() if os.path.exists(top + "/stub.txt") else ""
    out = g + "/.check/reviews/job-cross.md"
    return r, stub, open(out, encoding="utf-8").read() if os.path.exists(out) else ""


def test_oc_run_goes_to_agy_with_the_skip_flag_from_an_empty_box():
    top, g = toy()
    r, stub, out = review(top, g)
    assert r.returncode == 0, (r.stdout, r.stderr)
    assert "--dangerously-skip-permissions" in stub and "--sandbox" in stub, ("agy denies its tools headless", stub)
    assert "FILES packet.md" in stub, ("the box holds only the packet: no repo to explore or push from", stub)
    packet = open(top + "/game-wt/xr/job-agy/packet.md", encoding="utf-8").read()
    assert "BEGIN FINDINGS" in packet and "f returns the first letter" in packet and "return name[0]" in packet
    assert "NEWER MAIN WORK" not in packet, "the diff runs from the merge base, never main's newer commits"
    assert "GENERATED MAP LINE" not in packet, "generated files bloat the packet (DeepSeek runaway, 10-29)"
    assert "| high | tools/x.py:3 |" in out, ("colour codes and CRLF must not hide the block", out)


def test_no_block_gets_one_forced_round():
    top, g = toy()
    r, stub, out = review(top, g, mode="late")
    log = open(top + "/game-wt/job.xr-agy.log", encoding="utf-8").read()
    assert r.returncode == 0 and stub.count("ARGS ") == 2 and "forced round" in log, (r.stdout, stub)


def test_cf_reviews_agy_runs_nemotron_only_as_backup_and_silence_is_invalid():  # Feras 10-30
    top, g = toy()
    git(g, "branch", "-m", "oc/job", "gemini/job")
    r, stub, out = review(top, g, mode="never")
    assert r.returncode == 1 and out.startswith("INVALID"), ("no block must never read as a clean review", out)
    calls = [line for line in stub.splitlines() if line.startswith("ARGS ")]
    assert len(calls) == 3 and all("-f packet.md" in c and "--print-logs" in c for c in calls), stub
    assert "deepseek" in calls[0] and "deepseek" in calls[1], ("cf DeepSeek reviews agy runs first", stub)
    assert "nemotron" in calls[2], ("nemotron is the backup lens only after cf fails twice", stub)
    assert "cross_review.opencode.json" in stub, ("opencode reviewers run with bash and edit denied", stub)


def test_nemotron_is_not_called_when_cf_answers():
    top, g = toy()
    git(g, "branch", "-m", "oc/job", "gemini/job")
    r, stub, out = review(top, g, mode="block")
    assert r.returncode == 0 and stub.count("ARGS ") == 1 and "nemotron" not in stub, stub


def test_review_config_denies_bash_and_edit():
    import json
    cfg = json.load(open(f"{TOOLS}/cross_review.opencode.json", encoding="utf-8"))
    perm = cfg["permission"]
    assert perm["bash"] == "deny" and perm["edit"] == "deny", perm
    # v2's execute tool (a JS sandbox) ran echo and fetched a page past the bash and webfetch denies (probe, row 18 10-30)
    assert all(perm.get(k) == "deny" for k in ("execute", "webfetch", "websearch", "task")), perm
    # Workers AI DeepSeek 1017 at "high" filled opencode's hidden 32k output cap with reasoning and printed nothing (3
    # runs, 10-29). Max with the cap at 128k: a valid block in 443 s, less noise than low (Feras 10-30: max).
    ds = cfg["provider"]["cloudflare-workers-ai"]["models"]["@cf/deepseek-ai/deepseek-v4.1-flash-1017"]
    assert ds["options"]["reasoning_effort"] == "max", ds
    build = json.load(open(f"{ROOT}/opencode.json", encoding="utf-8"))
    bds = build["provider"]["cloudflare-workers-ai"]["models"]["@cf/deepseek-ai/deepseek-v4.1-flash-1017"]
    assert bds["options"]["reasoning_effort"] == "max", ("cf builds think at max too", bds)
    # v2 dropped OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX (row 18): the cap lives on the model
    assert ds["limit"]["output"] >= 384000 and bds["limit"]["output"] >= 384000, (ds, bds)
    r = subprocess.run(["bash", "-c", f". '{TOOLS}/lib.sh'; echo $OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX"],
                       capture_output=True, text=True, env={k: v for k, v in os.environ.items()
                                                            if k != "OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX"})
    assert int(r.stdout.strip() or 0) >= 384000, ("DeepSeek 1017 may write 384k; opencode's default is 32k (Feras 10-30)", r)


def test_usage_errors_exit_2():
    top, g = toy()
    r, _, _ = review(top, g, "nobranch", "agy")
    assert r.returncode != 0
    env = {**os.environ, "GAME_WT_DIR": top + "/game-wt"}
    for args in (["Bad_Name", top + "/brief.md", "main"], ["job", top + "/missing.md", "main"]):
        r = subprocess.run(["bash", f"{TOOLS}/cross_review.sh", *args], cwd=g, env=env, capture_output=True, text=True,
                           stdin=subprocess.DEVNULL)
        assert r.returncode == 2, (args, r.stderr)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_cross_review_sh: {len(tests)} tests passed")
