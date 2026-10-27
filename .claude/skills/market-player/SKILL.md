---
name: market-player
description: Market brief and player-success checks for Neon Glitch: audience, comparables, platforms, price, and per-milestone checks (persona walkthrough, outside playtest, store signals). Use for any market, pricing, store-page or playtest-survey question. Claude drafts, Feras publishes.
---
# Market and player (draft only: Feras decides, publishes and spends)
Sources: the market-card role card (.agents/skills/market-card) and `.claude/agents/review-market`. Research is done by others
(plan section 16: Feras's Gemini Deep Research, free models, agy; never Claude). Every number is marked verified or unverified;
Gemini output is ideas only (LESSONS section 3).

## Market brief template (one page, docs/market/<date>-brief.md)
1. **Audience**: who plays, on what device, how long, why this game (Hades-like action, Old Sana'a setting). One persona per line.
2. **Comparables** (3-6): title | price | scope (hours, content) | review count and score | what we copy | what we avoid. Source link each.
3. **Hook**: one sentence a stranger repeats; the one image and the one 15-second clip that show it.
4. **Platforms**: Android first, iOS later (DECISIONS 2026-10-27); PC later or never: say which and why.
5. **Price model**: free, premium, or free demo + premium; one recommended default with the reason.
6. **Budget line**: store fees, tools, ads, all in $; $0 art budget stays. Nothing is bought without Feras's OK.

## Success checks per milestone
| Milestone | Check | Output |
| --- | --- | --- |
| Look gate (M1) | Persona walkthrough (Persona Walkthrough Specialist): a first-time player's thoughts at each scroll or screen of the trailer/store page | <= 20 lines, drop-off points |
| First playable | Outside playtest, 5 players who have not seen it, no coaching; 5-question survey (what was it about, what would you do next, what confused you, would you keep playing, what to change) plus telemetry (time to first attack, deaths, quit point) | survey table + the metric of acceptance F1 |
| Vertical slice | Store and wishlist signals: page views, wishlist adds, trailer retention | numbers vs the comparable's published figures (verified only) |
| Before release | Review-market lens on the store text; Feras reads | go / fix list |

## Rules
- Claude drafts the brief, survey, store text and trailer script; Feras publishes, posts and pays. Never sign up anywhere.
- Surveys and telemetry: no personal data in repo files; consent line on every form.
- A claim about a competitor's sales or reviews is unverified until a source link is attached.
