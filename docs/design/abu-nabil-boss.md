# Abu Nabil, the herb haggler (v0.3 mini-boss)
Owner's decisions 2026-10-22 (DECISIONS); Game Designer spec. Numbers marked [P] are placeholders for the balance
harness. v1, 2026-10-22.

## Fantasy and pillars
A greedy, funny herb merchant who prices his feathers like gold, loses a fight over it, and talks himself into a fair
deal. The player should laugh, feel clever (cancel his spice cloud, cure it with qishr), and come back to spar.
- Optional: the player chooses to haggle, to fight, or to walk away. Nothing on the roof forces it.
- Readable: his big move is a slow, telegraphed cast the party can cancel (the timeline's fun hypothesis).
- Safe to practise: after the first win he is a risk-free sparring partner.

## Where and when
- His stall stands on R2, the market roof, a home roof with no patrols (DECISIONS 2026-10-23).
- He only sells the feathered herbs: pink, yellow, white. qishr_cup leaves his stock (chests, loot and his gift).

## States (flags in GameState.flags)
| state | flag | talking to him gives |
|---|---|---|
| greedy | none | the haggle talk (below); his shop at x10 prices [P] |
| beaten | abu_nabil_beaten | a menu: Shop (fair prices, x1) / Spar / Chat / Leave |
Extra flags remember the player's choices (abu_nabil_insulted, abu_nabil_charmed) so later lines can nod to them.

## The haggle talk (branching; first visit and every visit while greedy)
1. He waves Zayd closer: "Come, come, look at this merchandise!" -> his shop opens at greedy prices (pink 300,
   yellow 200, white 800 riyal [P]); the player looks, can't afford them, closes it.
2. Zayd: "Three hundred riyal for a feather? Are you out of your mind?" Abu Nabil defends the "finest feathers in
   Sana'a". Choices:
   - A "These prices are robbery." -> he doubles down, offers the "old way" to settle it -> Fight / Walk away.
   - B "Your herbs look half-dead, uncle." -> he is offended (sets abu_nabil_insulted) and attacks: the fight starts
     with HIM ahead on the timeline (opening enemy_first).
   - C "Surely a discount for an old friend of the family?" -> he laughs it off but likes the flattery (sets
     abu_nabil_charmed): "Beat me and we'll talk." -> Fight (opening party_first) / Walk away.
   - D "Keep your feathers." -> "You'll be back. Everyone comes back." The talk ends; nothing changes.
3. "Fight" asks once more ("Fight Abu Nabil?" yes / not yet) so the player can save at the sabil first.
Lines are drafts for the Narrative pass: playful, never cruel; Abu Nabil is greedy, proud and soft underneath.

## The fight: encounter abu_nabil_duel
- Abu Nabil alone (enemy slot 0), party slots [0, 2]; music boss_abu_nabil; money 0, no loot; not a patrol (the
  sabil never resets it); no reverse stab (talk-started). Defeat in the first fight: the normal defeat screen.
- Target: 55-80 s; the party wins >= 95% of harness runs and ends with >= 40% of its HP on average (easy).

| combatant abu_nabil (same id as his model) | value | why |
|---|---|---|
| max_hp | 1200 | tuned by the harness (2026-10-23); his heals add ~240 |
| max_sp | 12 | spice cloud once at the start, then about every third act |
| attack / defense | 45 / 10 | hits a bit softer than an enforcer (31); soft to Zayd's strikes |
| agility / weight | 60 / 5.0 | slower than the party; heavy, so knockback pushes him less |
| interrupt_resist | 0.7 | at 0 the harness AI chain-interrupted him and he never acted (party ended 99.8% HP) |

| move | target | power | cast | recovery | sp | effect |
|---|---|---|---|---|---|---|
| pot_swing (clay pot bonk) | foe, melee | 16 [P] | 1.1 | 600 | 0 | knockback 900 |
| spice_cloud (hawaij in your face) | all_foes | 4 | 0.6 (slow) | 900 | 8 | applies confused; cancellable |
| feather_snack (chews a pink feather) | self | 0 | 0.9 | 500 | 0 | heal 80 [P]; 3 uses a battle |

- Status confused: 2 turns [P] (one turn per act of the unit); each HOSTILE action of a confused unit misses with
  chance 0.5 (one seeded roll per action, all its hits together). A miss: event "missed" (actor, detail action id),
  no damage, no knockback, no cancel, no status; SP is still gained. Friendly moves and items never miss.
- qishr_cup also cures confused on every ally it reaches (new consumable/action field `cures`).
- AI (BattleAI): a self-target heal counts for rule 2 when the actor is under ai_heal_below and has uses left; a
  move whose status every valid target already has (and power <= 4) is not "useful" (no re-cloud on a confused
  party). Otherwise the existing rules.
- View: the intent label over his cast ("Spice Cloud: confuses all", the "will interrupt" preview as today), a
  "MISS" pop for misses, a confused icon/tint and a sneeze puff on the afflicted, his herb count (3 leaves) by his
  name. Win: he sits down on the tiles, fanning himself.

## After the first win
Dialogue: he self-justifies ("It's late. Nobody buys feathers at this hour anyway."), agrees to fair prices, and makes
Zayd promise to buy herbs from nobody else. He hands over a qishr_cup ("for the road")... then asks for 45 riyal for
it. Choices: "Pay him" -> Bilqis stops Zayd's hand ("Don't you dare."); "A gift is a gift, uncle." -> he grumbles.
Both end the same: nobody pays; flag abu_nabil_beaten; the shop drops to x1.

## Spar (rematch, after the first win)
- Same fight, risk-free: before it, snapshot the party's HP, SP and bag; after it (win or loss) restore them.
  No rewards, no defeat screen (a loss returns to the roof with "Up you get. Again?"), patrols untouched.
- BattleRequest gets `practice: bool`; the snapshot lives in the router, never in the save.

## Failure states and edge cases
- Walking away at any choice changes nothing but the flags above; the talk can be replayed.
- Losing the first fight: the defeat screen (Retry fight / Load / Title); Retry keeps the chosen opening.
- Saving during a spar is impossible (the sabil is outside the battle); quitting mid-spar loads the pre-fight state.
- The whole party confused: they can still use items and friendly moves; the cloud lasts 2 of each unit's acts.
- He heals at most 3 times; a cancelled feather_snack still spends a use (he dropped the feather) [P].

## Build split (agy, two briefs)
A. Combat (pure + battle view): StatusDef.miss_chance, ActionDef `cures` and `uses_per_battle`, BattleSim misses,
   cures and use counts, BattleAI rules above, content (status, 3 moves, combatant, encounter + music field,
   qishr cures), MISS pop, intent text; tests (miss rate over seeds, cure, uses, AI picks, harness win rate).
B. World + dialogue: dialogue choices (choice -> next dialogue id + effects: open_shop, start_battle with opening,
   set_flag, give item), shop price multiplier by flag, the herb seller's talk states, spar (practice requests),
   localization; tests (each branch's outcome, flags, prices, spar restores everything).
