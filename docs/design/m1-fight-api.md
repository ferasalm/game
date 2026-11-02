# M1 fight: shared types and signatures (row 3, 2026-11-02; every m1 part builds against exactly this)
Rules: docs/design/m1-fight.md. Parts: docs/briefs/m1-plan.md. All in `features/fight/`; logic/ is pure (no nodes, input,
autoloads, await); ints only (milli-pixels of ground space, ticks of 1/60 s); no gameplay number in code.

## Data types (part m1-defs writes them, features/fight/logic/)
- `FightInput`: `move: Vector2i` (-1000..1000 per axis, the stick), `aim: Vector2i` (zero = none), `attack: bool`,
  `dash: bool`, `parry: bool` (pressed this tick), `parry_held: bool`.
- `FightUnit`: `id: StringName`, `kind: StringName` (&"hero", &"baton", &"rifle"), `pos: Vector2i`, `facing: int` (IsoDir row
  0..7), `hp`, `hp_max`, `posture`, `posture_max`, `state: StringName`, `tick: int` (ticks in the state), `step: int`
  (combo step or attack index), `frozen: int` (hit-stop ticks left; a frozen unit's machine does not step), `mercy: int`,
  `counter: int` (riposte ticks left), `aware: bool`, `dead: bool`, `path: Array[Vector2i]`, `path_index: int`,
  `no_contact: int` (ticks since a hit), `locked_dir: Vector2i` (rifle line), `note: Dictionary` (machine scratch).
- `FightEvent`: `tick: int`, `kind: StringName`, `unit: StringName`, `other: StringName`, `value: int`, `pos: Vector2i`,
  `detail: StringName`. Kinds: attack_started, hit, guarded, deflected, perfect, evaded, telegraph, shot, flinch, posture_broken,
  finisher, riposte, hurt, ko, dash, alert, won, lost. `detail` carries the move or step (&"step1", &"windup").
- `Hitbox`: `owner: StringName`, `kind: StringName` (&"arc" | &"line"), `origin: Vector2i`, `dir: Vector2i` (unit vector, 1000
  = 1), `reach: int`, `half_arc_deg: int` (arc) or `width: int` (line), `damage`, `posture`, `hitstop`, `knockback`, `step`,
  `first_active: bool`, `ranged: bool`.
- `FightWorld`: `rules: FightRulesDef`, `hero_def: FightHeroDef`, `guard_defs: Dictionary` (kind -> FightGuardDef), `units:
  Array[FightUnit]`, `hero: FightUnit`, `outline: PackedVector2Array`, `holes: Array[PackedVector2Array]` (plate px),
  `tick: int`, `events: Array[FightEvent]` (this tick; FightSim clears it), `rng: RandomNumberGenerator` (seeded), and
  `emit(kind, unit, other, value, pos, detail)`.
- `FightSetup`: `rules`, `hero_def`, `guard_defs`, `outline`, `holes`, `hero_spawn: Vector2` (plate px), `guards: Array[Dictionary]`
  (`id`, `kind`, `pos` plate px, `path` plate px, `facing`), `seed: int`.

## Pure classes (the part that builds each is named in docs/briefs/m1-plan.md)
- `Ground`: `to_ground(plate: Vector2) -> Vector2i`, `to_plate(ground: Vector2i) -> Vector2`, `step_walkable(world, from, delta) -> Vector2i`.
- `InputBuffer`: `push(kind, tick)`, `take(kind, tick, window) -> bool`, `clear()`.
- `AimAssist`: `pick(origin, dir, foes: Array[FightUnit], rules) -> FightUnit` (null if none) and `facing_toward(...) -> int`.
- `Posture`: `add(unit, amount) -> bool` (true = just broke), `regen(unit, def)`, `reset_after_finisher(unit, rules)`.
- `DefenceRules`: `resolve(world, hitbox, target: FightUnit) -> Dictionary` with `outcome` (&"hit", &"guard", &"deflect",
  &"perfect", &"evade", &"miss"), `damage`, `target_posture`, `attacker_posture`, `hitstop`, `flinch`; reads the target's state and ticks.
- `Trauma`: `add(amount)`, `tick(dt)`, `shake() -> float`.
- `HeroMachine.step(world: FightWorld, input: FightInput) -> Array[Hitbox]`: one tick of the hero (buffers, move, combo, dash,
  parry, hurt, broken); writes `world.hero`, emits events.
- `GuardMachine.step(world: FightWorld, unit: FightUnit) -> Array[Hitbox]`: patrol, alert, role loop (baton | rifle),
  stagger, broken, ko; sight and alert helpers `Sight.sees(...)`.
- `HitResolver.resolve(world: FightWorld, boxes: Array[Hitbox]) -> void`: tests each box against living targets of the other
  side (arc: distance <= reach and angle <= half_arc; line: distance to segment <= width/2), asks DefenceRules, applies hp,
  posture, hit-stop (both units), knockback (walkable), ambush x2 and finisher x3 and riposte x1.5 rules, ko, events.
- `FightSim`: `_init(setup: FightSetup)`, `step(input: FightInput) -> Array[FightEvent]` (order: events cleared; every unit's
  frozen counter tick down, frozen units skip; hero; guards; resolve; mercy and counters tick; won/lost), `world() ->
  FightWorld`, `result() -> StringName` (&"" | &"won" | &"lost"), `snapshot() -> Array[Dictionary]` (a copy for the view).

## View contract (part m1-view)
`FightView` (Node) holds a FightSim; `begin(setup)`, `set_active(bool)`, signal `ended(won: bool)`; steps with `_physics_process`
(fixed 60 Hz accumulator, max 4 steps per frame); reads `Input` into FightInput; plays events on `IsoActor`s.
