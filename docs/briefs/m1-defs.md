# Brief: m1-defs (cf DeepSeek high; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-defs (made from origin/m1-defs-base, the locked tests; pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: features/neon/roof/defs/neon_roof_rules_def.gd, core/tests/test_def_reader.gd, content/neon/roof_rules.json
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: real-time Hades + Sekiro fight, every number tunable. This part is the data layer all m1 parts read. Pillar served
(docs/VISION.md): 1 Hades-feel combat (numbers in content so tuning costs no code).

## Read first
The locked tests (read-only). docs/design/m1-fight.md sections 2, 3, 5 (the numbers) and docs/design/m1-fight-api.md (the data
types). core/defs/def_reader.gd (DefReader methods), the pattern files, core/content_db.gd (the kind table near line 55).

## What to build
1. Data classes in features/fight/logic/ (RefCounted, typed, exactly the fields of m1-fight-api.md): FightInput, FightUnit,
   FightEvent, Hitbox, FightWorld (with emit), FightSetup. Defaults are the neutral value (0, false, empty).
2. Defs in features/fight/defs/, each `extends Def`, read with DefReader, ranges validated, a purpose line first:
   FightRulesDef (kind fight_rules), FightHeroDef (fight_hero: hp, posture, speed, three combo steps, dash, parry),
   FightGuardDef (fight_guard: baton and rifle, attacks list with kind melee or line), FightTouchDef (fight_touch: stick radius,
   deadzone, buttons with id, size px, anchor %, offset). One field per number in sections 2, 3 and 5 of the spec.
3. Content files content/fight/rules.json, hero.json, enemies.json, touch.json holding the spec's [PLACEHOLDER] values; register
   the four kinds in core/content_db.gd (smallest edit: four lines).
4. Rooms: each guard entry of content/neon/rooms.json gets `kind` (baton or rifle) and `facing` (0..7); the first guard is
   baton, the second rifle. NeonRoomDef reads both (guards stay Array[Dictionary] with `id`, `path`, `kind`, `facing`).
5. Player text rows in localization/neon.csv: FIGHT_RETRY, FIGHT_DEFEAT, FIGHT_VICTORY, FIGHT_BROKEN (keys only; English).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/neon/battle/`
`features/combat/`

## May edit
`core/content_db.gd`
`features/neon/defs/neon_room_def.gd`
`content/neon/rooms.json`
`localization/neon.csv`

## Ripple
rooms.json guards gain two fields: test_neon_foundation and test_roof_scene read rooms.json (they ignore extra keys; the build
runs them). content_db.gd gets four kinds: test_content_db loads all shipped content, so a bad file fails it. neon.csv gains four
keys: test_text_db checks key shape. Nothing else reads the new files yet.

## Pre-mortem
Player: a wrong content number ships silently -> every field has a range and a test that loads the shipped JSON through
JSON.parse_string. Gate: a def reads ints as floats (JSON) -> DefReader.integer only, a test feeds real JSON text. Review: a
number hides in code -> the lint test greps features/fight for float/int literals above 1 outside defs.

## Tests
- features/fight/tests/test_fight_defs.gd :: each def reads its shipped JSON with zero errors; each bad field (negative hp,
  perfect window longer than window, empty combo, unknown guard kind) reports the field name.
- features/fight/tests/test_fight_types.gd :: FightWorld.emit appends an event with the current tick; FightUnit defaults.
- features/neon/tests/test_neon_foundation.gd stays green (rooms guards carry kind and facing).
- player-visible: touch buttons in touch.json are >= 96 px at the 1920x1080 viewport and inside it (acceptance U3).

## Checklist
- file: features/fight/logic/fight_world.gd
- has: features/fight/logic/fight_world.gd :: func emit
- file: features/fight/defs/fight_hero_def.gd
- test: features/fight/tests/test_fight_defs.gd :: test_shipped_content_reads_clean
- key: localization/neon.csv :: FIGHT_RETRY

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
