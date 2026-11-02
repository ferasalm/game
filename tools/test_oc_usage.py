#!/usr/bin/env python3
"""Row 26 S2 (Feras 11-02): a builder run's cost is read from opencode's own session export, never guessed from its log
(the log holds no token counts; build_pipeline.sh wrote cost 0 and cf_spend.csv `?`). Unknown is `?`, never 0.
Also pins the effort lookup: opencode.json says what a model key reasons at, the model's name does not."""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OC_USAGE = os.path.join(HERE, "oc_usage.py")
MODEL_EFFORT = os.path.join(HERE, "model_effort.py")


def export_json(inp, out, reasoning=0, cread=0, cwrite=0):  # the shape `opencode session export` printed 11-02
    return {"info": {"id": "ses_x", "cost": 0.5, "outcome": "succeeded",
                     "tokens": {"input": inp, "output": out, "reasoning": reasoning,
                                "cache": {"read": cread, "write": cwrite}}},
            "messages": []}


def run(*args, stdin=None, env=None):
    e = dict(os.environ)
    e.update(env or {})
    return subprocess.run([sys.executable, *args], capture_output=True, text=True, input=stdin, env=e, timeout=60)


def write(d, name, obj):
    p = os.path.join(d, name)
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(obj if isinstance(obj, str) else json.dumps(obj))
    return p


def test_sum_adds_every_session_of_a_run_build_plus_fix_passes():
    with tempfile.TemporaryDirectory() as d:
        a = write(d, "a.json", export_json(1000, 200, reasoning=50, cread=10, cwrite=5))
        b = write(d, "b.json", export_json(300, 40, reasoning=7, cread=1, cwrite=2))
        r = run(OC_USAGE, "sum", a, b)
        assert r.returncode == 0, r.stderr
        t = json.loads(r.stdout.strip().splitlines()[-1])
        assert (t["sessions"], t["input"], t["output"], t["reasoning"]) == (2, 1300, 240, 57), t
        assert (t["cache_read"], t["cache_write"]) == (11, 7), t


def test_sum_of_nothing_is_zero_sessions_not_zero_tokens():
    r = run(OC_USAGE, "sum")
    assert r.returncode == 0, r.stderr
    assert json.loads(r.stdout.strip().splitlines()[-1])["sessions"] == 0


def test_fields_prices_tokens_and_reasoning_counts_as_output():
    tot = {"sessions": 2, "input": 1000000, "output": 200000, "reasoning": 100000, "cache_read": 0, "cache_write": 0}
    r = run(OC_USAGE, "fields", "--in-rate", "0.30", "--out-rate", "1.20", stdin=json.dumps(tot))
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == "1000000,300000,0.66", r.stdout  # in, out + reasoning, usd


def test_fields_without_a_session_is_question_marks_never_zero():
    r = run(OC_USAGE, "fields", "--in-rate", "0.30", "--out-rate", "1.20", stdin=json.dumps({"sessions": 0}))
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == "?,?,?", r.stdout


FAKE_OC = """#!/usr/bin/env bash
# stands in for opencode: `session list --standalone` prints two sessions, `session export` prints a fixture
case "$*" in
  *"session list"*) printf 'ses_one\\tbuild\\t11/2/2026\\nses_two\\tfix\\t11/2/2026\\n' ;;
  *"session export"*) for a in "$@"; do last="$a"; done; cat "$FIXTURES/$last.json" ;;
  *) echo "unexpected: $*" >&2; exit 9 ;;
esac
"""


def test_collect_lists_a_worktrees_sessions_and_sums_their_exports():
    with tempfile.TemporaryDirectory() as d:
        write(d, "ses_one.json", export_json(1000, 200))
        write(d, "ses_two.json", export_json(500, 100))
        fake = write(d, "fake_oc.sh", FAKE_OC)
        wt = os.path.join(d, "wt")
        os.makedirs(wt)
        r = run(OC_USAGE, "collect", "--wt", wt, env={"OC_BIN": fake, "OC_MAJOR": "2", "FIXTURES": d})
        assert r.returncode == 0, r.stderr
        t = json.loads(r.stdout.strip().splitlines()[-1])
        assert (t["sessions"], t["input"], t["output"]) == (2, 1500, 300), t


def test_collect_with_opencode_failing_is_zero_sessions_exit_0():  # a broken meter must never fail a run
    with tempfile.TemporaryDirectory() as d:
        fake = write(d, "fake_oc.sh", "#!/usr/bin/env bash\necho boom >&2\nexit 1\n")
        r = run(OC_USAGE, "collect", "--wt", d, env={"OC_BIN": fake, "OC_MAJOR": "2"})
        assert r.returncode == 0, r.stderr
        assert json.loads(r.stdout.strip().splitlines()[-1])["sessions"] == 0


def test_effort_comes_from_opencode_json_by_model_key_not_from_the_name():
    cases = {
        "cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017": "max",   # no effort word in the name
        "cloudflare-workers-ai/deepseek-v4.1-flash-fast": "none",                    # "fast" is none
        "cloudflare-workers-ai/deepseek-v4.1-flash-low": "low",
        "cloudflare-workers-ai/@cf/zai-org/glm-5.3": "max",
        "gemini-3.8-flash-medium": "medium",                                         # not in opencode.json: the name says it
        "nonsense-model": "-",
    }
    for model, want in cases.items():
        r = run(MODEL_EFFORT, model)
        assert r.returncode == 0, (model, r.stderr)
        assert r.stdout.strip() == want, (model, r.stdout)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_oc_usage")
