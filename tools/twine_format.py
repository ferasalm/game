#!/usr/bin/env python3
"""Twee 3 <-> Twine 2 library HTML conversion for tools/twine_sync.py (parse, write, layout, to/from HTML)."""
import html, json, re, uuid

HEADER = re.compile(r"^::\s*((?:\\.|[^\\\[{])*?)\s*(?:\[((?:\\.|[^\\\]])*)\])?\s*(\{.*\})?\s*$")
ATTR = re.compile(r'([\w-]+)(?:="([^"]*)")?')
SPECIAL = {"stylesheet": "style", "script": "script"}
GRID, COLS = 150, 6


def esc(s): return re.sub(r"([\\\[\]{}])", r"\\\1", s)
def unesc(s): return re.sub(r"\\(.)", r"\1", s)
def a(s): return html.escape(str(s), quote=True)



def parse_twee(text):
    """Twee 3 text -> {"title", "data", "passages": [{"name", "tags", "meta", "text"}]}."""
    raw, cur = [], None
    for line in text.replace("\r\n", "\n").split("\n"):
        m = HEADER.match(line) if line.startswith("::") else None
        if m:
            cur = {"name": unesc(m[1]), "tags": unesc(m[2] or "").split(),
                   "meta": json.loads(m[3]) if m[3] else {}, "lines": []}
            raw.append(cur)
        elif cur is not None:
            cur["lines"].append(line[1:] if line.startswith("\\::") else line)
    story = {"title": "", "data": {}, "passages": []}
    for p in raw:
        p["text"] = "\n".join(p.pop("lines")).strip("\n")
        if p["name"] == "StoryTitle":
            story["title"] = p["text"].strip()
        elif p["name"] == "StoryData":
            story["data"] = json.loads(p["text"])
        else:
            story["passages"].append(p)
    return story


def write_twee(story):
    parts = [":: StoryTitle\n" + story["title"], ":: StoryData\n" + json.dumps(story["data"], indent=2)]
    for p in story["passages"]:
        head = ":: " + esc(p["name"])
        if p["tags"]:
            head += " [" + " ".join(p["tags"]) + "]"
        if p["meta"]:
            head += " " + json.dumps(p["meta"], separators=(",", ":"))
        body = "\n".join("\\" + ln if ln.startswith("::") else ln for ln in p["text"].split("\n"))
        parts.append(head + "\n" + body)
    return "\n\n\n".join(parts) + "\n"


def fill_data(story):
    d = story["data"]
    d.setdefault("ifid", str(uuid.uuid4()).upper())
    d.setdefault("format", "Harlowe")
    d.setdefault("format-version", "3.3.9")
    d.setdefault("start", story["passages"][0]["name"] if story["passages"] else "")
    d.setdefault("tag-colors", {})
    d.setdefault("zoom", 1)


def layout(story):
    """Gives passages without a position a grid spot below every placed passage."""
    placed = [p for p in story["passages"] if "position" in p["meta"]]
    top = max((int(float(p["meta"]["position"].split(",")[1])) for p in placed), default=-GRID) + GRID + 100
    for i, p in enumerate(q for q in story["passages"] if "position" not in q["meta"]):
        p["meta"]["position"] = f"{100 + i % COLS * GRID},{top + i // COLS * GRID}"
        p["meta"].setdefault("size", "100,100")


def to_html(story):
    """Story -> a Twine 2 library file (one <tw-storydata> element)."""
    d = story["data"]
    special = {t: "\n".join(p["text"] for p in story["passages"] if t in p["tags"]) for t in SPECIAL}
    ps = [p for p in story["passages"] if not set(SPECIAL) & set(p["tags"])]
    names = [p["name"] for p in ps]
    rows = "".join(
        f'<tw-passagedata pid="{i}" name="{a(p["name"])}" tags="{a(" ".join(p["tags"]))}" '
        f'position="{a(p["meta"].get("position", "100,100"))}" size="{a(p["meta"].get("size", "100,100"))}">'
        f'{a(p["text"])}</tw-passagedata>' for i, p in enumerate(ps, 1))
    tags = "".join(f'<tw-tag name="{a(k)}" color="{a(v)}"></tw-tag>' for k, v in d["tag-colors"].items())
    start = names.index(d["start"]) + 1 if d["start"] in names else 1
    return (f'<tw-storydata name="{a(story["title"])}" startnode="{start}" creator="Twine" '
            f'creator-version="2.10.0" format="{a(d["format"])}" format-version="{a(d["format-version"])}" '
            f'ifid="{a(d["ifid"])}" options="" tags="" zoom="{a(d["zoom"])}" hidden>'
            f'<style role="stylesheet" id="twine-user-stylesheet" type="text/twine-css">{a(special["stylesheet"])}'
            f'</style><script role="script" id="twine-user-script" type="text/twine-javascript">'
            f'{a(special["script"])}</script>{tags}{rows}</tw-storydata>\n')


def attrs(s): return {k: html.unescape(v or "") for k, v in ATTR.findall(s)}


def from_html(text):
    sd = attrs(re.search(r"<tw-storydata([^>]*)>", text)[1])
    colors = {t["name"]: t["color"] for t in (attrs(x) for x in re.findall(r"<tw-tag([^>]*)>", text))}
    ps, start = [], ""
    for at, body in re.findall(r"<tw-passagedata([^>]*)>(.*?)</tw-passagedata>", text, re.S):
        p = attrs(at)
        start = p["name"] if p.get("pid") == sd.get("startnode") else start
        ps.append({"name": p["name"], "tags": p.get("tags", "").split(), "text": html.unescape(body),
                   "meta": {"position": p.get("position", "100,100"), "size": p.get("size", "100,100")}})
    for tag, el in SPECIAL.items():
        m = re.search(rf"<{el}[^>]*>(.*?)</{el}>", text, re.S)
        if m and m[1].strip():
            ps.append({"name": "Story " + tag.title(), "tags": [tag], "meta": {}, "text": html.unescape(m[1])})
    data = {"ifid": sd.get("ifid", ""), "format": sd.get("format", "Harlowe"),
            "format-version": sd.get("format-version", "3.3.9"), "start": start, "tag-colors": colors,
            "zoom": json.loads(sd.get("zoom") or "1")}
    return {"title": sd.get("name", ""), "data": data, "passages": ps}
