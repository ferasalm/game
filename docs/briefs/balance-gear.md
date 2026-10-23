# Brief: balance-gear (<= 60 lines; content numbers only)
You are in your own worktree on branch oc/balance-gear (made from claude/menus-rpg-5089fa). Your working directory is
the repo root of that worktree; every path below is relative to it; never read outside it. Follow GEMINI.md.

## Why
Feras's target for every fight: the party wins 65-90% and a battle lasts 40-90 s. After the new rolls, levels, armor and
Zayd's kit, the start gear wins 82.7% but better gear wins 92-99% (docs/design/prosthetics.md, the 2026-10-23
zayd-kit table): upgrades make fights trivial.

## Read first
docs/design/prosthetics.md (the balance section and the latest table); docs/design/rpg-systems.md 6-7;
features/combat/harness/balance.gd (its header says how to run it); content/jambiyah/hilts.json, blades.json;
content/prosthetics/*.json; content/items/armor.json; content/combat/combatants.json; content/combat/encounters.json.

## What to build
1. Run the harness for all obtainable rows: `GODOT_TIMEOUT=1800 tools/run_godot.sh -s
   res://features/combat/harness/balance.gd -- 300 obtainable` (also once per encounter id: patrol_pair, patrol_drone,
   patrol_gate). Save the raw table.
2. Tune ONLY numeric stat values on existing lines of hilts.json, blades.json, prosthetic content, armor.json and the
   three patrol enemies in combatants.json (never abu_nabil: his own test keeps him easy, >= 95% and 55-80 s). Change
   numbers in place, keep every line's keys and order (another build adds keys to these files).
3. Goal: every obtainable row 65-90% wins and 40-90 s; the start gear row stays 78-86%; better gear still wins more
   than the start gear (an upgrade must feel like one). Iterate: change, re-run, compare.
4. Paste the final table into docs/design/prosthetics.md under a dated line with every number you changed
   (old -> new).

## Do NOT edit
Any .gd file, features/**, core/**, content/world/**, content/ui/**, content/combat/actions.json, statuses.json, rules.json,
tests, docs/DECISIONS.md, HANDOFF.md, any *.import. No Arabic script.

## Tests
`bash tools/check.sh` must pass (test_abu_nabil_balance and every balance test included). No new tests: the table is
the proof.

## Proof
`bash tools/check.sh` raw last 15 lines; the final table; small WIP commits after each tuning round; final message
ends with `Built-by: inkling:free (opencode)`.
