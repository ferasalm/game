#!/usr/bin/env python3
"""nv_build.sh walks NV_CHAIN (Feras 11-04): a provider refusal (`why: quota`) reruns the task on the next model; a
model's own failure, a PASS and a REFUSED stop the walk; a pinned 4th arg runs that one model only.
The real nv_build.sh, lib.sh and builders.conf run against a stub build_pipeline.sh and slots.sh."""
import os
import re
import shutil
import subprocess
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
BASH = shutil.which("bash") or "bash"
PIPE = """#!/usr/bin/env bash
# stub: $1 builder, $2 task, $5 model; REFUSE_MODELS get a provider refusal, FAIL_MODELS a model failure
echo "$1 $5" >> "$GAME_WT_DIR/calls"
case " $REFUSE_MODELS " in *" $5 "*) printf 'NOWORK 10:00 oc/%s\\nwhy: quota: provider refused\\n' "$2" > "$GAME_WT_DIR/$2.result"; exit 1 ;; esac
case " $FAIL_MODELS " in *" $5 "*) printf 'NOWORK 10:00 oc/%s\\nwhy: idle: no commit\\n' "$2" > "$GAME_WT_DIR/$2.result"; exit 1 ;; esac
case " $SHUT_MODELS " in *" $5 "*) echo REFUSED; exit 3 ;; esac
printf 'PASS 10:00 oc/%s\\n' "$2" > "$GAME_WT_DIR/$2.result"
"""


def run(**env):
    top = tempfile.mkdtemp().replace("\\", "/")
    tools = top + "/tools"
    os.makedirs(tools)
    for f in ("nv_build.sh", "lib.sh", "builders.conf"):
        shutil.copy(f"{TOOLS}/{f}", f"{tools}/{f}")
    for name, body in (("build_pipeline.sh", PIPE), ("slots.sh", "#!/usr/bin/env bash\nexit 0\n")):
        with open(f"{tools}/{name}", "w", encoding="utf-8", newline="\n") as f:
            f.write(body)
    wtd = top + "/wtd"
    os.makedirs(wtd)
    e = {**{k: v for k, v in os.environ.items() if not k.startswith("NV_")}, "GAME_WT_DIR": wtd,
         "OC_BIN": "/nonexistent/opencode",  # preflight (part d) warns and runs the chain unchanged
         "NV_CHAIN": "nvidia/a opencode/b-free cerebras/c", "REFUSE_MODELS": "", "FAIL_MODELS": "", "SHUT_MODELS": ""}
    e.update(env)
    args = [BASH, tools + "/nv_build.sh", "job", top + "/brief.md", "origin/main"] + e.pop("_ARGS", "").split()
    r = subprocess.run(args, capture_output=True, text=True, env=e, stdin=subprocess.DEVNULL, timeout=60)
    calls = open(wtd + "/calls").read().split("\n")[:-1] if os.path.exists(wtd + "/calls") else []
    return r, calls


def test_a_pass_on_the_first_model_stops_there():
    r, calls = run()
    assert r.returncode == 0 and calls == ["nv nvidia/a"], (r.stderr, calls)


def test_a_provider_refusal_falls_through_to_the_next_free_model():
    r, calls = run(REFUSE_MODELS="nvidia/a opencode/b-free")
    assert r.returncode == 0 and calls == ["nv nvidia/a", "nv opencode/b-free", "nv cerebras/c"], (r.stderr, calls)
    assert r.stderr.count("refused by its provider") == 2, r.stderr


def test_every_model_refused_ends_red_after_the_whole_chain():
    r, calls = run(REFUSE_MODELS="nvidia/a opencode/b-free cerebras/c")
    assert r.returncode == 1 and len(calls) == 3, (r.returncode, calls)


def test_a_models_own_failure_never_falls_through():
    r, calls = run(FAIL_MODELS="nvidia/a")
    assert r.returncode == 1 and calls == ["nv nvidia/a"], calls


def test_refused_by_the_pipeline_exits_3_without_a_fallback():
    r, calls = run(SHUT_MODELS="nvidia/a")
    assert r.returncode == 3 and calls == ["nv nvidia/a"], (r.returncode, calls)


def test_a_pinned_model_runs_alone():
    r, calls = run(REFUSE_MODELS="groq/x", _ARGS="groq/x")
    assert r.returncode == 1 and calls == ["nv groq/x"], calls


def test_the_glm_word_walks_the_glm_chain_only():
    # Feras 11-05: a refusal retries the same family's next route, never another model (NV_CHAIN is not touched)
    r, calls = run(GLM_CHAIN="nvidia/g opencode/g-free", REFUSE_MODELS="nvidia/g", _ARGS="glm")
    assert r.returncode == 0 and calls == ["nv nvidia/g", "nv opencode/g-free"], (r.stderr, calls)


def test_the_deepseek_word_is_the_default_chain():
    r, calls = run(_ARGS="deepseek")
    assert r.returncode == 0 and calls == ["nv nvidia/a"], (r.stderr, calls)


def test_the_build_chains_hold_one_model_each():
    # D11 + Feras 11-05: a fallback hop is another route to the same calibrated model, so every id in a chain names it
    conf = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "builders.conf"), encoding="utf-8").read()
    for var, name in (("NV_CHAIN", "deepseek-v4.1-flash"), ("GLM_CHAIN", "glm-5.3-flash")):
        ids = re.search(r'\$\{' + var + r':=([^}]*)\}', conf).group(1).split()
        assert ids and all(name in i for i in ids), (var, ids)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_nv_build")
