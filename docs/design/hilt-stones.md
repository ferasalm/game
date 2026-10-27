# Hilt stones (design v1, 2026-10-22; every number is [PLACEHOLDER] until the harness and a play-through)
Owner ask (2026-10-22): the grandfather's jambiyah hilt (Heirloom) has 3 stone slots so it lasts and grows very
strong late; other hilts have fewer (Common none). Stones set in the hilt add stats or passive abilities to Zayd.
Moves the stones change: docs/design/rydan-moves.md. Rarity rules: docs/design/prosthetics.md.

## 1. Player experience
- Fantasy: Zayd restores his grandfather's hilt, one stone at a time; the hilt "remembers" more as the story goes.
- Decision: which 3 stones for this fight (SP engine? counters? team play with Bilqis?), and riyal on stones vs
  herbs. Fun hypothesis: a stone that changes how a move plays (Eye Bead, Ma'rib Stone) feels like a new trick.
- Learnable: the heirloom starts with one stone already set (Red Aqiq), so the first workshop visit shows a
  filled socket and two empty ones before any shop.

## 2. Slots per hilt rarity (content/items/rarities.json gains `stone_slots`; fixed by rarity, never per hilt)
| Rarity | Slots | Takes stones up to | Hilts in v0.3 |
|---|---|---|---|
| Common | 0 | - | (none yet) |
| Uncommon | 1 | Uncommon | swift_hilt |
| Rare | 1 | Rare | anvil_hilt |
| Epic | 2 | Epic | - |
| Legendary | 2 | Legendary | - |
| Heirloom | 3 | everything, incl. Heirloom stones | grandfather_hilt |
Fit rule: a stone fits when its rarity order <= the hilt's (Heirloom order 5 takes all); Heirloom stones fit only
Heirloom hilts. Blades and prosthetics have no slots. Rarer hilts keep the stronger ability; the heirloom keeps
the most slots.

## 3. How the heirloom lasts
1. Most slots of any hilt, forever (3 vs at most 2).
2. Restoration rank I-III opens its slots (owner 2026-10-22): rank I = 1 slot (v0.3), rank II = 2 slots (end of
   Chapter 1), rank III = 3 slots (later story beat). content/jambiyah/heirloom.json: rank -> story flag; the rank is
   derived from GameState flags, not saved. No resonance multiplier (dropped with this choice).
3. Only the heirloom takes Heirloom stones (story-only, never sold or looted): the Grandfather's Aqiq is the first.

## 4. Getting, buying and setting stones (riyal economy: docs/design/economy.md)
- Owned stones live in GameState.inventory (each stone id at most once, like gear). Stones never sell.
- Buy: a new shop "workshop_bench" (ShopDef, reuses the shop screen) at the workshop: Common and Uncommon stones
  plus one Rare. Find: chests and patrol loot (EncounterDef "loot", chests.json), Rare passives mostly found.
- Set or remove at the workshop bench only, free and unlimited. Setting a stone that sits in another hilt moves
  it (a stone is in one slot at a time). Stones in an unworn hilt do nothing. Swapping hilts keeps each hilt's
  stones in place.
- Economy impact: this is a second riyal sink beside the herb stall. Bench stock costs 540 against ~380 slice
  income, so stones and herbs compete. economy.md section 3 (riyal flow) needs a re-run after the build.

## 5. Stones for the slice (content/jambiyah/stones.json, kind "stone"; 11 in the slice + 1 story stone)
| Id (display) | Rarity | Effect (engine) | Where | Flavour line |
|---|---|---|---|---|
| aqiq_red (Red Aqiq) | Common | HP +30 | set in the heirloom at start | "Yemeni carnelian: the stone on every grandfather's ring." |
| sulaimani (Sulaimani Agate) | Common | Def +2 | bench 60 | "Banded like the layers of a tower-house wall." |
| dam_akhawayn (Dragon's Blood Bead) | Common | Atk +2 | bench 70 | "Socotra resin, hardened red; healers swore by it." |
| jaz_black (Black Jaz') | Uncommon | first-hit knockback +400 (bonus_knockback) | bench 80 | "Onyx from the Haraz: heavy in the hand, heavier in a blow." |
| fayruz (Fayruz) | Uncommon | +1 SP per act (sp_per_act) | bench 90 | "Turquoise for safe roads; the couriers still carry it." |
| milh_crystal (Salt of Souq al-Milh) | Uncommon | 5 HP per act (hp_regen) | bench 90 | "Salt keeps what it touches." |
| kamaran_pearl (Kamaran Pearl) | Uncommon | battle start +400 (start_bonus) | chest_saila | "Dived off Kamaran island, before the sea went grey." |
| qamar_stone (Moonstone) | Rare | Jambiyah Strike: sp_gain +1, first-hit knockback +300 | bench 150 | "Pale as the qamariya glass at midnight." |
| ayn_bead (Eye Bead) | Rare | Elder's Patience also counters ranged hits | rooftop_patrol loot | "The eye agate that watches your back." |
| marib_stone (Ma'rib Stone) | Rare | when Zayd interrupts a cast, refund 4 SP | patrol_gate loot | "Cut for the great dam; it remembers breaking." |
| sabatayn_glass (Sab'atayn Glass) | Rare | Zayd's hits on jammed foes x1.25 | chest_mafraj | "Lightning fused this sand in the desert east of Ma'rib." |
| jadd_aqiq (The Grandfather's Aqiq) | Heirloom | after a counter, Zayd jumps to COMMAND_POINT (acts next) | story: end of the slice | "He set it himself. It was always meant to come back." |
Kit links: Moonstone feeds the Strike SP engine; Eye Bead lets Elder's Patience answer the drone; Ma'rib Stone
makes Breaker chains affordable; Sab'atayn Glass rewards Bilqis's static_net; the Grandfather's Aqiq turns a
counter into a full turn (the late-game heirloom moment; first session ends on that hook).

## 6. Stacking rules and caps (content/jambiyah/stone_rules.json)
- Merge order: base -> hilt -> stones -> blade -> prosthetic -> perks -> caps (Gear.build).
- Each stone is unique, so one copy per hilt. Same-kind effects from different stones (and from item perks) add.
- Caps on the totals from all sources: sp_per_act bonus <= 3, hp_regen <= 15,
  first-hit knockback bonus <= 1500, start_bonus <= 1500 (4500 + 1500 stays below COMMAND_POINT 7000),
  damage vs jammed <= x1.5, stone Atk <= +8, Def <= +6, HP <= +120. An SP refund never exceeds the move's cost.
  Existing caps stay (agility 1-99, cast_speed 0.5-2.0).
- "Broken" means: any harness row over 90% wins on rooftop_patrol or under 40 s, or Zayd acting twice in a row
  more than once per battle on average. The 3 strongest slice sets (fayruz + marib + sabatayn; aqiq + milh +
  sulaimani; moonstone + fayruz + marib) get harness rows; each must stay within 65-90%.

## 7. Engine and content work
- RarityDef `stone_slots` (int). New StoneDef (kind "stone"): id, name_key, desc_key, flavour_key, rarity, price
  (0 = not sold), stats {hp, sp, attack, defense, agility}, perk (PerkDef id, optional). ContentDB KINDS gains it.
- PerkDef kinds gain: counter_ranged, interrupt_refund (amount SP), bonus_vs_status (status id + percent),
  action_sp_gain (action id + amount), counter_to_command. PerkDef gains optional `action` and `status` fields.
- Pure logic features/jambiyah/logic/sockets.gd: slots_for(hilt), fits(hilt, stone) -> "" or reason,
  set_stone / remove_stone (moves between hilts), effects(hilt, stones, rank, rules) -> capped adds.
  heirloom_rank(flags) -> int. Combat reads the results through CombatantDef fields (no stone code in combat).
- View: workshop bench "Stones" tab; shop "workshop_bench"; battle popups for refund and conducted.
- Localization: localization/stones.csv (names, effects, flavour lines).

## 8. UI (workshop screen)
Worn hilt drawn large with its sockets (empty ring; filled with a gem in its rarity colour; 0-slot hilts say "no
sockets"). Owned stones list: fits / greyed with the reason ("needs a Rare hilt"). Before/after stat rows
(WorkshopStats.rows) on hover; passive stones show the changed move's new description with a "changed" tag. A
"max" marker when a total sits at its cap. The heirloom shows "Restoration I" and its open slots (1/3). One button
"Remove" per filled socket; no confirm needed (free and undoable).

## 9. Save data (GameState, SaveCodec v4 -> v5)
`sockets: Dictionary[StringName, Array]`, hilt id -> one entry per slot, "" = empty; e.g.
`{"grandfather_hilt": ["aqiq_red", "", ""], "swift_hilt": [""]}`. Hilts are unique items, so the hilt id is the
instance. Migration v4 -> v5: if grandfather_hilt is owned, own aqiq_red and set it in slot 0. On load: unknown or
unowned stone ids are emptied, a stone in two slots keeps the first, arrays are padded or trimmed to the slot count.

## 10. Tests the builder writes
Slots per rarity (Common 0, Heirloom 3); fit rule incl. Heirloom-only stones; set, remove, move between hilts;
a stone in an unworn hilt changes nothing; merge order; every cap clamps;
start_bonus never reaches COMMAND_POINT; each new perk kind in battle (refund on interrupt only, x1.25 vs jammed
only, ranged counter only with ayn_bead, counter_to_command); save round trip and v4 -> v5 migration; load repairs
bad sockets; content checks: Heirloom stones never in a shop, chest or loot, every stone has name, effect and flavour
keys in stones.csv; harness rows for the 3 strongest sets.

## 11. Owner decisions (2026-10-22)
- The heirloom's slots open with the story (1, then 2, then 3), no resonance.
- Taking a stone out is free and unlimited at the bench.
- Stones are bought at the bench and found in chests and patrol loot.
