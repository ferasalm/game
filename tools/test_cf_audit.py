#!/usr/bin/env python3
"""Self-test for tools/cf_audit.sh (row 25, 2026-11-01): the read-only cf audit stages its box, runs opencode with the
read-only config and the cf model, writes the report, and reports a timeout as 124. Stub opencode on OC_BIN."""
import json
import os
import shutil
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
BASH = shutil.which("bash") or "bash"
STUB = """#!/usr/bin/env bash
echo "ARGS $*"
echo "CONFIG ${OPENCODE_CONFIG:-none}"
echo "BOX $(ls .check/audit | tr '\\n' ' ')"
echo "INLINE ${OPENCODE_CONFIG_CONTENT:-none}" | tr -d '\\n\\r '; echo
[ "${STUB_SLEEP:-0}" = 0 ] || sleep "$STUB_SLEEP"
echo "REPORT: all fine"
"""


def toy():
    top = tempfile.mkdtemp().replace("\\", "/")
    repo = top + "/repo"
    os.makedirs(repo)
    subprocess.run(["git", "init", "-q", repo], check=True, capture_output=True)
    for name, text in (("stub.sh", STUB), ("prompt.md", "audit it\n")):
        with open(top + "/" + name, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        os.chmod(top + "/" + name, 0o755)  # Linux CI: a stub opencode must be executable (the Windows run never noticed)
    os.makedirs(top + "/coach")
    open(top + "/coach/skills.md", "w").write("checklist\n")
    os.makedirs(top + "/mem")
    open(top + "/mem/MEMORY.md", "w").write("- index\n")
    return top, repo


def run(top, repo, *args, **env):
    e = {**os.environ, "OC_BIN": top + "/stub.sh", "OC_MAJOR": "2", "GAME_WT_DIR": top + "/wt", "COACH_DIR": top + "/coach",
         "MEMORY_DIR": top + "/mem", **env}
    return subprocess.run([BASH, TOOLS + "/cf_audit.sh", *args], cwd=repo, capture_output=True, text=True, env=e,
                          stdin=subprocess.DEVNULL, timeout=120)


def test_it_stages_the_box_and_runs_the_read_only_cf_model():
    top, repo = toy()
    r = run(top, repo, top + "/prompt.md", top + "/out.md")
    assert r.returncode == 0, r.stdout + r.stderr
    out = open(top + "/out.md", encoding="utf-8").read()
    assert "cross_review.opencode.json" in out, out  # the read-only config
    assert "deepseek-v4.1-flash-1017" in out and "--model" in out, out
    assert "coach" in out and "memory" in out and "prompt.md" in out, out  # the staged box
    assert "REPORT: all fine" in out
    # the repo's own opencode.json allows bash and edit and outranks OPENCODE_CONFIG: only inline content holds (probed 11-01)
    assert '"bash":"deny"' in out and '"edit":"deny"' in out, out
    assert open(repo + "/.check/audit/coach/skills.md").read() == "checklist\n"
    assert open(repo + "/.check/audit/memory/MEMORY.md").read() == "- index\n"


def test_the_config_it_uses_denies_every_write_and_run_tool():
    cfg = json.load(open(TOOLS + "/cross_review.opencode.json", encoding="utf-8"))["permission"]
    for tool in ("edit", "bash", "webfetch", "task", "execute", "websearch"):
        assert cfg[tool] == "deny", tool
    assert cfg["external_directory"] == {"*": "deny"}, "it may read the repo only, nothing outside"


def test_audit_root_audits_another_checkout():
    top, repo = toy()
    other = tempfile.mkdtemp().replace("\\", "/")  # not the cwd's repo: the box must land here
    r = run(top, repo, top + "/prompt.md", top + "/out.md", AUDIT_ROOT=other)
    assert r.returncode == 0, r.stdout + r.stderr
    assert os.path.exists(other + "/.check/audit/prompt.md") and not os.path.exists(repo + "/.check/audit")


def test_a_missing_prompt_is_usage_exit_2():
    top, repo = toy()
    assert run(top, repo, top + "/nope.md", top + "/out.md").returncode == 2
    assert run(top, repo, top + "/prompt.md").returncode == 2


def test_a_run_past_its_time_is_124_and_keeps_the_partial_report():
    top, repo = toy()
    r = run(top, repo, top + "/prompt.md", top + "/out.md", "3s", STUB_SLEEP="30")
    assert r.returncode == 124, (r.returncode, r.stdout, r.stderr)
    assert "audit exited 124" in open(top + "/out.md", encoding="utf-8").read()


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_cf_audit")
