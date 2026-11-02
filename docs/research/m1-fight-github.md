# M1 fight: public code and timing numbers (agy Gemini 3.8 Flash digest 2026-11-02; repos verified with gh api by Opus)
Design input only, never facts (DECISIONS 10-19). agy's dates were wrong in 6 of 10; only existence and licence were rechecked.

## Repos (verified: exist, licence per GitHub)
| Repo | Licence | Has | Verdict for M1 |
|---|---|---|---|
| MarcoFazioRandom/Virtual-Joystick-Godot (990 stars) | MIT | floating/dynamic touch stick | reference for m1-touch; copy only with licence header + manifest line |
| Pyxus/fray | MIT | input buffer, combo state machine | idea only: our sim is pure integer logic |
| catprisbrey/Cats-Godot4-Modular-Souls-like-Template | Unlicense | parry + roll states (3D) | idea only (parry window, i-frame toggle) |
| pnscripts/godot-whumpkit-lite (0 stars) | MIT | hit-stop via time_scale, shake | skip: time_scale hit-stop breaks acceptance H3 and our deterministic sim |
| filipbasara/trauma-gd (4 stars) | MIT | trauma camera shake | idea only: `Trauma` is 15 lines of ours |
| haowg/GODOT-VFX-LIBRARY | MIT | white flash shader | reference for the flash shader; write our own 6 lines |
| gdquest-demos/godot-design-patterns | NOASSERTION | state machine | skip (licence unclear) |
| drkitt/godot-input-buffer | MIT | timestamp input buffer (Godot 3 era) | idea only |
| xpTURN/Klotho | Apache-2.0 | deterministic fixed-tick C# core | skip (C#); confirms the fixed-tick approach |
No repo gives parry + posture + 8-direction iso together: the sim is ours.

## Timing numbers with a source (agy-cited pages, not opened by Opus; tune by play)
- Sekiro neutral deflect ~12 frames at 60 fps (fextralife wiki), shrinking on spam: our 12-tick window; spam control = our 10-tick recovery.
- Perfect window in other games: SF6 2 frames; Lies of P 3-5 frames (a reddit table): our 6 ticks is generous on purpose (phone latency); tighten on PC/Hard later.
- Input buffer 80-150 ms (infil glossary): our 8 ticks = 133 ms.
- Hit-stop light 4-6 frames, medium 8-10, heavy 12-16 (infil glossary, SF): our hits 4/4/7, perfect 8, finisher 12.
- Roll i-frames in Souls games 26 frames (too long for a Hades dash): ours 9 of 12 ticks.
- Trauma shake recipe decays 0.8/s, power 2 or 3 (kidscancode): ours 2.0/s, snappier on purpose.
