# Architecture Audit: 2026-10-22

## Verdict
The codebase exhibits disciplined low-level craft—small typed files, pure deterministic sim logic, and clean lint passes—but the system boundary model currently inverts the "many short buildings on a large surface" vision. Core autoloads heavily depend downward on feature internals (combat, items, audio, ui), while features cross-import foreign view nodes directly (art requires combat VFX; combat arena requires world diorama dressing). True system swappability is blocked because BattleSession lacks a polymorphic battle port, and several content Def classes are treated as mutable runtime state. Resolving these couplings through proper boundary ports, relocating shared visual primitives, and cleaning doc drift will establish genuine architectural modularity.

## Findings (Ranked by Risk to Future Change)

### 1. Inverted Core Dependencies on Feature Internals (Risk: Critical, Size: M)
- **Evidence**: `core/scene_router.gd:7-10`, `134` import `BattleOutcome`, `BattleStage`, `BattleRequest` (`features/combat`). `core/battle_session.gd:9-16`, `79` instantiate `BattleRunner` and call `RewardApplier.victory` (`features/items`). `core/audio_director.gd:7`, `81-88` directly imports `MusicDeck`, `SoundLogic` (`features/audio`) and `ActionDef` (`features/combat`). `core/game_state.gd:48`, `88-99` loads `EconomyRulesDef` and instantiates `Holdings`, `Bag` (`features/items`). Autoload `Screens` in `project.godot:20` points directly to `res://features/ui/view/ui_stack.gd`.
- **Why it matters for reuse/swapping**: Violates ARCHITECTURE.md §4 ("every feature may use core; dependencies point one way"). Core is not an independent platform; swapping battle systems, bag mechanics, or audio backends breaks core compilation and flow routing.
- **Fix**: Introduce a generic `BattlePort` in `core/` (analogous to `AreaPort`) so `Router` and `BattleSession` interact with an abstract interface. Decouple `AudioDirector` from `ActionDef` (pass string sound/vfx ids). Relocate `Screens` autoload or base stack into `core/`, and move `Holdings` bridging to `features/items/item_service.gd`.

### 2. Cross-Feature View Entanglement: Art FX & Arena Dressing (Risk: Critical, Size: M)
- **Evidence**: `features/art/view/character_fx.gd:12-26` instantiates `VfxSprite`, `VfxLayer` and calls `VfxTextures.texture(&"glow")` from `features/combat/view/`. `features/combat/view/arena_dressing.gd:8-15` and `arena_builder.gd:15` directly invoke `PropBuilder`, `AreaLights`, `SkylineBuilder`, `Diorama` from `features/world/view/`. `features/combat/defs/arena_def.gd:58` (`as_area()`) constructs a `features/world/defs/area_def.gd` object.
- **Why it matters for reuse/swapping**: Fails the feature swap test. Replacing timeline battles with another genre breaks general character exploration shadows and dust puffs because `CharacterFx` depends on combat view code. Replacing 3D rooftop exploration with another genre breaks combat arena generation because arena dressing is hardwired to rooftop builders.
- **Fix**: Relocate `VfxSprite`, `VfxLayer`, and `VfxTextures` to `features/art/view/` or `core/` (particle/quad billboard rendering is a general visual primitive, not a combat mechanic). Inject arena scenery through scene composition or environmental delegates rather than having combat call world builders.

### 3. Direct Cross-Feature View Node Couplings (Risk: High, Size: M)
- **Evidence**: `features/combat/view/battle_ending.gd:14-34` and `battle_end_panel.gd:34-115` call `Screens.open(Screens.DEFEAT_ID)`, `UiScreen`, `UiLayers`, `Ui.transition_sweep()`, `UiRarity`. `features/dialogue/view/dialogue_box.gd:23-118` calls `UiLayers`, `UiType`, `Ui.style()`. `features/world/interact/sabil_spot.gd:24-41` calls `Screens.open(Screens.SABIL_ID)`, `SabilScreen.DRINK`, `Ui.toast()`. `features/world/interact/pill_spot.gd:6-21` calls `Ui.interaction_prompt()`. `features/ui/view/screens/equipment_host.gd:6-26` instantiates `EquipmentScreen`.
- **Why it matters for reuse/swapping**: Violates ARCHITECTURE.md §4 ("A feature never reaches into another feature's view. Cross-feature talk goes through EventBus or GameState"). UI components cannot be independently replaced or tested headlessly because gameplay views directly instantiate and manipulate UI controls.
- **Fix**: Route screen openings and toasts via `EventBus` signals or router state events. Move design system layout constants and styling tokens (`UiLayers`, `UiRarity`) into a shared `core/ui/` library.

### 4. Mutable Definition Antipattern via `CombatantDef.clone()` (Risk: High, Size: S)
- **Evidence**: `features/combat/defs/combatant_def.gd:49` exposes `func clone() -> CombatantDef`. `features/items/logic/gear.gd:9-15`, `features/items/logic/perks.gd:7-8`, `features/jambiyah/logic/jambiyah.gd:10-20`, and `features/prosthetics/logic/prosthetics.gd:8-22` clone `CombatantDef` and mutate stats (`agility`, `cast_speed`, `actions`).
- **Why it matters for reuse/swapping**: Violates ARCHITECTURE.md §6 ("ContentDB reads every file once into typed Def objects... Never mutate a definition"). Cloned Defs masquerade as runtime state objects, blurring the architectural boundary between authored content and dynamic player attributes.
- **Fix**: Replace Def cloning with an explicit runtime `CombatantBuild` or `CombatantStats` RefCounted class in `features/combat/logic/` that holds resolved runtime numbers without mutating definitions.

### 5. Hardcoded Pacing and Flow Constants in GDScript (Risk: High, Size: S)
- **Evidence**: `features/combat/logic/timeline.gd:7-11` hardcodes `TICKS_PER_SECOND = 60`, `COMMAND_POINT = 7000`, `ACT_POINT = 10000`, `INTERRUPT_POS = 2500`, `AFTER_ACT_POS = 2000`. `core/battle_session.gd:12` hardcodes `const SAVE_SLOT: int = 1`.
- **Why it matters for reuse/swapping**: Violates ARCHITECTURE.md §14 ("no gameplay numbers in code (content JSON; named constants for engine values)"). Timeline pacing and interrupt penalties cannot be balanced via `content/combat/rules.json` without modifying GDScript and invalidating tests.
- **Fix**: Move timeline action positions and interrupt reset targets into `content/combat/rules.json` (`BattleRulesDef`). Pass save slot dynamically from router flow requests.

### 6. Gameplay Logic Embedded Inside Content Def Classes (Risk: Medium, Size: S)
- **Evidence**: `features/combat/defs/action_def.gd:54-59` implements targeting queries `is_hostile()` and `needs_picker()`. `features/items/defs/consumable_def.gd:65-69` implements context rules `usable_in_battle()` and `usable_in_field()`. `features/items/defs/equip_def.gd:31` validates `perk_problem()`.
- **Why it matters for reuse/swapping**: Def classes are meant to be pure data representations (`core/defs/def.gd`). Placing gameplay rules inside Defs scatters domain logic between `defs/` and `logic/`, impeding rule swapping and serialization portability.
- **Fix**: Move action targeting queries to `features/combat/logic/battle_targets.gd`, consumable usage context queries to `features/items/logic/field_use.gd`, and perk validation to `features/items/logic/perks.gd`.

### 7. Missing Test Coverage for Content Kinds and Pure Logic (Risk: Medium, Size: S)
- **Evidence**: Content kind `flow_rules` (`content/prototype/flow.json`) has no test in `tests/test_*.gd`. Pure logic files `features/art/logic/model_gait.gd`, `features/jambiyah/logic/workshop_stats.gd`, `stat_row.gd`, `features/world/logic/facade_details.gd`, and `masonry.gd` have zero direct test coverage.
- **Why it matters for reuse/swapping**: Violates GEMINI.md ("Every rule and every fixed bug gets a test"). Untested logic in model gait selection or workshop comparison math allows regressions to pass CI undetected.
- **Fix**: Add `core/tests/test_flow_rules.gd` and unit tests in `features/art/tests/test_model_logic.gd` and `features/jambiyah/tests/test_jambiyah.gd`.

### 8. Documentation Drift in Folder Structure and Audio Engine (Risk: Medium, Size: S)
- **Evidence**: `docs/ARCHITECTURE.md:66` specifies folders `exploration/`, `inventory/`, `puzzles/`, `party/`, which do not exist (implemented as `art`, `audio`, `equipment`, `items`, `jambiyah`, `prosthetics`, `prototype`, `world`). `docs/ARCHITECTURE.md:137` mandates `AudioStreamInteractive` and `AudioStreamSynchronized`, but `features/audio/view/music_deck.gd:15-42` implements manual twin-player Tween crossfades.
- **Why it matters for reuse/swapping**: Misleads contributors and agents regarding component boundaries and obscures that manual audio crossfades bypass Godot's interactive music graph.
- **Fix**: Reconcile the folder map in `ARCHITECTURE.md` §5; update §12 to document the twin-player tween implementation.

### 9. DECISIONS.md Discrepancies in Content, Text, and Saves (Risk: Medium, Size: S)
- **Evidence**: `docs/DECISIONS.md:58` mandates `Jambiyah` replacing `djanbeyyah` ("saves migrate the old key"), yet `core/save/save_codec.gd:31-62` contains no migration for legacy `djanbeyyah` keys. `docs/DECISIONS.md:64` specifies `grandfather_hilt` grants counter stance instead of `elder_cut`, but `content/jambiyah/hilts.json:5` still assigns `elder_cut`. `docs/design/ui.md:42-142` and `v03-text.md:98-100` retain Arabic text despite `DECISIONS.md:60` prohibiting Arabic script in the game.
- **Why it matters for reuse/swapping**: Legacy saves risk dropping grandfather gear; design docs contradict the single source of truth.
- **Fix**: Add key migration in `SaveCodec.sanitize()`; update `content/jambiyah/hilts.json` to assign counter stance; strip Arabic text from design docs.

### 10. Incomplete Linter Guardrails in `tools/lint_gd.py` (Risk: Low, Size: S)
- **Evidence**: `tools/lint_gd.py:13` checks `IMPURE` only for `EventBus|GameState|ContentDB`, omitting `Router`, `AudioDirector`, `TextDB`, and `Screens`. `features/combat/logic/item_action.gd:2` extends `ActionDef` (a `Def` subclass) rather than `RefCounted`. (Linter ran clean: `lint: 389 GDScript files ok`).
- **Why it matters for reuse/swapping**: Permissive linter rules allow future impure calls or node dependencies to slip into `logic/` undetected.
- **Fix**: Add all autoload names to `tools/lint_gd.py` and enforce that files in `logic/` extend only `RefCounted`.

## Top 5 Fixes in Priority Order
1. **Decouple Core from Combat & UI**: Introduce a `BattlePort` in `core/` for `BattleSession` and move the `Screens` autoload into `core/` so core has zero feature dependencies. (Size: M)
2. **Untangle Character FX from Combat**: Move `VfxSprite`, `VfxLayer`, and `VfxTextures` from `features/combat/view/` to `features/art/view/` or `core/` to restore character visual autonomy. (Size: S)
3. **Decouple Combat Arena from World Diorama**: Remove direct calls to `PropBuilder`, `AreaLights`, and `SkylineBuilder` from `arena_dressing.gd`, injecting arena scenery via delegates. (Size: M)
4. **Replace Mutable `CombatantDef.clone()`**: Implement a pure `CombatantBuild` RefCounted class in `features/combat/logic/` so authored content definitions remain immutable. (Size: S)
5. **Reconcile DECISIONS.md Discrepancies**: Implement the promised `djanbeyyah` -> `jambiyah` migration in `SaveCodec` and update `grandfather_hilt` to grant counter stance in `hilts.json`. (Size: S)
