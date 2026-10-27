#!/usr/bin/env python3
"""Self-test for res_graph.py --check: python tools/test_res_graph.py (a fake project in a temp folder, exit 1 on failure).
One planted dead script must fail the check; reached files, glTF side files and runtime portraits must not."""
import pathlib
import subprocess
import sys
import tempfile

TOOL = pathlib.Path(__file__).resolve().parent / "res_graph.py"
FILES = {
    "project.godot": '[application]\nrun/main_scene="res://features/a/main.tscn"\n',
    "features/a/main.tscn": '[ext_resource type="Script" path="res://features/a/main.gd"]\n'
                            '[ext_resource type="PackedScene" path="res://assets/hero.gltf"]\n',
    "features/a/main.gd": "extends Node\n## Main.\nvar x: Helper\n",
    "features/a/helper.gd": "class_name Helper\nextends RefCounted\n## Reached by its class name.\n",
    "assets/hero.gltf": '{"buffers": [{"uri": "hero.bin"}], "images": [{"uri": "t_hero.png"}]}\n',
    "assets/hero.bin": "x",
    "assets/t_hero.png": "x",
    "assets/portraits/hero_happy.png": "x",
    "assets/licence.txt": "CC0",
}


def run(root: pathlib.Path) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(TOOL), "--check", "--root", str(root)], capture_output=True, text=True)


def main() -> int:
    fails = []
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        for rel, body in FILES.items():
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text(body, encoding="utf-8")
        clean = run(root)
        if clean.returncode != 0:
            fails.append(f"a project with no dead file fails:\n{clean.stdout}{clean.stderr}")
        (root / "features/a/dead.gd").write_text("extends Node\n## Nothing loads me.\n", encoding="utf-8")
        planted = run(root)
        if planted.returncode == 0 or "unused: features/a/dead.gd" not in planted.stdout:
            fails.append(f"the planted dead script passed:\n{planted.stdout}{planted.stderr}")
        if planted.stdout.count("unused:") != 1:
            fails.append(f"only the planted file is unused:\n{planted.stdout}")
    for f in fails:
        print("FAIL", f)
    print("test_res_graph:", "FAIL" if fails else "ok")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
