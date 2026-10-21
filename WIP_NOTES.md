# WIP notes P1b (UI and visual foundation)
State: ALL 6 brief items are built; `bash tools/check.sh` passed (307 tests) before this commit. Only the report is left.

## Done
1. UiLayers (features/ui/view/ui_layers.gd): HUD 5, DIALOGUE 8, PAUSE 9, SCREEN 10, CONFIRM 14, LOOT 20, CARD 25, TITLE 30, TOAST 35, TRANSITION 40. Used in loot_popup, area_title_card, title_overlay, equipment_screen (one-line edit, not mine).
2. UiScreen, UiPanel, UiMotion (tweens ignore time scale), UiSweep, style.json + ui_style_def.gd v2 keys (plus s_party_w, s_pause_h, s_slide, s_loot_*, s_end_button_*, s_cmd_desc_h). Ui.panel/title_pair/sweep/confirm added to ui.gd.
3. Screens (ui_stack.gd): push/pop/clear/top/depth/is_open_id/register/has_screen/open, pause + focus restore, back/menu routing, EventBus.game_paused, closes all on Router.flow_changed != exploring.
4. PauseMenu + PauseParty + PauseLogic (features/ui/logic), ConfirmDialog, EquipmentHost (registered &"equipment"), localization/pause.csv. Items hidden until someone registers &"items".
5. PauseWait (features/combat/view/pause_wait.gd) used by battle_event_player and battle_juice; juice cancels freeze on game_paused. Tests in features/combat/tests/test_pause_safety.gd.
6. CharacterVisual facade: play(state, facing), anchor_position(feet|hand|head), clip_event; VisualSource base, PixelSource, PixelMotion, PuppetSource stub, CharacterMotion (root moves only); VisualRulesDef flags puppet / pulse_squash.

## Left
- Send the final report (<=300 words) via SubagentHandback. Run `python tools/map.py` and recommit if MAP.md differs.

## Gotchas / report items
- Layer literals left in files I do not own: dialogue_box.gd and battle_hud.gd (default layer 1, no constant), rooftop.gd debug CanvasLayer (default).
- create_timer still used in files I do not own: battle_action_player.gd:56, battle_stage.gd:113, battle_fighters.gd:154 (use PauseWait.seconds(host, t)).
- Tweens-ignore-time-scale is not unit-testable (no Tween getter).
- Tab (menu) while PrototypeMain's direct EquipmentScreen is open would open pause on top.
- Tests are synchronous (no await) so waits are tested via PauseWait._process and can_process().
