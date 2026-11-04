#!/usr/bin/env python3
"""nv_build.sh preflight (row 28 part d): a chain model whose provider is not stored in oc-v2 is skipped with a login
line; nothing left (or a pinned model without a login) exits 3; a failing or empty `auth list` runs the chain unchanged.
Uses test_nv_build.run (stub build_pipeline.sh) plus a stub opencode that prints the real `auth list` shape (CRLF)."""
import os
import tempfile

import test_nv_build as base

STUB_DIR = tempfile.mkdtemp().replace("\\", "/")
STUB = STUB_DIR + "/opencode"
with open(STUB, "w", encoding="utf-8", newline="\n") as f:
    f.write("""#!/usr/bin/env bash
if [ "$1 $2" = "auth list" ]; then
  [ -n "$AUTH_FAIL" ] && { echo boom >&2; exit 1; }
  printf '%b' "$AUTH_OUT"; exit 0
fi
exit 0
""")
os.chmod(STUB, 0o755)
REAL = "Cerebras    Cerebras 2                  stored\r\nGoogle      Google 2                    stored\r\nNvidia      Nvidia 2                    stored\r\nOpenRouter  OpenRouter                  stored\r\nOpenRouter  API key                     stored\r\n"
CEREBRAS_ONLY = "Cerebras    Cerebras 2                  stored\r\n"


def run(auth=REAL, **env):
    return base.run(OC_BIN=STUB, AUTH_OUT=auth, **env)


def test_missing_provider_is_skipped_and_chain_continues():
    r, calls = run(auth=CEREBRAS_ONLY)
    assert r.returncode == 0 and calls == ["nv opencode/b-free"], (r.returncode, r.stderr, calls)
    assert "skipping nvidia/a: Nvidia is not logged in to oc-v2" in r.stderr and "auth login --standalone" in r.stderr, r.stderr


def test_all_logged_in_runs_the_first_model_as_before():
    r, calls = run()
    assert r.returncode == 0 and calls == ["nv nvidia/a"] and "skipping" not in r.stderr, (r.stderr, calls)


def test_every_model_missing_exits_3_without_a_build():
    r, calls = run(auth="Groq   Groq 1   stored\r\n", NV_CHAIN="nvidia/a cerebras/c")
    assert r.returncode == 3 and calls == [], (r.returncode, calls)
    assert "skipping nvidia/a" in r.stderr and "skipping cerebras/c" in r.stderr, r.stderr


def test_a_pinned_model_without_a_login_exits_3():
    r, calls = run(auth=CEREBRAS_ONLY, _ARGS="nvidia/x")
    assert r.returncode == 3 and calls == [] and "skipping nvidia/x: Nvidia is not logged in" in r.stderr, (r.returncode, r.stderr, calls)


def test_auth_list_failing_runs_the_chain_unchanged():
    r, calls = run(AUTH_FAIL="1")
    assert r.returncode == 0 and calls == ["nv nvidia/a"] and "gave no providers" in r.stderr, (r.stderr, calls)


def test_unparseable_or_empty_auth_list_runs_the_chain_unchanged():
    r, calls = run(auth="")
    assert r.returncode == 0 and calls == ["nv nvidia/a"] and "gave no providers" in r.stderr, (r.stderr, calls)


def test_provider_matching_is_case_insensitive():
    r, calls = run(auth="NVIDIA   key   stored\r\n", NV_CHAIN="nvidia/a")
    assert r.returncode == 0 and calls == ["nv nvidia/a"], (r.stderr, calls)


def test_opencode_models_need_no_login():
    r, calls = run(auth=CEREBRAS_ONLY, NV_CHAIN="opencode/b-free")
    assert r.returncode == 0 and calls == ["nv opencode/b-free"], (r.stderr, calls)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_nv_preflight")
