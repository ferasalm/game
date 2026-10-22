# Prototype v0: "Rooftop patrol" (owner answers 2026-10-21; acceptance tests at the end)
Goal: the smallest loop that feels like the game. Walk the souq rooftops, set Zayd's jambiyah at a workshop,
bump into a Concession patrol, win or lose a timeline battle, return. Rules: docs/design/combat.md.

## What you play (press F5 in the editor)
1. Start on one rooftop area of the Old City (block diorama, the accepted look v1, FPS label kept).
2. Walk Zayd in 8 directions (WASD or arrows, or the left stick / d-pad). Bilqis follows him. The camera follows
   smoothly; walls and parapets block; the area has edges.
3. A workshop bench: walk up, press E (or Enter, Space, pad A). The first time, Bilqis and Zayd talk (3-4
   lines): a text box at the bottom with the speaker's name, a chest-up painted portrait beside it, the
   expression changing per line (stand-ins until Feras's Gemini art). Then pick 1 of 2 hilts and 1 of 2 blades; the menu
   shows how Zayd's numbers change. Esc (pad B) closes it. Default pair: swift hilt + keen blade.
4. A Concession patrol (one enforcer sprite) walks back and forth. Touching it starts a battle in place. If it
   catches Zayd from behind: the reverse stab (he spins and stabs backward with the jambiyah's hook, damage and
   stagger on that enemy), and the enemies start ahead. If Zayd reaches it from behind, the party starts ahead.
5. Battle: the camera moves to the battle view. Zayd stands in front, Bilqis behind him. Enemies: two enforcers
   in front, a survey drone behind them. A timeline bar shows every fighter's icon moving toward COMMAND.
6. Wait mode: time stops when a hero reaches COMMAND. Pick a move (name, SP cost, a "cancels" tag), then a
   target. Enemies choose by themselves. Moves charge, then hit: damage numbers, knockback, "Interrupted!"
   with a short hit-stop. A charging enemy shows its move's name above it; the target picker marks a cancel
   move "will interrupt" when it lands before that enemy's charge (BattleSim.lands_before). One-time tips at
   the first command ("time stops while you choose") and the first enemy charge ("hit it with a cancels move").
7. Win: every enemy down -> "Victory" -> back on the rooftop. Lose: both heroes down -> "Defeated" -> retry
   the battle or go back. HP and SP refill after each battle. The patrol returns to its route a few seconds
   later, so another pairing can be tried.

## Built from
- Logic (pure, tested): BattleSim (damage, SP, statuses, deaths, victory), BattleAI, the jambiyah merge,
  a balance harness (1,000 seeded battles headless -> one table per pairing).
- Content (JSON): fighters, moves, statuses, hilts, blades, battle and explore rules, the rooftop layout,
  pixel sprites. Player text through localization keys (English).
- View: rooftop scene, player and follower, CharacterVisual (billboard sprite, bob, lunge, flash), battle
  stage, battle HUD (timeline bar, party panel, command menu, target picker, banners), workshop menu,
  dialogue box (name, text, portrait; next line on E or pad A).
- Art: pixel sprites drawn by Claude as palette-indexed rows in content/art/ (art bible); tools/art/pixelize.py
  turns a Gemini or Flow picture into the same format later.

## Not in v0
Dialogue beyond the workshop talk, saves, items, healing, sound, title screen, Arabic text, walk-cycle frames
(a bob stands in), more than one area, Sheikh Hamoud.

## Acceptance tests
Automated (tools/check.sh runs them all):
- T1 Same seed and same choices give the same battle events, twice in a row.
- T2 Every battle ends (victory or defeat) within the rules' tick limit, for all 4 pairings, 200 seeds each.
- T3 The 4 hilt + blade pairings give 4 different Zayd stat sets; all stay inside the timeline caps; each
  hilt adds exactly one move.
- T4 A cancel move landing on a casting enemy interrupts it (back to 2500) inside BattleSim; lands_before agrees.
- T5 Damage, SP costs, cover (a covered unit can't be a melee target) and status turns follow combat.md.
- T6 The rooftop scene builds headless; a simulated touch starts a battle; an auto-played battle ends and
  control returns to walking.
- T7 Every sprite row has the same width and uses only palette letters; every sprite has a source and licence.
- T8 Every dialogue line names a known speaker and expression (portrait or stand-in exists) and a text key.
Balance target (harness, auto-play policy): each pairing wins 60-95% of battles, and no pairing beats another
by more than 25 points. Battles last 40-90 seconds of game time.
Owner (Feras on the Latitude): walk, set a pairing, fight, win or lose, return without help; >= 60 FPS;
the 4 pairings feel different. Verdict logged in DECISIONS.

## v0.2 additions (2026-10-21)
- The rooftop (Funduq Roof, Souq al-Milh) is a 34x26 single-terrace guesthouse roof with breathing room, open middle patrol loop, stair head spawn south, Abu Nabil stall west, workshop deck east, sabil north facing the vista, and chests in far corners. Basalt-base tower-houses, glowing qamariya, moon, stars, clouds and fog.
- The 2150 megacity shows on the horizon. Real place names: Souq al-Milh, al-Saila, Bab al-Yaman, Zubairi, Haddah, Bayt Baws.
- Rooftop dressing: moonlit tile tints, warm light only at lamps and doorways, and neon signs with glow and blink.
- Area data lives in content/world (areas, buildings, props, lights, signs); a light budget caps real lights at 8.
- Prosthetics: one slot per hero. A prosthetic grants tech moves paid from SP. The jambiyah stays the physical weapon.
- Rarity: common, uncommon, rare, epic, legendary (white, green, blue, purple, gold), plus a story-only heirloom tier.
- Loot: the patrol drops anvil_hilt. Two chests on the roofs (Saila and Mafraj) give arc_arm and lens_array, once each.
- Music: two tracks, night_rooftops while exploring and battle in fights. The owner made both in Google Flow.
- Dialogue: the owner's Gemini portraits, 4 expressions each for Zayd and Bilqis (assets/portraits/).
- Sprites: real 64 px Zayd, Bilqis and enforcer (68 px) and the drone, from the owner's Flow pictures via
  tools/art/pixelize.py --outline; his Pixelorama touch-up can replace them through the same ids.
