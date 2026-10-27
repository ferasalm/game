# Acceptance list: what a player must see (draft by Haiku H3, edited by Claude 2026-10-27; Feras edits the bars)
Sources: docs/audits/2026-10-26-overnight-retro.md B/C, docs/feras-notes.md, Hades digest (unverified numbers).
Format: `id | what a player must see | how to check`. "bar: Feras sets" = no number yet. eye_metrics.py checks M1, C1, U1.
Metric bars (eye_metrics.py, from the sources): fps >= 24, colours > 256, font >= 18 px at 720p.

## Colour
C1 | Characters in full colour, not grey or retro, in motion | metric: sheet colours > 256; frame: beside a Hades reference
C2 | Neon and qamariya glow in colour, not a flat fill | frame: glow on vs off; bar: Feras sets
C3 | Pink and cyan UI text stays distinct from white text | frame at in-game size; bar: Feras sets contrast
## Motion
M1 | Sprites move smoothly, about 24-30 fps per clip | metric: clip fps >= 24; playback, not stills
M2 | Enough baked frames per clip to read as motion | metric: frames per clip; bar: Feras sets minimum
M3 | Attack startup, active, recovery show; the hit lands on active frames | frames of one attack; bar: Feras sets
## Light
L1 | Lights off is the same room lit differently, not a dark rectangle | frame: lights-off variant in play
L2 | Lights flicker; dust, embers and wind drift | playback of one room; bar: Feras sets
L3 | Sprites shade from nearby lights | frame: sprite in lit and unlit spots; bar: Feras sets
L4 | The qamariya lights its surroundings and the hero | frame: qamariya light on vs off
## Hit feedback (VFX + SFX)
H1 | Every hit has impact + voice sound with pitch variation; each swing its own sound | playtest 20 hits, 10 swings
H2 | Every hit flashes the target white and bursts VFX (flash about 0.1 s) | frame: the hit frame
H3 | The attacker freezes briefly on hit (60-100 ms, never Engine.time_scale) | test: pause in frames
H4 | Camera shake on hit, decays and stops | playtest; bar: Feras sets duration
## UI legibility
U1 | Font readable at in-game size, word spaces visible | metric: smallest font_size >= 18 px at 720p; 1:1 frame
U2 | Text outlined, readable over light and dark backgrounds | frames over both
U3 | Icons (the umbrella too) legible at the smallest screen size | smallest-screen capture; bar: Feras sets
U4 | One title picture, seamless loop, native resolution (not 360p upscaled) | title frame; loop seam; asset size
## Portraits and framing
P1 | Portraits are a real cut-out: no grey box, no faded edge | portrait at full size in dialogue and menu
P2 | Portrait crop keeps the head whole and centred | dialogue frame; bar: Feras sets
P3 | Occluders have an object mask; the hero is not clipped behind one | frames along a walk past the occluder
P4 | No unused empty space in a layout | full-size screenshot; bar: Feras sets
## World logic (walk mask, doors, occluders)
W1 | Solid things (booth) block; no illogical walkable spots | test: edge walk; walk-mask overlay on the plate
W2 | An open door shows something behind it, or stays shut | walk to each door
W3 | The umbrella protects from acid rain; people carry umbrellas | playtest in rain with and without
W4 | No rain overlay during gameplay | in-play frame, judged in motion
## Story text
S1 | The prologue hints at the story | fresh player retells the premise; bar: Feras sets
S2 | Lines read clearly, no "what does this mean" moments | narrative pass, Feras reads captions
S3 | Player-facing name is "Jambiya" (no h) | grep player strings for Jambiyah
## Fun (the core action unprompted within ~30 s)
F1 | A fresh player attacks unprompted within ~30 s of control | playtest; bar: Feras sets players and pass rate
F2 | First fight: hit-stop, flash, sound and shake land together | Feras plays it at full size
F3 | Music changes across the game | listen-through; bar: Feras sets
F4 | Flee works; the starter bag has usable items | tests: flee rule, starter bag
F5 | Corpses clear after fights; KO'd guards stay down | test: post-fight scene
F6 | Fights are neither too easy nor too hard | test: balance sim time-to-kill; bar: Feras sets
