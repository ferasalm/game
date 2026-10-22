# Brief: abu-nabil-combat (part A of docs/design/abu-nabil-boss.md; part B, world + dialogue, comes later)
You are in your own worktree on branch gemini/abu-nabil-combat (made from claude/night-sanaa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras: Abu Nabil is an easy, funny mini-boss: his spice cloud confuses the party (half their attacks miss), qishr
coffee cures it, he chews his own feathers to heal. This brief builds the fight; part B starts it from his talk.

## Read first
docs/design/abu-nabil-boss.md ("The fight" section is the spec), docs/design/combat.md (Resolving an action,
BattleAI), then grep docs/MAP.md for: battle_sim, battle_ai, status_def, action_def, consumable_def, item_action,
timeline_event, battle_numbers, battle_fighters, battle_event_player, balance (harness), encounter_def.

## What to build
1. StatusDef: `miss_chance` (0..1, default 0). Content status `confused`: name key STATUS_CONFUSED, turns 2,
   miss_chance 0.5.
2. ActionDef: `cures` (status ids removed from each target it reaches, friendly moves only) and `uses_per_battle`
   (0 = unlimited; a move with no uses left can't be chosen, and a cancelled cast still spends its use).
   ConsumableDef + ItemAction: `cures` passes through; qishr_cup cures ["confused"].
3. BattleSim: a confused unit's HOSTILE action rolls once (seeded battle RNG) against the highest miss_chance of its
   statuses; a miss emits TimelineEvent "missed" (unit = actor, detail = action id) and skips damage, knockback,
   cancel and status for every hit and target; SP gain and the actor's status countdown still happen. Friendly
   moves never miss. Cures emit "status_ended" for the removed status. battle_sim.gd is at 198 lines: put the
   roll, cures and use counts in a new pure helper in features/combat/logic/ and keep every file <= 200 lines.
4. BattleAI: a `self` heal counts for the heal rule when the actor is under ai_heal_below and has uses left; a
   hostile move with power <= 4 whose status every valid target already has is not useful.
5. Content: actions pot_swing, spice_cloud, feather_snack and combatant `abu_nabil` with the numbers in the spec's
   two tables (name key: reuse NPC_HERB_SELLER); encounter `abu_nabil_duel` (enemy abu_nabil in slot 0, party
   slots [0, 2], money 0, no loot, "music": "boss_abu_nabil"). Move names and descriptions in localization/
   combat.csv (append; never a new CSV). Clips: reuse existing clip ids (attack for pot_swing, cast for
   spice_cloud, item for feather_snack).
6. View: a "missed" event shows a MISS pop (localization key, BattleNumbers style) over the actor's target and
   plays the swing without hit-stop or flinch; the intent line over his spice_cloud cast names it; a confused unit
   shows its status text like jammed does.
7. combat.md: add the miss rule, cures and uses_per_battle in "Resolving an action" and the AI changes (short).

## Do NOT edit
content/dialogue/, features/dialogue/, features/world/, core/scene_router.gd, content/economy/ (part B owns them).
Shared files (localization CSVs, MAP.md, combat.md): append or smallest edit; regenerate MAP.md after `git add`.

## Tests
- Miss: with miss_chance 0.5 over 200 seeds a confused unit's hostile actions miss 40-60%; a miss deals no damage,
  no knockback, no cancel; friendly moves and items never miss; SP is still gained.
- Cure: qishr_cup removes confused from every ally (status_ended events); a unit without it is unaffected.
- Uses: feather_snack can be chosen 3 times, not a 4th; a cancelled cast spends the use.
- AI: Abu Nabil under 40% HP with uses left heals himself; he never re-casts spice_cloud on a fully confused party.
- Harness (features/combat/harness): Zayd + Bilqis vs abu_nabil_duel, policy AI on both sides, 200 seeds: party wins
  >= 95%, median battle 55-80 s, party ends with >= 40% HP on average; tune only the [P] numbers in content to get
  there and report the final numbers.
- Content check: every new key exists in a CSV; the encounter's music id exists.

## Proof
`bash tools/check.sh` raw last 15 lines; the harness numbers; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
