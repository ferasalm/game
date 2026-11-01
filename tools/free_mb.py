#!/usr/bin/env python3
"""Prints the available PHYSICAL memory in MB, the number Task Manager calls "available" (Feras 11-01: the floor used to count
free virtual memory, RAM plus pagefile, which read 18-20 GB on a 16 GB PC). Windows: GlobalMemoryStatusEx; elsewhere
MemAvailable in /proc/meminfo; unreadable prints 999999 (plenty: a broken read must never block a run). Used by lib.sh free_mb.
Tests: tools/test_free_mb.py."""
import ctypes
import os

PLENTY_MB = 999999


def available_mb() -> int:
    if os.name == "nt":
        class Status(ctypes.Structure):
            _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
        try:
            status = Status()
            status.dwLength = ctypes.sizeof(Status)
            if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
                return int(status.ullAvailPhys // (1024 * 1024))
        except (OSError, AttributeError):
            pass
        return PLENTY_MB
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            for line in f:
                if line.startswith("MemAvailable:"):
                    return int(line.split()[1]) // 1024
    except (OSError, ValueError):
        pass
    return PLENTY_MB


if __name__ == "__main__":
    print(available_mb())
