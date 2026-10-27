# CANON: game content decisions in force (world, story, heroes, combat, art, UI)
Read before any content work (story, dialogue, names, art, UI, combat design). Same format and log rules as
docs/DECISIONS.md: date | rule as it stands | by; new decisions logged verbatim in docs/decisions-log.md.
Story detail: docs/story/bible.md (CONFIRMED = locked). Vision and pillars: docs/VISION.md.

## World and story
- 2026-10-26 | Story: Feras's bible (docs/story/bible.md; map rydan.twee): CONFIRMED = locked; Old Sana'a, rationed water, acid rain, no supernatural (tech explains all); no calendar year; old story stays cut | Feras
- 2026-10-21 | Real places: Souq al-Milh, al-Saila, Bab al-Yaman, Zubairi, Haddah, Bayt Baws | Feras
- 2026-10-21 | Save spot: sabil fountain (full refill; patrols return); HP/SP carry over; losing offers retry | Feras
- 2026-10-25 | Rydan only for now, Bilqis set aside (two campaigns, one story: later); first build = start flow + one rooftop fight, on the prison roof of the escape (2026-10-26) | Feras
- 2026-10-26 | Opening: start flow -> Roya cold open (in-engine, not Flow video) -> prison escape tutorial -> "Earlier": Zayd's first shift -> back to the escape; old 3D level 1 parked, its content not used | Feras
- 2026-10-21 | Currency: riyal | Claude
## Heroes
- 2026-10-25 | The hero is Rydan (was Zayd); code id "rydan" since 2026-10-27 (save v7 migrates "zayd"; a guard test keeps it gone) | Feras
- 2026-10-26 | Zayd is a new NPC, a rookie officer; code id "officer_zayd" when he enters code (never "zayd") | Feras
- 2026-10-27 | Jambiya on screen (no h; code ids keep jambiyah for now; old save key migrates): two parts, hilt and blade, each upgraded or swapped separately | Feras
- 2026-10-26 | Jambiya: three hilts only, 1/2/3 slots: prison hilt (start), after Numan, grandfather's grave (heirloom); each a full jambiya, blades vary; chained much later; slot contents open (gems with a tech reason or tech modules); hero ring 1-2 sockets | Feras
- 2026-10-22 | Prosthetic: one per hero; tech moves paid from SP; the jambiya stays the weapon; Rydan's cast clips mirrored | Feras
- 2026-10-23 | Rydan's kit (rydan-moves.md): a combat job per move; ATK split across multi-hit moves so SP beats the free strike | Feras/Claude
- 2026-10-24 | Bilqis: rivet pistol; frame and barrel upgraded like Rydan's hilt and blade | Feras
- 2026-10-21 | Rarity: Common to Legendary (white, green, blue, purple, gold); Heirloom tier story-only | Feras
## Combat
- 2026-10-27 | Combat is real-time like Hades (feel, controls, mechanics: move, dash, attack, special, cast); turn-based battle code archived; the 25 playtest notes re-triaged (docs/playtest/2026-10-27.md) (D15) | Feras
- 2026-10-24 | RPG layer: XP, levels, fixed class per hero, Luck, dodge/crit/resist; no flee vs bosses | Feras
- 2026-10-25 | Hero fights alone; story allies are call-in assists; combat rules in logic/, apart from the real-time loop; Hard = stronger enemies, tighter resources | Feras
- 2026-10-21 | Ambush: jambiya reverse stab before a fight; Rydan from behind on a patrol = a head start | Feras
- 2026-10-23 | Abu Nabil, a 40-year-old herb seller (R2, no patrols): optional haggle; spice-cloud fight, qishr cures; fair prices; risk-free rematches | Feras
## Art and audio
- 2026-10-27 | Character style, one for all: Basilisk anime design + sumi-e brush ink, full colour (no grey); references made in Google Flow, then Rodin; Rydan and Bilqis re-coloured to match; Roya = the owner's "after the tragedy" picture (rebel, her dead husband's jambiya); Bilqis ref = concept art Bilqis.jpg (old Flow picture and its model retired) | Feras
- 2026-10-27 | Looks and moves like Hades (isometric, our ink style); the Hades look gets a spike first, then the art-budget decision (D13) | Feras
- 2026-10-24 | 2D: isometric ink-comic per concepts; old Sana'a at night (tower-houses, moon, stars, clouds, fog), neon accents, megacity on the horizon (no year), rain, qamariya glow at the heart; characters: offline 3D renders as sprites, none at runtime | Feras
- 2026-10-21 | 3D inputs (for sprite renders): A-pose pictures (arms 30-45 deg down), flat light, grey background; CC0 motion, no Mixamo | Feras/Claude
- 2026-10-22 | Motif: jambiya hook; smoke, dust, slashes, UI corners, logo curl into it; party hooks left, enemy right | Feras
- 2026-10-24 | Music: Yemeni fusion (Flow); battle, battle_2, battle_3; no menu or merchant tracks (area music plays); to be redesigned for 2D | Feras
- 2026-10-21 | Art budget $0: free tools, CC0/OFL packs, Gemini and Flow outputs; no paid artist or packs; free assets: manifest entry, owner OK to download | Feras
## UI and text (style guide: docs/design/ui.md)
- 2026-10-25 | Title "Neon Glitch"; start: menu -> qamariya -> pick hero -> blur zoom: brief + Normal/Hard -> reaction -> blur pull-back -> game; clips play as video, UI on top | Feras
- 2026-10-25 | UI English + Musnad accents, world Musnad only; motion blur hides AI-video flaws; looped sound | Feras
- 2026-10-22 | Writing: world signs in Musnad only (Noto Sans Old South Arabian, OFL); no Arabic script | Feras
- 2026-10-21 | Dialogue: chest-up painted portrait by text box; 4 expressions (neutral, happy, angry, surprised) | Feras
- 2026-10-23 | Menus: equipment menu (hologram hero, paused); workshop = upgrade, gemstones, crafting; pause over backdrops; holo map | Feras
- 2026-10-24 | Menu keys: Q/E (LB/RB) switch hero; Tab/Shift+Tab (LT/RT) and clicks switch Equipment/Items/Map tabs | Feras
