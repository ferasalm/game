# Architecture

How the game is built and why. Not loaded at session start: grep the heading you need. Rules that tools enforce
are marked (enforced). Decisions behind this file: docs/DECISIONS.md, 2026-10-19. Code map: docs/MAP.md.

## 1. Goals (what every choice below optimizes)
1. **Cheap to change for years.** A change touches one feature folder; nothing reaches across by node path.
2. **Verified by text, not by eye.** Rules live in pure code with headless tests, so Claude checks work by reading
   one summary line instead of playing the game or reading screenshots.
3. **Art never blocks code.** Every visual has a placeholder; real art swaps in by id.
4. **AI-friendly.** Small typed files, data in JSON, one generated map, levels described as text.
5. **Runs well on a laptop with integrated graphics** at 60 fps.

## 2. Platform
- Godot **4.7.2 stable**, pinned in `.godot-version` (tools/godot.sh downloads it; CI and cloud sessions use it).
  Upgrade only in a chat of its own: bump the file, run tools/check.sh, play the look test.
- **GDScript, statically typed** (Godot treats an untyped declaration as an error: project.godot).
- Renderer **Forward+** (Vulkan/D3D12). Fallback if the owner's laptop is too slow: Mobile renderer.
- Target: Windows first (Steam later if the owner decides). Linux and Steam Deck cost little later.
- Window 1920x1080, scales down; 60 fps on integrated GPUs (Intel Iris Xe / AMD Radeon 600M class).

## 3. The render model (Neon Glitch, DECISIONS 2026-10-24/26)
- **The old 3D game is retired (2026-10-26).** Its world, prototype scene, 3D battle stage, holo map and their
  tests live at git tag `3d-archive` (audit: docs/archive/design-3d/retire-3d-audit.md). Restore a file with
  `git show 3d-archive:<path>`; never re-add 3D runtime code without a decision.
- **World = painted isometric plates** (2:1 dimetric, camera 30 degrees down) per room, walkable polygons and
  occluder cut-outs in `content/neon/rooms.json`; y-sort by feet (docs/design/first-playable.md section 2).
- **Characters = baked sprites, never 3D at runtime.** The Rodin models in `assets/characters/` are offline
  sources: `tools/bake_sprites.tscn` renders them through `CharacterVisual` / `ModelRig` (features/art/view, kept
  for the baker) into 8-direction sheets (`tools/art/sprite_sheet.py`, `content/neon/sprites.json`).
- **Fights on the map:** BattleSim and the timeline (features/combat/logic) drive `features/neon/battle/`; the
  command menu and timeline bar are the reused 2D pieces of the old battle HUD.

## 4. Layers (dependencies point one way)
```
tools/ (outside the game)          content/*.json (data)
core/  autoloads, Def base, save   <- every feature may use core
features/<f>/defs/    read-only definitions built from content
features/<f>/logic/   pure rules: RefCounted, no nodes (enforced)
features/<f>/view/    nodes and scenes that show logic results and collect input
levels/<area>/        scenes built from level data + hand-placed dressing
```
- Logic never touches nodes, the scene tree, autoloads, input or `await` (enforced in `logic/` folders).
- View never computes rules: it asks logic and plays the events logic returns.
- A feature never reaches into another feature's view. Cross-feature talk goes through EventBus or GameState.

## 5. Folders (by feature, so one task reads one folder)
```
project.godot  .godot-version  CLAUDE.md  HANDOFF.md  README.md
core/           event_bus.gd game_state.gd content_db.gd defs/ tests/   (later: scene_router, save_service,
                audio_director, settings, asset_manifest)
features/       combat/ exploration/ dialogue/ inventory/ puzzles/ party/ ui/ world/
  <feature>/    defs/ logic/ view/ tests/ (only the folders it needs)
content/        <feature>/*.json   {"kind": ..., "items": [...]}
levels/         <area>/layout.txt area.json area.tscn (generated) dressing.tscn (hand-made)   (M2)
assets/         sprites/ textures/ models/ audio/ fonts/ + manifest.json   (binary; Claude doesn't read them)
localization/   strings.csv (key, en[, ar])   (M4)
tests/          runner.gd base_test.gd
tools/          check.sh run_godot.sh godot.sh lint_gd.py map.py doc_check.py (later: art/, build_level)
docs/           ARCHITECTURE BRIEFING WORKFLOW DECISIONS LESSONS MAP USAGE design/ research/
```

## 6. Data: definitions, state, saves
- **Content** is JSON under `content/`. Each file: `{"kind": "action", "items": [{...}]}`. Ids are
  lowercase_identifiers. Player-facing text is a localization key (`name_key`), never the text itself.
- **ContentDB** (autoload) reads every file once into typed **Def** objects (ActionDef, CombatantDef, StatusDef...),
  reports every problem at once (missing field, range, bad id, dangling reference) and is read-only afterwards.
  A test loads all shipped content and a broken fixture, so bad data fails CI before anyone plays.
- **Runtime state** lives in separate objects (UnitState in battle; later PartyState, InventoryState). Never mutate a
  definition: two enemies of one kind share one CombatantDef but each has its own UnitState.
- **GameState** (autoload) is the save file: plain data with `to_dict()/from_dict()`, a `SAVE_VERSION`, a migration
  for each version bump, slots in `user://saves/`. Settings in `user://settings.cfg`.
- Why JSON and not Godot `.tres` for content: one format, short diffs Claude can edit by the line, validation in
  tests, editable by the owner in any text editor. Scenes (`.tscn`) stay Godot's own format.

## 7. Communication
- **EventBus** (autoload): a few coarse cross-feature signals (area entered, battle started/ended, item gained,
  lore read, dialogue, music mood). It holds no state and no logic.
- Inside a feature: direct calls downward and signals upward; battle events come back from logic as data.
- Child references: `@export var x: Node` set in the scene, or `%UniqueName`. Never `$Path`, `get_node`,
  `get_parent`, `find_child` or `/root/` paths (enforced).

## 8. Combat (Grandia-style timeline; design source: docs/research/gemini-blueprint.md, Module 3)
Status 2026-10-28: this is the turn-based code still on main. Combat is real-time like Hades (CANON 10-27, VISION
pillar 1); the M1 brief (HANDOFF queue) replaces this section. Kept from it: integer fixed ticks, pure logic, events.
- **Timeline** (pure, built): positions are integers 0..10000; COMMAND at 7000, ACT at 10000; 60 fixed ticks a
  second; units move in list order; every change returns a `TimelineEvent`. A unit reaching COMMAND freezes time
  until `choose()` (player menu or AI). Cancel hits during a cast interrupt (back to 2500); other hits knock back,
  never below COMMAND while casting. Same inputs give the same events (tested), so battles can be replayed.
- **Formation** (pure, built): two rows per side; slot n+2 is covered by a living slot n; melee row multipliers.
- Next (M3): `BattleSim` (damage, statuses, deaths, victory) in logic/, seeded RNG per battle; AI policies as pure
  classes; `BattleController` (view) runs ticks, plays each event's animation and waits for it ("wait mode");
  HUD reads state. A **balance harness** runs 1,000 seeded battles headless and prints one table (win rate,
  length, interrupts), so tuning costs a few lines of output.

## 9. Exploration, encounters, puzzles (M2, M4, M5)
Status 2026-10-28: the 3D player and Area3D lines are retired (D20); the 2D roof is features/neon (section 3).
- Player: CharacterBody3D + CharacterVisual; 8-way movement, sprite faces 4 ways (left = mirrored right).
- Interaction: Area3D zones emit to a small interaction component; lore stones, wheels, doors are scenes with ids.
- Encounters are visible enemies; touching one from behind gives the ambush timeline bonus (blueprint Module 7).
- Battles run in an arena built beside the area (v0.3): the Router (autoload, core/scene_router.gd) hides and
  disables the area through its AreaPort (the area stays in the tree), BattleSession launches a BattleRunner
  (arena + BattleStage) and turns the result into GameState changes (victory pays once; defeat and Retry restore
  the pre-battle snapshot). The Router also owns new game, save slot I/O, load, unstuck and the play-time clock.
- Puzzles (sluice wheels, twin weir) are small pure state machines in logic/ with tests for every solution.
- Hydration, resin drops (pity ramp) and trust bonds are counters in GameState with rules in logic/.

## 10. Levels as data (M2/M7)
- `levels/<area>/layout.txt` (an ASCII height/tile map, about 20 lines) + `area.json` (spawns, exits, camera
  limits, lights, encounters) -> `tools/build_level` (headless Godot) -> `area.tscn` (generated, never hand-edited).
- Hand-placed props go in `dressing.tscn`, which the builder never touches. The owner can paint blocks in the
  editor's GridMap tool too; the builder then keeps his cells (decided when M2 starts).
- Why: Claude edits a 20-line text map instead of a 5,000-line scene file.
- Retired with the 3D world (D20; tag 3d-archive): `content/world/areas.json` (kind "area": rows of tile characters, legend char -> tile id, markers S spawn,
  W workshop, P/Q patrol ends, encounter id) + `tiles.json` (height, palette letter or hex, solid, glow, cap); `features/world/view/area_builder.gd` builds it at runtime (MultiMesh per tile type + box colliders), no generated scene. Look: `content/world/look.json`.

## 11. Dialogue, text and languages (M4)
- Dialogue as plain-text scripts (recommended: the Dialogue Manager plugin, MIT; decided in M4 after a test).
- All player text through `tr()` keys in `localization/<feature>.csv` (header `keys,en`), loaded at startup by
  the TextDB autoload (the CSVs use the "keep" importer: Godot's CSV import fails on a fresh clone). English first.
- No Arabic script in the game (DECISIONS 2026-10-22): world signs and the second heading line (`*_MUSNAD` keys) are Musnad only,
  in Noto Sans Old South Arabian (`font_musnad`, `MusnadLabel`; U+10A60-10A7F, right to left); `tools/musnad.py` transliterates; a test enforces it.

## 12. Audio (M8)
- AudioDirector autoload; buses Music, Ambience, SFX, UI.
- Music moods with Godot's built-in AudioStreamInteractive (switch on the beat) and AudioStreamSynchronized
  (layers), instead of hand-written crossfades. Separately generated AI tracks don't line up as layers: layers
  must come from one track split into stems (Demucs, free) or be switched, not stacked.

### Music contexts
Menus and places each have their own track identity (`docs/design/music.md`). `content/audio/screen_music.json` maps
screen ids to music ids. A pure stack (`MusicStack` in `features/audio/logic/`) resolves the active track: top screen wins,
unmapped screens keep what is playing, and an empty stack returns to the base exploration or combat track. `MusicDeck`
crossfades, remembers playback positions to resume base tracks after closing menus, starts battle tracks from the top,
runs with `process_mode = PROCESS_MODE_ALWAYS` across pauses, and resolves missing audio files through fallback chains.

## 13. Art pipeline at $0 (M1 spike, M6 production)
- Raw generations (Gemini, Flow) stay in the owner's Google Drive, not in git.
- `tools/art/` (Python): downscale to the target size, lock to the palette, key out the background, trim, pack
  sprite sheets, split a Flow video into frames for animation reference. Output goes to `assets/`.
- 3D characters (spec: docs/archive/design-3d/characters-3d.md): stand-in bodies and moves are CC0 (Quaternius Universal Base
  Characters and Universal Animation Library; KayKit as fallback). Feras unpacked them at the top of `inbox/`
  (git-ignored). Godot retargets them at import (BoneMap, humanoid profile): no Blender for the stand-ins, and no
  Mixamo (the repo is public). Later: Feras's Flow A-pose picture -> Hyper3D Rodin (image to 3D and UE-template rig,
  archive/design-3d/characters-3d.md 8) -> Blender cleanup only if needed (Claude, after the owner's OK to install). The ModelDef points at the new scene.
- `assets/manifest.json`: id, path, source (gemini, flow, kenney-cc0, quaternius-cc0, own), licence, prompt reference. Code asks
  for assets by id and gets a placeholder if missing; a check fails on any asset without a licence entry; the
  credits screen is generated from it.

## 14. Code rules (enforced by Godot and tools/lint_gd.py)
- Typed everything; <= 200 lines a file; <= 40 lines a function; a `## purpose` line in the first 6 lines.
- logic/ is pure; no node lookups by path; no gameplay numbers in code (content JSON; named constants for engine
  values); every rule and every fixed bug gets a test; Godot 4 syntax only.
- `tools/check.sh` = docs + lint + import + tests. Godot errors fail the run even when Godot exits 0.

## 15. Checks, CI, builds, branches
- `tools/check.sh` before every push; GitHub Actions runs it on every push (`.github/workflows/check.yml`).
- Planned: screenshot checks at 640x360 with software rendering for visual regressions (M1, if it works in the
  container); a Windows export built by CI on `main` so the owner downloads and plays without the editor (M2).
- Git: work on the session branch; `main` is the shared branch (merging into it needs the owner's standing OK);
  tag playable builds (`v0.1-look`, `v0.5-combat`, `v1.0-slice`).

## 16. What we kept and changed from the Gemini blueprint
| Blueprint | Here | Why |
|---|---|---|
| Godot 4, headless tests, typed GDScript, small files | Kept | Text-checkable, AI-friendly |
| EventBus with ~20 signals incl. every combat tick | Small bus + feature-local events | A god-bus couples everything |
| CombatantData Resource holds stats and HP | Def (read-only) + UnitState | Shared .tres would give all enemies of a kind one HP bar |
| Timeline in `_process(delta)` floats | Integer fixed ticks | Frame-rate independent, replayable, testable |
| 2D Parallax2D, PointLight2D, normal maps | 3D diorama + billboard sprites | Owner chose true HD-2D |
| JSON schema files + .tres data | One format: JSON read into Defs | One validator, small diffs |
| Hand-written stem crossfades | Godot interactive audio streams | Built in since 4.3 |
| WSL2 mandatory; token statistics | Not needed; ignored | Cloud sessions are Linux; the numbers have no source |
| One file per commit; 120-line cap | One change per commit; 200 lines | Fewer tool calls and CI runs; less fragmentation |
| Never open the GUI | Owner playtests every milestone | Someone has to see it |
| PR per feature via gh | Session branch, then main | Solo project; no gh in cloud sessions |
| World, cast, timeline, rows, pacing ledger | Kept as design input | Owner reviews before it becomes a spec |
