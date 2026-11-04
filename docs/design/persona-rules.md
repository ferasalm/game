# Persona rules that exist nowhere else (kept from the retired tailored personas, row 28 part g, 11-04)
Read by builders and chats through .agents/project-overlay.md when the brief names one of these roles. The persona texts
are stock; these are the only project rules the role needs beyond docs/CANON.md, docs/design/*.md and .claude/rules/code.md.

## Technical art and shaders
- Shader numbers live in content/art/visual.json, not in the shader. Runtime shaders are canvas_item; spatial shaders only in features/art/view.
- Uniforms carry hints (hint_range, source_color); no per-frame screen-texture read without a named cost.
- Nothing new on the phone: no addon or renderer feature; a PC-only effect needs a flag and Feras's OK.
- Example path: the roof rain is features/neon/roof/view/roof_rain.gdshader.
- Import art at source resolution, let the pipeline downscale. Count overdraw and particle layers; a many-layer glow is a shader job.
- Paid generation: tools/hooks/pre_spend.py blocks it without Feras's "spend ok", plus one docs/SPEND.md line. Rodin: name the credit cost first (D14).

## Blender tools
- Rename, delete, apply transforms or merge only after confirmation or a dry run; keep the source scene non-destructive.
- Read tools/art/refs.json and tools/art/bake_all.sh before writing a bake or reference tool.

## Levels
- Grey-box first: the critical path reads untextured. Flag gameplay-critical against dressable geometry at blockout.
- The exit is visible within 3 seconds; the lit critical path is brighter than optional paths.
- An enemy is visible before it can damage, except a telegraphed ambush.

## Narrative
- Three voice pillars per speaker: vocabulary, rhythm, avoided topics. A consequence is felt within two beats.
- Lore is optional: the critical path works with no collectibles. Playtest text with audio off.
- A story line that needs a CONFIRMED change is BLOCKED: cite the canon row (docs/CANON.md).

## Audio
- Randomise pitch and gain per play; nothing identical twice. Music crossfades are tempo-synced; loop points and loudness belong to the asset.
- Test at the maximum simultaneous count (two guards, Rydan, a full effect burst) and mix on phone speakers.

## Gameplay code
- Input becomes an intent, then a command, then events: three separate steps. A child signals upward, never get_parent().
- Run a save, timer or frame test three times before trusting it.

## UI
- Name the states empty, error and loading beside normal, focus, disabled and new (docs/design/ui.md); touch targets reachable on the phone.
- The UI gate itself (PASS or HOLD, the forbidden-defaults list, old mockups retired) lives in the studio:ui-finish-gate-reviewer agent.

## Design
- Balance space and time before stats; stats are the last lever. An economy has no infinite loop (docs/design/economy.md).
