#!/usr/bin/env python3
"""Bridge Claude Code's stdio LSP to Godot's TCP language server, so an edit gets Godot's own errors and references.
Usage: python godot_lsp.py [--project DIR] [--port N] [--no-spawn] [--wait SECONDS]. Raw bytes are relayed both ways in
two threads, so frames and unknown notifications (gdscript_client/changeWorkspace) pass through unchanged; the port is
stable per worktree path, the editor is spawned only when nothing listens, and its tree is killed when this exits.
Standard library only; the client side is plugins/studio/.lsp.json (system-v3 row 22, 2026-11-01)."""
import argparse
import contextlib
import os
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
import zlib

HOST = "127.0.0.1"
PORT_MIN, PORT_MAX = 40000, 59999
CHUNK = 65536
PLENTY_MB = 999999  # an unreadable memory figure must not stop the studio


def port_for(path: str) -> int:
    """A stable port in 40000..59999 from the worktree path, so two worktrees never fight over one server."""
    key = path.replace("\\", "/").rstrip("/").lower().encode("utf-8")  # slash, case and trailing slash do not matter
    return PORT_MIN + zlib.crc32(key) % (PORT_MAX - PORT_MIN + 1)


def free_mb() -> int:
    """Free memory in MB: GODOT_LSP_FREE_MB when set (tests), else available physical memory; unreadable = plenty."""
    if os.environ.get("GODOT_LSP_FREE_MB"):
        return int(os.environ["GODOT_LSP_FREE_MB"])
    if os.name == "nt":
        return free_mb_windows()
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            for line in f:
                if line.startswith("MemAvailable:"):
                    return int(line.split()[1]) // 1024
    except (OSError, ValueError):
        pass
    return PLENTY_MB


def free_mb_windows() -> int:
    """Available physical memory in MB from GlobalMemoryStatusEx; PLENTY_MB when ctypes cannot read it."""
    import ctypes

    class Status(ctypes.Structure):
        _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                    ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                    ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                    ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                    ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]

    status = Status()
    status.dwLength = ctypes.sizeof(Status)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
        return PLENTY_MB
    return int(status.ullAvailPhys) // (1024 * 1024)


def wait_port(port: int, seconds: float):
    """A blocking socket to 127.0.0.1:port, or None when nothing listens within seconds (0 = one try)."""
    deadline = time.time() + seconds
    while True:
        try:
            sock = socket.create_connection((HOST, port), timeout=2)
        except OSError:
            if time.time() >= deadline:
                return None
            time.sleep(0.25)
            continue
        sock.settimeout(None)
        return sock


def godot_exe(project: str) -> str:
    """The pinned console exe from tools/godot.sh run in the project, else GODOT_BIN, else godot on PATH."""
    try:
        done = subprocess.run(["bash", "tools/godot.sh"], cwd=project, capture_output=True, text=True, timeout=120)
        if done.returncode == 0 and done.stdout.strip():
            exe = done.stdout.strip().splitlines()[-1].strip()
            if os.name == "nt" and len(exe) > 3 and exe[0] == "/" and exe[1].isalpha() and exe[2] == "/":
                exe = exe[1].upper() + ":" + exe[2:]  # godot.sh prints an msys path (/c/dev/...) that Windows cannot run
            return exe
    except (OSError, subprocess.SubprocessError):
        pass
    return os.environ.get("GODOT_BIN") or shutil.which("godot") or "godot"


def command_line(project: str, port: int) -> list:
    """The argv that starts the editor: GODOT_LSP_CMD with {port} and {project} filled in, else the pinned exe."""
    raw = os.environ.get("GODOT_LSP_CMD")
    if not raw:
        return [godot_exe(project), "--headless", "--editor", "--lsp-port", str(port), "--path", project]
    argv = []
    for token in shlex.split(raw, posix=False):  # posix=False keeps backslashes in a Windows path
        token = token.replace("{port}", str(port)).replace("{project}", project)
        argv.append(token[1:-1] if len(token) > 1 and token[0] == token[-1] and token[0] in "\"'" else token)
    return argv


def spawn(project: str, port: int) -> subprocess.Popen:
    """Starts the editor as its own process group, with the client's stdin/stdout kept away from it (stdout is the LSP
    channel; Godot's console log would corrupt it). Its stderr stays visible as the bridge's own."""
    extra = {"start_new_session": True} if os.name != "nt" else {}
    return subprocess.Popen(command_line(project, port), cwd=project, stdin=subprocess.DEVNULL,
                            stdout=subprocess.DEVNULL, **extra)


def stop(proc: subprocess.Popen, project: str) -> None:
    """Stops the tree this bridge started: kill_tree.py when the project ships it, else taskkill /T or the group."""
    helper = os.path.join(project, "tools", "kill_tree.py")
    try:
        if os.path.isfile(helper):
            subprocess.run([sys.executable, helper, str(proc.pid)], capture_output=True, timeout=180)
        elif os.name == "nt":
            subprocess.run(["taskkill", "/T", "/F", "/PID", str(proc.pid)], capture_output=True, timeout=180)
        else:
            os.killpg(proc.pid, signal.SIGKILL)
    except (OSError, subprocess.SubprocessError):
        proc.kill()


def pump(read, write, done: threading.Event) -> None:
    """Copies raw bytes one way, unchanged, until the source ends; write is sendall or a flushing writer."""
    try:
        while True:
            chunk = read(CHUNK)
            if not chunk:
                break
            write(chunk)
    except (OSError, ValueError):
        pass
    finally:
        done.set()


def relay(sock) -> None:
    """Two threads, no parsing: every framed message and unknown notification passes through unchanged."""
    done = threading.Event()

    def to_stdout(chunk):
        sys.stdout.buffer.write(chunk)
        sys.stdout.buffer.flush()

    stdin_read = getattr(sys.stdin.buffer, "read1", sys.stdin.buffer.read)
    threads = [threading.Thread(target=pump, args=(stdin_read, sock.sendall, done), daemon=True),
               threading.Thread(target=pump, args=(sock.recv, to_stdout, done), daemon=True)]
    for thread in threads:
        thread.start()
    done.wait()


def serve(args) -> int:
    """Uses a listening server or starts one, relays until stdin ends, and always stops what it started."""
    project = os.path.abspath(args.project)
    port = args.port or port_for(project)
    proc = None
    sock = wait_port(port, 0)
    if sock is None and not args.no_spawn:
        floor = int(os.environ.get("MIN_FREE_MB") or "2000")
        free = free_mb()
        if free < floor:
            sys.stderr.write("memory: %d MB free < %d MB floor, not starting Godot\n" % (free, floor))
            return 3
        proc = spawn(project, port)
    try:
        if sock is None:
            sock = wait_port(port, args.wait)
        if sock is None:
            sys.stderr.write("port %d is not open\n" % port)
            return 4
        relay(sock)
        return 0
    finally:
        if sock is not None:
            with contextlib.suppress(OSError):
                sock.shutdown(socket.SHUT_RDWR)  # a plain close under the reading thread resets the connection
            sock.close()
        if proc is not None:
            stop(proc, project)


def main(argv=None) -> int:
    """Parses the command line and returns the exit code (0 relayed, 3 memory floor, 4 no server)."""
    parser = argparse.ArgumentParser(description="Relay Claude Code's stdio LSP to Godot's TCP language server.")
    parser.add_argument("--project", default=".", help="Godot project directory (default: the current directory)")
    parser.add_argument("--port", type=int, default=0, help="server port (default: stable per project path)")
    parser.add_argument("--no-spawn", action="store_true", help="never start Godot, only use a listening server")
    parser.add_argument("--wait", type=float, default=120.0, help="seconds to wait for the port (default: 120)")
    return serve(parser.parse_args(argv))


if __name__ == "__main__":
    sys.exit(main())
