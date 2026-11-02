#!/usr/bin/env python3
"""Red tests for docs/briefs/row26-s4-routing.md (row 26 S4, Feras 11-02): the cross-review reviewer comes from the
run's .result (agy or DeepSeek work -> GLM max, GLM work -> DeepSeek max), merge_run reads its prefix from the .result
and refuses one without a VERDICT PASS line, ci_state maps gh run list JSON to one word, handoff's ci step asks for the
check.yml workflow and waits CI_WAIT_SEC, and OC_MODEL defaults to CF_MODEL. Red on this base because that spec is
unbuilt; the routing run implements them and may not edit this file. python tools/test_routing.py"""
import os
import shutil
import subprocess
import sys
import tempfile
import time

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
sys.path.insert(0, TOOLS)
from test_cross_review_sh import review, toy as xr_toy  # the xr toy + runner; the stub logs ARGS lines to assert on
from test_handoff import BASH, last_line, put, sh, toy as h_toy  # the handoff toy: bare origin + clone + stub steps

XR_GLM = "cloudflare-workers-ai/@cf/zai-org/glm-5.3"  # XR_REVIEWER_GEMINI and XR_REVIEWER_DEEPSEEK (spec item 1)
CF_DEEPSEEK = "cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017"  # CF_MODEL, so also XR_REVIEWER_GLM
GH_OK = '[{"status":"completed","conclusion":"success"}]'
GH_STUB = '#!/usr/bin/env bash\necho "GH $*" >> "$GH_REC"\necho \'%s\'\n'


def result_toy(branch, builder, model):
    """(top, g) of the xr toy plus <wt_dir>/job.result naming the run's branch, builder and model (pipeline format)."""
    top, g = xr_toy()
    put(top + "/game-wt/job.result", f"PASS 10:00 {branch}\nbuilder {builder}\nmodel {model}\n")
    return top, g


def oc_calls(stub):
    """The stub opencode reviewer's ARGS lines; the agy reviewer is never handed -f packet.md."""
    return [ln for ln in stub.splitlines() if ln.startswith("ARGS ") and "-f packet.md" in ln]


def git_out(cwd, *a):
    return subprocess.run(["git", "-C", cwd, *a], capture_output=True, text=True, check=True).stdout.strip()


def run_merge(top, g):
    return sh(g, BASH, TOOLS + "/merge_run.sh", "job", env={**os.environ, "GAME_WT_DIR": top + "/game-wt"})


def merge_toy(prefix, verdict=True, both=False):
    """(top, g, base, tip): a repo on main, a real worktree at game-wt/job on <prefix>/job one commit ahead, a .result."""
    top = tempfile.mkdtemp().replace("\\", "/")
    g = top + "/repo"
    git_out(top, "init", "-q", "-b", "main", "repo")
    git_out(g, "config", "user.email", "t@t")
    git_out(g, "config", "user.name", "t")
    put(g + "/README.md", "one\n")
    git_out(g, "add", "-A")
    git_out(g, "commit", "-qm", "base")
    base = git_out(g, "rev-parse", "HEAD")
    wt = top + "/game-wt/job"
    git_out(g, "worktree", "add", "-q", "-b", f"{prefix}/job", wt)
    put(wt + "/thing.txt", "built\n")
    git_out(wt, "add", "-A")
    git_out(wt, "commit", "-qm", "built")
    tip = git_out(wt, "rev-parse", "HEAD")
    if both:  # the base's gemini default would merge this alias: only the VERDICT gate can refuse it
        git_out(g, "branch", "gemini/job", tip)
    body = f"PASS 10:00 {prefix}/job\nbuilder cf\nchecked {tip}\n" + ("VERDICT PASS\n" if verdict else "")
    put(top + "/game-wt/job.result", body)
    return top, g, base, tip


def handoff_toy(gh_json):
    """(top, g): test_handoff's toy + a fake gh first on PATH recording its args + the real ci_state.py once it exists."""
    top, g = h_toy()
    if os.path.exists(TOOLS + "/ci_state.py"):
        shutil.copy(TOOLS + "/ci_state.py", g + "/tools/ci_state.py")
    put(top + "/bin/gh", GH_STUB % gh_json)
    os.chmod(top + "/bin/gh", 0o755)
    return top, g


def handoff_run(top, g, *flags, **env_extra):
    env = {k: v for k, v in os.environ.items() if k != "HANDOFF_CI"}
    env["PATH"] = top + "/bin" + os.pathsep + env["PATH"]
    env["GH_REC"] = top + "/gh.txt"
    env.update(env_extra)
    return sh(g, BASH, "tools/handoff.sh", "m", *flags, env=env)


def test_a_deepseek_run_is_reviewed_by_glm():
    top, g = result_toy("oc/job", "cf", "cloudflare-workers-ai/deepseek-v4.1-flash-high")
    r, stub, _ = review(top, g)
    calls = oc_calls(stub)
    assert r.returncode == 0 and len(calls) == 1, (r.stdout, stub)  # a cf reviewer, not the base's branch-prefix agy
    assert f"--model {XR_GLM}" in calls[0], calls[0]


def test_a_glm_run_is_reviewed_by_deepseek_max():
    top, g = result_toy("oc/job", "oc", XR_GLM)
    r, stub, _ = review(top, g)
    calls = oc_calls(stub)
    assert r.returncode == 0 and len(calls) == 1, (r.stdout, stub)
    assert f"--model {CF_DEEPSEEK}" in calls[0], calls[0]


def test_an_agy_run_is_reviewed_by_glm():
    top, g = result_toy("gemini/job", "agy", "gemini-3.8-flash-medium")
    git_out(g, "branch", "-m", "oc/job", "gemini/job")  # an agy run lands on gemini/<run>
    r, stub, _ = review(top, g)
    calls = oc_calls(stub)
    assert r.returncode == 0 and len(calls) == 1, (r.stdout, stub)  # the base picks DeepSeek here: the contradiction
    assert f"--model {XR_GLM}" in calls[0], calls[0]


def test_unknown_family_falls_back_to_the_branch_prefix_rule():
    top, g = xr_toy()
    os.makedirs(top + "/game-wt", exist_ok=True)  # no job.result: the old oc/ -> agy rule still picks the reviewer
    r, stub, _ = review(top, g)
    assert r.returncode == 0, (r.stdout, stub)
    assert "--dangerously-skip-permissions" in stub and "-f packet.md" not in stub, stub


def test_an_explicit_reviewer_argument_wins():
    top, g = result_toy("oc/job", "cf", "cloudflare-workers-ai/deepseek-v4.1-flash-high")
    r, stub, _ = review(top, g, "oc/job", "agy")
    assert r.returncode == 0, (r.stdout, stub)
    assert "--dangerously-skip-permissions" in stub and "-f packet.md" not in stub, stub


def test_the_reviewer_models_are_data_in_builders_conf():
    top, g = result_toy("oc/job", "cf", "cloudflare-workers-ai/deepseek-v4.1-flash-high")
    r, stub, _ = review(top, g, XR_REVIEWER_DEEPSEEK="cloudflare-workers-ai/@cf/other/model")
    calls = oc_calls(stub)
    assert r.returncode == 0 and len(calls) == 1, (r.stdout, stub)
    assert "--model cloudflare-workers-ai/@cf/other/model" in calls[0], calls[0]


def test_merge_run_reads_the_prefix_from_the_result():
    for prefix in ("oc", "gemini"):
        top, g, _, tip = merge_toy(prefix)
        r = run_merge(top, g)
        assert r.returncode == 0, (prefix, r.stdout, r.stderr)
        assert sh(g, "git", "rev-parse", "HEAD").stdout.strip() == tip, f"{prefix}: merged the .result's own branch"
        assert not os.path.exists(top + "/game-wt/job"), f"{prefix}: the run's worktree is removed"
        assert sh(g, "git", "rev-parse", "-q", "--verify", f"{prefix}/job").returncode != 0, f"{prefix}: branch removed"


def test_merge_run_refuses_a_result_without_a_verdict_line():
    top, g, base, _ = merge_toy("oc", verdict=False, both=True)
    r = run_merge(top, g)
    assert r.returncode == 1, (r.returncode, r.stdout, r.stderr)  # the base merged it: only the VERDICT gate refuses
    assert top + "/game-wt/job.result" in r.stdout + r.stderr, (r.stdout, r.stderr)
    assert sh(g, "git", "rev-parse", "HEAD").stdout.strip() == base, "nothing is merged from an unverified .result"
    assert os.path.exists(top + "/game-wt/job"), "the run's worktree is untouched"


def test_ci_state_words():
    cases = (("[]", ""), ('[{"status":"queued","conclusion":null},{"status":"completed","conclusion":"success"}]',
              "in_progress"), ('[{"status":"completed","conclusion":"success"}]', "success"),
             ('[{"status":"completed","conclusion":"failure"}]', "failure"),
             ('[{"status":"completed","conclusion":"cancelled"}]', "failure"))
    for js, want in cases:
        r = subprocess.run([sys.executable, TOOLS + "/ci_state.py"], input=js, capture_output=True, text=True)
        assert r.returncode == 0 and r.stdout.strip() == want, (js, r.stdout, r.stderr)


def test_handoff_ci_asks_for_the_check_workflow():
    top, g = handoff_toy(GH_OK)
    put(g + "/README.md", "two\n")
    r = handoff_run(top, g, "--main")
    assert r.returncode == 0 and last_line(r) == "HANDOFF PASS", (r.stdout, r.stderr)
    sha = sh(g, "git", "rev-parse", "HEAD").stdout.strip()
    rec = open(top + "/gh.txt", encoding="utf-8").read() if os.path.exists(top + "/gh.txt") else ""
    assert "--workflow check.yml" in rec and sha in rec, rec


def test_ci_wait_cap_is_960_and_overridable():
    conf = open(TOOLS + "/builders.conf", encoding="utf-8").read()
    assert "CI_WAIT_SEC:=960" in conf, "the cap is data in builders.conf, not a literal in handoff.sh"
    top, g = handoff_toy('[{"status":"in_progress","conclusion":null}]')
    put(top + "/bin/sleep", "#!/usr/bin/env bash\nexit 0\n")  # a poll round waits 20 s: instant, the cap is the rule
    os.chmod(top + "/bin/sleep", 0o755)
    r = handoff_run(top, g, "--main", CI_WAIT_SEC="1")
    assert last_line(r) == "HANDOFF FAIL ci" and r.returncode != 0, (r.stdout, r.stderr)
    # counted polls, not seconds: a wall-clock bound flaked under load (row 26, 11-02); the old 600 s cap polls ~31 times
    polls = open(top + "/gh.txt", encoding="utf-8").read().count("GH ")
    assert 2 <= polls <= 3, ("a 1 s cap polls the run, then gives up after one wait round", polls)


def test_oc_model_defaults_to_the_cf_model():
    env = {k: v for k, v in os.environ.items() if k not in ("OC_MODEL", "CF_MODEL")}
    r = subprocess.run(["bash", "-c", f". '{TOOLS}/lib.sh'; echo $OC_MODEL $CF_MODEL"], capture_output=True, text=True,
                       env=env)
    words = r.stdout.split()
    assert r.returncode == 0 and len(words) == 2 and words[0] == words[1], (r.stdout, r.stderr)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_routing")
