#!/usr/bin/env python3
"""Self-test for tools/twine_sync.py: python tools/test_twine_sync.py (temp dirs, plain asserts, exit 1 on failure)."""
import importlib.util
import os
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
SCRIPT = HERE / "twine_sync.py"
spec = importlib.util.spec_from_file_location("twine_sync", SCRIPT)
ts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ts)

SAMPLE = """:: StoryTitle
Test Story


:: StoryData
{
  "ifid": "11111111-2222-4333-8444-555555555555",
  "format": "Harlowe",
  "format-version": "3.3.9",
  "start": "Start",
  "tag-colors": {
    "idea": "yellow"
  },
  "zoom": 1
}


:: Start [idea scene] {"position":"100,100","size":"100,100"}
Quotes "a" & 'b' <i>tags</i>
\\:: a line that starts with two colons
[[Odd \\[name\\]]]


:: Odd \\[name\\] {"position":"250,100","size":"100,100"}
Second passage.
"""


def run(tmp, *args, running="0"):
    env = dict(os.environ, TWINE_STORIES=str(tmp / "lib"), TWINE_SYNC_FAKE_RUNNING=running)
    return subprocess.run([sys.executable, str(SCRIPT), *args, "--story", str(tmp / "s.twee")],
                          env=env, capture_output=True, text=True)


def test_round_trip():
    story = ts.parse_twee(SAMPLE)
    assert story["passages"][1]["name"] == "Odd [name]", story["passages"][1]["name"]
    assert story["passages"][0]["text"].splitlines()[1].startswith(":: a line"), "colon escape not undone"
    back = ts.write_twee(ts.from_html(ts.to_html(story)))
    assert back == SAMPLE, "round trip changed the story:\n" + back


def test_push_guards(tmp):
    (tmp / "s.twee").write_text(SAMPLE, encoding="utf-8", newline="\n")
    assert run(tmp, "push", running="1").returncode == 1, "push ran while Twine was open"
    r = run(tmp, "push")
    assert r.returncode == 0, r.stderr
    lib = tmp / "lib" / "Test Story.html"
    lib.write_text(lib.read_text(encoding="utf-8").replace("Second passage.", "Edited in Twine."), encoding="utf-8")
    assert run(tmp, "push").returncode == 1, "push overwrote unpulled Twine edits"
    r = run(tmp, "pull")
    assert r.returncode == 0 and "Edited in Twine." in (tmp / "s.twee").read_text(encoding="utf-8"), r.stderr
    assert run(tmp, "push").returncode == 0, "push refused after a pull"


def test_pull_conflict(tmp):
    lib = tmp / "lib" / "Test Story.html"
    lib.write_text(lib.read_text(encoding="utf-8").replace("Second passage.", "Twine side."), encoding="utf-8")
    twee = tmp / "s.twee"
    twee.write_text(twee.read_text(encoding="utf-8") + "\n:: Repo only\nRepo side.\n", encoding="utf-8")
    assert run(tmp, "pull").returncode == 1, "pull overwrote repo edits while Twine also changed"
    assert run(tmp, "pull", "--force").returncode == 0, "pull --force refused"


def test_merge(tmp):
    twee = tmp / "s.twee"
    twee.write_text(SAMPLE, encoding="utf-8", newline="\n")
    (tmp / "in.twee").write_text(":: Start [draft]\nNew start text.\n\n:: Brand new [scene]\nHello.\n",
                                 encoding="utf-8")
    r = run(tmp, "merge", str(tmp / "in.twee"))
    assert r.returncode == 0 and "1 new, 1 replaced" in r.stdout, r.stdout + r.stderr
    ps = {p["name"]: p for p in ts.parse_twee(twee.read_text(encoding="utf-8"))["passages"]}
    assert ps["Start"]["text"] == "New start text." and ps["Start"]["tags"] == ["draft"], ps["Start"]
    assert ps["Start"]["meta"]["position"] == "100,100", "merge moved a placed passage"
    assert ps["Brand new"]["meta"]["position"] == "100,350", ps["Brand new"]["meta"]


def main():
    test_round_trip()
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        test_push_guards(tmp)
        test_pull_conflict(tmp)
        test_merge(tmp)
    print("twine_sync: 4 tests passed")


if __name__ == "__main__":
    main()
