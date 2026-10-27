# Process audit plan: how the game studio works (approved by Feras 2026-10-27)
Source of truth for P1-P4; checklist: docs/audits/2026-10-27-plan-checklist.md.

## Context
You asked to make sure every bottleneck, lesson and bug from the overnight run is remembered, and to audit and
reorganize how we work. Inputs: the retro, three Haiku audits (rules, scripts, skills plus start cost), one web
research pass (sources below), and your 12 extra points. This plan is also the brief for the chats that build it.
Your earlier answers: tidy ~/.claude too; hand off on work tokens.

## Your points, and where each is solved
| Your point | Solved by |
|---|---|
| Efficient iterations and testing, a solid foundation | Iteration loop (Operating model 3); foundation milestone M1 in VISION |
| Vision, mission, objectives; no drift, open to additions | VISION stack (Operating model 2); canon reviewer; changes only by logged decision |
| Reuse the 3D archive where it fits | Lookup only: before building a feature, the spec step greps docs/archive/3d-reuse.md once. Reuse only if we want that exact thing and it is ready; no reuse work otherwise |
| Real-time Hades combat, linear story, phones, success and money, research by others | D15-D18; Market and player department (section 15); research protocol (section 5) |
| Accurate builder prompts, strong tests, no deception | Builder playbook + protected tests + gate + reward-hack reviewer (Operating model 4) |
| Tests and assets Do NOT edit; gate rejects removed checks | Confirmed by you; P1 items 5-6 |
| Research and best practices; each session better than the last | ops-review every 5 sessions with a research scan; one improvement per handoff |
| Departments and roles | Operating model 1: departments as skills plus reviewer agents, not always-on chats |
| Docs always at their caps | Lesson lifecycle, sharding by department, DECISIONS/CANON split, warning at 75% |
| Structural issues not yet looked at | List S1-S8 below |
| Reviews from several perspectives | Review panel: 4 Haiku lenses |
| Skills to add, use, retire | Skills table below |
| Protocols for every session | docs/WORKFLOW.md protocols (Operating model 5) |

## What the audits found (top 10)
1. **Start cost.** Every chat starts at ~89k tokens before any work. The repo notes are only ~9k of that. The rest:
   connector tools ~22k, Claude's tools plus the agent list ~35k, skills ~8k.
2. **The builder roster is said four different ways.** CLAUDE/HANDOFF/memory: 5 runs with Inkling. DECISIONS:
   2 agy, 3 DeepSeek, 1 GLM. slots.sh: 2/3/0. Retro: 2 + 1 Godot. The GLM slot cannot launch.
3. **slots.sh run from any worktree reports 0 runs.** It looks in the wrong folder (checked: it printed 0/2 0/3 0/0).
   The pipeline never calls it, and nothing checks free memory, which is why the PC froze.
4. **BREACH does not fail a run.** build_pipeline.sh always exits 0. The gate reads only added lines, so a deleted
   assert is invisible. Assets are protected only when a brief lists them (15 of 74 briefs).
5. **Launches are unsafe.** The pipeline does not check that the base is pushed. There is no idle watchdog (agy sat
   55 min). agy/oc runs have no `< /dev/null` or outside timeout.
6. **Tool bugs.**
   - map.py lists untracked files (the CI failure).
   - check.sh's tool tests stop at the first failure.
   - The spend log reads an overwritten log (19 of 21 rows are "?").
   - The session hook reports C:\dev\game, not the session's worktree.
7. **Three skills route work to retired models** (GLM, Gemma, Nemotron). emergency-efficiency lets builders push
   to main, against GEMINI.md.
8. **Tonight's routes are written nowhere usable.** Flow JS, the Rodin call order, and the bake batch (only in a temp
   folder; saved below). There is no acceptance list, so nobody played the build the way you do.
9. **Stale and mixed lines.** "Qarnaw", "2.5D action RPG", 3D lines marked "paused", the Rydan/Zayd line,
   BRIEFING.md (10-19) read as current, a TEMPLATE base branch that does not exist.
10. **Docs at their caps.** LESSONS is at 100/100 and DECISIONS at 67/70: half of it is how-to for one route.
Cost note: the three Haiku audits used ~15% of the 5-hour window. Audits get narrower briefs from now on.

## Structural issues found
- **S1** docs/design/ mixes 30 files from the 3D era and today, with no status → index with a status per file;
  retired files move to docs/archive/design-3d/.
- **S2** Claude's code rules (CLAUDE.md) and the builders' rules (GEMINI.md, AGENTS.md) are copies that drift → one
  `.claude/rules/code.md` with `paths: ["**/*.gd", "**/*.tscn"]`. It loads only when Claude touches code (an
  @-import would load in every chat), and build_pipeline pastes it into builder prompts. GEMINI.md and AGENTS.md keep
  only builder-specific lines.
- **S3** Several chats share C:\dev\game, which holds someone's uncommitted work → no chat edits there; worktrees
  only; the main checkout is for your play and for builder launches.
- **S4** 19 builder worktrees are left in C:/dev/game-wt (cleanup only on merge) → tools/wt_clean.sh removes
  merged and dead ones.
- **S5** HANDOFF still carries tracks for paused and retired work, and idle sessions stay open → /handoff archives
  finished tracks; ops-review proposes archiving idle sessions.
- **S6** Your playtest notes have no tracker → docs/playtest/<date>.md with a status per note (the 25 from 10-27
  first).
- **S7** Paid calls are logged in three places (cf_spend.csv, USAGE, manifest) → one docs/SPEND.md line per paid
  call, Rodin included.
- **S8** API keys: .gitignore has no .env rule → add it. Keys live in user env vars, named (never valued) in the
  art skill.

## Operating model

### 1. Departments
Each department is one skill plus one reviewer agent, not an always-on chat. An always-on chat would pay ~89k
tokens of start cost on every turn.

| Department | Its skill(s): charter, playbook, own lessons | Reviewer lens | Measure |
|---|---|---|---|
| Producer (the orchestrator chat; you direct) | builders (brief, launch, gate, review, merge) | n/a | features merged per % of window |
| Ops and efficiency | ops-review (every 5 sessions, or at 50% of the window) | review-cost | start cost, stalls, breaches, window per feature |
| Art and assets | flow-media, 3d-model, sprite-bake; art bible; accounts and keys named | review-player | your art notes per build |
| Gameplay (design and code) | builders + spec; game-designer, level-designer, godot-gameplay-scripter personas | review-code | bugs you find per build |
| Narrative | narrative-designer persona + bible; a pass on every player-facing line | review-canon | text notes per build |
| UI and menus | ui role card; docs/design/ui.md style guide; rpg-menus.md | review-player (UI half) | legibility notes from you per build |
| QA, the player's eye | players-eye-gate + F12 capture | review-player | items passed before you play |
| Market and player (business, marketing, player psychology) | market-player skill; role card from Business Strategist, Product Manager, UX Researcher, Behavioral Nudge Engine, Persona Walkthrough Specialist, Feedback Synthesizer | review-market | outside-playtest scores, wishlists, comparable titles |

Each department's lessons live in its skill folder (`lessons.md`), read only when that department works. Global
LESSONS keeps cross-cutting traps only.

### 2. VISION stack against drift
- docs/VISION.md (<= 60 lines): vision, mission, 3-5 pillars, objectives with measures, and a roadmap.
- The roadmap is milestones M1..Mn, each with a definition of done. Your retro directions and the
  market brief (section 15) go under them.
- You edit VISION; it changes only by a logged decision.
- CLAUDE.md carries a 3-line north star.
- Every spec and brief names the pillar it serves; review-canon flags drift.
- M1 = foundation pass: colour sprites with smooth motion, light layers, VFX/SFX hooks, a legible UI theme, the
  walk mask, then the 25 notes.

### 3. Iteration loop (each feature)
1. A spec with acceptance tests (Opus) and a timebox.
2. Claude or Haiku writes the failing tests first; they are protected.
3. Builders, at most 2, build.
4. Gate, then the review panel, then the player's-eye gate.
5. You play.
6. Your notes go to docs/playtest/, then the next loop.

### 4. Builder playbook (in the builders skill and TEMPLATE)
- **Per-builder profile from what we saw.**
  - agy: strong on UI code with renders. Stalls on baseline checks, so give it a first-commit deadline. Misses
    what a player sees.
  - DeepSeek: steady on code. Edits outside its scope (it shrank Rydan), so protected paths.
  - Neither builder judges legibility or feel.
- **Brief rules.**
  - Exact files and functions.
  - Numbers and keys come from content.
  - One skill named.
  - First commit within 15 min.
  - WIP commits.
  - The tests to make pass are named.
- **Anti-deception.**
  - Tests are written before the build and are read-only.
  - The gate fails any edited or removed test, assert or asset unless the brief lists it under "May edit".
  - New tests must fail on the base commit.
  - review-code checks for hard-coded expected values, test-detection branches, stubs/TODO, skipped asserts.
    Research says an LLM judge catches hacks best, and that held-out tests add little.
- **Cost.**
  - Claude reads only the .result verdict line and the panel's findings (<= 15 lines each).
  - Merges run on Sonnet.

### 5. Protocols (one home: docs/WORKFLOW.md, renamed from EFFICIENCY.md)
- **Start.** The hook prints sync for this worktree. Then the HANDOFF line, then get_usage.
- **Brief.** TEMPLATE.
- **Build.** slots → pipeline.
- **Review.** Panel of 2 lenses for small runs, 4 for anything that reaches you.
- **Eye gate.** Before you play.
- **Handoff.** At ~100k work tokens; it records one improvement made and one proposed.
- **ops-review**, every 5 sessions (research is never run by Claude: section 16):
  - usage trend and start cost;
  - promote lessons to checks;
  - condense the notes on schedule;
  - research prompts dispatched from the department queues, digests read (section 16);
  - archive idle sessions.
- **Lesson lifecycle.** A lesson gets added, then promoted to a test, tool, hook or skill line, or archived after
  30 days unused. The rule from the Claude Code docs: a rule the agent keeps breaking becomes a check.

### 6. Skills: add, use regularly, retire
- **Add.**
  - builders
  - flow-media
  - 3d-model (Rodin now, free route later)
  - market-player
  - sprite-bake
  - players-eye-gate
  - ops-review
  - 6 reviewer agents in .claude/agents (`model: haiku` or the calibrated reader): review-code, review-player, review-canon,
    review-cost, review-market, review-feras
- **Use regularly.**
  - handoff: every chat.
  - Review panel: every builder PASS.
  - players-eye-gate: every build that goes to you.
  - ops-review: every 5 chats.
- **Manual only (`disable-model-invocation: true`, so their description costs nothing at start):**
  - handoff
  - emergency-efficiency
  - ops-review
- **Retire.**
  - architecting-, coding- and debugging-games (they merge into builders).
  - 5-run nights.
  - An orchestrator that does browser or art work.
  - Max-effort audits that read whole doc sets.
  - Condensing at every handoff.
  - Opus merges.
  - Judging art from stills.
  - BRIEFING.md as a live doc.
  - Model swaps without a test: every new model or effort level goes through calibration first.
- **Look at, do not install blind.** "Claude-Code-Game-Studios" (third-party studio-role skills). The gdUnit4
  scene runner for player-input tests.

### 7. From your links (code.claude.com best-practices, large-codebases, sub-agents, hooks, skills; awesome-gamedev-agent-skills; developersdigest; Gemini doc read as data)
- Reviewer agents: `.claude/agents/review-*.md` with `model: haiku`, `tools: Read, Grep, Glob`, `maxTurns: 8`,
  `effort: low`, `omitClaudeMd: true` (each lens carries its own rules; measure first), a `description` (files
  without one are skipped silently). They flag only correctness and stated-requirement gaps; review-fix loops stop
  after 3 rounds and escalate.
- Skills: department skills get `paths:` globs where they fit (art: assets/**, tools/art/**); ops-review runs with
  `context: fork` + `agent: Explore` so its heavy reads stay out of the chat. Correction: disable-model-invocation
  does not remove a skill's listing; manual skills go to `skillOverrides` "name-only" (P3 verifies the syntax).
- CLAUDE.md: the line test ("would removing it cause a mistake?"), <= 200 lines, IMPORTANT on 2-3 lines only.
- Measure start cost with `/context` and an InstructionsLoaded hook log, not estimates.
- Read-deny binaries in .claude/settings.json (`Read(./assets/**/*.glb)`, wav/ogg/mp4); deny rules and hooks bind
  only Claude, so builder protection stays in the gate. Blocking hooks must exit 2.
- Godot: every fresh worktree runs `--import` before tests (pipeline does it); a boot smoke run
  (`--headless --quit-after 120` on the main scene) joins check.sh; builders are told bare assert() can hang headless.
- Art: one approved hero asset at native scale before any batch spend; eye_metrics checks alpha and colour caps.
- Prototypes: a spec asks one question with a 30-90 min timebox; spikes never merge. acceptance.md gets a fun line:
  a new player does the core action unprompted within ~30 s.
- P0 VISION is an interview (AskUserQuestion rounds), then the doc. Feras tip: `/btw` for side questions.
- Skipped: Stop hook running check.sh every turn (cost), agent teams (experimental), Godot MCP servers (unvetted),
  the doc's 3D-specific rules. Not readable: the Reddit thread (blocked); the Gemini doc's numbers are unverified.

### 8. UI and menus: where they live
- Today UI is spread across DECISIONS (UI lines), docs/design/ui.md, rpg-menus.md and a half-paused HANDOFF track.
  Nobody owns legibility, which is why the fonts were unreadable.
- New: a **UI and menus department**.
  - Home: docs/design/ui.md, rewritten as the UI style guide. Fonts and minimum sizes at 720p, contrast,
    colour roles (no pink/cyan on white), the jambiya-hook motif, the dialogue box and portrait rules.
  - docs/design/rpg-menus.md holds the menu flows.
  - The DECISIONS UI lines move to CANON.
  - The personas ui-designer and ui-finish-gate-reviewer become its role card.
  - Its checks sit in the eye gate (font size, contrast) and in review-player's UI half.
  - The menus get reskinned to the Neon look in M1, after the style guide.

### 9. Agency agents: keep, replace, retire
- **What we use.** The builder prompts use 6 of the 20 generic personas plus 7 of the 8 game personas. Claude
  itself almost never loads them. They are long (8-26 KB each), generic, and know nothing of our rules or failures.
- **Replace.** Over time, a short project role card (<= 60 lines) for each department replaces the generic persona.
  It holds:
  - the persona's useful core;
  - our code rules;
  - our builder failure modes;
  - the department's checks.
  Cards are written from the persona with a Haiku pass and kept in .agents/skills/<card>. build_pipeline pastes the
  card, not the 15 KB persona: a better fit, and cheaper prompts.
- **Keep, as card sources.**
  - godot-gameplay-scripter (40+ briefs)
  - technical-artist
  - level-designer
  - godot-shader-developer (light, ink, VFX)
  - game-designer
  - narrative-designer
  - game-audio-engineer (SFX now needed)
  - ui-designer and ui-finish-gate-reviewer
  - minimal-change-engineer
  - code-reviewer (seeds review-code)
  - image-prompt-engineer (seeds flow-media prompts)
  - cultural-intelligence-strategist (seeds review-canon: Sana'a authenticity)
- **Retire** (to .agents/archive/; reversible): workflow-architect, codebase-archaeologist, codebase-onboarding-
  engineer, devops-automator, feedback-synthesizer, git-workflow-master, mcp-builder, prompt-engineer, rapid-
  prototyper, technical-writer, ux-architect, software-architect, test-results-analyzer, performance-benchmarker.
  Kept on your word: blender-addon-engineer, the Blender MCP and Blender-related tools.
- **User-level.** In ~/.claude/agents (56 general agency agents: business, LinkedIn, video...), game chats use none.
  They go to ~/.claude/archive (D7).

### 10. Critique of v2, and what this version adds
- **There was no baseline, so no gain could be proved.** → P1 first records a baseline in USAGE: /context start
  cost, window % of the last 3 sessions, .result verdict counts, and 25 notes from you per build. ops-review compares
  against it.
- **The reorganization could eat the window itself (4-5 chats).** → Budget: P1 and P2 each <= 20% of a window, P3
  <= 15%, P0 an interview of about 10%. Opus only for P0. Narrow briefs; no max-effort full-doc audits.
- **Risk of changing the pipeline while builders depend on it.** → P1 dry-runs the new pipeline on a toy brief
  before any real run, and keeps the old one until then.
- **Bureaucracy risk.** → Start with 6 departments as skills, not 6 chats. ops-review skips itself when nothing
  changed. Each department card stays <= 60 lines.
- **"Hades-level" was a slogan with no technical route.** → P0 gets an M1 tech spike: re-bake one character at full
  colour and 24-30 fps, a light pass on the roof (2D lights, normal maps), and hit feedback. It is judged by you.
  The Hades research digest feeds it (Appendix).
- **Your role was not written down.** → You decide, edit VISION, CANON and acceptance.md, and play only gated
  builds. You never debug or fetch files that a tool can fetch.
- **Builders cannot read .claude/skills.** → Department knowledge reaches them only through the role card and
  .claude/rules/code.md, which build_pipeline pastes.
- **Feature versions.** omitClaudeMd and some hook events need a recent Claude Code → P2 checks `claude --version`
  first.

### 11. Expected gains (rough estimates from tonight's numbers; ops-review measures the real ones against the baseline)
| Area | Estimate | Main reason |
|---|---|---|
| Claude usage per merged feature | 35-50% fewer tokens | Start cost 89k → ~60k per turn; chats capped at ~100k of work instead of 400k (long-chat turns ~40% cheaper); no rediscovery (~30 calls → ~3 per route); Claude reads verdicts and findings, not diffs |
| Speed to a build you can play | 25-40% faster | Idle runs killed at 15-20 min instead of 55; no PC freezes or stale-base reruns; fewer fix loops after you play. Offset: 2 parallel runs instead of 4 |
| Adherence and coherence | Most contradictions gone (~25 conflicting facts → ~0); off-brief edits caught by the gate, not by you | One place per fact, path rules, VISION and CANON, protected tests |
| Critical, well-rounded review | 50-65% fewer issues reach you (25 → ~9-12 per build) | 4 review lenses + eye gate; the retro shows most of the 25 were visible to a player's-eye check |
| Reusable workflows | 4 routes + the review panel become one-command skills | Flow, Rodin, bake and eye gate are written once and tested |
| Solid and reliable runs | Unattended runs that end usable: ~50% → ~80% | 6 known silent-failure paths closed, each with a test |
| Editable and updateable game | ~20-30% easier | Mostly in place already (content JSON); CANON, VISION, the UI style guide and acceptance.md give you one file each to edit |
| Autonomy without you | ~40% less of your time per feature | You play gated builds only; questions batched; routes need no help from you except Flow logins and spending |
These are judgment calls, not measurements. The first ops-review after 5 sessions replaces them with real numbers.

### 12. Hyper3D: ~50 credits, ~3 weeks left. Use them early, then a free route
**Week 1 (art chat right after P4):**
- One approved hero asset.
- Then a batch, in this order: the cast, recurring props, icons, the title video.
- Rigs and animation presets fetched for each.
**Before access ends:** prove the free route on one character and write it into the 3d-model skill. The free route:
1. Image to 3D with an open-source model on a free host (TRELLIS, Hunyuan3D or TripoSR on Hugging Face Spaces).
   Unverified: test one.
2. Or Blender MCP `search_assets` / `import_asset` from CC0 libraries (Poly Haven, Poly Pizza; Sketchfab only with
   a licence check).
3. Rig with Blender Rigify, then our retarget (ModelRig) and the Godot bake.
**Flow:** Nano Banana for images, Omni for video (title loop, VFX plates). Both are in the flow-media skill.
**Community assets first:** CC0 SFX (Freesound CC0, Kenney), CC0 VFX textures and fonts (OFL). Your OK before each
download (DECISIONS), plus a manifest entry. Research finds them before we make them.

Where the credits pay most:
1. Every recurring character: Zayd, Roya, the prison guard, Abu Nabil, enemies. Each is baked to colour + normal
   sheets, so all of them light the same way.
2. Recurring props as 3D: booth, floodlight, qamariya window, umbrella. They are rendered as sprites with real masks
   and normal maps. This fixes "the occluder looks pasted", and the floodlight gets a true on/off.
3. Item and head icons from the same models. This unblocks the icon art that is waiting on you.
4. More animation clips via the rigging animation presets (rodin_list_animation_presets).
5. The title loop with Hyper3D video (your retro direction).

Credit rules (in the 3d-model skill):
- Name the cost before each job.
- One approved hero asset before any batch.
- Log every job in SPEND.md.
- Priority: assets with many uses come first.
- Blender MCP handles decimation, normal bakes and the ink hull when Godot cannot.

### 15. Market and player department: will it succeed, will it earn?
- **Market brief in VISION.**
  - Audience.
  - Comparables (Hades, Transistor, Pyre; cyberpunk and Middle-East settings), each with price, scope and reviews.
  - The unique hook: cyberpunk Old Sana'a, Yemeni culture, the jambiya.
  - Platforms (PC first, Android, iOS) and price model.
  - A budget sanity line.
- **Success checks per milestone, cheapest first:**
  1. A persona walkthrough. An agent plays target players from captures and notes. Weak evidence, but nearly free.
  2. Outside playtests: 3-5 people per milestone (friends, a Discord, itch.io), with a 5-question survey and local
     run telemetry (deaths, quits, time to first kill).
     Bar: the fun line (the core action, unprompted, within ~30 s) and a fun score >= 4/5.
  3. Market signals once public: Steam wishlists, short clips of the art on TikTok or YouTube, then a demo at Steam
     Next Fest.
  Claude never posts or signs up for you (CLAUDE.md): the department drafts and you publish.
- **It helps the other departments with:**
  - first-session psychology (onboarding, difficulty curve, reward timing) for gameplay;
  - "what sells" references for art;
  - hook and pacing for narrative;
  - store-page and trailer plans.
- **Lens:** review-market runs at each milestone build, not on every code run.

### 16. Research and department evolution (D18): everyone except Claude
- Each department keeps `research-queue.md` (open questions) and an upgrade log in its skill folder.
- When a queue holds 3 or more questions, or at ops-review, Claude writes one prompt per question:
  - a big question → a Gemini Deep Research prompt (Argon High) for you to run and share as a doc;
  - a small lookup → opencode + OpenRouter :free with web fetch, or agy;
  - a code or tool question → Cloudflare DeepSeek.
- Results go to docs/research/<department>/<date>-<topic>.md, marked unverified.
- The calibrated free reader digests each into <= 30 lines: adopt / adapt / skip, with sources. Claude reads only
  the digest, then updates the department card, its lessons and its tools.
- One department gets a deep upgrade at each ops-review, in rotation, so the system itself improves every week.

### 17. Claude as your advisor and systems thinker (D21): mechanisms, not intentions
**Advisor duty (CLAUDE.md, always loaded, 4 lines).** Claude:
- checks every request and decision against VISION and our goals;
- warns, critiques and offers a better alternative with a recommended default, even on design;
- helps shape the vision;
- asks batched multiple-choice questions whenever intent, edge cases or details are vague, before building.

**Dependency map.** docs/design/systems-map.md: how the pieces connect. Examples:
- a portrait appears in the dialogue box AND the menus;
- a light touches the plate, the sprites (normal maps) and the props;
- a combat change touches balance, VFX/SFX, UI and save.
Every spec and brief gets a "Ripple" section: what else this change touches, and where else each asset appears. The
reviewers check it.

**Player-visible tests.** TEMPLATE requires tests on what you would see, not only the simulation. Examples:
- the portrait's box sits inside the dialogue frame and the menu frame;
- each sprite sheet keeps full colour (colour count above a floor);
- a light changes the pixels around it, not just a rectangle;
- the combat win rate lands in the balance band over 200 simulated fights.
Every visual asset is checked in every context where it appears.

**Free route before paid, enforced.**
- A routes table in WORKFLOW: need → free route first (Flow Nano Banana/Omni, CC0 libraries, Blender) → paid
  fallback with its cap.
- A PreToolUse hook (exit 2) blocks paid generation tools (Runware, OpenRouter image/speech) unless the chat holds
  your OK for that job.
- It reminds before Hyper3D jobs to name the credit cost.
The Runware mistake cannot repeat silently.

**Your eye, without bias.**
- docs/feras-notes.md logs every correction you have had to repeat (cropped portraits, the light rectangle,
  black-and-white sprites, paid before free, unbalanced combat...). Each one becomes a check (lesson lifecycle).
- A `review-feras` agent with fresh context sees only the output, VISION, CANON, DECISIONS and that ledger. It runs
  before any plan or build reaches you, and asks: "What would Feras notice or object to?"
- A note you repeat twice becomes an automated check or a reviewer rule.

### 18. The Opus standard (D22): what "high level" must deliver
These go into CLAUDE.md as 4 lines that Opus and every model follow. Each one is checked by review-feras and by
ops-review.
- **Root cause, not patch.** Every bug fix states its cause chain in one line and fixes the class of the problem:
  a test, check, tool or rule that stops it coming back. A fix without that is incomplete.
- **Automate before asking you.** Before asking you to do something (fetch a file, run the game, download, check a
  screen), try every tool route: Chrome, Flow, Godot renders, playtest capture, scripts. Only logins, spending and
  matters of taste come to you.
- **Creative range.** Design questions get 2-3 distinct options, one of them bold, each with its trade-off and a
  recommendation. Never a single safe default when the choice shapes the game.
- **Think before acting.** Before building: ripple, edge cases, your view as a player, and a 3-line pre-mortem.
  Before presenting: review-feras and a self-check against acceptance.md.
- **Leave the system better.** Every session ends with one concrete upgrade to a tool, check, skill or doc, recorded
  by /handoff. Opus effort high or above goes to vision, design, art judgment, root-cause debugging and plans;
  mechanical work goes to cheaper hands.

### 13. Pre-mortem: how this plan could fail, and the safeguard for each
| Failure point | Safeguard |
|---|---|
| A P-chat drifts from the plan or skips items | Each starts from the plan committed in the repo plus docs/audits/2026-10-27-plan-checklist.md (every item checkable by grep or a test). P4 runs a conformance pass: every item done, or deferred with a reason |
| The builder that builds P1 weakens the gate it is changing | Claude writes the gate's tests first and protects them. Sonnet reviews every gate and pipeline line. The dry run must BREACH on a planted test edit |
| A script edited while a builder runs breaks the run (a known trap) | Merge P1 only when slots.sh shows 0 runs |
| Windows specifics: `timeout`, killing the process tree, reading free memory from Git Bash | Each gets a test on this PC: coreutils timeout, `taskkill //T //F`, a PowerShell CIM read with a stub |
| A P-chat outgrows ~100k work tokens or the window runs out mid-package | Packages are sized below 20% of a window. WIP commits plus a notes file make every step resumable |
| ~/.claude tidy breaks your other projects | Moves only. ~/.claude/archive/MOVED.txt lists each file with a one-line restore. Nothing is deleted |
| A hook change breaks every chat | The hook never exits non-zero. It is tested from a worktree and from the main checkout |
| Free readers return wrong or incomplete input that misleads planning | Calibration first (P2 step 0). Below the bar → Haiku. The bar is re-checked at each ops-review |
| Skills exist but nobody invokes them | CLAUDE.md maps task types to skill names in one line. ops-review counts skill use from transcripts and retires the unused |
| Review panel cost creeps | 2 lenses for small runs, 4 for builds that reach you. Each returns <= 15 lines in <= 8 turns |
| Eye-gate metrics pass while the game still looks wrong | The metrics cover only what is measurable. Opus judges frames against acceptance.md. You stay the final gate |
| Caps fill up again | doc_check warns at 75%. The lesson lifecycle promotes or archives entries. ops-review condenses on schedule |

### 14. Where I would push back on your decisions
- **All sequential.** Safe, but about 2-3 windows pass before any game work. The P0 VISION interview uses your time,
  not builders, and touches only VISION.md, so it could overlap P1 at low risk. I follow your choice unless you say
  otherwise.
- **Running many chats at once (corrected after your question).** The cap is on chats working at the same moment,
  not on chats in total. A chat past ~100k work tokens hands off; its successor takes its place, so no slot is held
  by a bloated chat. Every working chat re-sends its whole context each turn, so 4 chats at once burn the window
  about 4x as fast. The rule: at most 2 working at once; idle and finished chats don't count; a chat past the line
  hands off instead of waiting.
- **Private before release.** Until then the story bible, concept art and the system are public, and free models
  may train on them. Acceptable for now. Two risks: a Steam page or devlog draws eyes earlier than "release"; and
  CI minutes shrink once the repo is private. Decide the date when the first public demo is planned.
- **Real-time combat plus phones.** Real-time combat on touch screens is the hardest control problem in the plan.
  The M1 spike must play on your phone before more combat content is built.
- **Emergency mode at 50%.** It was set from one incident. Once ops-review has data, set the trigger from measured
  burn rates.

## Target structure: one place per fact
| Layer | Holds | Files |
|---|---|---|
| Always loaded (<= 27 KB, aim 20) | Rules every chat needs, north star, state, process decisions, cross-cutting traps | CLAUDE.md, HANDOFF.md (<= 8 lines per track), DECISIONS.md (process, engine, scope), LESSONS.md (~50 lines) |
| On demand | Protocols and limits; game canon; vision | docs/WORKFLOW.md, docs/CANON.md (world, heroes, art, UI decisions; read before any content work), docs/VISION.md |
| Path rules | Code rules, loaded only when code is touched | .claude/rules/code.md |
| Skills | Department playbooks, each with its own lessons.md | listed above |
| Config | Numbers that tools enforce | tools/builders.conf: MAX_RUNS=2 (Godot runs), AGY=2, CF=2, OC=1 (text only, no Godot), MIN_FREE_MB, IDLE_MIN, CHECK_SLOTS=2 |
| Archive | History, never loaded | decisions-archive, lessons-archive, docs/archive/ (BRIEFING, design-3d) |
| Memory | Only what the repo cannot hold | 2 files |

doc_check warns at 75% of every cap, so condensing happens in ops-review, not in the middle of a task.

## Decisions this plan changes (approving the plan approves them; logged verbatim)
- **D1 Builders.**
  - Godot code: agy and Cloudflare DeepSeek, at most 2 runs that run Godot, machine-wide, under a free-memory floor.
    Godot suites: 2 machine-wide.
  - Text work (docs, content drafts, research digests, role-card drafts) and calibrated review lenses: opencode and
    OpenRouter :free, 1 extra run (OC=1; no Godot). Within the 50 requests/day; public repo content only.
  - Claude's own tasks: the cheapest reader that passed calibration (free → Haiku low/high → Sonnet).
  - GLM and Kimi slots are removed.
- **D2** One builders skill replaces the 10-24 routing skills.
- **D3** Emergency mode never lets builders merge or push to main.
- **D4** Hand off at ~100k work tokens (get_usage Messages). Logged as your decision of 10-27.
- **D5** Player's-eye gate before any build reaches you. It is separate from check.sh.
- **D6** Tests and assets are Do NOT edit by default, with a "May edit" whitelist. The gate rejects removed
  checks. You confirmed this 10-27.
- **D7** ~/.claude tidy. Logged as your decision of 10-27.
- **D8** Departments as skills plus a 4-lens review panel. ops-review every 5 sessions.
- **D9** Lesson lifecycle, and the CANON split out of DECISIONS.
- **D10** No chat edits in C:\dev\game.
- **D11** Free models get text work and review lenses only after calibration. Big asks use narrow briefs, with
  readers chosen by calibration (Feras 10-27).
- **D12** The reorganization runs sequentially before game work: P1 → P2 → P0 → P3 → P4 (Feras 10-27).
- **D13** Hades look: spike first, then the art-budget decision (Feras 10-27).
- **D14** Hyper3D: ~50 credits and ~3 weeks left. Use them early, under the credit rules in section 12, and prove a
  free route before access ends. Blender stays. Flow gives Nano Banana (images) and Omni (video) (Feras 10-27).
- **D15** Combat becomes real-time like Hades now (feel, controls, mechanics). The story stays linear: not a
  roguelite, fun to replay, cheap to make. The turn-based battle code is archived and the 25 notes are re-triaged.
  This replaces the 10-24/10-26 turn-based lines (Feras 10-27).
- **D16** The repo stays public until before the first public release or demo, then goes private (Feras 10-27).
- **D17** Mobile from M1: the Mobile renderer (not Forward+), touch controls, UI sized for phones, an Android export
  in CI, a test on your phone. iOS later, with its costs as your decision (Feras 10-27).
- **D18** Research is done by everyone except Claude:
  - you, with Gemini Deep Research (Argon High);
  - opencode + OpenRouter :free with web fetch;
  - agy;
  - Cloudflare DeepSeek.
  Claude only writes the questions and reads digests of <= 30 lines (Feras 10-27).
- **D19** A Market and player department (section 15).
- **D20** The 3D archive is lookup only (Feras 10-27).
- **D21** Claude acts as your advisor and thinks about dependencies (section 17):
  - an advisor duty in CLAUDE.md;
  - the systems map and a Ripple section in every spec and brief;
  - player-visible tests;
  - a paid-tool hook;
  - the feras-notes ledger;
  - the review-feras agent before anything reaches you (Feras 10-27).
- **D22** The Opus standard (section 18) goes into CLAUDE.md (Feras 10-27).
  Work packages: the hook script and its test go in P1; review-feras goes in P2; CLAUDE.md, TEMPLATE, WORKFLOW,
  systems-map and feras-notes go in P3.
- Wording only: 3D lines change from "paused" to "retired"; the Rydan/Zayd line splits; the game is described as
  "2D isometric action RPG with real-time combat and a linear story".

## Work packages (each its own chat, in order P1 → P2 → P0 → P3 → P4, D12; each ends with check.sh green, a merge to main, and the next chat's paste-ready prompt in HANDOFF Efficiency)
**P0 VISION**: Opus, high. Already HANDOFF's Neon Glitch step 1.
- docs/VISION.md from the bible, DECISIONS, retro C, the market brief (section 15) and the 25 notes (re-triaged
  for D15 into docs/playtest/2026-10-27.md).
- You edit it.
- M1 holds the UI style guide (docs/design/ui.md, section 8) and the spike, judged on your phone and on PC:
  - real-time Hades-feel combat on the roof: move, dash, attack, special, cast, hit feedback;
  - the Mobile renderer with touch controls;
  - one character re-baked in full colour at 24-30 fps;
  - a 2D light pass;
  - an Android export in CI.
  The spike is game work for the first build chat after P4, not part of the reorganization.
- docs/research/hades-digest.md is saved from the Appendix.

**P1 Tool fixes**: Sonnet, medium. DeepSeek builds from a brief made of this list; each item gets a test that
fails today and passes after.
0. Baseline first, recorded in USAGE (Critique). At the end, a dry run on a toy brief before any real run.
1. tools/builders.conf + tools/lib.sh (paths, prefixes, python) are sourced by slots, check_slot, build_pipeline,
   cf_build, merge_run, agy_review, check. Their copied logic is deleted.
2. slots.sh: a total cap; a memory floor (Win32_OperatingSystem FreeVirtualMemory, stubbed in tests); it finds
   C:/dev/game-wt via `git rev-parse --git-common-dir`.
3. build_pipeline.sh:
   - Refuses when slots is full, or when local base != origin/base.
   - Writes the pid to the .result.
   - Idle watchdog: no commit for IDLE_MIN → kill, NOWORK.
   - `< /dev/null` on every child.
   - A non-zero exit unless PASS.
   - Pastes .claude/rules/code.md into the prompt.
   - Runs `--import` in each fresh worktree before tests.
4. agy_task.sh / oc_task.sh: an outside timeout. The oc default model = DeepSeek. Refuse to reuse a worktree with
   another base.
5. build_gate.py:
   - No "Do NOT edit" heading → FAIL.
   - The D6 protected set and the "May edit" whitelist.
   - A removed assert / test func → FAIL.
   - New tests must fail when run against the base.
   - *.import under assets/ counts.
6. cf_build.sh: spend is read from the saved build log. cf_mcp triage uses DeepSeek.
7. map.py: `--cached` only. check.sh: discovers tools/**/test_*.py, runs all, lists every FAIL, and adds a
   boot smoke run (`--headless --quit-after 120` on the main scene). check_slot.sh: a wait limit.
8. session-start.sh: uses $PWD and `timeout 15 git fetch`. New tools/wt_clean.sh (S4). doc_check.py: warns at 75%.
   .gitignore: .env.

**P2 Skills and reviewers**: Sonnet, medium.
- Step 0, calibration (D11). The gold set:
  - the 10 script defects from this audit, at pinned commit 1981e15, 5 of them verified by hand;
  - the neon-battle builder diff, with its known misses (model shrink, hair_texture).
  Run the same narrow brief on OpenRouter :free (2 models via opencode), Haiku low, Haiku high and Haiku max. Score
  recall, false claims, tokens and window %.
  Bar: recall >= 90% of Haiku max, and no false critical claim. The cheapest model that passes becomes the reader and
  lens model in WORKFLOW's routing table. The result goes to docs/research/calibration-2026-10.md.
- A Haiku subagent (or the calibrated reader) exports the coordinator transcript (local_09cce88c) and greps the exact
  Flow JS and the Rodin calls.
- The skills above (builders, flow-media, 3d-model, sprite-bake, players-eye-gate, ops-review, market-player), plus
  the reviewer agents (review-code, -player, -canon, -cost, -market, -feras). Each skill has a research-queue.md and a
  lessons.md, seeded from LESSONS §4/§5. bake_all.sh moves into tools/art/ with arguments, plus test_sprite_sheet.py.
- tools/eye_gate.sh: a --write-movie playthrough → contact sheet + mp4.
- tools/eye_metrics.py, with a test: fps and frames per clip, colours per sheet, smallest UI font.
- docs/design/acceptance.md (the Hades bar from retro B; you edit it). The reviewer agents.
- Agency agents (section 9):
  - The retire list moves to .agents/archive/.
  - The first three role cards (gameplay, art, ui) are written with a Haiku pass from their personas.
  - build_pipeline's skill paste finds cards by name, so no P1 file is touched.
- Delete the three routing skills. Shrink emergency-efficiency to a delta. Fix characters-3d.md:92 and
  shot_neon_game.gd:5.

**P3 Docs, memory, ~/.claude**: Sonnet, high.
- CLAUDE.md:
  - North star.
  - D1, D4, D10.
  - One usage rule.
  - `python`.
  - sync_main.sh.
  - "Read CANON before content work."
- .claude/rules/code.md split out of CLAUDE.md (S2). Settings: binary read-denies, skillOverrides, InstructionsLoaded
  log. DECISIONS: process only, superseded lines struck, D1-D10. CANON.md from the
  content lines. decisions-log: verbatim.
- LESSONS to ~50 lines (route lessons into skills, opencode ones archived). Today's lessons:
  - Audit cost.
  - slots.sh counted 0 runs from a worktree.
  - The hook read the main checkout.
  - Scratchpad scripts vanish.
- WORKFLOW.md (protocols, org, one limits table). docs/design index plus archive (S1). BRIEFING to the archive.
  SPEND.md (S7). TEMPLATE (D6, May edit, timebox, first commit, pillar). GEMINI.md and AGENTS.md slimmed to builder
  specifics.
- Memory:
  - Delete claude-as-manager.
  - Fix big-asks.
  - openrouter-free-only becomes one-shot :free.
  - Update the index.
- ~/.claude:
  - Move unused agents and skills to ~/.claude/archive.
  - Measure a fresh chat's start cost before and after, into USAGE.
  - Write the connector list for you to switch off.
- docs/audits/2026-10-27-process-audit.md: findings, research sources, and notes for other HANDOFF track owners
  (their sections untouched).
- HANDOFF: only Shared and Efficiency.

**P4 Close**: the last chat to finish.
1. `bash tools/check.sh`, reading the FAIL lines.
2. doc_check.
3. Push to origin main from its worktree.
4. /handoff.

## Saved from the temp scratchpad: tools/art/bake_all.sh as it ran
```bash
#!/usr/bin/env bash
# Bakes and packs the Neon Glitch sprite sets, one Godot at a time.
set -uo pipefail
S="$1"; cd /c/dev/game
G="$(bash tools/godot.sh)"
STATES="idle:16:2.5,walk:12:1.333,run:10:0.933,attack:12:1.23,cast:8:0.67,hurt:4:0.33,ko:10:1.85"
for id in rydan concession_enforcer; do
  rm -rf "$S/bake_$id"
  timeout 1200 "$G" --path . --fixed-fps 60 res://tools/bake_sprites.tscn -- "$id" "$S/bake_$id" "$STATES" 256 2.6 < /dev/null > "$S/bake_$id.log" 2>&1
  echo "$id baked: $(ls "$S/bake_$id" | wc -l) frames"
  python tools/art/sprite_sheet.py "$S/bake_$id" "$id" assets/sprites/neon > "$S/sheet_$id.jsonl"
  echo "$id packed: $(wc -l < "$S/sheet_$id.jsonl") states"
done
```
(The localhost route, receiver.py, failed: the flow-media skill records it as a dead end.)

## Appendix: Hades digest (from your Gemini doc; every number unverified). P0 saves it as docs/research/hades-digest.md
**Look and motion**, for the M1 spike:
- Sprites rendered from the rigged 3D model with colour and normal sheets per direction. Frame rate per clip is set
  in SpriteFrames; test one character at two resolutions; no 256-colour cap.
- CanvasTexture normal maps plus PointLight2D (light_mask, shadow_enabled), so lights from hits and props shade the
  sprites. HDR 2D + glow for emissive neon and the qamariya.
- Lights that live: tween PointLight2D energy with noise for flicker; slow GPUParticles2D for dust and embers;
  Parallax2D layers for depth.
- An ink outline as a canvas_item shader (alpha-edge darkening). A 2-step cel shade that reads NORMAL_MAP.
- Hit feedback:
  - hit-stop on the attacker (~60-100 ms, never via Engine.time_scale);
  - a white flash uniform tweened over ~0.1 s;
  - Camera2D shake from decaying noise;
  - pooled one-shot GPUParticles2D;
  - AudioStreamRandomizer with pitch jitter plus impact and voice layers on their own buses.
- Attack phases (startup, active, recovery) drive the frames, so the hit lands on the active frames.
- UI: outlined LabelSettings text, icons checked at the smallest screen size.

**Gameplay**: Hades feel, mechanics and controls inside a linear story (D15; for VISION):
- Attack phases plus an input buffer.
- A dash with invulnerability frames.
- Attack, special and cast on separate buttons.
- Enemy telegraphs.
- Upgrade choices as story rewards: pick 1 of 3 at set points.
- Pre-fight banter and boss intro lines (S).
- Talks gated by what you have done.
- A loadout before a fight (S); local run telemetry for balancing (S).
Not adopted: the roguelite run, death-return and seeded runs.

## Research sources used
- code.claude.com/docs/en/best-practices, /features-overview, /memory.
- anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills.
- futuretech.mit.edu EvilGenie (reward-hacking benchmark).
- ImpossibleBench.
- Godot command-line docs.
- GUT and gdUnit4.
- Third-party blog posts are marked unverified in docs/research/practices.md.

## Verification
- **P1.** Each new test fails on today's code and passes after. slots.sh from a worktree shows the real runs. A
  stubbed low-memory reading refuses a launch. A test edit in a fake run gives BREACH and a non-zero exit.
- **P2.** Each route runs once for real: one Flow image, one rydan bake, one eye_gate render of neon_game. The
  review panel runs on one past builder diff (neon-battle) and must flag the model shrink.
- **P3.**
  - doc_check passes.
  - A grep for Inkling|GLM|Qarnaw|night-sanaa in the loaded notes finds nothing.
  - A fresh chat's start cost is measured, before and after.
- **All.** check.sh green, merged to main, HANDOFF Shared and Efficiency updated.

## Right after approval (this chat; it is past its handoff line)
1. Commit this plan to main as docs/audits/2026-10-27-process-audit-plan.md, with the checklist
   docs/audits/2026-10-27-plan-checklist.md: one checkable line per item.
2. Log D1-D22 verbatim in decisions-log. This is the only edit in DECISIONS territory before P3.
3. Propose P1 as a session card for after the 5-hour reset. Each P-chat writes the next one's prompt into HANDOFF
   Efficiency (sequential, D12).
