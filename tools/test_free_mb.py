#!/usr/bin/env python3
"""The memory floor reads available PHYSICAL memory (Task Manager's "available"), not free virtual memory (row 25,
Feras 11-01: slots.sh counted RAM + pagefile, so it read 20 GB on a 15 GB PC and Godot steps timed out under real pressure)."""
import ctypes
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)


def total_physical_mb() -> int:
    """Total RAM in MB from the OS (Windows GlobalMemoryStatusEx, else /proc/meminfo); 0 when unreadable."""
    if os.name == "nt":
        class Status(ctypes.Structure):
            _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
        status = Status()
        status.dwLength = ctypes.sizeof(Status)
        ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status))
        return status.ullTotalPhys // (1024 * 1024)
    with open("/proc/meminfo", encoding="ascii") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                return int(line.split()[1]) // 1024
    return 0


def lib_free_mb() -> int:
    env = {k: v for k, v in os.environ.items() if k != "FREE_MB"}
    out = subprocess.run(["bash", "-c", f". '{HERE}/lib.sh'; free_mb"], capture_output=True, text=True, env=env,
                         stdin=subprocess.DEVNULL).stdout.strip()
    assert out.isdigit(), out
    return int(out)


def test_the_floor_never_reads_more_than_the_ram_the_pc_has():
    total = total_physical_mb()
    assert total > 0
    free = lib_free_mb()
    assert 0 < free <= total, f"{free} MB 'free' on a {total} MB PC: that is virtual memory, not RAM"


def test_free_mb_py_prints_one_number_and_lib_uses_it():
    out = subprocess.run([sys.executable, HERE + "/free_mb.py"], capture_output=True, text=True,
                         stdin=subprocess.DEVNULL).stdout.strip()
    assert out.isdigit(), out
    assert abs(int(out) - lib_free_mb()) < 1500, (out, lib_free_mb())  # two reads a moment apart


def test_the_lsp_script_and_the_floor_agree():
    import importlib.util
    spec = importlib.util.spec_from_file_location("godot_lsp", ROOT + "/plugins/studio/scripts/godot_lsp.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    saved = os.environ.pop("GODOT_LSP_FREE_MB", None)
    try:
        assert abs(mod.free_mb() - lib_free_mb()) < 1500, "two memory readers in one repo must agree"
    finally:
        if saved is not None:
            os.environ["GODOT_LSP_FREE_MB"] = saved


def test_the_stub_still_wins():
    env = {**os.environ, "FREE_MB": "1234"}
    out = subprocess.run(["bash", "-c", f". '{HERE}/lib.sh'; free_mb"], capture_output=True, text=True, env=env,
                         stdin=subprocess.DEVNULL).stdout.strip()
    assert out == "1234", out


def test_the_default_floor_is_2000_mb():
    text = open(HERE + "/builders.conf", encoding="utf-8").read()
    assert ":=2000}" in text and "MIN_FREE_MB" in text, "Feras 11-01: floor 2000 MB of available physical memory"
    lsp = open(ROOT + "/plugins/studio/scripts/godot_lsp.py", encoding="utf-8").read()
    assert '"MIN_FREE_MB") or "2000"' in lsp, "the LSP script must use the same default floor"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_free_mb")
