#!/usr/bin/env python3
"""tools/obscura.sh: the Obscura fetch wrapper (11-03). Stub binaries only: no network, no real Obscura."""
import os
import subprocess
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
STUB = '#!/bin/bash\necho "$@" >> "$STUB_LOG"\necho "page text"\n'
HANG = "#!/bin/bash\nsleep 30\n"


def stub(body):
    d = tempfile.mkdtemp().replace("\\", "/")
    path = d + "/obscura.exe"
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(body)
    os.chmod(path, 0o755)
    return d, path


def run(*args, **env):
    e = {**os.environ, **env}
    return subprocess.run(["bash", TOOLS + "/obscura.sh", *args], capture_output=True, text=True, env=e, timeout=60)


def test_a_fetch_passes_the_url_and_mode_to_obscura():
    d, bin_ = stub(STUB)
    r = run("https://example.com", "markdown", OBSCURA_BIN=bin_, STUB_LOG=d + "/calls")
    assert r.returncode == 0 and "page text" in r.stdout, (r.returncode, r.stdout, r.stderr)
    assert open(d + "/calls").read().strip() == "fetch https://example.com --dump markdown"


def test_text_is_the_default_mode():
    d, bin_ = stub(STUB)
    run("https://example.com", OBSCURA_BIN=bin_, STUB_LOG=d + "/calls")
    assert open(d + "/calls").read().strip() == "fetch https://example.com --dump text"


def test_stealth_is_refused_and_obscura_never_runs():
    d, bin_ = stub(STUB)
    r = run("https://example.com", "--stealth", OBSCURA_BIN=bin_, STUB_LOG=d + "/calls")
    assert r.returncode == 2 and "not allowed" in r.stderr, (r.returncode, r.stderr)
    r = run("https://example.com", "text", "--stealth", OBSCURA_BIN=bin_, STUB_LOG=d + "/calls")  # a valid call plus the flag
    assert r.returncode == 2 and "not allowed" in r.stderr, (r.returncode, r.stderr)
    assert not os.path.exists(d + "/calls"), "obscura must not run when --stealth was asked for"


def test_only_http_urls_and_known_modes_are_accepted():
    d, bin_ = stub(STUB)
    for args in (("file:///etc/passwd",), ("example.com",), ("",), ("https://example.com", "cookies")):
        r = run(*args, OBSCURA_BIN=bin_, STUB_LOG=d + "/calls")
        assert r.returncode == 2, (args, r.returncode, r.stderr)
    assert not os.path.exists(d + "/calls")


def test_a_missing_binary_says_where_to_put_it():
    r = run("https://example.com", OBSCURA_BIN="/nonexistent/obscura.exe")
    assert r.returncode == 3 and "OBSCURA_BIN" in r.stderr, (r.returncode, r.stderr)


def test_a_hanging_fetch_is_killed_at_the_timeout():
    d, bin_ = stub(HANG)
    r = run("https://example.com", OBSCURA_BIN=bin_, OBSCURA_TIMEOUT="2")
    assert r.returncode == 124, (r.returncode, r.stderr)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_obscura", serial=())
