# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. Each report: Done | Still open | When | How | Your move vs mine | Checked.

## 2026-10-29 (Thu): row 12 chat (Opus 5.5 high), closed
**Done (on main, CI green; your checkout synced):**
- Cross-review: agy reviews DeepSeek/oc runs (3/5 known bugs); nemotron :free reviews agy runs (1/2); DeepSeek off
  as a reviewer (0 findings in 3 runs). The runner is tools/cross_review.sh; every finding is vetted by Opus.
- The session hook prints the top queue row; the review gate's frame-name bug fixed; process review written
  (docs/audits/2026-10-29-process-review.md); ideas inbox docs/ideas.md; the handoff report format.
- CLAUDE.md: COOKE, fiduciary duty, top-down, solid + flexible foundations, the cache rule (<= ~10 calls stay),
  parallel tool calls, the advisor only with your OK.
- Decisions logged: process first, M1 Saturday; chats sync C:\dev\game at handoff; connectors off; DeepSeek and
  other free models (Cloudflare-hosted, opencode free, OpenRouter :free) free to use, Claude assigns them, agy
  researches them.

**Still open (row 16, docs/briefs/process-completion.md):** calendar re-plan; Open points list in HANDOFF; the
heredoc hook; the token hook's cumulative warning (proposed, NOT built); the "How we work" page with the diagram;
builder jobs: doc_dupes (Cloudflare embeddings), model cards (agy researches Artificial Analysis), open-source
research (licences, art bible); combat-first M1 framing; CLAUDE.md audit with the plugin.

**When:** row 16 Thu-Fri; Sat 16:00 limit reset -> M1 brief (combat feel first); Sun M1 review; Mon you play.

**Your moves:** (1) add the 4 allow rules to C:\Users\AUC\.claude\settings.json now; (2) after this chat ends,
switch off Gmail, Google Drive, Google Docs, the duplicate Rodin connector, Cloudflare Bindings; (3) start a fresh
chat with: "Take HANDOFF row 16: docs/briefs/process-completion.md." **Mine:** everything in row 16.

**Checked:** check.sh (582 tests, earlier today; later changes docs/tools only: check.sh --no-godot passed),
CI green on the pushes I watched. **Not checked:** the game was not run; CI on the last two pushes.
