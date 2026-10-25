# Decisions in force (loaded summary; full history: docs/decisions-log.md)
Each line: date of the deciding entry | the rule as it stands today | by. Update a line when a later decision changes
it; log every new decision verbatim in docs/decisions-log.md too.

## In force
### Process
- 2026-10-24 | 2D redesign: one person, low budget; turn-based first, action later | Feras
- 2026-10-22 | Log: never reword; struck (~~...~~) lines go to docs/decisions-archive.md | Claude
- 2026-10-21 | Ask Feras 2-4 multiple-choice questions, recommended first; big asks: plan mode (Opus xhigh), agent audit, then orchestrate | Feras
- 2026-10-21 | Runs stop only for owner questions, logins, CAPTCHAs, downloads, spending | Feras/Claude
- 2026-10-23 | Hand off at ~150k tokens; milestone-only reports; one owner per HANDOFF section | Feras
- 2026-10-23 | Emergency mode (50% of the 5-hour window): one director chat, builders on backups | Feras
- 2026-10-22 | Always-loaded notes <= 27 KB; LESSONS <= 100 lines; one task, model, effort per chat | Feras
- 2026-10-19 | Merge checked work into main at each session's end (standing OK) | Feras
- 2026-10-19 | Blueprint = design input only; WSL2 rule and 120-line cap rejected | Claude
### Tools and builders
- 2026-10-24 | Builders: 5 runs = 2 agy, 2 DeepSeek V4.1 Flash, 1 GLM-5.3 (no Inkling, Kimi); agy out: all DeepSeek, max 3; triage GLM-5.3 Flash; skills: design V4 Pro/Nemotron/Gemini, code GLM-5.3 | Feras
- 2026-10-23 | Builds: build_pipeline.sh + build_gate.py; Claude reads PASS runs only; merge chats on Sonnet | Feras
- 2026-10-23 | Briefs: gate-tested Checklist; Haiku diff pass before Opus (design, renders); tools/slots.sh counts slots | Feras
- 2026-10-23 | Own tasks go to subagents: Haiku first, Sonnet if Haiku can't; Claude reviews sensitive results | Feras
- 2026-10-22 | Hyper3D Rodin (paid plan) makes 3D models for sprites; Claude drives its MCP; name cost first | Feras
- 2026-10-21 | Game skills: .agents/skills/ copied to .claude/skills/ | Feras
### Engine and code
- 2026-10-21 | Godot 4.7.2 pinned; typed GDScript; Windows first, exes git-ignored; Forward+ (3D, paused) | Feras/Claude
- 2026-10-19 | Min target: Dell Latitude 5520 (16 GB), 60 FPS (3D look tests, paused) | Claude
- 2026-10-22 | Content = read-only Def classes from JSON; runtime state separate; folders per feature, logic/ pure; saves: GameState (versioned), 3 slots | Claude/Feras
- 2026-10-19 | Combat timeline: integers, fixed 60 ticks/s, deterministic, returns events | Claude
- 2026-10-21 | Player text: localization/<feature>.csv via the TextDB autoload, not Godot CSV import | Claude
### World and story
- 2026-10-19 | World: cyberpunk futuristic Sana'a, Yemen (no Malik/Thurya/Dharib cast); Claude invents the cast, Feras reviews | Feras
- 2026-10-21 | Real places: Souq al-Milh, al-Saila, Bab al-Yaman, Zubairi, Haddah, Bayt Baws | Feras
- 2026-10-21 | Save spot: sabil fountain (full refill; patrols return); HP/SP carry over; losing offers retry | Feras
- 2026-10-23 | Demo = level 1 (3D, paused); slice.md parked: 5 roofs, tayramana sole room, valve puzzles (walk up, interact) | Feras
- 2026-10-21 | Currency: riyal; battle: party right, enemies left (3D camera, paused) | Claude
### Heroes and combat
- 2026-10-25 | Zayd renamed Rydan; Neon Glitch only for now (older lines here say Rydan) | Feras
- 2026-10-22 | Jambiyah (not djanbeyyah; old save key migrates): two parts, hilt and blade, each upgraded or swapped separately | Feras
- 2026-10-22 | Prosthetic: one per hero; tech moves paid from SP; Jambiyah stays the weapon; Rydan's cast clips mirrored | Feras
- 2026-10-21 | Ambush: Jambiyah reverse stab before battle; Rydan from behind on a patrol = party head start | Feras
- 2026-10-21 | Rydan's default skin wears the grandfather's Jambiyah hilt (grandfather_hilt), drawn to strike | Feras
- 2026-10-24 | Hilt stones: grandfather hilt 3 slots (open by story 1 -> 2 -> 3); other hilts fewer by rarity (Common 0); stones bought at the bench or found, free removal; hero ring, 1-2 gem sockets | Feras
- 2026-10-23 | Rydan's kit (zayd-moves.md): a combat job per move; ATK split across multi-hit moves so SP beats the free strike | Feras/Claude
- 2026-10-24 | Bilqis: rivet pistol; frame and barrel upgraded like Rydan's hilt and blade | Feras
- 2026-10-21 | Rarity: Common to Legendary (white, green, blue, purple, gold); Heirloom tier story-only | Feras
- 2026-10-24 | Combat: RPG layer (XP, levels, fixed class per hero, Luck, dodge/crit/resist; no flee vs bosses); battles on the map; timeline kept | Feras
- 2026-10-23 | Abu Nabil, a 40-year-old herb seller (R2, no patrols): optional haggle; spice-cloud fight, qishr cures; fair prices; risk-free rematches | Feras
### Art and audio
- 2026-10-24 | 2D: isometric ink-comic per concepts; old Sana'a at night (tower-houses, moon, stars, clouds, fog), neon accents, 2150 megacity on the horizon, rain, qamariya glow at the heart; characters: offline 3D renders as sprites, none at runtime | Feras
- 2026-10-21 | 3D inputs: A-pose pictures (arms 30-45 deg down), flat light, grey background; CC0 motion, no Mixamo | Feras/Claude
- 2026-10-22 | Motif: Jambiyah hook; smoke, dust, slashes, UI corners, logo curl into it; party hooks left, enemy right | Feras
- 2026-10-24 | Music: Yemeni fusion (Flow); battle, battle_2, battle_3; no menu or merchant tracks (area music plays); music to be redesigned for 2D | Feras
- 2026-10-21 | Art budget $0: free tools, CC0/OFL packs, Gemini and Flow outputs; no paid artist or packs; free assets: manifest entry, owner OK to download | Feras
### UI and text
- 2026-10-25 | Title "Neon Glitch"; start: menu -> qamariya -> pick hero -> blur zoom: brief + Normal/Hard -> reaction -> blur pull-back -> game | Feras
- 2026-10-25 | UI English + Musnad accents, world Musnad only; motion blur hides AI-video flaws; looped sound | Feras
- 2026-10-22 | Writing: world signs in Musnad only (Noto Sans Old South Arabian, OFL); no Arabic script | Feras
- 2026-10-21 | Dialogue: chest-up painted portrait by text box; 4 expressions (neutral, happy, angry, surprised) | Feras
- 2026-10-23 | Menus: equipment menu (3D hologram hero, paused); workshop = upgrade, gemstones, crafting; pause over backdrops; holo map | Feras
- 2026-10-24 | Menu keys: Q/E (LB/RB) switch hero; Tab/Shift+Tab (LT/RT) and clicks switch Equipment/Items/Map tabs | Feras
