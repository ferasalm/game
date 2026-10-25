#!/usr/bin/env python3
"""Syncs a Twee 3 story in the repo with the Twine 2 desktop library, both ways (docs/story/README.md).

push: repo -> Twine (refused while Twine runs or when Twine has edits not yet pulled); pull: Twine -> repo;
merge FILE: adds or replaces passages from a Twee file (e.g. ChatGPT output); status: which side changed.
Usage: python tools/twine_sync.py push|pull|status|merge FILE [--story docs/story/rydan.twee] [--force]
"""
import argparse, hashlib, json, os, pathlib, re, subprocess, sys

from twine_format import fill_data, from_html, layout, parse_twee, to_html, write_twee

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_STORY = ROOT / "docs" / "story" / "rydan.twee"


def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else ""


def stories_dir():
    """TWINE_STORIES, else Twine's own library folder setting (app-prefs.json), else Documents/Twine/Stories."""
    if os.environ.get("TWINE_STORIES"):
        return pathlib.Path(os.environ["TWINE_STORIES"])
    prefs = pathlib.Path(os.environ.get("APPDATA", pathlib.Path.home())) / "Twine" / "app-prefs.json"
    folder = json.loads(prefs.read_text(encoding="utf-8")).get("storyLibraryFolderPath") if prefs.exists() else None
    return pathlib.Path(folder) if folder else pathlib.Path.home() / "Documents" / "Twine" / "Stories"


def library_file(story):
    for f in sorted(stories_dir().glob("*.html")):
        if f'ifid="{story["data"]["ifid"]}"' in f.read_text(encoding="utf-8", errors="replace"):
            return f
    return stories_dir() / (re.sub(r'[<>:"/\\|?*]', "_", story["title"]) + ".html")


def twine_running():
    fake = os.environ.get("TWINE_SYNC_FAKE_RUNNING")
    if fake is not None or os.name != "nt":
        return fake == "1"
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq Twine.exe", "/NH"], capture_output=True, text=True)
    return "twine.exe" in out.stdout.lower()


def state_path(twee): return twee.with_name("." + twee.stem + ".sync.json")
def load_state(twee): return json.loads(state_path(twee).read_text()) if state_path(twee).exists() else {}
def write(path, text): path.parent.mkdir(parents=True, exist_ok=True); path.write_text(text, "utf-8", newline="\n")


def save_state(twee, lib):
    write(state_path(twee), json.dumps({"twee": sha(twee), "library": sha(lib)}) + "\n")


def push(twee, force):
    story = parse_twee(twee.read_text(encoding="utf-8"))
    fill_data(story)
    lib = library_file(story)
    if twine_running():
        return "Twine is open: close it, then push (Twine would overwrite the file)."
    if lib.exists() and sha(lib) != load_state(twee).get("library") and not force:
        return f"Twine has edits not pulled yet ({lib.name}): run pull first, or push --force to drop them."
    layout(story)
    write(twee, write_twee(story))
    write(lib, to_html(story))
    save_state(twee, lib)
    print(f"pushed {len(story['passages'])} passages -> {lib}")


def pull(twee, force):
    story = parse_twee(twee.read_text(encoding="utf-8")) if twee.exists() else {"data": {}, "passages": []}
    fill_data(story)
    lib, state = library_file(story), load_state(twee)
    if not lib.exists():
        return f"No Twine file for this story in {stories_dir()}: push first."
    if sha(lib) == state.get("library"):
        print("Twine has nothing new.")
        return None
    if twee.exists() and sha(twee) != state.get("twee") and not force:
        return f"Both {twee.name} and Twine changed since the last sync: pull --force keeps Twine's version."
    pulled = from_html(lib.read_text(encoding="utf-8"))
    write(twee, write_twee(pulled))
    save_state(twee, lib)
    print(f"pulled {len(pulled['passages'])} passages <- {lib}")


def merge(twee, src):
    story = parse_twee(twee.read_text(encoding="utf-8"))
    fill_data(story)
    by_name = {p["name"]: p for p in story["passages"]}
    added = replaced = 0
    for p in parse_twee(pathlib.Path(src).read_text(encoding="utf-8"))["passages"]:
        old = by_name.get(p["name"])
        if old:
            old["text"], old["tags"], replaced = p["text"], p["tags"], replaced + 1
        else:
            p["meta"] = {k: v for k, v in p["meta"].items() if k != "position"}
            story["passages"].append(p)
            added += 1
    layout(story)
    write(twee, write_twee(story))
    print(f"merged {src}: {added} new, {replaced} replaced (in {twee.name}; push to see them in Twine)")


def status(twee):
    story = parse_twee(twee.read_text(encoding="utf-8"))
    fill_data(story)
    lib, state = library_file(story), load_state(twee)
    print(f"repo: {'changed' if sha(twee) != state.get('twee') else 'synced'} ({twee})")
    print(f"Twine: {'changed' if sha(lib) != state.get('library') else 'synced'} ({lib})")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("cmd", choices=["push", "pull", "merge", "status"])
    ap.add_argument("file", nargs="?", help="merge: the Twee file to add")
    ap.add_argument("--story", default=str(DEFAULT_STORY))
    ap.add_argument("--force", action="store_true")
    o = ap.parse_args()
    twee = pathlib.Path(o.story)
    if o.cmd == "merge" and not o.file:
        ap.error("merge needs a Twee file")
    err = {"push": lambda: push(twee, o.force), "pull": lambda: pull(twee, o.force),
           "merge": lambda: merge(twee, o.file), "status": lambda: status(twee)}[o.cmd]()
    if err:
        print("REFUSED: " + err, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
