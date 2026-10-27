# Feras's notes: what he has objected to (read by review-feras and review-player; add a line per new objection)
Seeded 2026-10-27 from the overnight retro (section B), the 25 playtest notes and chat. Format: name | what he saw | the check that would catch it
Grey sprites | character not coloured, grey; he wants Hades-level colour, not retro | render: full-colour frames of baked sprites in motion
Low-FPS sprite motion | movement choppy | render: playback of baked clips at 24-30 fps, not stills
Portraits cropped and boxed | square box around talkers, grey edges, bad crop (dialogue and menus) | render: portraits at full size with a real cut-out
Floodlight as rectangle | lights-off shows a dark rectangle, not the environment lit differently | render: lights-off variant in a play frame
Static, unlit world | no moving or flickering lights, wind or shadows; qamariya casts none | review: light/emissive/shadow plan before building
Walk mask wrong | booth does not block; hero walks onto illogical spots | test: edge-walk test + render of the mask overlay
Occluder pasted over hero | box looks like a picture on the plate, hero cropped | render: occluder over the hero's path with an object mask
Open door invites entry | hero can walk into an open door with nothing behind it | review: what the plate promises the player
Font legibility | poor font, no visible word spaces | render: UI text at in-game size
Text colour clash | pink and cyan text merges into white | render: text contrast at in-game size
Wrong spelling | "Jambiyah" on screen; decision is "Jambiya" | review: player strings against the decision log
Two titles | two title pictures; keep the original top one | render: title screen capture
Title loop not seamless | loop jumps at the seam | render: playback across the seam
Title low resolution | 360p source upscaled | test: asset dimension check
Rain in gameplay | rain overlay looks wrong in play; remove | render: in-play frame judged in motion
Acid rain without umbrella | rain is acidic; no umbrella item protects the player | review: world rules against the brief
Music | music should change | review: listen-through against references
Empty space | unused space left in the layout | render: full-size screenshot review
Weak narrative, unclear text | "what does this even mean"; prologue gives no story hints | review: narrative pass before captions ship
No attack SFX or VFX | hits have no sound or visual effects | review: battle brief needs SFX+VFX per hit, then playthrough
Flee does nothing | flee does nothing; player has zero items | test: scripted-fight flee rule + starter-bag test
Corpses linger, KO'd guards revive | corpses stay; knocked-out guards wake up dead | test: post-fight scene asserts cleared bodies, no revive
Unbalanced combat | fights too easy or too hard (chat) | test: balance simulation with time-to-kill bounds
Runware before free Flow | paid Runware used before free Flow (chat) | review: provider order of image routing before a run
