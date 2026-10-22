# Portrait prompts (Gemini): Zayd and Bilqis, 4 expressions each
Chest-up painted portraits for the dialogue box. Until a PNG exists the game draws a pixel stand-in.
Character looks come from docs/design/world.md; change the look lines below if you want a different face.

## Base prompt, Zayd (neutral)
```
Painted digital illustration, detailed brushwork, chest-up portrait of Zayd al-Sana'ani, a 28-year-old Yemeni
courier-fixer in cyberpunk Sana'a, year 2150. Warm brown skin, short dark hair, trimmed stubble, alert calm eyes.
Worn indigo jacket with brass details, a curved jambiyah hilt at his belt, a faint cyan neon glint on one
shoulder. Three-quarter view, body turned slightly right so he looks toward the right edge. Lighting from the
upper left, warm key light and a cool cyan rim light. Neutral, calm expression. Background: one flat plain
bright green (#00FF00) colour, no gradient, no shadow on the background, no text, no frame, no logo.
```
## Base prompt, Bilqis (neutral)
```
Painted digital illustration, detailed brushwork, chest-up portrait of Bilqis, a 26-year-old Yemeni hacker-engineer
in cyberpunk Sana'a, year 2150. Warm tan skin, dark hair under a loose indigo headscarf, a slim cyan visor pushed
up on her forehead, small magenta neon accents on her collar, soot on one cheek. Three-quarter view, body turned
slightly right so she looks toward the right edge. Lighting from the upper left, warm key light and a cool cyan
rim light. Neutral, focused expression. Background: one flat plain bright green (#00FF00) colour, no gradient,
no shadow on the background, no text, no frame, no logo.
```
## Edit prompts (attach the base picture of the same character each time)
Use the same three for both characters; say "this character" and keep the base picture attached.
- happy: `Using the attached picture as the exact reference, redraw this same character with a warm happy smile and relaxed brows. Keep the face, hair, clothes, pose, framing, lighting and flat green background identical. Change only the expression.`
- angry: `Using the attached picture as the exact reference, redraw this same character looking angry: lowered brows, tight jaw, a hard stare. Keep the face, hair, clothes, pose, framing, lighting and flat green background identical. Change only the expression.`
- surprised: `Using the attached picture as the exact reference, redraw this same character surprised: raised brows, wide eyes, lips slightly open. Keep the face, hair, clothes, pose, framing, lighting and flat green background identical. Change only the expression.`

## Steps for each picture (8 in all)
1. Save the picture as a PNG anywhere, for example `C:\dev\game\inbox\zayd_happy.png`.
2. In the repo folder run (change the names; `--prompt-id` is just a label for yourself):
   `python tools/art/portrait.py --in inbox/zayd_happy.png --speaker zayd --expression happy --licence "Gemini, owner-generated" --prompt-id zayd_happy_v1`
   Speakers: `zayd`, `bilqis`. Expressions: `neutral`, `happy`, `angry`, `surprised`.
3. If green fringes remain, raise `--tolerance` (default 40); if parts of the figure vanish, lower it.
4. Press F6 on `features/dialogue/view/dialogue_demo.tscn` in the editor and press E: the new portrait replaces the
   stand-in. The tool wrote `assets/portraits/<speaker>_<expression>.png`, its `.import` and a manifest entry.
5. Commit the PNG, the `.import` file and `assets/manifest.json`.
