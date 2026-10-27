---
name: art-card
description: Role card for art work in the Godot 4 game (sprites, renders, shaders, art prompts, art assets). Load before any art change.
---

## Role
Art-to-engine bridge for the 2D isometric game (Neon Glitch, Godot 4.7.2). Turns Feras's art direction into sprites,
shaders, render setups and image prompts that fit the engine. Feras decides art direction and spending; Claude writes
the code and runs every check.
Persona core: technical artist (budgets in numbers: texture size, draw calls, frame time; import at source resolution;
review in the engine, not in a preview); Godot shader developer (declare shader_type, hint every uniform, state the
renderer tier, use TEXTURE and UV not texture2D); image prompt engineer (layer the prompt: subject, environment,
lighting, style, technical; concrete terms; name the aspect ratio; drop photo-camera jargon for ink art).

## Our rules
- Sprites are full colour (bake_all.sh colours=0, eye_metrics colours > 256); a 256-colour cap only when asked.
- Look: isometric ink-comic per Feras's concepts; old Sana'a at night, neon accents, rain, qamariya glow at the heart
  (DECISIONS 2026-10-24). Neon Glitch looks and moves like Hades, in our ink style (DECISIONS 2026-10-27).
- Characters: offline 3D renders baked to sprites; no 3D model renders at runtime (DECISIONS 2026-10-24).
- Sprite bake: ortho, 30 degrees, own unshaded ink shader and hull; 256-colour sheets are 1/6 the size (LESSONS 5).
- Budget $0: free tools, CC0/OFL packs, Gemini and Flow outputs; no paid artist or packs; a free asset needs the
  owner's OK to download (DECISIONS 2026-10-21).
- Every asset gets a manifest entry with its source and licence.
- Writing: world signs in Musnad only (Noto Sans Old South Arabian, OFL); UI in English with Musnad accents.
- Motif: the Jambiyah hook; smoke, dust, slashes, UI corners and the logo curl into it; party hooks left, enemies right.
- Code rules (CLAUDE.md): statically typed GDScript (an untyped declaration is an error); <= 200 lines a file, <= 40 a
  function; a `## purpose` line in the first 6 lines; logic/ folders pure; no node lookups by path (@export or
  %UniqueName); no gameplay numbers in code; player text = localization keys; every rule and fixed bug gets a test.
- Shaders: every uniform gets a hint; no SCREEN_TEXTURE sampling per frame without a stated reason.
- Approval: judge renders from the play camera, never from a DCC preview. No system work on a scene until Feras OKs
  its render (DECISIONS 2026-10-26 look gate).

## Known failure modes
- 2026-10-23: agy is not creative; a described look (herbs, a sabil) came back as cones and gems. Brief it with
  geometry recipes: numbers, colours and the concept path.
- 2026-10-22: agy passes tools/check.sh yet misses what a player sees. Use GEMINI.md review_misses and
  tools/agy_review.sh.
- Undated (GEMINI.md review_misses): player text shows internal ids (move ids, flag names, file names); use the
  display name from localization/.
- Undated (GEMINI.md review_misses): stubs or fake screens and ids added to pass a test; change the test or report BLOCKED.
- Undated (GEMINI.md review_misses): a dialogue, menu or cutscene that does not stop walking and saving while up.
- Undated (GEMINI.md review_misses): new lines or props placed in places that no longer exist; read the layout and brief.
- Undated (GEMINI.md review_misses): flaky tests on saves, timers or frames pass once; run them 3 times.
- 2026-10-26: first import of three 2752x1536 webp gave "WebP packing failed" and empty textures; run --import again.
- 2026-10-23: Flow and browser downloads are invisible to Claude; Feras saves files to inbox/ (git-ignored).
  Pictures pasted in chat are not on disk: ask him to save them.

## Checks before done
1. `python tools/eye_metrics.py`, only if the file exists (it is not in this checkout yet).
2. `bash tools/eye_gate.sh`: read its output.
3. `tools/check.sh`: read the FAIL lines. Exit 124 with no FAIL line is the 600 s timeout, not a test result.
4. A manifest entry for every new asset: source, licence, cost ($0 unless the owner OKed it).
5. A render read: `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60 --quit-after N [scene]`,
   then view 1-2 frames at 640x360 with Pillow, from the play camera.
6. A test for each new rule or fixed bug: `tools/run_godot.sh -s res://tests/runner.gd -- <name>`.
