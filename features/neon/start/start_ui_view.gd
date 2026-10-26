class_name StartUIView
extends Control
## Typed node references and view signals shared by the start-flow UI and its styling helper.

signal menu_hovered(index: int)
signal menu_chosen(index: int)
signal hero_hovered(hero: StringName)
signal hero_chosen(hero: StringName)
signal difficulty_hovered(difficulty: StringName)
signal difficulty_chosen(difficulty: StringName)
signal any_pressed

@onready var title_view: Control = %TitleView
@onready var title_label: Label = %TitleLabel
@onready var press_prompt: Label = %PressPrompt
@onready var menu_view: Control = %MenuView
@onready var menu_new_game: Control = %MenuNewGame
@onready var menu_new_game_bar: ColorRect = %MenuNewGameBar
@onready var menu_new_game_bg: Panel = %MenuNewGameBg
@onready var menu_new_game_label: Label = %MenuNewGameLabel
@onready var menu_continue: Control = %MenuContinue
@onready var menu_continue_label: Label = %MenuContinueLabel
@onready var menu_options: Control = %MenuOptions
@onready var menu_options_label: Label = %MenuOptionsLabel
@onready var menu_quit: Control = %MenuQuit
@onready var menu_quit_bar: ColorRect = %MenuQuitBar
@onready var menu_quit_bg: Panel = %MenuQuitBg
@onready var menu_quit_label: Label = %MenuQuitLabel
@onready var pick_view: Control = %PickView
@onready var pick_header: Label = %PickHeader
@onready var pick_musnad: Label = %PickMusnad
@onready var card_rydan: Control = %CardRydan
@onready var card_rydan_border: Panel = %CardRydanBorder
@onready var card_rydan_name: Label = %CardRydanName
@onready var card_rydan_musnad: Label = %CardRydanMusnad
@onready var card_rydan_role: Label = %CardRydanRole
@onready var card_bilqis: Control = %CardBilqis
@onready var card_bilqis_border: Panel = %CardBilqisBorder
@onready var card_bilqis_name: Label = %CardBilqisName
@onready var card_bilqis_musnad: Label = %CardBilqisMusnad
@onready var card_bilqis_later: Label = %CardBilqisLater
@onready var panel_view: Control = %PanelView
@onready var panel_name: Label = %PanelName
@onready var panel_musnad: Label = %PanelMusnad
@onready var panel_role: Label = %PanelRole
@onready var panel_story: Label = %PanelStory
@onready var panel_style_1: Label = %PanelStyle1
@onready var panel_style_2: Label = %PanelStyle2
@onready var panel_style_3: Label = %PanelStyle3
@onready var panel_style_4: Label = %PanelStyle4
@onready var diff_title: Label = %DiffTitle
@onready var diff_musnad: Label = %DiffMusnad
@onready var btn_normal: Control = %BtnNormal
@onready var btn_normal_bg: Panel = %BtnNormalBg
@onready var btn_normal_bar: ColorRect = %BtnNormalBar
@onready var btn_normal_label: Label = %BtnNormalLabel
@onready var btn_hard: Control = %BtnHard
@onready var btn_hard_bg: Panel = %BtnHardBg
@onready var btn_hard_bar: ColorRect = %BtnHardBar
@onready var btn_hard_label: Label = %BtnHardLabel
@onready var diff_desc: Label = %DiffDesc
@onready var hud_boot_view: Control = %HudBootView
@onready var hud_musnad_1: Label = %HudMusnad1
@onready var hud_musnad_2: Label = %HudMusnad2
@onready var hud_musnad_3: Label = %HudMusnad3
@onready var hint_bar: Control = %HintBar
@onready var hint_label: Label = %HintLabel
