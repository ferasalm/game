# Economy, items and rest (prototype v0.3; every number is [PLACEHOLDER] until the harness and a play-through)
Owner decisions 2026-10-21: riyal; feathered herbs; HP/SP carry over; the sabil saves and refills; Retry or Load on
defeat. Scope: the rooftops only (10-15 min). Rules code reads numbers from content/economy/ and content/items/.
Base stats: Zayd HP 400 SP 24, Bilqis HP 280 SP 36 (combat.md). Party pool = 680 HP.
## 1. Pillars and loop
1. Every fight leaves a mark: HP and SP carry, so the next choice is already loaded.
2. Money buys time, never power: herbs cost a turn in battle and a walk back to the stall outside it.
3. One safe place: the sabil is the only save, the only free refill, and it wakes the Concession again.
Loop: explore -> fight -> earn -> buy -> rest at the sabil -> fight again.
| Step | The player decides | Cost of the wrong call |
|---|---|---|
| Explore | which patrol first, take the chest or not, touch from behind (ambush) or not | walking time |
| Fight | spend a turn on a herb or attack; which herb | a lost turn; a dead hero |
| Earn | nothing (automatic): riyal + drops on the end panel | - |
| Buy | herbs now, or save riyal; walk back to the stall or push on | 40 s of backtracking |
| Rest | drink now (patrols return) or fight on hurt | farmed patrols give half pay |
Fun hypothesis: "do I heal now or press the attack" must be a real choice inside the timeline, not a menu chore.
## 2. Consumables (content/items/consumables.json, kind "consumable")
Cast speed uses ActionDef units: speed per tick = agility x weight mult x cast_speed; cast = 3000 units (COMMAND 7000
to ACT 10000). Zayd (Agi 40, Wt 3) at 1.8 = ~69/tick = 44 ticks = 0.73 s; the enforcer's baton (0.8) takes ~2.3 s.
| id | Effect | Target | Use in | Cast | Rec. | Price | Sell | Stack | Rationale |
|---|---|---|---|---|---|---|---|---|---|
| pink_herb | hp 120 | ally | both | 1.8 | 300 | 30 | 15 | 5 | 30% of Zayd, 43% of Bilqis; ~2.7 baton hits; beats nanite_mend (58) because it costs riyal |
| yellow_herb | sp 12 | ally | both | 1.8 | 300 | 20 | 10 | 5 | half of Zayd's SP, 1.5 breakers; cheap because SP also returns by +3 per act |
| white_herb | revive, hp_pct 0.30 | ko_ally | battle | 1.2 | 400 | 80 | 40 | 3 | Zayd back at 120, Bilqis 84; slower than a heal so a revive is a planned risk |
| qishr_cup | hp 75 | all_allies | both | 1.3 | 400 | 45 | 22 | 5 | Yemeni husk drink; 150 HP in one turn vs 120; the group-heal option |
Argued: pink + yellow (the owner's) + white are the core. The qishr cup is the first thing to cut if scope slips: it
is the only other all_allies path in the Items menu, but nothing else depends on it. Risk: yellow may be a dead item
because fights give +3 SP per act (section 9 watches "yellow used per fight").
Rules: recovery is the same as actions; no SP cost; sell is explicit, never above price/2; the white herb is never
usable in the field (KO heroes stand up after victory, section 6). In the field an item cannot target a hero it would
not change (full HP/SP): the row is greyed.
## 3. Riyal: start, sources, sinks, flow
Start: 100 riyal, bag {pink_herb: 1}. Cap 9999. Content/economy/rules.json holds these (section 8).
| Source | When | Amount |
|---|---|---|
| patrol_scouts / rooftop_patrol / patrol_gate | first win | 40 / 70 / 120 |
| Repeat win of a patrol after a sabil reset | later wins | 50% (`repeat_payout`), no loot, no herb drops |
| chest_saila / chest_mafraj | once | 25 + yellow_herb / 25 + pink_herb (items unchanged) |
| Selling herbs at the stall | any time | sell price |
Sink: the herb stall only (v0.3). Max spend at the stall (5 pink + 5 yellow + 3 white + 5 qishr = 715) is above the
total income (380 incl. start), so riyal always matters. Over-cap loot converts to riyal at sell price, never lost.
15-minute flow (first run, no farming):
| Min | Event | In | Out | Riyal after |
|---|---|---|---|---|
| 0-2 | title, workshop talk | 100 | 0 | 100 |
| 2-3 | stall: 2 pink + 1 yellow (or 3 pink) | 0 | 80 (90) | 20 |
| 3-5 | patrol_scouts (A) | 40 | 0 | 60 |
| 5-6 | chest_saila | 25 | 0 | 85 |
| 6-9 | rooftop_patrol (B), no refill since A | 70 | 0 | 155 |
| 9-10 | sabil: drink, save, patrols return | 0 | 0 | 155 |
| 10-11 | optional walk back to the stall: white + 2 pink | 0 | 140 | 15 |
| 11-14 | patrol_gate (C) | 120 | 0 | 135 |
| 14-15 | chest_mafraj | 25 | 0 | 160 |
Income ~280 over ~13 min = ~21 riyal/min. Before fight A the player affords 2-3 herbs (start bag makes 3-4 in hand);
after A, 60 riyal plus 1 herb in hand makes "walk back or press on to B" a real choice. Sabil is placed after B so
A to B is a chain on carried HP.
## 4. The herb stall (content/economy/shops.json, kind "shop")
- Stock: pink, yellow, white, qishr; unlimited supply; price from the consumable def.
- Buy: a +/- stepper; max = min(affordable, max_stack - owned). Cannot buy a full stack or without money.
- Sell: consumables only (bag, never reserved), at the def's `sell` (half price). Gear and equipped items: never.
  No sell price rises or falls (no arbitrage: sell <= price/2).
- Walking up is free; the shop is a screen (UiStack), the game is paused, and it ends in one Back.
## 5. Items in battle (Items command, beside Moves)
- Items lists every battle-usable consumable with its count; empty or zero -> the command is greyed.
- Choose: pick item, then target (ally / all_allies skips target / ko_ally only downed). At choose the item is
  RESERVED: available = bag count - items reserved by all heroes' pending casts. Two heroes cannot both claim the last
  herb. The cast then runs like a move: cast_speed, the cast bar, the timeline icon, the preview.
- ACT: if the target is valid and the item would change something, CONSUME one and apply (events: item_used, then
  healed / sp_restored / revived with the real amount). Items give no sp_per_act, no perk regen; they do tick the
  actor's status turns (a turn passed).
- REFUND (the reservation is released, the bag is unchanged) when: the cast is cancelled/interrupted; the user is KO'd
  before ACT (a KO already clears the cast, combat.md rule 7); the target became invalid at ACT (a hp/sp herb on a
  downed ally, a white herb on a living one) or the effect would be 0 (full HP). Event: fizzled, no loss.
- Interruptible: yes, an item is a cast. An enemy move with cancels_cast hitting the user puts the hero back to
  INTERRUPT_POS and the herb stays in the bag. No v0.3 enemy has cancels_cast, so this is a rule for later enemies.
- AI never uses items: BattleAI does not know the bag. The balance harness has its own opt-in ItemPolicy (section 9).
## 6. Carry-over, KO, defeat, the sabil
- Start of a battle: the party's vitals come from GameState.vitals (missing = full). After victory they are written back.
- KO after victory: downed heroes stand up at 1 HP (`ko_stand_hp`, content). Why: a hero left KO would need a
  white herb or the sabil to continue; with only the sabil as free exit the player could soft-lock (no herb, no way
  back). 1 HP keeps the debt (the next ambush ends the fight) without a dead end, and the white herb stays a
  battle-only tool. SP is whatever remained.
- Equipment changes in the field clamp current HP/SP to the new max, never raise them.
- Defeat: the screen offers Retry fight, Load last save (greyed until a sabil drink exists), Title. No money lost.
  Retry restores the pre-battle snapshot (vitals, bag, money) and restarts the same encounter and ambush flag at once,
  with a new seed (`seed + retry_count`) so it is not a replay. cleared_patrols is unchanged by Retry.
- The sabil, Drink: HP and SP of the whole party to full, save to the slot, empty cleared_patrols (patrols return,
  repeat pay 50% via the `patrol_paid_<id>` flag). It is the only save in v0.3. Cleared patrols are saved so a
  quit mid-run keeps its dead enemies; a load from the sabil save has the list empty.
- Respawn safety: after any battle ends (win, retry, load) no patrol may touch for `grace_seconds`, and the patrol
  that fought stays gone or is placed at its home; patrols returning at the sabil spawn only while the party is at
  least `spawn_min_distance_m` away, else they wait. A patrol never starts a battle inside the sabil's radius.
## 7. Patrol set (content/combat/encounters.json; ambush rules unchanged: combat.md, touch from behind = party ambushed, reverse stab)
| id | Enemies (slots) | Party slots | Money | Other | Target win (full HP) |
|---|---|---|---|---|---|
| patrol_scouts | enforcer (0), drone (2) | 0, 2 | 40 | - | >= 92% |
| rooftop_patrol (exists) | enforcer (0), enforcer (1), drone (2) | 0, 2 | 70 | loot anvil_hilt | 73-88% |
| patrol_gate | enforcer (0, 1), drone (2, 3) | 0, 2 | 120 | white_herb x1 | 50-70% |
Curve: A teaches, B is the proven fight, C is the optional test that guards chest_mafraj. After A the party has lost
~25-40% of its pool: B on carried HP wins ~55-70% without herbs, ~75-85% with 1-2. C on a full refill; on carried HP
below 50% it should be under 30% (the sabil and herbs are the answer). Level order wanted: stall -> A -> chest_saila
-> B -> sabil -> C -> chest_mafraj; the stall within 15 s of spawn, A and B in sight of a retreat route.
## 8. JSON shapes (all text keys in localization/items.csv and shop.csv; ids lowercase_snake)
content/items/consumables.json:
`{"kind":"consumable","items":[{"id":"pink_herb","name_key":"ITEM_PINK_HERB","desc_key":"ITEM_DESC_PINK_HERB",`
`"icon":"herb_pink","hp":120,"hp_pct":0,"sp":0,"revive":false,"target":"ally","use_in":"both","cast_speed":1.8,`
`"recovery":300,"price":30,"sell":15,"max_stack":5,"vfx":"heal"}]}`
Validation: one effect > 0 (revive uses hp_pct); target in ally|all_allies|ko_ally; ko_ally implies revive and
use_in battle; cast_speed 0.1-5 like ActionDef; sell <= price/2; max_stack >= 1.
content/economy/shops.json:
`{"kind":"shop","items":[{"id":"herb_stall","name_key":"SHOP_HERB_STALL","keeper_key":"NPC_HERB_SELLER",`
`"greeting_key":"SHOP_HERB_GREETING","stock":["pink_herb","yellow_herb","white_herb","qishr_cup"]}]}`
References: stock -> ["consumable", id]. Only consumables are sold or bought in v0.3.
content/economy/rules.json (kind "economy_rules", id "default"): `{"start_money":100,"start_bag":{"pink_herb":1},`
`"money_cap":9999,"repeat_payout":0.5,"ko_stand_hp":1,"grace_seconds":3.0,"spawn_min_distance_m":10.0}`
Encounter adds `"money":40` and optional `"consumables":{"white_herb":1}` (id to count, refs checked). Chest adds
`"money":25` and `"consumables":{"yellow_herb":1}`; `item` becomes optional if money or consumables exist.
GameState v4 (Phase 1): money, bag, vitals, cleared_patrols, flags `patrol_paid_<id>`.
## 9. Edge cases, levers, harness
Edge cases:
- Bag at max_stack on pickup -> overflow to riyal at sell price. Money at the cap -> excess dropped, popup says so.
- Qishr with one hero KO'd: heals the living only; if nobody would change, fizzle + refund.
- Same target chosen by two heroes with one white herb: second choose is blocked (reservation).
- Retry after a hero used the last herb: bag is back to the snapshot. Quit mid-battle: nothing saved.
- Rewards apply once per battle id (outcome is idempotent) so Load or Retry never double-pays.
Tuning levers (all content): prices and sell, hp/sp values, cast_speed, start_money/bag, patrol money,
repeat_payout, ko_stand_hp, grace_seconds, spawn_min_distance_m, enemy stats (combat.md), stack caps. Optional off by
default: mercy heal after 2 defeats in a row on one encounter.
Harness report (opt-in ItemPolicy: pink when a hero < 40% HP, white on a downed hero, yellow when SP < cost of the
cheapest move; 300 seeds per row; enemies never use items):
| Metric | Healthy | Broken (fix before the owner plays) |
|---|---|---|
| Win % A / B / C at full HP | >= 92 / 73-88 / 50-70 | A < 85, B outside 65-90, C > 80 or < 35 |
| B on carried HP after A, no herbs / 2 herbs | 55-70 / 75-85 | no herbs > 85 (carry-over is toothless) or < 35 |
| C on carried HP < 50%, no herbs | < 30 | > 50 (the sabil is optional) |
| Herbs used per fight A / B / C | 0.3-0.7 / 0.8-1.5 / 1.5-3 | > 4 in any, or yellow < 0.1 on average |
| Battle length | 40-90 s | > 120 s (herb stalling) |
| Money per minute, first run | 15-30 | < 8 (poor) or > 40 (rich) |
| Farm: repeat A at 50% pay, riyal per minute | <= 12 | > first-run rate (farming beats playing) |
| Herb-only play (no attacks) | loses >= 95% | wins (stalling exploit) |
Also report herbs bought vs used, riyal unspent and defeats per run.
