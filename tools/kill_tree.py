#!/usr/bin/env python3
"""Kills a process and every descendant, also children forked while the kill runs (tools/lib.sh kill_tree calls it).
Freeze the tree (NtSuspendProcess / SIGSTOP) round by round until no new child appears, then kill the frozen set; a
killed parent's children lose their link (init on Linux, a dead pid on Windows). Windows has two parent links: its Windows parent, and its msys parent from msys `ps` (an msys program exec'd
by a fork has a dead Windows parent, the fork; taskkill //T misses it, tools/test_kill_tree.py).
A child counts only if it started at or after its parent (a reused pid is never a descendant). Bounded rounds.
Usage: python tools/kill_tree.py <pid> (a Windows pid on Windows). Exit 0 = nothing of the tree is left, 1 = survivors."""
import os
import signal
import sys
import time

ROUNDS = 8
PAUSE_S = 0.25


def _kernel32():
    import ctypes
    from ctypes import wintypes as w
    k32 = ctypes.WinDLL("kernel32", use_last_error=True)
    k32.CreateToolhelp32Snapshot.restype, k32.CreateToolhelp32Snapshot.argtypes = w.HANDLE, [w.DWORD, w.DWORD]
    k32.Process32FirstW.argtypes = k32.Process32NextW.argtypes = [w.HANDLE, ctypes.c_void_p]
    k32.OpenProcess.restype, k32.OpenProcess.argtypes = w.HANDLE, [w.DWORD, w.BOOL, w.DWORD]
    k32.GetProcessTimes.argtypes = [w.HANDLE] + [ctypes.c_void_p] * 4
    k32.CloseHandle.argtypes = [w.HANDLE]
    return k32


def snapshot_windows() -> dict:
    """{pid: (parent pids, creation time)} from a Toolhelp snapshot plus msys links; creation time 0 if unreadable."""
    import ctypes
    from ctypes import wintypes as w

    class Entry(ctypes.Structure):
        _fields_ = [("dwSize", w.DWORD), ("cntUsage", w.DWORD), ("th32ProcessID", w.DWORD),
                    ("th32DefaultHeapID", ctypes.c_size_t), ("th32ModuleID", w.DWORD), ("cntThreads", w.DWORD),
                    ("th32ParentProcessID", w.DWORD), ("pcPriClassBase", ctypes.c_long), ("dwFlags", w.DWORD),
                    ("szExeFile", ctypes.c_wchar * 260)]
    k32 = _kernel32()
    snap = k32.CreateToolhelp32Snapshot(2, 0)  # TH32CS_SNAPPROCESS
    if not snap or snap == w.HANDLE(-1).value:
        raise OSError("CreateToolhelp32Snapshot failed")
    out = {}
    entry = Entry()
    entry.dwSize = ctypes.sizeof(Entry)
    ok = k32.Process32FirstW(snap, ctypes.byref(entry))
    while ok:
        out[entry.th32ProcessID] = (entry.th32ParentProcessID, start_windows(k32, entry.th32ProcessID))
        ok = k32.Process32NextW(snap, ctypes.byref(entry))
    k32.CloseHandle(snap)
    if not out:
        raise OSError("empty process snapshot")
    msys = msys_parents()
    return {pid: ((parent,) + msys.get(pid, ()), start) for pid, (parent, start) in out.items()}


def msys_parents() -> dict:
    """{winpid: (winpid of its msys parent,)} from msys `ps -e`; empty when there is no msys ps."""
    import shutil
    import subprocess
    exe = shutil.which("ps")
    if not exe:
        return {}
    rows = {}
    for line in subprocess.run([exe, "-e"], capture_output=True, text=True).stdout.splitlines()[1:]:
        cols = line.lstrip("SIOC ").split()
        if len(cols) >= 4 and cols[0].isdigit():
            rows[int(cols[0])] = (int(cols[1]), int(cols[3]))  # msys pid -> (msys ppid, winpid)
    return {win: (rows[ppid][1],) for _, (ppid, win) in rows.items() if ppid in rows}


def start_windows(k32, pid: int) -> int:
    import ctypes
    from ctypes import wintypes as w
    h = k32.OpenProcess(0x1000, False, pid)  # PROCESS_QUERY_LIMITED_INFORMATION
    if not h:
        return 0
    times = [w.FILETIME() for _ in range(4)]
    ok = k32.GetProcessTimes(h, *[ctypes.byref(t) for t in times])
    k32.CloseHandle(h)
    return (times[0].dwHighDateTime << 32 | times[0].dwLowDateTime) if ok else 0


def snapshot_proc() -> dict:
    """{pid: ((parent pid,), start ticks)} from /proc, zombies left out (they are dead, only not reaped)."""
    out = {}
    for name in os.listdir("/proc"):
        if not name.isdigit():
            continue
        try:
            with open("/proc/%s/stat" % name) as f:
                fields = f.read().rsplit(")", 1)[1].split()
        except OSError:
            continue
        if fields[0] != "Z":
            out[int(name)] = ((int(fields[1]),), int(fields[19]))
    return out


def grow(known: dict, procs: dict) -> int:
    """Adds every live descendant of a known pid to known; returns how many were new."""
    added, changed = 0, True
    while changed:
        changed = False
        for pid, (parents, start) in procs.items():
            if pid not in known and any(p in known and start >= known[p] for p in parents):
                known[pid] = start
                added, changed = added + 1, True
    return added


def freeze(pid: int) -> None:
    """Stops a process without killing it, so it forks no more and its children keep their parent links."""
    if os.name != "nt":
        os.kill(pid, signal.SIGSTOP)
        return
    import ctypes
    k32 = _kernel32()
    h = k32.OpenProcess(0x0800, False, pid)  # PROCESS_SUSPEND_RESUME
    if h:
        ctypes.WinDLL("ntdll").NtSuspendProcess(ctypes.c_void_p(h))
        k32.CloseHandle(h)


def each(pids: list, action) -> None:
    for pid in pids:
        try:
            action(pid)
        except OSError:
            pass


def kill_tree(root: int) -> int:
    """Freeze rounds until no new descendant shows up, then kill the frozen set; a second pass for stragglers."""
    snap = snapshot_windows if os.name == "nt" else snapshot_proc
    hard = signal.SIGTERM if os.name == "nt" else signal.SIGKILL  # os.kill on Windows = TerminateProcess
    procs = snap()
    known = {root: procs[root][1] if root in procs else 0}
    left: list = []
    for _ in range(2):
        for rnd in range(ROUNDS):
            added = grow(known, procs)
            each([pid for pid in known if pid in procs], freeze)
            if rnd > 0 and not added:
                break
            time.sleep(PAUSE_S)
            procs = snap()
        each(list(known), lambda pid: os.kill(pid, hard))
        time.sleep(PAUSE_S)
        procs = snap()
        left = [pid for pid in known if pid in procs and procs[pid][1] == known[pid]]
        if not left and not grow(dict(known), procs):
            return 0
    print("kill_tree: %d left of %d: %s" % (len(left), len(known), left[:10]), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(kill_tree(int(sys.argv[1])))
