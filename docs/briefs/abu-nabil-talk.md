# Brief: talk to Abu Nabil, and more party dialogue
You are in your own worktree on branch gemini/abu-nabil-talk (made from claude/night-sanaa). Follow GEMINI.md. Load the
narrative-designer skill (.agents/skills/narrative-designer) for the writing.

## Why
The owner wants many more dialogue lines, especially with Abu Nabil, the herb seller on the roof.

## Who he is (canon; never contradict)
Abu Nabil: a 40-year-old man who runs the herb stall on the roof of a guesthouse tower in Souq al-Milh, Sana'a, 2150.
Warm, wry, unhurried; Sana'ani hospitality (qishr, dry mint, "sit first"); knows every roof and rumour; distrusts the
Concession (the corporate occupiers whose patrols and drones work the rooftops) but keeps his head down. Read his
existing lines in localization/shop.csv (SHOP_GREET_*) and match that voice. Also read docs/design/world.md (cast,
Concession), docs/design/prototype.md and localization/dialogue.csv (Zayd, Bilqis voices). Zayd carries his
grandfather's jambiyah (Jiddi); Bilqis is an engineer who fixes it at her bench. English only; at most one Yemeni word
per line, explained by context; no Arabic script. Every line <= 140 characters. Speaker ids: zayd, bilqis, abu_nabil.

## What to build
1. Speaker `abu_nabil` in content/dialogue/speakers.json (name_key NPC_HERB_SELLER exists; add EPITHET_ABU_NABIL
   "Herb Seller of Souq al-Milh"; colour "#8fbf6a"; copy the field shapes of the others; portrait stand-in is fine).
2. Dialogues in content/dialogue/dialogues.json, text rows in localization/dialogue.csv (existing file only):
   - abu_nabil_first (7-9 lines, Abu Nabil + Zayd, maybe Bilqis): who he is, the guesthouse roof, herbs and what
     they do in a fight (pink heals, yellow, white, qishr: read content for their real effects), a warning about the
     patrol, a nudge toward the sabil to rest.
   - abu_nabil_after_battle (4-5 lines): he noticed the fight; dry humour; a hint about interrupts (Bilqis's
     static_net cancels a cast).
   - abu_nabil_chat_1 .. abu_nabil_chat_4 (2-3 lines each): small talk on later visits, each a small piece of world
     (the souq, the old towers, the Concession, Zayd's grandfather).
   - party_after_first_win (4-5 lines, Zayd + Bilqis): after the first won battle.
   - party_sabil_first (3-4 lines, Zayd + Bilqis): the first time they reach the sabil fountain.
3. Talking: content/dialogue/talks.json (new kind `talk`, Def + reader like the other kinds) maps a place id to
   `first`, `after_battle` and an ordered `chats` list. A pure picker in features/dialogue/logic/ picks the next
   dialogue from saved flags (seen first? a battle won since the last talk? next chat index, wrapping). State lives in
   the existing GameState flags (no save version bump unless the codec requires it; then migrate one version).
4. Interaction: walking up to the npc place `herb_seller` and pressing confirm plays the picked talk (an interact
   spot like features/world/interact/stall_spot.gd). The stall `shop_herbs` stays the shop. party_after_first_win
   plays once when exploring resumes after the first victory; party_sabil_first plays once before the sabil screen
   opens the first time. Wire in features/prototype/prototype_main.gd or the existing spot scripts, small edits.
5. Do NOT edit content/world/areas.json (another brief rebuilds the roof; it keeps the ids herb_seller and sabil),
   content/audio/, features/audio/, features/ui/view/ui_stack.gd.
6. Tests: the picker (every branch), talks.json well formed (every id exists), every new line passes the existing
   T8 dialogue test, and one interact test that confirm on herb_seller plays abu_nabil_first then a chat.

## Proof
`bash tools/check.sh`: paste the raw last 15 lines. List every new line in your final report (id, speaker, text) so
the lead can review the writing. Small WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
