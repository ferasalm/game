# Hades digest (from Feras's Gemini Deep Research doc, 2026-10-27; every number unverified; design input, not facts)
Saved by P0 from the appendix of docs/audits/2026-10-27-process-audit-plan.md. It feeds M1 (docs/VISION.md).
Pillars served: Hades-feel combat, Living Old Sana'a.

## Look and motion (the M1 spike)
- Sprites rendered from the rigged 3D model, with colour and normal sheets per direction. Set the frame rate per clip
  in SpriteFrames. Test one character at two resolutions. No 256-colour cap.
- CanvasTexture normal maps plus PointLight2D (light_mask, shadow_enabled), so hit and prop lights shade the sprites.
  HDR 2D plus glow for emissive neon and the qamariya.
- Lights that live:
  - tween PointLight2D energy with noise for flicker;
  - slow GPUParticles2D for dust and embers;
  - Parallax2D layers for depth.
- An ink outline as a canvas_item shader (alpha-edge darkening). A 2-step cel shade that reads NORMAL_MAP.
- Hit feedback:
  - hit-stop on the attacker (~60-100 ms; never through Engine.time_scale);
  - a white-flash uniform tweened over ~0.1 s;
  - Camera2D shake from decaying noise;
  - pooled one-shot GPUParticles2D;
  - AudioStreamRandomizer with pitch jitter, plus impact and voice layers on their own buses.
- Attack phases (startup, active, recovery) drive the frames, so the hit lands on the active frames.
- UI: outlined LabelSettings text; icons checked at the smallest screen size.

## Gameplay: Hades feel, mechanics and controls inside a linear story (D15)
- Attack phases plus an input buffer.
- A dash with invulnerability frames.
- Attack, special and cast on separate buttons.
- Enemy telegraphs.
- Upgrade choices as story rewards: pick 1 of 3 at set points.
- Pre-fight banter and boss intro lines (S).
- Talks gated by what the player has done.
- A loadout before a fight sequence (S).
- Local run telemetry for balancing (S).
- Not adopted: the roguelite run, death-return, seeded runs. Bigger shifts, each Feras's decision: a hub (M),
  relationships (M).

## Mobile notes (D17; to verify in the M1 spike)
- Mobile renderer, not Forward+.
- Touch: a virtual stick plus attack, dash, special and cast buttons.
- Sheet memory on phones: fps x frame px x states. The sprite-bake skill holds the open question; M1 measures it.
