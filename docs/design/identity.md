# Identity: the Hook (the game's signature motif)
Decision 2026-10-22: the jambiyah hook is to Qarnaw what the spiral is to Naruto. Smoke, steam, dust, slashes, UI
corners and the logo curl into it. It is a SHAPE (section 1) and a MOTION (section 4). Mark file: identity_hook.svg.
Reference: the real jambiyah: a straight shaft, then a bend that tightens into a small up-turned tip.

## 1. The hook as geometry
One curve of length L, parameter s from 0 (root) to 1 (tip):
- Heading: `a(s) = 230 deg * s^2`, measured from the root direction. Curvature grows in a straight line from 0 (a
  straight shaft) to its tightest at the tip (an Euler spiral). Never a plain circle arc: the tightening IS the hook.
- Point: step along the heading, `p(s) = p0 + L * integral(dir(a(u)) du, 0..s)`, `dir(a) = (-sin a, cos a)` in
  screen space (root points down, the hook turns left, then up). The tip ends 0.74 L left of and 0.24 L below the
  root, after 230 degrees of turn (a bit past a half turn).
- Half width: `w(s) = L * (0.11 * (1 - s)^0.9 + 0.012)`. Thick root, taper to a thin point, never below 1.2% of L
  (so it survives mip-mapping). The root end is cut flat (the hilt top); the tip is pointed.
- Ink edge: 5% of L, at least 2 px on screen, colour ink #1a1020 (same ink as the world outline). On smoke the edge
  is a darker rim, not a hard line.
- Handedness: LEFT hook is the master (a "J"). RIGHT hook = mirror in x. The hook curls toward the centre of the
  thing it decorates (UI corners, trails); dust and steam curl away from the mover. The party's hooks are left, the
  enemy's are right, so a battle reads at a glance.
- Scaling: same shape at every size, only stroke and detail change.
  - 16 px (UI corner): one filled stroke, no outline, tip at least 2 px wide.
  - 32 to 64 px (icons, cursor): fill plus 2 px ink edge.
  - 512 px (logo): fill, ink edge, and a thin highlight line along the outer curve (gypsum ornament).
  - 1 to 3 m (smoke plume): the curve is a guide path for particles; the plume is a fat hook with a fuzzy edge and
    one small tendril (0.25 L) in its tail that curls the same way. One hook per plume.

## 2. Where it appears (one rule each)
- Steam and smoke (sabil, qishr cups, chimneys, vents): rises straight for the first 25% of its life, then follows
  the hook and ends in a curl. Sabil steam curls left; chimneys left of the street curl right (toward the centre).
- Footstep and landing dust: a sprint start or landing throws one small hook (L 0.4 m) from each heel, curling away
  from travel. Ordinary walking steps: a plain puff, no hook.
- Slash smears and weapon trail: the jambiyah trail IS the hook: a tapering crescent whose last 20% hooks in the
  swing direction. Light attack L 1.2 m; heavy L 2 m plus an echo hook behind at 40% alpha.
- Hit sparks: 3 to 5 streaks leave an impact; only the biggest is a hook, and only on criticals and interrupts.
- BREAK flash: a white-carnelian hook sweeps once (full 230 degrees) around the broken enemy, then shatters.
- Battle transition wipe: a hook-shaped curtain of ink inflates from the top-right, tip curling to the middle, and
  fills the screen; it reverses on exit.
- UI frame corners: panels and menus get a 16 to 24 px hook in the top-left corner and its 180 degree twin in the
  bottom-right; the other corners stay square. Popups and tooltips: none.
- Focus ring and cursor: the cursor is a 32 px hook with its tip toward the item. The focus ring is the normal
  frame plus one hook at its top-left, which slides to the new item.
- Timeline icons: only the ACTING unit's marker gets a small hook on its upper-left. Waiting units: none.
- Title logo: the Musnad title where one letter's vertical stem is replaced by a large hook whose tip curls around
  the rest of the title. Hook carnelian #d9503f, letters gypsum #efe3c8, ink edge.
- Loading indicator: a 48 px hook that traces itself in a circle (head draws, tail fades). No text spinner.
- The save sabil: on saving, its steam curls as three hooks at once (one plume, two tendrils), then settles to the
  normal single curl. Saving feels special.

## 3. Frequency budget and colour
The hook stays special because most things are NOT hooks.
- At most 3 hooks in the world at once while exploring, 4 in battle (UI corners count as one group).
- Never: ambient wind dust, rain, fog, embers, clutter, idle effects, text, damage numbers, walking. Never two hooks
  touching, a hook inside a hook, or a hook rotated sideways for variety.
- Rule of thumb: a hook means "this moment matters" (fast move, hard hit, saved, broke, a fight starts).
Colour per use:
- Steam and smoke: the local light colour a little lighter (lantern pool = warm cream, shadow = grey-violet), no
  outline, a darker violet rim at 30% alpha.
- Dust: sand #c9a46a lit, #5b4452 in shade.
- Slash and trail: party = warm white core #fff1d0, carnelian #d9503f edge; enemy = cold violet core #b9a6ff, dark
  magenta edge. Heirloom weapons add carnelian to the core.
- Sparks: white-gold #ffe9a8 for the hook, plain streaks stay amber.
- BREAK: white core, carnelian edge, then qamariya glass colours (red, green, amber, blue) in the shards.
- UI corners, cursor, loading: gypsum #efe3c8 with ink edge; carnelian only for the focused or active one.
- Accessibility: a hook is never the only signal (a state also has text or an icon). Carnelian on dark ink is only
  about 4:1 contrast, so keep it off small text.

## 4. Motion: how a curl unfolds (60 fps)
The motion is the signature. Every hook draws itself root to tip, holds a breath, then dissolves tip first.
- Unfold: `s_visible(t) = ease_out_cubic(t / T_draw)`: the root appears fast, the tip arrives slowly, with a 4%
  overshoot in L. The tightening happens last.
- Dissolve: alpha and width shrink from the tip back toward the root (it retracts and thins, never fades evenly),
  with ease_in_quad. Hook speed is never constant.
Timings in frames (draw / hold / dissolve):
- Smoke or steam curl: 50 / 20 / 40, one curl per puff, repeating every 150 frames.
- Dust hook: 8 / 2 / 14.
- Light slash: 4 / 1 / 9; heavy slash: 6 / 2 / 14. The hit frame is draw frame 3.
- Critical spark hook: 5 / 2 / 10.
- BREAK sweep: 10 / 6 / 20, with a 4 frame white flash and 2 frames of hit-stop.
- Battle transition: 24 in, 20 out, no hold.
- UI corner: draws in 8 frames when the panel opens, then static. Cursor and focus hook slide in 6 frames with a
  2 frame tip lag (the tip trails the root like a whip).
- Logo: draws in 40 frames when the title appears; every 600 frames a 20 frame shine runs along the curve.
- Loading indicator: one loop = 90 frames, continuous.
- Reduced-motion option: UI and logo hooks appear instantly.

## 5. Implementation sketch (Godot 4.7; cost on an Iris Xe laptop, 60 fps floor)
Shared pieces, built once:
- `hook_curve` (pure logic): `point(s)`, `half_width(s)`, `tangent(s)`, and a ribbon of N points (default 24).
  Everything below samples it. Test: heading at s=1 is 230 deg, width stays above 1.2% of L, mirror flips x.
- `hook_sdf.gdshaderinc`: distance to a 16-segment polyline minus half width, with params `draw`, `dissolve`,
  `mirror`, `ink_px`. About 0.05 ms for a full UI of small quads; full-screen only for the transition.
- Constants (230, 2.0, 0.11, 0.9, 0.012) and caps below live in one `hook.json`, not in code.
Per item:
- Steam and smoke: GPUParticles3D, 24 to 48 billboard particles per plume. Velocity follows `tangent(s)` where s is
  the particle's age ratio (a 16-sample curve in a small texture or a velocity curve in ParticleProcessMaterial).
  Lit by tinting with the painted light colour (unshaded). About 0.2 ms a plume; at most 2 in view.
- Dust: one-shot GPUParticles3D, 8 particles, same curl, L 0.4 m. About 0.05 ms.
- Slash smear and trail: a short ArrayMesh ribbon built from `hook_curve` when the swing starts (scaled to weapon
  reach), one unshaded ShaderMaterial with `draw` and `dissolve` uniforms from a tween. 24 verts, under 0.1 ms.
- Hit spark hook: a billboard quad with the SDF shader plus ordinary spark particles. About 0.02 ms.
- BREAK flash: a billboard quad at 3 m with the SDF shader, plus a 4 frame white ColorRect. About 0.1 ms for 20 frames.
- Battle transition: a full-screen ColorRect with a CanvasItem shader evaluating the SDF scaled to cover the screen.
  About 0.3 ms for the 44 frames only.
- UI frame corners: StyleBoxFlat cannot draw them. Use a baked 64 px hook PNG (from the SDF, mipmapped) placed in
  the panel's `_draw()` or as a NinePatchRect corner; twin = flip_h/flip_v. No shader cost.
- Focus ring, cursor, timeline icons: the same baked PNG in a TextureRect (12 to 32 px), moved by a 6 frame Tween.
- Title logo: an SVG authored once (hook plus Musnad letters as paths, no font load at the title), baked to PNG;
  the draw-on animation is a `hook_sdf` mask. Negligible cost.
- Loading indicator: the baked hook with a small shader filling it by angle over `TIME`. About 0.01 ms.
- Save sabil: the existing steam emitter plus a one-shot burst of 3 plumes sharing the curl script.
Cost summary: worst case in the world (2 plumes, dust, a smear, a spark, UI) is about 0.6 ms a frame on Iris Xe
(under 4% of 16.6 ms). The transition is the only full-screen use. Screenshots of each placement go to inbox/
for the owner's review.

## 6. Owner choices
1. Tip style: pointed (drawn in the mark; clean at 16 px) or with the small round bulb of the real jambiyah's
   sheath tip (more recognizable, busier when small). Recommended: pointed.
2. Which Musnad letter provides the logo's hook stem (Claude will render 3 candidates; Feras picks).
3. Mirrored handedness for party (left) and enemy (right) hooks (recommended), or all hooks curl the same way.
