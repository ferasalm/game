#!/usr/bin/env python3
"""plugins/studio/scripts/godot_lsp.py bridges Claude Code (LSP over stdio) to Godot's LSP (TCP) (system-v3 row 22, 2026-11-01)."""
import json
import os
import socket
import subprocess
import sys
import tempfile
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCRIPT = os.path.join(ROOT, "plugins", "studio", "scripts", "godot_lsp.py")
sys.path.insert(0, os.path.dirname(SCRIPT))
import godot_lsp as gl  # noqa: E402


def frame(obj) -> bytes:
    body = json.dumps(obj).encode("utf-8")
    return b"Content-Length: " + str(len(body)).encode() + b"\r\n\r\n" + body


def read_frame(stream):
    length = None
    while True:
        line = stream.readline()
        if not line:
            return None
        if line in (b"\r\n", b"\n"):
            break
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":")[1])
    return json.loads(stream.read(length)) if length is not None else None


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class FakeGodot(threading.Thread):
    """A TCP server that answers initialize, pushes one unknown notification, and echoes any other request id."""

    def __init__(self, port):
        super().__init__(daemon=True)
        self.srv = socket.socket()
        self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.srv.bind(("127.0.0.1", port))
        self.srv.listen(1)
        self.received = []

    def run(self):
        conn, _ = self.srv.accept()
        f = conn.makefile("rb")
        while True:
            msg = read_frame(f)
            if msg is None:
                return
            self.received.append(msg)
            if msg.get("method") == "initialize":
                conn.sendall(frame({"jsonrpc": "2.0", "method": "gdscript_client/changeWorkspace", "params": {"path": "x"}}))
            if "id" in msg:
                conn.sendall(frame({"jsonrpc": "2.0", "id": msg["id"], "result": {"echo": msg.get("method")}}))


def start_bridge(*args, env=None):
    full_env = dict(os.environ, **(env or {}))
    return subprocess.Popen([sys.executable, SCRIPT, *args], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, env=full_env)


def test_port_for_is_stable_in_range_and_differs_per_worktree():
    a, b = gl.port_for("C:/dev/game/.claude/worktrees/a"), gl.port_for("C:/dev/game/.claude/worktrees/b")
    assert a == gl.port_for("C:/dev/game/.claude/worktrees/a") and a != b
    assert all(40000 <= p <= 59999 for p in (a, b)), (a, b)
    assert gl.port_for("C:\\dev\\Game\\x") == gl.port_for("c:/dev/game/x/")  # slash, case and trailing slash do not matter


def test_bridge_relays_requests_replies_and_unknown_notifications():
    port = free_port()
    fake = FakeGodot(port)
    fake.start()
    bridge = start_bridge("--port", str(port), "--no-spawn")
    bridge.stdin.write(frame({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}))
    bridge.stdin.flush()
    first, second = read_frame(bridge.stdout), read_frame(bridge.stdout)
    methods = {m.get("method") for m in (first, second)}
    assert "gdscript_client/changeWorkspace" in methods, (first, second)  # an unknown notification passes through
    assert {"echo": "initialize"} in [m.get("result") for m in (first, second)]
    bridge.stdin.write(frame({"jsonrpc": "2.0", "id": 2, "method": "textDocument/references", "params": {}}))
    bridge.stdin.flush()
    assert read_frame(bridge.stdout)["result"] == {"echo": "textDocument/references"}
    bridge.stdin.close()
    assert bridge.wait(timeout=30) == 0
    assert [m.get("method") for m in fake.received] == ["initialize", "textDocument/references"]


def test_no_spawn_with_a_closed_port_fails_with_exit_4_and_a_reason():
    bridge = start_bridge("--port", str(free_port()), "--no-spawn", "--wait", "1")
    bridge.stdin.close()
    err = bridge.stderr.read().decode()
    assert bridge.wait(timeout=30) == 4 and "port" in err, err


def test_below_the_memory_floor_nothing_is_spawned():
    with tempfile.TemporaryDirectory() as d:
        marker = os.path.join(d, "spawned.txt")
        cmd = f'"{sys.executable}" -c "open(r\'{marker}\', \'w\').write(\'x\')"'
        bridge = start_bridge("--port", str(free_port()), "--project", d,
                              env={"GODOT_LSP_CMD": cmd, "GODOT_LSP_FREE_MB": "100", "MIN_FREE_MB": "3000"})
        bridge.stdin.close()
        err = bridge.stderr.read().decode()
        assert bridge.wait(timeout=30) == 3 and "memory" in err, err
        time.sleep(1)
        assert not os.path.exists(marker), "spawned below the floor"


FAKE_SERVER = """import json, socket, sys
port, pidfile = int(sys.argv[1]), sys.argv[2]
open(pidfile, 'w').write(str(__import__('os').getpid()))
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1); s.bind(('127.0.0.1', port)); s.listen(1)
c, _ = s.accept(); f = c.makefile('rb')
while True:
    line = f.readline()
    if not line: break
    if line.lower().startswith(b'content-length:'):
        n = int(line.split(b':')[1]); f.readline(); body = json.loads(f.read(n))
        out = json.dumps({'jsonrpc': '2.0', 'id': body['id'], 'result': 'spawned-ok'}).encode()
        c.sendall(b'Content-Length: ' + str(len(out)).encode() + b'\\r\\n\\r\\n' + out)
"""


def pid_alive(pid: int) -> bool:
    if os.name == "nt":
        out = subprocess.run(["tasklist", "/FI", f"PID eq {pid}", "/NH"], capture_output=True, text=True).stdout
        return str(pid) in out
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def test_spawns_the_server_when_the_port_is_closed_relays_and_kills_it_on_exit():
    port = free_port()
    with tempfile.TemporaryDirectory() as d:
        server = os.path.join(d, "fake_server.py")
        pidfile = os.path.join(d, "pid.txt")
        with open(server, "w", encoding="utf-8", newline="\n") as f:
            f.write(FAKE_SERVER)
        cmd = f'"{sys.executable}" "{server}" {{port}} "{pidfile}"'
        bridge = start_bridge("--port", str(port), "--project", d, "--wait", "30",
                              env={"GODOT_LSP_CMD": cmd, "GODOT_LSP_FREE_MB": "99999"})
        bridge.stdin.write(frame({"jsonrpc": "2.0", "id": 7, "method": "initialize", "params": {}}))
        bridge.stdin.flush()
        assert read_frame(bridge.stdout)["result"] == "spawned-ok"
        pid = int(open(pidfile, encoding="utf-8").read())
        assert pid_alive(pid)
        bridge.stdin.close()
        assert bridge.wait(timeout=30) == 0
        deadline = time.time() + 15
        while pid_alive(pid) and time.time() < deadline:
            time.sleep(0.3)
        assert not pid_alive(pid), "the server the bridge started outlived it"


def test_lsp_json_points_at_the_bridge_and_names_gd_files():
    path = os.path.join(ROOT, "plugins", "studio", ".lsp.json")
    cfg = json.load(open(path, encoding="utf-8"))
    server = next(iter(cfg.values())) if "command" not in cfg else cfg
    assert server["extensionToLanguage"][".gd"] == "gdscript", server
    assert "godot_lsp.py" in " ".join(server["args"]) and "${CLAUDE_PLUGIN_ROOT}" in " ".join(server["args"]), server
    assert set(server) <= {"command", "args", "extensionToLanguage", "transport", "env", "initializationOptions",
                           "settings", "workspaceFolder", "startupTimeout", "shutdownTimeout", "requestTimeout",
                           "restartOnCrash", "maxRestarts", "diagnostics"}, set(server)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_godot_lsp: {len(tests)} tests passed")
