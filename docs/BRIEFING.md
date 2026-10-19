# Briefing: the HD-2D timeline RPG (2026-10-19)

For Feras. What we are building, how, what it will cost in time and tokens, what to install, and the open questions.
Written by Claude (Opus 5.5, `claude-opus-5-5`) in session 1. Estimates are ranges; they get recalibrated from
real usage after the first three build sessions (docs/USAGE.md).

## 1. What we're building
A 30-minute Chapter 1 vertical slice of an HD-2D RPG: pixel-art characters in small 3D diorama worlds with
miniature-style depth of field, a Grandia-style timeline battle system (choose an action, charge it, interrupt
enemies who are charging), set in a cyberpunk futuristic Sana'a, Yemen (owner decision;
see docs/design/world.md). After the slice, you decide whether to make a full game.

Gemini's research is a good start: Godot, headless tests, typed code, a data-driven combat design, a strong world
and a minute-by-minute slice plan. It also has problems: invented statistics (the token numbers have no source),
a WSL2 requirement we don't need, process rules that waste tokens (one file per commit), a data design with a real
bug (all enemies of one kind would share one HP bar), a frame-rate-dependent battle clock, and a 2D renderer
instead of true HD-2D. Some lore needs a check: the khopesh is an Egyptian sword, and Hojari and Najdi are modern
Omani frankincense grade names. Details: docs/ARCHITECTURE.md, section 16.

## 2. Decided today
True HD-2D (3D world, 2D sprites); $0 art budget (Gemini Pro, Google Flow, free tools, free packs); slice first;
Claude Pro. Claude's technical calls (you can veto any): Godot 4.7.2 with typed GDScript; content in JSON;
combat on a fixed-tick integer timeline; no WSL2; Claude works in cloud sessions, you play on your laptop.
All logged in docs/DECISIONS.md.

## 3. What exists now (built and checked today)
- A Godot 4.7.2 project: core services (event bus, save state, content database), the combat timeline and
  formation rules with tests, sample content (Malik, Thurya, a Syndicate halberdier, four actions, two statuses).
- An HD-2D look test: a block diorama with a placeholder character, depth of field, bloom, shadows, FPS counter.
- One check command (`tools/check.sh`): docs, code rules, Godot import, 11 tests. All pass.
- The token-saving system (docs/EFFICIENCY.md) wired into CLAUDE.md, HANDOFF.md, a /handoff skill, a session hook,
  read-deny rules for generated files, and a CI workflow that runs the checks on every push.

## 4. Roadmap to the slice
| Milestone | What you'll see | Claude sessions |
|---|---|---|
| M0 Foundation | This; CI green on GitHub | 1-2 |
| M1 Look + art spike | The look tuned on your laptop; one Gemini character as a pixel sprite in it; art bible | 4-6 |
| M2 Exploration | Walk around a greybox area, talk, read a stone, change areas, save/load, gamepad; Windows build from CI | 8-10 |
| M3 Combat | Full timeline battles: menus, AI, interrupts, rows, statuses, victory/defeat; balance harness | 12-16 |
| M4 Story systems | Dialogue, lore stones, items, waterskin, resin drops, trust bonds | 6-8 |
| M5 Puzzles | Counterbalance sluice and twin-weir puzzles | 4-6 |
| M6 Asset production | Characters, enemies, block kits, portraits, UI through the pipeline | 6-10 |
| M7 Chapter 1 levels | Five areas, greybox then dressed | 8-12 |
| M8 Audio | Music moods, stingers, sound effects | 3-5 |
| M9 UI and juice | Title, menus, settings, hit-stop, shake, particles, theme | 8-10 |
| M10 Playtest and ship | Bug fixing, performance on your laptop, a slice build | 8-12 |
| **Total** | | **about 70-100, plus ~20% rework = 85-115** |

## 5. Token and money estimates
**Per session** (one feature, Sonnet, 40-70 tool calls): about 2-5 million input tokens processed (about 95% of
them cheap cache reads) and 40-90 thousand output tokens. At API prices that is about $1.50-3.50 for Sonnet 5.5,
$3-6 for an Opus 5.5 design or review session, and well under $0.50 for Haiku 5.5. This founding session (Opus,
large) is roughly $8-15 of API-equivalent usage, the most expensive kind; such sessions should be rare.

**Slice total:** about 85-115 sessions, roughly 300-500 million tokens processed and 5-9 million output tokens:
about **$200-400 at API prices**. On Pro you pay **$20 a month** instead; the cost is time, because the 5-hour
window and weekly cap (shared with reem-bot and feras-career) limit how many sessions you get.

**Calendar:** planning on 1 build session per 5-hour window and 5-8 sessions a week, Claude's part takes about
11-23 weeks. With your art work and playtests in between, the slice takes about **5-8 months part-time**. Max 5x
($100/month) for a heavy month (combat, levels) would shorten that; it is optional.

**Your own time for the slice:** art generation and cleanup 100-200 h (the free route moves cost from money to your
time), playtesting 20-40 h, answering questions and reviews 15-30 h, story and lore review 10-30 h: about
**150-300 hours**, or 6-10 hours a week.

**Money for the slice:**
| Item | Cost |
|---|---|
| Claude Pro, 5-8 months | $100-160 |
| Gemini Pro / Google Flow | already yours |
| Godot, Blockbench, Pixelorama, Audacity, GitHub (private repo, 2,000 free CI minutes a month) | $0 |
| Free asset packs (Kenney, Quaternius: CC0) and fonts (Google Fonts: OFL) | $0 |
| Later, only if you sell on Steam: Steam Direct fee | $100 per game |

**A full game after the slice:** systems are reused, content is not. A short game (5-10 h) is about 3-5x the
slice's work: roughly 2-4 years part-time on Pro, sooner on Max. Decide after the slice, with real numbers.

## 6. Prerequisites: what to install on Windows 11
**Must have (free):**
1. **Godot 4.7.2, Standard version** (not .NET): godotengine.org/download/archive/4.7.2-stable. It's a zip: unzip to
   `C:\Tools\Godot\` and run the .exe. No installer.
2. **GitHub Desktop**: desktop.github.com. Sign in, clone `ferasalm/game` to `C:\dev\game`. Keep the project out
   of OneDrive-synced folders (Documents, Desktop): sync fights with Godot's cache.
3. **Laptop check**: Settings > System > About (processor, RAM) and Task Manager > Performance > GPU (graphics
   name). Send me those three lines.

**Recommended (free), install when the milestone needs them:**
- **Pixelorama** (pixelorama.org): pixel-art editing and sprite sheets (M1).
- **Blockbench** (blockbench.net): 3D blocks and props with pixel textures, exports glTF for Godot (M1).
- **Audacity** (audacityteam.org): trim and loop audio, export OGG (M8).
- **VS Code** (code.visualstudio.com): read docs and diffs comfortably (any time).
- **Python 3.12+** (Microsoft Store): only if you want to run the art scripts yourself; otherwise Claude runs
  them in the cloud on files you upload.
- A **gamepad** (any Xbox-compatible one) if you have one, for testing controls (M2).

**Not needed:** WSL2/Ubuntu (Gemini's plan), Unity, Aseprite (Pixelorama is free), a local Claude Code install
(keep using Claude Code in the app; a local install can come later if we need your GPU for screenshots).

**Your first run:** open Godot > Import > `C:\dev\game\project.godot` > Edit, then press **F5**. You should see a
small checkered diorama with a blocky figure, blurred near and far edges, and an FPS number in the corner.
Send a screenshot and the FPS.

## 7. The $0 art plan
- **Style first (M1):** Gemini makes concept sheets; we fix a palette (about 32-48 colors), 16 px per meter,
  characters about 32 px tall, light from the upper left. Every later image is forced onto that palette by script,
  which is what keeps AI art consistent.
- **Characters:** Gemini (image model, with a reference picture of the character for consistency) draws front,
  side and back poses; `tools/art` shrinks them to pixel size on the palette; you clean details in Pixelorama.
  Animations use few frames (idle 2, walk 4, attack 3-4, hurt, down), like Octopath's. For motion, Flow can make
  a short video of the move; the script cuts it into frames to trace from.
- **World:** Blockbench blocks with pixel textures (AI-made, palette-locked); Kenney and Quaternius CC0 kits as
  placeholders and base shapes.
- **Portraits and UI:** Gemini; pixel or painted style decided in M1.
- **Fonts:** free OFL fonts, including Noto Sans Old South Arabian for Musnad inscriptions.
- **Music and sound:** Gemini/Google music generation if your plan includes it; otherwise CC0 and CC-BY music and
  sounds (credit them), and jsfxr for retro effects. Avoid "non-commercial" licences (e.g. some free tiers of music
  generators) so a later sale stays possible.
- **Records:** every asset gets a manifest entry (source, licence, prompt). Steam asks you to disclose AI content.

## 8. Top risks and what we do about them
| Risk | Plan |
|---|---|
| Animated characters at $0 (AI can't keep frames consistent) | Spike one character in M1; few frames; motion by tweens; fallback: credited CC-BY-SA base sprites |
| Pro limits slow the calendar | Lean sessions, Sonnet by default, usage ledger; a Max month if needed |
| Laptop GPU too weak for HD-2D effects | Look test FPS now; baked light; Mobile renderer fallback |
| Godot 4.7 is newer than Claude's training | Pinned version; strict parser and tests catch wrong APIs; lessons logged |
| Scope creep | Slice only; every new feature needs a dated decision |
| Licences and AI disclosure | Manifest from day one |
| Separately generated music layers don't line up | Switch moods on the beat; layers only from one split track |
| Historical and cultural accuracy | Your review of world and names before the design docs are final |

## 9. Questions for you (answer by number; "default" is fine)
1. Your laptop's processor, RAM and graphics, plus the look test's screenshot and FPS.
2. Gemini's world (pre-Islamic South Arabia, water and frankincense) and cast (Malik, Thurya, Muqaddam Dharib):
   keep, change, or replace? Default: keep as the base and fix lore errors.
3. Grandia-style timeline battles with interrupts as the core: keep? Default: yes.
4. Arabic language: at launch, later, or never? Default: English first, Arabic later (the code is ready for it).
5. May each session merge its checked work into `main` at the end (as in feras-career)? Default: yes.
6. A working title? Default: "Qarnaw" (from Gemini's pass).

## Sources checked today
- Godot releases: 4.7.2-stable downloads from GitHub (4.7.3 and 4.8 don't exist yet); [Godot release blog](https://godotengine.org/blog/release).
- Claude API prices per million tokens (input/output): Opus 5.5 $4/$20, Sonnet 5.5 $2/$10, Haiku 5.5 $0.10/$0.50;
  cache reads $0.20 for Opus and Sonnet (Claude API reference, cached 2026-10-06).
- Plan prices (Pro $20, Max $100/$200; limits unpublished): [zenken comparison](https://ai.zenken.co.jp/en/post/claude-pro-vs-max-comparison/),
  [Superblocks](https://www.superblocks.com/blog/claude-code-pricing). Verify at claude.com/pricing.
