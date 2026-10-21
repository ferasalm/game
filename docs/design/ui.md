# UI look: Sana'a night glass (menus, HUD, popups)
Owner brief 2026-10-21. Code: features/ui (style, theme, painted ornaments), plus the screens that use it.
Every number and colour lives in `content/ui/style.json` (UiStyleDef): sizes are pixels at 1920x1080 and the project
stretches (canvas_items, keep aspect) so 1280x720 and 1920x1080 both read well.

## Identity
- Deep indigo glass panels, a thin brass outline, a thin gypsum line inside it and a small brass diamond in each corner
  (painted nine-patch frames, UiOrnament). The gypsum zigzag frieze of tower-house facades divides sections.
- Fonts (OFL, assets/fonts): Amiri for reading, Reem Kufi for titles, names and numbers (it falls back to Amiri).
- Focus = warm brass glow and a brass bar on the left of a button. Neon cyan (SP, tech moves) and magenta
  (cancels, cast zone) are tiny accents only. HP bars run red to orange, SP bars blue to cyan.
- Rarity colours come from RarityDef (rarities.json); a name uses its tier colour, a small pill names the tier.

## API
`Ui.theme()` (cached Theme), `Ui.style()`, `Ui.label(text, variant, colour)`, `Ui.divider()`, `Ui.screen_root()`,
`Ui.chip_row(chips)`. Label variations: TitleLabel, NameLabel, NumberLabel, MutedLabel, SmallLabel, CaptionLabel,
BannerLabel. Panels: PanelContainer, PlatePanel, InsetPanel. Buttons: Button, TabButton. Bars: HpBar, SpBar.
`UiRarity.colour / item_label / tag / order`. Every screen root comes from `Ui.screen_root()` (theme + linear filter).

## Screens
- Battle HUD: brass timeline track with COMMAND mark and a tinted cast zone, framed head icons with a team pointer;
  command menu with SP cost, [cancels], target scope and "will interrupt" tags and a description line; party panel with
  name plates and HP/SP bars; end panel lists the spoils (items not owned yet) in rarity colours.
- Dialogue: ornate frame, name plate in the speaker colour, Amiri text, `portrait_flip` per speaker in speakers.json
  (Bilqis's real portrait faces away: flipped; stand-ins already face the box).
- Equipment (EquipmentScreen, the bench): tabs per hero, OWNED items per slot, perk and tech moves of the focused item,
  stats base vs. staged kit; Confirm writes GameState.equipment through Inventory.equip.
- LootPopup (EventBus.item_obtained): queued "Obtained" banners, light sweep for Rare and above, AudioDirector.play_item.
- TitleOverlay "Qarnaw / قرناو / Press any key" holds the opening shot on the moon (ExploreCamera.hold_intro); then
  the intro pan plays and AreaTitleCard shows the area in Latin and Arabic.

## Open
No gamepad shoulder buttons for the hero tabs yet (focus moves to them). The 3D intent labels still use the old font.
