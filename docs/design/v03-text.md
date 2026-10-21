# v0.3 text: herb seller, sabil, items, nameplates, pause and defeat (draft for owner review)
Owner: Feras. Writer: Narrative Designer. Rows go to localization/<file>.csv as `keys,en` (keys lowercase, prefixed).
Facts used: water is power; the Concession rations it; currency riyal; Zayd carries his grandfather's djanbeyyah;
Bilqis runs a coffee stall as cover. Invented names and lines are marked for owner review.

## Herb seller (invented: Umm Nabil)
Personality: older woman who has run the roof stairs' herb stall for decades. Dry humour, no small talk about the
Concession, sells fairly and will not haggle over water. Calls young customers by their fathers' names. She is not
a mother figure to the hero; she is a shopkeeper who has already decided he is trouble.

Greeting, first visit: "You climbed four flights with that face. Sit. Dry mint first, then business."
Greeting, return: "Back already. The herbs haven't changed, and neither have my prices."
Greeting, after a battle: "Your sleeve is torn and your hand is shaking. Sit, drink something, then tell me who you hit."

## Rows for shop.csv
```
keys,en
shop_name,Umm Nabil
shop_epithet,Herbs from the roof stairs
shop_heading,Herb stall
shop_greet_first,"You climbed four flights with that face. Sit. Dry mint first, then business."
shop_greet_return,"Back already. The herbs haven't changed, and neither have my prices."
shop_greet_after_battle,"Your sleeve is torn and your hand is shaking. Sit, drink something, then tell me who you hit."
shop_buy,"Pink feathers for the wound, yellow for the head. Take what you can carry."
shop_buy_done,"Paid in full, the souq way. Good."
shop_sell,"Bring me what you don't need. I weigh fairly. I always have."
shop_sell_done,"That's worth a cup of qishr for both of us."
shop_not_enough,"Not enough riyal. Come back when a job pays, or sell me something first."
shop_bag_full,"Your bag is full. Drink what you carry, or leave something here."
shop_farewell,"Go in peace, and come back with your hands full."
```

## Rows for sabil.csv
Inscription (invented, carved in gypsum over the basin, no scripture quoted). Owner or a native reviewer should
replace it with a real-style Sana'a inscription; the line below is the English gloss.
```
keys,en
sabil_inscription,"Drink, and leave the cup full for the one behind you."
sabil_inscription_source,"Carved over the basin of the old sabil on the roofs; a gift of a guild family, long dead."
sabil_prompt,Drink
sabil_saved,"You drank. Water restored, and the game is saved."
sabil_patrols_return,"Their patrols are back on this street. Drink again when you need to, but keep your voice low."
```
Note: "drink again when you need to" is the party line for patrols returning; Bilqis is the speaker.

## Rows for items.csv
```
keys,en
item_herb_pink_name,Pink-feather herb
item_herb_pink_desc,"Restores HP. Dried on the roof and bundled by hand; it smells of rain on dust."
item_herb_yellow_name,Yellow-feather herb
item_herb_yellow_desc,"Restores SP. Bitter enough to wake a tired courier before a bad climb."
item_herb_white_name,White-feather herb
item_herb_white_desc,"Revives a fallen ally at half HP. Kept for the worst night of the year."
item_qishr_name,Qishr cup
item_qishr_desc,"Small heal for the whole party. Husk coffee and ginger, poured from a brass pot."
```
Description lengths are under 90 characters. Qishr (dried coffee husk) and the ginger serving are marked "check" in
the Respect notes below.

## Rows for battle.csv (nameplates)
```
keys,en
battle_epithet_zayd,Courier-fixer of the souq
battle_epithet_bilqis,Engineer behind the coffee stall
battle_epithet_enforcer,"Concession enforcer, paid by the litre"
battle_epithet_drone,Concession survey drone
battle_defeat_heading,Defeated
battle_defeat_retry,Retry fight
battle_defeat_load,Load last save
battle_defeat_to_title,Title
```

## Rows for pause.csv
```
keys,en
pause_heading,Paused
pause_resume,Resume
pause_items,Items
pause_equipment,Equipment
pause_load_last,Load last save
pause_restart,Restart
pause_unstuck,Unstuck
pause_title,Title
pause_quit,Quit
pause_confirm_restart,"Restart from the last save? Progress since then is lost."
pause_confirm_load,"Load the last save? Progress since then is lost."
pause_confirm_unstuck,"Move back to the last safe spot? Party and items are kept."
pause_confirm_title,"Return to the title? Unsaved progress is lost."
pause_confirm_quit,"Quit the game? Unsaved progress is lost."
pause_confirm_yes,Yes
pause_confirm_no,No
```

## Arabic screen titles (separate list, not in the CSV rows)
| Key (screen) | en | ar note |
|---|---|---|
| shop_heading | Herb stall | دكان الأعشاب |
| pause_heading | Paused | متوقف |
| battle_defeat_heading | Defeated | مهزوم |

Arabic lines get a native review later (Respect notes). The sabil inscription's Arabic original is not written here.

## Respect and review notes
- Umm Nabil is a shopkeeper, not a symbol of hospitality. Her warmth is in her bluntness and her fair weights.
- The sabil is a public good, so the save and refill are a gift, not a shop transaction. The inscription is invented.
- Qishr and ginger serving: (check) against Yemeni practice. The brass pot is a detail to confirm.
- How a young customer addresses an elder shopkeeper: (check) before the Arabic is written. The English uses no
  honorific, so the shop lines avoid one.
- The Concession is the only villain in the text. No line blames a neighbourhood or a people.
- Owner decision needed: the herb seller's name and epithet (Umm Nabil is an invented kunya).
