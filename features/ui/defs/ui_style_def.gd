class_name UiStyleDef
extends Def
## The look of every menu and HUD (content/ui/style.json): three font files, named colours (c_*), sizes in pixels
## at 1920x1080 (s_*) and times in seconds (t_*). Screens ask for a name; they never hold a number or colour.

const COLOURS: Array[StringName] = [
	&"c_glass", &"c_glass_deep", &"c_indigo", &"c_indigo_lit", &"c_brass", &"c_brass_dim", &"c_gypsum",
	&"c_gypsum_dim", &"c_text", &"c_muted", &"c_cyan", &"c_magenta", &"c_hp_a", &"c_hp_b", &"c_sp_a", &"c_sp_b",
	&"c_good", &"c_bad", &"c_party", &"c_enemy", &"c_cast", &"c_shadow", &"c_scrim", &"c_title_shade",
	&"c_glass_lit", &"c_epithet", &"c_disabled", &"c_qam_red", &"c_qam_amber", &"c_qam_green", &"c_qam_blue", &"c_qam_violet"]
const SIZES: Array[StringName] = [
	&"s_font_body", &"s_font_small", &"s_font_name", &"s_font_title", &"s_font_big", &"s_font_number", &"s_margin",
	&"s_pad", &"s_gap", &"s_frame_cell", &"s_frame_line", &"s_frame_gap", &"s_ornament", &"s_frieze_h",
	&"s_frieze_period", &"s_button_h", &"s_bar_h", &"s_icon", &"s_focus_glow", &"s_outline", &"s_title_space",
	&"s_list_row_h", &"s_card_w", &"s_card_h", &"s_card_portrait", &"s_money_h", &"s_prompt_h", &"s_key_icon", &"s_confirm_w",
	&"s_toast_w", &"s_pause_w", &"s_pause_h", &"s_party_w", &"s_dialog_w", &"s_dialog_h", &"s_plate_h", &"s_portrait_w", &"s_portrait_h",
	&"s_sweep_h", &"s_slide", &"s_loot_top", &"s_loot_w", &"s_end_button_w", &"s_end_button_h", &"s_cmd_desc_h",
	&"s_head_icon", &"s_timeline_w", &"s_timeline_top", &"s_prompt_near", &"s_prompt_far", &"s_toast_top",
	&"s_strip_bottom", &"s_defeat_w", &"s_defeat_h", &"s_portrait_x", &"s_portrait_slide", &"s_dialog_right",
	&"s_dialog_bottom", &"s_plate_w", &"s_plate_lift", &"s_dialog_inset", &"s_area_x", &"s_area_y", &"s_area_w"]
const TIMES: Array[StringName] = [
	&"t_loot_fade", &"t_loot_hold", &"t_loot_shine", &"t_title_fade", &"t_pulse", &"t_card_in", &"t_card_hold",
	&"t_card_out",
	&"t_focus_sweep", &"t_screen_in", &"t_screen_out", &"t_portrait_in", &"t_text_char", &"t_money_count", &"t_toast_hold",
	&"t_toast_fade", &"t_transition_sweep", &"t_defeat_fade", &"t_money_flash", &"t_caret", &"t_prompt_fade"]
const FONTS: Array[StringName] = [&"font_body", &"font_bold", &"font_title", &"font_musnad"]

var colours: Dictionary[StringName, Color] = {}
var sizes: Dictionary[StringName, int] = {}
var times: Dictionary[StringName, float] = {}
var fonts: Dictionary[StringName, String] = {}
## Per-character icon paths (character id -> image file); a missing file falls back to a coloured disc.
var icons: Dictionary[String, String] = {}


func read(r: DefReader) -> void:
	id = r.id()
	for key: StringName in COLOURS:
		colours[key] = r.color(String(key))
	for key: StringName in SIZES:
		sizes[key] = r.integer(String(key), 1, 4000)
	for key: StringName in TIMES:
		times[key] = r.number(String(key), 0.0, 30.0)
	for key: StringName in FONTS:
		fonts[key] = r.text(String(key))
	icons = r.text_map("icons")


func colour(key: StringName) -> Color:
	return colours.get(key, Color.MAGENTA)


func size(key: StringName) -> int:
	return sizes.get(key, 0)


func time(key: StringName) -> float:
	return times.get(key, 0.0)
