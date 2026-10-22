# Brief: tayramana (<= 60 lines; start only after camera-v2 and level1-blockout are merged)
You are in your own worktree on branch gemini/tayramana (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/godot-gameplay-scripter).

## Why
Owner playtest 2026-10-23 item 6: a Sana'ani tayramana (rooftop room with large windows) holding a Yemeni majlis
(low cushions along the walls) that the party enters, sits in, and shares qishr with Bilqis. Spec: level-1.md 6.

## Read first
docs/design/level-1.md section 6; docs/MAP.md lines for camera-v2's framed_shots and camera_room, the door place
(level1-blockout), dialogue (dialogues.json, talks.json, dialogue box), talk_spot, rooftop freeze_actors, the router.

## What to build
0. One room only (owner: "keep the Tayramana", no other rooms): its east corner holds the workbench (the prop
   content/world/props/workbench.json); interacting with it opens the existing workshop talk and equipment menu
   exactly as the outdoor workshop spot does today; remove the outdoor workshop spot from the area.
1. content/world/rooms.json (new kind "room", Def + ContentDB registration): id "tayramana", size 7 x 5 x 3 m,
   wall colour letters, qamariya arches on three walls (lit), the props of level-1 section 6
   as prop JSON (cushions, armrests, carpet, brass tray, jamana pot, cups, shelf, radio, holo-frame), two framed
   shots, the entry spot, the exit spot on R3 outside the door (level-1.md 2, 6), two sit spots.
2. A room builder (view) that builds a room from its def, reusing PropBuilder and the painted materials.
3. The door place enters: fade out 0.4 s (input locked), the rooftop is hidden like a battle (rooftop_port), the room
   is shown with the framed camera, fade in; leaving through the door reverses it. Area music keeps playing.
4. Sit: interact at a sit spot; Zayd and Bilqis kneel (hold the crouch pose; no new clip), then the talk below plays;
   first time only: +2 qishr into the bag (ItemService) and a loot banner. Later sits: line 7 only.
5. The talk "tayramana_qishr" in content/dialogue (speakers zayd, bilqis; neutral unless noted), text in
   localization/dialogue.csv (English column; Arabic column empty):
   1 BILQIS (happy): "Sit. The qishr is still hot, and you look like a man who ran across half the souq."
   2 ZAYD: "Three roofs and a bridge. The guild pays by the parcel, not by the step."
   3 BILQIS (surprised): "Show me this parcel... That seal. It's the Concession's own."
   4 ZAYD: "The Concession doesn't hire couriers. It has drones for that."
   5 BILQIS (angry): "Unless it wants no record. Look east, their water tower. The valve that starves this souq is at its foot."
   6 BILQIS: "Take these. Qishr keeps a head clear, whatever Abu Nabil burns in that stall."
   7 BILQIS: "Still hot. Drink, then go."

## Do NOT edit
features/combat/, content/combat/, localization/combat.csv, camera-v2's logic files (use them), docs/design/,
HANDOFF.md, docs/DECISIONS.md.

## Tests
Room def parses; the builder makes every prop; enter and leave move the party and restore the rooftop; input is locked
during fades and the talk; the first sit gives 2 qishr once (also after a save and load); later sits give nothing.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless) of both framed shots with the party seated, to
C:/dev/game/inbox/tayramana_*.png (960x540); small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
