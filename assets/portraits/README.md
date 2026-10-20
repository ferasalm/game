# Portraits

One PNG per speaker and expression: `<speaker>_<expression>.png` (speaker = id in content/dialogue/speakers.json;
expression = neutral, happy, angry or surprised). When a file is missing, the game draws a stand-in from the
speaker's pixel sprite.

Each PNG needs a `<name>.png.import` next to it containing `[remap]` and `importer="keep"` (the game loads
the file itself, so a fresh clone needs no import step), and an entry in `assets/manifest.json`.
`python tools/art/portrait.py` writes all three. Steps: docs/design/portrait-prompts.md.
