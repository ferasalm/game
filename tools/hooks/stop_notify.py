#!/usr/bin/env python3
"""Stop hook (coach 12, Feras 10-31): a Windows balloon when a chat ends its turn, so Feras need not watch it. Runs the
balloon in a detached PowerShell and exits at once; STOP_NOTIFY_DRY=1 prints the command instead. Never blocks: exit 0
on bad JSON or any error; a repeat Stop (stop_hook_active) stays quiet. Test: tools/test_hook_stop_notify.py.
"""
import json
import os
import subprocess
import sys

BALLOON = ("Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; "
           "$n = New-Object System.Windows.Forms.NotifyIcon; $n.Icon = [System.Drawing.SystemIcons]::Information; "
           "$n.Visible = $true; $n.ShowBalloonTip(5000, 'Neon Glitch', 'A Claude chat finished its turn', "
           "[System.Windows.Forms.ToolTipIcon]::Info); Start-Sleep -Seconds 6; $n.Dispose()")
COMMAND = ["powershell", "-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", BALLOON]
DETACHED = 0x00000008 | 0x08000000  # DETACHED_PROCESS | CREATE_NO_WINDOW


def main():
    data = json.load(sys.stdin)
    if data.get("stop_hook_active"):
        return 0
    if os.environ.get("STOP_NOTIFY_DRY"):
        print(" ".join(COMMAND))
        return 0
    subprocess.Popen(COMMAND, creationflags=DETACHED, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
