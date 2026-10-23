# Plan: prototype v0.3 "Painted Rooftops" (approved by Feras 2026-10-21; the build follows this file)

## Context
Feras played v0.2 and sent 12 notes:
- The world mixes 3D blocks with pixel textures, so it looks incoherent.
- Characters float as single pictures with no walk.
- The camera is too close.
- He wants the look of Hades II and Octopath as references, with our own twist.
- Battles must warp to a dedicated arena, because the rooftop covered the fighters.
- Add a shop, currency, an inventory with feathered herbs (HP/SP), a reset and an iconic save spot.
- Aim for top-tier graphics and motion on a micro scale (the rooftops only).
- Use the installed agents at fitting models and efforts, and audit before building.
- Build on a foundation that survives future change.

Audited with 3 Explore agents (world/camera, systems, tools), the game-designer and technical-artist lenses, and an
Opus red-team of this draft. All of their fixes are folded in.

**Owner answers (2026-10-21; to log in DECISIONS):**
1. Look: **painted diorama.**
   - From Hades: painted surfaces, ink outlines, painted light, pools of lamp and neon light in the dark.
   - From Octopath: tilt-shift depth and side-view battles.
   - Our twist: qamariya stained-glass colour and white gypsum ornament in the light, the effects and the UI.
   - The 3D diorama world stays. This supersedes the pixel-art billboard characters and the 32 px = 1 m pixel rule.
2. Characters: ~~painted puppets~~ superseded 2026-10-21: **live 3D models** (2.5D, Hades-like), painted shader +
   ink outline; CC0 stand-ins now, Feras's own models later (spec: docs/design/characters-3d.md).
3. Save spot: **the sabil fountain.** Drinking saves and fully refills, and the Concession re-sends its patrols.
4. **HP/SP carry over between fights.** This supersedes slice.md's "refill after each". Losing offers "retry the fight".

**Claude defaults (owner may veto):**
- The currency is the riyal (renaming it is one CSV line).
- In battle, the party stands on the right and enemies on the left.
- Feras picks the camera angle from spike renders.
- His norm, to log: big asks start in plan mode (Opus xhigh), audit with agents, then orchestrate; every installed
  agent runs at a fitting model and effort.

## Audit: what is wrong today (code facts)
**Look**
- Every surface is a code-painted pixel texture (palette letters, NEAREST, 32 px/m) on a 3D block.
- Scales are mixed: the bench is 16 px/m, the far city 4 px/m, and the props are smooth and untextured.
- One texel covers about 6.7 screen px, there is no anti-aliasing, and sprites use their own lighting.

**Characters**
- Each is a single frame on a Y-billboard. The bob lifts the sprite off the floor, which reads as floating.
- Facing changes only on horizontal input.
- Bilqis follows a path by lerp with no physics, so she clips through props.

**Camera**
- Offset (0, 4.9, 8.5): about 9.4 m at 25.8 deg, FOV 30. Zayd fills about 40% of the screen height.
- There is no occlusion handling.
- test_explore_camera.gd:25 hard-codes the pitch.

**"Stuck"** (inferred; confirm with `rooftop_shot.tscn -- 22.5 8`)
- East of the bridge (row 5, x 16-19, a 1 m slot between invisible walls), the camera sits inside house_a
  (x 21-25, z 12-15, 12 m tall), so Zayd disappears.
- There is no pause, quit or save, so Alt+F4 was the only way out.
- A respawned patrol can re-touch Zayd at (6.5, 9.5).
- No test covers reachability or occlusion.

**Battle in place**
- BattleStage reuses the Rooftop's environment, tiles, skyline and mist (rooftop.gd:108-117), and props hide the
  fighters.
- The swoop starts from `get_viewport().get_camera_3d()` (battle_stage.gd:153). The anchor is a rooftop position.

**State**
- Nothing is ever written to disk.
- GameState v3 has no money, stackable items, HP/SP or position.
- Bug: Chest.is_open (chest.gd:13) ignores its flag, so a loaded game shows opened chests as closed.

**Flow and UI**
- PrototypeMain (164 lines) holds all game flow and loot rules, and a test calls its private `_grant`.
- There is no UI stack or pause, and layer numbers are scattered (10/20/25/30).
- Esc is already "back", and there is no "menu" action.

**Combat**
- UnitState always starts at full HP/SP, and hero ids are hard-coded (battle_loader:55, battle_sim:62,
  battle_stage:143).
- BattleSim.create takes 9 parameters.
- A heal is the actor's attack times a factor, with no flat heal and no SP restore.
- The command menu lists only `def.actions`.

**Items**
- `get_def("item")` covers equippables only, and EquipmentData casts every item to EquipDef, so consumables need
  their own kind.
- `item_gained` is never emitted.

**Pause hazards**
- `battle_event_player.gd:174` uses `create_timer`, and timers keep running while the game is paused.
- The hitstop (battle_juice.gd:22) ignores pause.

**Size cap and numbers in code**
- Files at the 200-line cap: character_visual 199, audio_director 195, def_reader 194, rooftop 193,
  equipment_screen 190, battle_command_menu 182.
- Numbers in code: unit_state:53, formation:6-7, rooftop:155-170, loot_popup:87-89, battle_end_panel:96,
  battle_command_menu:46.

## What v0.3 plays like (acceptance)
1. Title, then the opening pan, then painted night rooftops from a pulled-back camera. Zayd is about 12-15% of the
   screen height, and occluders dither away.
2. Zayd and Bilqis walk and run with planted feet, swinging limbs, a lagging coat and scarf, and a paper-turn flip.
3. Workshop talk in the Hades II style: a big portrait slides in, with a nameplate and an epithet.
4. The herb stall: buy and sell with riyal.
5. The sabil: "Drink" saves the game, refills HP/SP and brings the patrols back.
6. Touching a patrol plays the qamariya-glass shatter and opens a painted side-view arena: party right, enemies left,
   Grandia timeline on top, an Items command.
7. Victory pays riyal and loot, and HP/SP carry back to the rooftops.
8. Defeat offers Retry fight, Load or Title.
9. The pause menu works at any time: Resume, Items, Equipment, Load last save, Unstuck, Title, Quit.
10. Two or three patrols, two chests, one stall, one sabil, one workshop, one vista.
11. 60 FPS or more on the Latitude; target 90 or more in fps_probe with all characters live.

## Phase 0: lead (this chat, Opus xhigh)
**Sync and docs**
- Merge origin/main by fast-forward (it holds only merges of this branch).
- Log the answers, the defaults and the process norm in docs/DECISIONS.md and in memory.
- Align CLAUDE.md's "No subagents to explore" line with the new norm.
- Rewrite ARCHITECTURE sections 3 (the painted render model), 6 (saves) and 9 (the battle scene), and the art bible
  (painted v2).

**Design agents, run in parallel (they write docs only)**

| Agent | Model, effort | Writes |
|---|---|---|
| Game Designer | Sonnet, high | docs/design/economy.md: items, prices, sources and sinks, the item-in-battle rules, KO after victory (proposal: back at 1 HP), defeat/retry, patrol respawn, numbers marked [PLACEHOLDER] |
| UI Designer | Sonnet, medium | ui.md v2: night-glass panels framed in gypsum tracery, a qamariya colour sweep on focus, Musnad + English titles; text wireframes for pause, items, shop, sabil, defeat, dialogue, battle HUD and prompts; the style.json keys to add |
| Level Designer | Sonnet, medium | rooftop v3 layout: the stuck fix (a wider bridge, houses clear of camera paths), places for the stall, sabil, 3 patrols, chests and the NPC, sightlines for the new camera |
| Narrative Designer | Haiku, low | herb seller and sabil lines, item descriptions, nameplate epithets, as CSV rows |
| Image Prompt Engineer | Haiku, low | Flow prompt for the herb seller's full-body picture; Gemini prompts for parts sheets and herb icons (all optional for Feras) |

**Look spike** (Technical Artist, Opus, high, in a worktree), on one rooftop corner and one painted figure (a scale stand-in):
- painted_light.gdshaderinc: banded light, indigo shadow tint, rim, a min_light floor.
- The offline painterly bake (see Look below).
- The ink outline pass.
- AgX, a LUT, the vignette and canvas grain.
- SMAA, and compare MSAA 2x.
- 3 camera presets, each with its own depth of field.
- Output: 3 renders and fps_probe numbers. Then **checkpoint 1: Feras picks a look and camera** (2-4 options).
- The spike's light include and outline merge before Phase 2, because B3 and B4 both need them.

**Contract stubs** (signatures and purpose lines only), committed on the session branch.

## Phase 1: foundation (Godot Gameplay Scripter, Sonnet, high, one worktree; the lead reviews and merges it)
1. **Router** (core/scene_router.gd, an autoload after ContentDB).
   - It owns the flow: title, then area, then battle, then back to the area.
   - Battle start:
     - Capture the frame for the shatter.
     - Then hide the Rooftop and set it to PROCESS_MODE_DISABLED, so physics bodies leave the simulation and the
       patrol stops. It is not removed from the tree, because awaits, signals and the camera depend on it.
     - Build the arena as a sibling at a far origin read from arenas.json.
     - The arena camera has its own Camera3D environment and attributes, so the rooftop's WorldEnvironment is
       overridden.
   - The BattleCamera starts from a def pose (`previous=null`).
   - On return: free the arena, show and enable the Rooftop, `reset_patrol`, `restore_camera`.
   - API: `start_battle(BattleRequest)`, the signal `battle_finished(BattleOutcome)`, `go_to_title()`,
     `new_game()`, `load_slot(n)`, `can_save()` (true only while exploring with an empty UI stack).
   - Transitions are data (content/ui/transitions.json).
   - PrototypeMain becomes a composition root. Rewards move to pure features/items/logic/rewards.gd, and the test
     stops calling `_grant`.
2. **GameState v4 and SaveService.**
   - New fields:
     - money
     - bag {consumable: count}
     - vitals {hero: {hp, sp}} (missing means full; hp 0 is allowed)
     - place {area, save_point}
     - play_seconds: grows by `delta / Engine.time_scale`, only while not paused
     - cleared_patrols: saved, emptied at the sabil, kept on Retry
     - party list
   - A pure codec in core/save/save_codec.gd:
     - one step function per version (`_v3_to_v4`), tested against a v3 fixture
     - unknown content ids are dropped with a warning
   - SaveService:
     - files: user://saves/slot_N.json
     - atomic write: tmp, then rename, keeping a .bak; a test checks the rename overwrites on Windows
     - a slot summary
     - errors on corrupt files
     - a path override for tests
   - Fix the chest flag on load.
3. **UiStack, UiScreen/UiPanel base, layers, input.**
   - The stack pushes and pops screens, pauses the tree, restores focus, and routes "back" to the top consumer, which
     marks it handled. Only an unhandled `menu` opens pause.
   - Tweens ignore time scale.
   - One UiLayers table replaces the scattered layer numbers.
   - New `menu` action: Esc, Tab, pad Start.
   - A **pause-safe wait helper** (`create_timer(t, false)`) replaces timers in the battle view.
   - Opening pause resets Engine.time_scale and cancels the hitstop freeze.
   - PauseMenu: Resume, Items, Equipment, Load last save (or Restart), Unstuck (the last safe cell), Title, Quit.
4. **Shared item rules**, pure and used by both field and battle:
   - ConsumableDef (kind "consumable"). Fields: name/desc keys, icon, effect hp/hp_pct/sp/revive, target, use_in,
     cast_speed, price, sell, max_stack.
   - Bag (available = count − reserved).
   - ItemEffect.apply.
   - Consumables stay out of ITEM_KINDS, and references are `["consumable", id]`.
   - Only consumables are sellable in v0.3; equipped gear can never be sold.
5. **Battle contract.**
   - BattleSetup replaces the 9 parameters. It carries: party list, start vitals, bag, equipment snapshot, seed,
     ambush, encounter_id, arena_id, arena anchor.
   - BattleRequest also carries the pre-battle snapshot for Retry: vitals, bag, money.
   - BattleOutcome carries: result, vitals, bag, money, items.
   - Hero ids come from the party list.
6. **Registries owned here.** This prevents merge breakage at content_db.gd:7.
   - Every new ContentDB kind, with a stub Def: consumable, shop, arena, transition, puppet (now model), clip, camera_preset, place.
   - Empty per-builder CSVs (shop, arena, pause, sabil) with "keep" .import files.
   - project.godot: the `menu` action, the Router autoload, the AA settings.
   - The new style.json keys from the UI spec.
7. **CharacterVisual split and contract.**
   - The split: facade, CharacterMotion (root moves only: lunge, dash, hurt push), PixelSource (legacy stand-in),
     PuppetSource (stub; now ModelSource).
   - API: `play(state, facing)`. States: idle, walk, run, attack, cast, hurt, ko, victory, item.
   - Anchors: feet, hand, head. Clip events (the impact frame) are what the battle player waits on.
   - The `_pulse` squash is off for puppets (now models).
8. Hard-coded numbers move into content.

## Phase 2: parallel builders (Sonnet, one worktree each)
Every brief starts with `git merge --ff-only claude/night-sanaa`, asks for WIP commits after each unit of work, and
asks for a report of at most 300 words.

| Builder | Agent, effort | Owns | Builds |
|---|---|---|---|
| B1 Items and shop | Gameplay Scripter, medium | features/items, ui screens items/shop | ShopDef + Shop buy/sell (no money, full stack), money in Rewards and the loot popup, Items screen (use on a hero), Shop screen, the stall interaction |
| B2 Battle arena | Gameplay Scripter, high | features/combat, **sole owner of battle_stage.gd** | arena_builder + arenas.json (painted roof floor, parapet and props, skyline backdrop cards + sky, "battle_night" look), side camera (low, about 12 deg, its own DoF), qamariya shatter in / light wash out, carried vitals, Items command in a new file, defeat flow, riyal on the end panel; 3D: `face_dir` yaw with a 3/4 camera bias, waits on clip_event (not VfxDef timers), `hit_stop` on impact, VFX/projectiles/labels from `anchor_position`, lunge spacing from model width, KO plays its clip; P1b leftover: create_timer -> PauseWait |
| B3 Painted world | Godot Shader Developer, high | features/world/view, look/sky/mist JSON, the occlusion dither shader | spike rules on tiles, facades, props, skyline, mist and signs; sabil and stall props (water VFX, qamariya lamp); the arena look; FPS before and after each pass |
| B4 3D characters | Technical Artist (Sonnet), high | features/art, tools/art, content/art, assets/characters | docs/design/characters-3d.md: ModelDef + models.json, pure clip_timing / locomotion / yaw_turn, ModelSource (retargeted Quaternius clips, BlendSpace1D, anchors, hit-stop), painted skin shader, weapon trail and smear, fx.trail/fx.sync fix for non-pixel sources, stand-ins for Zayd (with his grandfather's hilt as a belt attachment), Bilqis, enforcer, Abu Nabil and the drone; PixelSource stays as the fallback |
| B5 Level | Gameplay Scripter, medium | features/world/logic + interact, areas.json, **camera.json and camera limits** | walk graph + reachability and occlusion tests, stuck fix, typed `places`, sabil (save + refill + patrols return), stall, 3 patrols, Bilqis as a CharacterBody3D, dialogue camera framing; 3D: player, follower and patrol pass (x, z) velocity to `face_dir`, capsules from ModelDef, dialogue framing on the head anchor, the workshop bench as a mesh |
| B6 UI v2 | Gameplay Scripter, medium | features/ui, content/ui, dialogue | theme v2, Hades II-style dialogue, pause/items/shop/save/defeat styling, battle HUD files only (timeline on top, party cards with portraits bottom right), interaction prompts; `head_icon` and stand-in portraits use per-character PNG icons, not sprite crops |

**B4 3D characters:** the spec is docs/design/characters-3d.md (sources, import and retargeting, shading, motion polish, data, budgets, tests). The contract stubs are on the session branch: `CharacterVisual.face_dir(dir)`, `hit_stop(seconds)`, ModelSource, ModelDef (kind `model`), `visual_rules.default_source`.

**Helpers**
- Haiku helpers (medium): CSV rows, the manifest, MAP, docs.
- Game Audio Engineer (Haiku, low): sounds.json entries for coin, buy, sell, save, drink, menu and warp, all from
  Kenney files already in the manifest; footsteps on gait foot-down events; the music cut at the warp.

**Shared registries**
- Phase 1 created them. Builders only append, and merges keep both sides.

## Look rules (the spike sets the numbers; B3 and B4 apply them)
- **One light model:** painted_light.gdshaderinc, shared by the world, prop and character shaders.
- **Textures, baked offline:**
  - A headless Godot tool exports the painter atlases. Image work is CPU-only, so it runs headless.
  - `tools/art/painterly_bake.py` (a numpy Kuwahara plus brush grain) writes cached PNGs, which are committed with
    manifest entries.
  - At runtime the PNG loads, with linear filtering and mipmaps. If it is missing, the unbaked atlas is used.
  - A test fails when the cache hash does not match the painter inputs.
  - Python self-tests run in check.sh.
- **Ink outline:** a depth + normal Sobel on a full-screen quad.
  - `render_priority = -128`, so mist, VFX, labels and neon draw over it.
  - The threshold grows with linear depth, and the line fades with the fog curve (no halo against the sky).
  - Neon Label3Ds never use alpha-cut.
- **Anti-aliasing:** SMAA plus `alpha_antialiasing` on cut-outs. No TAA, because it ghosts billboards.
- **Grade:** AgX, a LUT, a Hades-like vignette and canvas grain. A half-res painterly screen filter is optional,
  behind a quality flag.
- **Camera:** pulled back and higher, with per-area presets in camera.json that each carry their own DoF.
  - Anything between the camera and the party dithers to a cut-away.
  - The camera never enters a building.

## Verification
**Checks**
- tools/check.sh (read the FAIL lines).
- `tools/run_godot.sh --import` after each merge.

**New tests**
- Codec v3 to v4, including unknown ids and hp 0.
- SaveService: round trip, corrupt file, the Windows overwrite rename.
- Bag reservation:
  - two heroes sharing one herb
  - the reserver KO'd before ACT
  - the target invalid at ACT: the item fizzles and is refunded
- ItemEffect.
- Shop edge cases.
- Rewards.
- Carried vitals; KO after victory.
- Retry restores the snapshot.
- cleared_patrols.
- Play time while paused.
- UiStack:
  - push, pop, focus
  - back vs menu
  - pause during a battle event and during a hitstop
- Router battle round trip: the Rooftop is restored, the patrol reset, the camera restored.
- Walk-graph reachability and camera occlusion on every shipped area.
- Gait no-slide.
- Model def, clip timing and budget validation (characters-3d.md section 7).
- The bake hash.

**Smoke play-through** (headless, via Router)
- New game, buy a herb, use it, fight with AI autoplay, apply the outcome, drink at the sabil, load, then assert the
  state is equal.

**Balance harness**
- Win rates stay in the 73-88% band with carried HP and items.

**Renders and FPS**
- Renders at 640x360 (shot_scene, shot_battle, rooftop_shot): wide and close exploration, the stall, the sabil,
  mid-warp, arena battle, each menu. The lead views 1-2 frames per change.
- fps_probe (prototype + arena, every model live), before and after each pass.

**Review and push**
- Code Reviewer (Opus, high) reviews the integrated diff. Builders fix their own parts (resumed via SendMessage).
- Merge order: foundation, B1, B2, B5, B4, B3, B6.
- Push, merge to main (standing OK), check CI (`gh run list`), then /handoff.
- **Checkpoint 2: Feras plays v0.3.**

## Feras's part (none of it blocks the build)
- Checkpoint 1: pick a look and camera from 3 renders.
- Optional:
  - a Flow picture of the herb seller (stand-in until then)
  - later, a Gemini parts sheet per hero
  - herb icons in one Gemini picture
- Checkpoint 2: play v0.3, then send notes (FPS with F3, look, motion, menus, shop, fun).

## Risks and fallbacks
- **Hidden limbs** in front-3/4 pictures: darker duplicates for now; a Gemini parts sheet later.
- **The bake reads as noise:** flat painted tones + outlines + grade instead (the spike decides).
- **Iris Xe:** every pass sits behind a quality flag.
- **The 5-hour limit:** WIP commits; resume after the reset.
- **Lead context:** past about 150k tokens, /handoff mid-run.
- **Not used:** the Blender Add-on Engineer (no Blender installed, nothing to model).
