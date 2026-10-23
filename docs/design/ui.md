# UI look v2: Sana'a night glass, painted (menus, HUD, dialogue, popups)
Owner notes 2026-10-21. Code: features/ui plus the screens that use it. Every number and colour lives in
`content/ui/style.json` (UiStyleDef); sizes are pixels at 1920x1080 (canvas_items, keep aspect). Wireframes below use
that grid: (x,y) is the top-left, WxH the size. Reference only: Hades II (painted portrait, ornate box, prompts) and
Octopath (turn bar top, party top-right data, info under the enemy). Our twist is night glass plus gypsum plus qamariya.
## 1. Identity v2
- Panel = dark indigo glass (c_glass), brass outline, gypsum tracery frame: a zigzag/rosette frieze along the top and
  bottom edges (Ui.divider, UiOrnament) and a brass diamond per corner. Title bars carry a Musnad + English pair.
- Colour by role: surface c_glass / c_glass_deep (popups, toasts) / c_glass_lit (focused row); line c_brass, c_gypsum_dim;
  text c_text, c_muted, c_disabled; name c_brass; epithet c_epithet; good c_good; bad c_bad; party c_party; enemy c_enemy;
  SP and tech c_cyan; cancel c_magenta; rarity colours from RarityDef; money c_brass.
- Fonts: Reem Kufi for English titles, names, numbers, prices, button prompts; Noto Sans Old South Arabian for
  Musnad; Amiri for descriptions and dialogue.
- Focus: brass bar on the left (s_focus_glow wide), row tinted c_glass_lit, and a qamariya sweep: a 4 px line under the
  row runs red, amber, green, blue, violet (c_qam_*) left to right in t_focus_sweep, then rests on brass. The same five
  colours wipe across the screen in t_transition_sweep for screen changes and the battle warp (as stained-glass shards).
- Motion (tweens ignore time scale, run while paused): screen in t_screen_in (fade + 24 px rise), out t_screen_out;
  portrait slides in from -80 px in t_portrait_in; text reveal t_text_char per character (confirm = finish line);
  money counts up in t_money_count; toasts hold t_toast_hold. Honour a "reduce motion" flag later: skip sweeps.
- Sound cue ids (sounds.json): ui_move, ui_confirm, ui_back, ui_open, ui_close, ui_error, ui_coin, ui_buy, ui_sell,
  ui_save, ui_drink, ui_toast, ui_type_tick, ui_portrait_in, ui_sweep.
- Input: move = d-pad/left stick/arrows; accept = A/Enter/Space; back = B/Esc-handled; `menu` = Esc/Tab/Start. `menu`
  opens pause only when no screen is open and no unhandled consumer; otherwise the top screen handles `back`.
  Tabs: LB/RB or Q/E. Keyboard and gamepad are equal; mouse hover moves focus. Prompt strip shows device glyphs.
## 2. Components (style keys in brackets; all sizes s_*, colours c_*, times t_*)
- UiScreen (base, Control from Ui.screen_root): scrim [c_scrim], panel slot, `prompts: Array` (key, text_key), emits
  `closed`; handles back/menu through UiStack; focus restored on pop; fades [t_screen_in, t_screen_out].
- UiPanel (frame): nine-patch glass [c_glass, c_brass, s_frame_cell, s_frame_line, s_frame_gap, s_ornament], optional
  title bar (English Reem Kufi s_font_title + Musnad right-aligned c_brass_dim) and frieze
  [s_frieze_h, s_frieze_period].
- ListRow: h [s_list_row_h]; icon [s_icon] | name (rarity colour, NameLabel) | count "x3" (NumberLabel, c_muted) | tag
  chip right (chip_row). States: normal, focus (sweep + bar [s_focus_glow, c_glass_lit]), disabled [c_disabled], new.
- PartyCard: w [s_card_w] h [s_card_h]; portrait [s_card_portrait] in a small frame, name (NameLabel), HP bar and SP bar
  [s_bar_h, c_hp_a/b, c_sp_a/b] with numbers; KO state greys the portrait and shows "KO" [c_bad]; active hero: brass frame.
- MoneyCounter: [s_money_h] pill, riyal glyph + NumberLabel c_brass; counts up/down [t_money_count], flashes c_good/c_bad.
- InteractionPrompt: [s_prompt_h] small glass pill above the object: key glyph + verb ("Drink", "Talk", "Open").
- ConfirmDialog: w [s_confirm_w], centred over scrim; title, one line, two buttons (default = safe one), back = No.
- Toast: w [s_toast_w], top-centre y=96, queue, [t_toast_hold, t_toast_fade]; kinds: info, good, bad; ui_toast cue.
- PromptStrip (Hades): bottom centre y=1020, h [s_prompt_h]; "[A] Select   [B] Back   [LB] Cease" glyph + text pairs.
## 3. Wireframes (focus order = numbers; inputs listed under each)
### Pause (UiScreen, layer pause). Left menu, right party; frieze under the title.
```
(0,0)  scrim c_scrim
(120,120) 560x640 PAUSED / 𐩣𐩩𐩥𐩤𐩰      (760,120) 1040x640 PARTY
 1 Resume          2 Items            [PartyCard Zayd   (800,180) 360x120][PartyCard Bilqis (1200,180)]
 3 Equipment       4 Load last save   [Hero details: HP/SP numbers, equipped hilt, blade, prosthetic]
 5 Unstuck         6 Title            ---- frieze ----
 7 Quit                               Area: Souq al-Milh Rooftops   Time 01:24:07   (MoneyCounter) 1,240 riyal
(0,1020) PromptStrip: [A] Select  [B]/[Menu] Resume
```
Up/down move, A opens, B/Menu = Resume. Load/Unstuck/Title/Quit open ConfirmDialog (Load disabled with no save,
Unstuck = "Move to the last safe spot"). Items/Equipment push their screens on the stack.
### Items (pause > Items)
```
(120,100) 760x760 ITEMS / 𐩱𐩡𐩱𐩶𐩧𐩱𐩳           (920,100) 880x520 detail panel
 tabs [Herbs][Keys]  (LB/RB)                  icon 120 + name (rarity) + "Owned 3"
 1..n ListRow: icon name  x3  [HP+60]         description (Amiri s_font_body), effect line (c_good)
(920,640) 880x240 "Use on" hero picker: 2 PartyCards (focus order 1..2) showing HP/SP; preview "+60 -> 140/140"
```
A on a row selects it and moves focus to the hero picker; A on a hero uses it (ui_drink cue, bar animates, count drops,
toast "Used Feathered herb on Zayd"); B returns to the list; full HP/SP or no target = disabled hero + ui_error.
### Shop (herb stall; own screen over the world)
```
(120,100) 1680x80  HERB STALL / 𐩵𐩫𐩱𐩬 𐩱𐩡𐩱𐩲𐩪𐩱𐩨     tabs [Buy][Sell] (LB/RB)       MoneyCounter (1500,112)
(120,200) 900x700 ListRow: icon name  price(riyal)  owned x2       (1060,200) 740x470 detail: art, desc, effect
(1060,690) 740x210 Price 40  Owned 2  Money after: 1,200 -> 1,160 (c_bad when < 0)   Quantity [-] 1 [+]
```
Focus: tabs, list, quantity. Left/right changes quantity, A buys/sells (ui_buy / ui_sell + ui_coin), unaffordable or
sold-out rows use [c_disabled] and ui_error. Sell tab lists consumables only, price = sell value. B closes.
### Sabil prompt and save
```
In world: InteractionPrompt over the fountain: [A] Drink            (centre of fountain, y-140)
ConfirmDialog (720x300 at 600,390): SABIL / 𐩦𐩨𐩺𐩡   "Drink to rest? This saves your game and restores everyone."
   1 Drink (default)   2 Not now
Then: ui_drink, qamariya sweep, bars fill, Toast "Game saved" (good). Second line of the toast: "The Concession's patrols return."
```
Save slot is single (slot_1) in v0.3. If saving fails: Toast bad "Could not save", no refill.
### Defeat (over a darkened arena, no pause allowed)
```
Fade to c_scrim in [t_defeat_fade]; centre panel 640x420 at (640,330): DEFEATED / 𐩠𐩸𐩣𐩩𐩣
 1 Retry fight (default)   2 Load last save   3 Title
```
Retry restores the pre-battle snapshot; Load is disabled with no save; Title asks ConfirmDialog.
### Dialogue (Hades II style)
```
Portrait (60,120) 620x960: painted chest-up, bleeds off the bottom, slides in from the left, speaker flips via
   portrait_flip; the listener dims [c_scrim]. Speaker change = old slides out, new slides in.
Box (700,740) 1140x260 ornate glass + frieze; Nameplate (740,700) 420x56 raised tab on the box top edge:
   NAME (Reem Kufi, c_brass)     epithet line under it, smaller (Amiri, c_epithet): "Rooftop runner"
Text (740,780) 1060x180 Amiri s_font_body, reveal t_text_char/char; "advance" caret blinks bottom right.
PromptStrip bottom centre (y=1020): [A] Continue  [Y] Skip  [LB] Cease  (Cease = close at once, marks as read)
```
A: finish line, then next. Choices (later): up to 3 rows inside the box, focus order top to bottom.
### Battle HUD (Grandia timeline + Octopath data)
```
Timeline (360,24) 1200x96: brass track, COMMAND mark, magenta cast zone, framed head icons (party c_party, enemy c_enemy)
Enemy info under each enemy (world-space label, boosted): name, HP bar, intent text "Slash > Zayd [will interrupt]"
Party cards (1100,780) two cards 360x120 bottom right, stacked 1 row: portrait, HP/SP bars + numbers; acting hero = brass
Command menu (140,640) 460x300: 1 Attack  2 Skill/Tech (SP)  3 Items  4 Defend  5 Flee(disabled in boss)
   Items opens a sub-list at (620,640) 520x300: ListRow icon name x3 (reserved counts); A then target; B back
Description line (140,950) 1000x56: cost, [cancels], scope, "will interrupt" tags
PromptStrip y=1020: [A] Select  [B] Back  [LB] Info
```
Target pick: left/right cycles targets (cursor ring + enemy info enlarges), A confirms, B back. Timeline pauses while
the menu is open (Grandia "wait"). KO'd units show greyed icons; items that would revive show only on KO'd heroes.
### Area card and title
```
Area card: centre-left (160,420) 900x200, no panel: Musnad line (Noto Sans Old South Arabian s_font_big) over
English line, a gypsum frieze draws left to right; in [t_card_in], hold [t_card_hold], out [t_card_out]. No input.
Title: moon sky behind; "Qarnaw / 𐩤𐩧𐩬𐩱𐩥" centred (s_font_big), frieze below, menu list centre (760,620) 400x260:
 1 New game  2 Continue (disabled with no save)  3 Quit; PromptStrip bottom. Any key from the intro reveals the menu.
```
## 4. New style.json keys and localization
Add to content/ui/style.json "default" AND to the named const array in ui_style_def.gd (the reader requires both).

| Key | Value | Array |
|---|---|---|
| c_glass_lit | #241d4aee | COLOURS |
| c_qam_red / c_qam_amber / c_qam_green / c_qam_blue / c_qam_violet | #e0443c / #f2a93a / #4fbf7a / #3f8fe0 / #8a5ad8 | COLOURS |
| c_epithet | #7fc9c4 | COLOURS |
| c_disabled | #6f6784 | COLOURS |
| s_list_row_h / s_card_w / s_card_h / s_card_portrait | 64 / 360 / 120 / 88 | SIZES |
| s_money_h / s_prompt_h / s_key_icon | 48 / 44 / 34 | SIZES |
| s_confirm_w / s_toast_w / s_pause_w | 720 / 520 / 560 | SIZES |
| s_dialog_w / s_dialog_h / s_plate_h | 1140 / 260 / 56 | SIZES |
| s_portrait_w / s_portrait_h / s_sweep_h | 620 / 960 / 4 | SIZES |
| t_focus_sweep / t_screen_in / t_screen_out | 0.35 / 0.22 / 0.16 | TIMES |
| t_portrait_in / t_text_char / t_money_count | 0.40 / 0.025 / 0.5 | TIMES |
| t_toast_hold / t_toast_fade / t_transition_sweep / t_defeat_fade | 2.0 / 0.3 / 0.6 / 1.2 | TIMES |
Localization (CSV per feature, `keys,en,musnad`; Musnad only for titles; ids are the keys):
- pause.csv: pause.title (Paused, 𐩣𐩩𐩥𐩤𐩰), pause.resume Resume, pause.items Items, pause.equipment Equipment, pause.load
  Load last save, pause.restart Restart, pause.unstuck Unstuck, pause.title_menu Title, pause.quit Quit, pause.area
  Area, pause.time Time, pause.confirm_load "Load your last save? Unsaved progress is lost.", pause.confirm_unstuck
  "Move to the last safe spot?", pause.confirm_title "Return to the title?", pause.confirm_quit "Quit the game?",
  pause.yes Yes, pause.no No, defeat.title (Defeated, 𐩠𐩸𐩣𐩩𐩣), defeat.retry Retry fight, defeat.load Load last save,
  defeat.title_menu Title, title.new New game, title.continue Continue, ui.cease Cease, ui.select Select, ui.back Back,
  ui.continue Continue, ui.skip Skip, ui.toast_saved Game saved.
- items.csv: items.title (Items, 𐩱𐩡𐩱𐩶𐩧𐩱𐩳), items.tab_herbs Herbs, items.tab_keys Keys, items.owned "Owned %d",
  items.use_on "Use on", items.preview "%d -> %d", items.used "Used %s on %s", items.full "Already full",
  items.empty "Nothing here", item.<id>.name and item.<id>.desc per consumable.
- shop.csv: shop.title (Herb Stall, 𐩵𐩫𐩱𐩬 𐩱𐩡𐩱𐩲𐩪𐩱𐩨), shop.buy Buy, shop.sell Sell, shop.price Price, shop.owned Owned,
  shop.money_after "Money after", shop.qty Quantity, shop.cant_afford "Not enough riyal", shop.sold_out "Sold out",
  shop.bought "Bought %s", shop.sold "Sold %s", ui.riyal riyal, ui.riyal_short YR.
- sabil.csv: sabil.title (Sabil, 𐩦𐩨𐩺𐩡), sabil.prompt Drink, sabil.ask "Drink to rest? This saves your game and
  restores everyone.", sabil.drink Drink, sabil.not_now "Not now", sabil.saved "Game saved.", sabil.patrols "The
  Concession's patrols return.", sabil.fail "Could not save.", prompt.talk Talk, prompt.open Open.
## 5. API
Kept: `Ui.theme()`, `Ui.style()`, `Ui.label(text, variant, colour)`, `Ui.divider()`, `Ui.screen_root()`,
`Ui.chip_row(chips)`, `Ui.text(key)`, `Ui.clear_cache()`. Label variations: TitleLabel, NameLabel, NumberLabel, MutedLabel,
SmallLabel, CaptionLabel, BannerLabel. Panels: PanelContainer, PlatePanel, InsetPanel. Buttons: Button, TabButton.
Bars: HpBar, SpBar (Button, TabButton as v1). `UiRarity.colour / item_label / tag / order`. Every screen root comes from `Ui.screen_root()`.
New helpers (names are the contract; builders add them under features/ui/view):
- `Ui.panel(title_en, title_musnad) -> UiPanel`: framed glass panel with the title pair and frieze.
- `Ui.title_pair(en, musnad) -> Control`: Reem Kufi English left, Musnad right.
- `Ui.sweep(target: Control) -> Tween`: the five-colour qamariya line under a focused control.
- `Ui.transition_sweep(on: Control) -> Tween`: full-screen five-colour wipe (battle warp, screen change).
- `Ui.list_row(icon, name, count, colour, tag) -> Button`: ListRow with chip_row tags and the focus sweep.
- `Ui.party_card(hero_id) -> Control`: portrait, name, HP/SP bars bound to vitals; `update(hp, sp)` animates.
- `Ui.money_counter() -> Control`: pill with `set_amount(n, animate)`.
- `Ui.prompt_strip(pairs: Array) -> Control`: glyph + text pairs; glyphs follow the last used device.
- `Ui.confirm(title_key, body_key, default_yes) -> Signal`: pushes ConfirmDialog; emits true/false.
- `Ui.toast(text_key, kind)`: queues a Toast on the toast layer.
- `Ui.interaction_prompt(verb_key) -> Control`: world-space prompt pill that fades by distance.
- `Ui.type_text(label, text) -> Tween`: character reveal with ui_type_tick; confirm finishes it.
- `UiStack.push(screen)` / `pop()` / `top()`: pause-safe stack with focus restore, back/menu routing.
- `UiLayers`: one table of layer numbers (hud, dialogue, screen, pause, confirm, toast, transition).
## 6. Open
LB/RB hero tabs on Equipment; 3D intent labels use the old font; reduce-motion flag; Musnad layout flip (later).
