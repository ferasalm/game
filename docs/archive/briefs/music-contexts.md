# Brief: a music track per place and menu
You are in your own worktree on branch gemini/music-contexts (made from claude/night-sanaa). Follow GEMINI.md. Load the
game-audio-engineer skill (.agents/skills/game-audio-engineer).

## Why
The owner: menus must never go silent; the sabil, the merchant, the inventory and so on each get a track with its own
identity. The track list and ids are in docs/design/music.md (read it). The .ogg files do not exist yet; Feras makes
them later. Until then each new track must fall back so nothing goes silent.

## What to build
1. content/audio/music.json: entries for every id in docs/design/music.md, path res://assets/audio/music/<id>.ogg,
   loop true except `victory`. Add an optional `fallback` field to MusicDef (a music id played when this file is
   missing): explore_souq -> night_rooftops; menu_bag, sabil_serenity, merchant_stall, workshop_bench and
   title_theme -> night_rooftops; battle keeps its file; victory has no fallback (missing = nothing plays, the battle
   music keeps going). Keep night_rooftops as a track.
2. content/prototype/flow.json: explore_music becomes explore_souq.
3. Music contexts: content/audio/screen_music.json (new kind, Def + reader like the others) maps a Screens id to a
   music id: pause, items, equipment -> menu_bag; shop -> merchant_stall; sabil -> sabil_serenity; the workshop menu ->
   workshop_bench (find its id); title -> title_theme (find how the title overlay is shown). A pure stack in
   features/audio/logic/ (push on open, pop on close, top wins, unmapped screens keep what plays) decides the track;
   the base track is what the Router plays for exploring or fighting. The defeat screen keeps what plays.
4. Resume: returning from a menu to the base track resumes it where it was (remember the playback position per
   track in the music deck), with the usual crossfade; a battle starts its track from the top.
5. Music keeps playing while the tree is paused (menus pause the game): make sure the music players run with
   process_mode ALWAYS; add a test.
6. victory plays once when a fight is won (find where the win is announced), then the area's base track returns.
7. Do NOT edit content/world/, content/dialogue/, localization/dialogue.csv, features/world/ (other briefs own them).
   Keep edits to features/ui/view/ui_stack.gd to a signal or two that the audio side listens to (UI must not know
   music ids).
8. Tests: the stack (every branch), fallback resolution (missing file -> fallback; missing fallback -> keeps what
   plays), every screen_music entry names a real screen id and music id, pause keeps music, resume position.
9. Add one short "Music contexts" section to docs/ARCHITECTURE.md's audio section (grep it).

## Proof
`bash tools/check.sh`: paste the raw last 15 lines. Small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
