# Music: no menu or merchant tracks; menus and Abu Nabil's stall keep explore_souq (DECISIONS 2026-10-22)
Each track has its own identity: one lead instrument and one motif the player remembers. Shared colour: Sana'a 2150,
qanbus oud (short-neck Yemeni lute), mirwas and tasa hand drums, synth bass and analog pads. Loops are seamless.
Feras makes them in Google Flow Music from the prompts below and drops each into inbox/music/ under the id's name
(e.g. inbox/music/explore_souq.ogg or .mp3); Claude converts, places them in assets/audio/music/ and adds the manifest
entries. A track with no file falls back to the one named in content/audio/music.json, so the game never goes silent.

| id | where | prompt for Flow Music |
|---|---|---|
| title_theme | title screen | Cinematic JRPG title theme, cyberpunk Yemen in 2150. Solo qanbus oud states a proud, wistful 6-note motif over warm synth pads and distant city hum, then mirwas drums and a deep synth bass lift it into a full, hopeful swell. 90 BPM, D Hijaz, seamless loop, 2 min. |
| explore_souq | exploring the rooftops at night | Night exploration theme for a JRPG set on the rooftops of old Sana'a in 2150. Plucked qanbus oud melody in Maqam Bayati, soft mirwas and tasa hand-drum groove, pulsing analog synth bass, glassy neon arpeggios, light wind. Curious, adventurous, a little mysterious, never busy. 96 BPM, seamless loop, 2-3 min. |
| battle | every fight | Fast JRPG battle theme, Yemeni cyberpunk. Driving mirwas and tasa drums in a 6/8 Yemeni rhythm, distorted synth bass, aggressive qanbus oud riffs, stabbing brass synths, a heroic call-and-response hook. 150 BPM, Maqam Hijaz, energetic, seamless loop, 2 min. |
| ~~menu_bag~~ (dropped 2026-10-22: menus keep the area music) | pause, items, equipment | Calm JRPG menu music, cyberpunk Sana'a. Soft electric piano and muted qanbus oud trading a short gentle phrase, warm sub bass, slow brushed hand drums, vinyl crackle. Cozy, focused, unobtrusive. 80 BPM, seamless loop, 90 s. |
| sabil_serenity | the sabil fountain save spot | Serene save-point music. Running water, slow qanbus oud harmonics, a breathy ney flute line, shimmering synth pads like moonlight on gypsum, no drums. Peaceful, safe, sacred, restoring. 60 BPM, Maqam Saba softened, seamless loop, 90 s. |
| ~~merchant_stall~~ (dropped 2026-10-22: the stall keeps the area music) | Abu Nabil's herb stall | Warm, playful JRPG shop theme set in a Yemeni spice souq in 2150. Bouncy qanbus oud and plucked synth, hand claps and darbuka, a cheeky whistled hook, light bass. Friendly haggling mood, a smile in every bar. 110 BPM, Maqam Rast, seamless loop, 90 s. |
| workshop_bench | Bilqis's workshop and the jambiyah bench | Workshop theme: inventive and focused. Metallic percussion like tools tapping, clockwork synth arpeggios, a confident qanbus oud melody, warm tape-saturated bass, sparks of electric hum. 100 BPM, Maqam Nahawand, seamless loop, 90 s. |
| battle_2, battle_3 | more fights (Feras's own Flow tracks, 2026-10-22) | no prompt (made by Feras) |
| victory | after a won fight (plays once) | Short JRPG victory fanfare, Yemeni cyberpunk: a bright qanbus oud flourish over a mirwas drum roll and a rising synth brass chord, ending on a triumphant held chord. 6-8 seconds, no loop. |
| boss_abu_nabil | the Abu Nabil mini-boss fight | Playful, sneaky JRPG mini-boss battle theme for a funny, greedy Yemeni herb merchant in cyberpunk Sana'a. Tiptoeing pizzicato qanbus oud, sly clarinet-like ney runs, cheeky muted synth brass, bouncy tasa drums in a swung 6/8, a coin-jingle percussion accent, a mischievous whistled hook that keeps "changing its mind", sudden comic stops. Light, mischievous, never menacing. 132 BPM, Maqam Hijaz, seamless loop, 2 min. |
