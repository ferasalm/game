# Brief: workshop-menu (<= 60 lines; run AFTER rpg-progression, menu-skins AND equipment-menu merge)
You are in your own worktree on branch gemini/workshop-menu (made from claude/menus-rpg-5089fa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why: Feras approved the workshop: upgrade gear to +3, set hilt stones, craft from won materials; nothing fails.
## Read first
C:/dev/game/inbox/ui_refs/mock_workshop.png (layout target; Feras's Gemini mockup: copy its layout, not its names, numbers or glyphs);
docs/design/rpg-systems.md 8-9 and docs/design/hilt-stones.md 4-9 (THE SPEC; every number); rpg-menus.md 0 and 3
(rects at 1920x1080); features/ui/view/ui_screen.gd, ui_stack.gd, menu_backdrop.gd, ui.gd, list_row.gd,
money_counter.gd, prompt_strip.gd, ui_rarity.gd, toast_host.gd; features/equipment/view/hologram_stage.gd (reuse
for the turning jambiyah); features/progression/logic/ (Stones.open_slots/fits/set_stone); features/items/logic/
gear.gd, inventory.gd, shop.gd (the Holdings-copy pattern); core/game_state.gd (sockets, upgrades, materials, money);
core/battle_session.gd (_win); content/items/consumables.json, content/combat/encounters.json.

## What to build
1. Content + Defs (ContentDB.KINDS): content/items/materials.json kind "material" (MaterialDef: id, name_key,
   desc_key, rarity, icon): scrap_copper Common, drone_coil Uncommon, salt_crystal Uncommon.
   content/workshop/upgrades.json kind "upgrade_costs": riyal [40, 80, 140], rarity factor {common 1.0, uncommon 1.25,
   rare 1.5, epic 2, legendary 2.5}, materials per next level [{scrap_copper 2}, {scrap_copper 3, drone_coil 1},
   {drone_coil 2, salt_crystal 1}], max 3. content/workshop/recipes.json kind "recipe" (RecipeDef: id, output,
   count, riyal, materials): pink_herb x2 <- scrap_copper 1 + 10; yellow_herb x1 <- drone_coil 1 + 20; sulaimani x1
   <- scrap_copper 3 + 30; fayruz x1 <- drone_coil 2 + salt_crystal 1 + 40 (herb ids are [PLACEHOLDER] for "feathered
   herb"). EquipDef gains `upgrade` {stat: add per level} if rpg-progression did not add it; fill it on blades and
   armor (blade {"attack": 2}, armor {"max_hp": 15, "defense": 1}); the heirloom hilt has none.
2. Pure logic features/workshop/logic/ (no nodes, no GameState): Upgrades.next_cost(item, level, costs, rarities) ->
   {riyal, materials} or {} at max; Upgrades.problem(...) -> "" or a reason key (WS_MAX, WS_SHORT_MONEY,
   WS_SHORT_MATERIALS); Crafting.problem(recipe, holdings, owned) (a stone already owned -> WS_STONE_OWNED);
   Materials.add(materials, id, n) capped at 99. All act on a WorkshopHoldings copy (money, materials, owned,
   upgrades, sockets) like Shop does; a WorkshopService (features/workshop/workshop_service.gd) writes the copy back to
   GameState and emits toasts ("Keen Blade +2", "Crafted Sulaimani Agate").
3. Loot: EncounterDef gains optional `materials` {id: count}; encounters.json: each enforcer 1 scrap_copper, each drone
   1 drone_coil. BattleSession._win adds them (repeat wins at EconomyRulesDef repeat share, rounded down; smallest
   edit). Chests: add `materials` to ChestDef/chests.json only if the chest payout lives outside features/world;
   otherwise report `TODO(chests)`. Materials never sell (ShopService refuses them).
4. features/workshop/view/workshop_menu.gd: WorkshopMenu extends UiScreen, ID &"workshop", backdrop_id &"workshop";
   title WORKSHOP_TITLE + WORKSHOP_TITLE_MUSNAD,𐩱𐩡𐩥𐩧𐩪𐩠 (copy these exact letters); tabs (80,40) 1760x64 UPGRADE |
   GEMSTONES | CRAFTING (LB/RB), MoneyCounter (1600,48); left list (80,140) 460x760 (ListRow; "+2" chip, "MAX" chip);
   centre (580,140) 760x620: the jambiyah (hilt + blade meshes) turning in a HologramStage or the item icon 256 px;
   GEMSTONES shows the worn hilt's sockets as 3 circles 96 px under it (focus = c_brass, locked = hidden); right
   PREVIEW (1380,140) 460x620 stat rows now -> after (Gear.build_hero); MATERIALS REQUIRED (580,780) 760x120: icon 48 +
   name + "have/need" (c_good / c_bad) + riyal; big button (760,920) 400x80 UPGRADE / SET STONE / CRAFT, disabled with
   the reason text; PromptStrip [A] Confirm [X] Remove stone [B] Back [LB/RB] Tab. Setting a stone that sits in
   another hilt moves it (Stones.set_stone); X removes for free.
5. ui_stack.gd: change ONLY `register(WORKSHOP_ID, ...)` to WorkshopMenu.new(). The bench (WorkshopSpot.opened) opens
   &"workshop" as today. Text keys (English) in localization/workshop.csv.

## Do NOT edit (no Arabic script anywhere)
features/world/**, content/world/**, features/equipment/** (read only), features/progression/** (read only),
features/combat/logic/**, core/save/**, other ui_stack.gd lines, docs/DECISIONS.md, HANDOFF.md, any *.import.

## Tests (features/workshop/tests/)
next_cost at +0/+1/+2 for a Common and a Rare item (factor applied, rounded); +3 gives WS_MAX; short money and short
materials each refuse and change nothing; an upgrade raises Gear.build_hero's stat by upgrade x level; crafting
pays riyal + materials and adds the output; a second sulaimani refuses; materials cap at 99; a win pays materials and
a repeat win half (rounded down); materials cannot be sold; setting a stone moves it out of its old hilt; the screen
opens by id with 3 tabs and the button disabled with its reason when short.

## Proof
`bash tools/check.sh` raw last 15 lines; renders C:/dev/game/inbox/menu_workshop_<tab>.png (a .tscn wrapper,
non-headless); small WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
