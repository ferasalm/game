# Audio (Godot built-ins, no FMOD/Wwise)
Autoload `AudioDirector` (core/audio_director.gd) + `MusicDeck` (crossfade, duck). Content: content/audio/
sounds.json (kind sound), music.json (kind music), rules.json (kind audio_rules: volumes, voices, fades, mapping).

## Buses
Master > Music, Ambience, SFX, UI (built in code at startup; levels from rules.json). 12 pooled one-shot players,
oldest stolen when all are busy; 2 music players for the crossfade.

## API
`play_sfx(id, boost_db)`, `play_ui(id)`, `play_action(ActionDef)`, `play_hit(action, damage)`, `play_item(rarity)`,
`step(clock, delta, moving, id)` (footsteps, returns the new clock), `text_blip(chars_shown)`,
`play_music(id)`, `stop_music()`, `current_music()`. Unknown ids and missing files are skipped quietly.

## Sounds (all Kenney CC0, picked by file name)
- Walk: footstep_zayd, footstep_follower (quieter) on concrete steps, repeat interval in the sound.
- UI: menu_move, menu_confirm, menu_cancel, menu_open, dialogue_blip, dialogue_advance, status_apply, item_obtained.
- Moves: vfx_slash, heavy_slash, stab, piston, beam, bolt, arc_all, burst, heal, shield, overclock, net,
  drone_shot, baton. A move uses its ActionDef `vfx` field if it has one, else rules.json `action_vfx`, else the
  melee/ranged fallback. Hits add hit_light or hit_heavy (damage >= heavy_hit_damage).
- Battle: interrupt, knock_out, victory, defeat (stingers duck the music).
- Item chime louder per rarity: `item_rarity_db` offsets.

## Music (the owner's Google Flow tracks)
Save `night_rooftops.ogg` and `battle.ogg` in assets/audio/music/ (Ogg Vorbis), add a manifest entry each
(source flow, licence "owner-generated"), open the project once so Godot imports them. Nothing else changes: the
prototype plays night_rooftops while exploring and crossfades to battle. More tracks: add an entry to music.json.
Add a sound: put the .ogg under assets/audio/sfx/, add its manifest entry, add an item to sounds.json.
