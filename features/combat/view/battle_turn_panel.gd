class_name BattleTurnPanel
extends PanelContainer
## What a hero's turn shows, in one framed panel: that hero's full card over the compact command menu (or the herb list), placed beside the
## hero on the side where no fighter stands. It is only visible while a menu is open, and never wider than the view's
## turn_menu_w, so the fighters stay clear.

var card: BattleHeroCard
var _menu: BattleCommandMenu
var _items: BattleItemMenu
var _view: BattleViewDef
var _hero_id: StringName = &""


func setup(view: BattleViewDef, shown_hp: Dictionary[StringName, int], menu: BattleCommandMenu, items: BattleItemMenu) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	BattleStyle.tight_panel(self, &"PanelContainer", view)
	custom_minimum_size.x = view.turn_menu_w
	var box := VBoxContainer.new()
	add_child(box)
	card = BattleHeroCard.new()
	card.setup(view, shown_hp)
	box.add_child(card)
	box.add_child(Ui.divider())
	_menu = menu
	_items = items
	box.add_child(menu)
	box.add_child(items)
	visible = false


func is_open() -> bool:
	return _menu.is_open() or _items.is_open()


## The panel's screen rect right now (a zero rect when hidden).
func rect() -> Rect2:
	return Rect2(position, size) if visible else Rect2()


func update(sim: BattleSim, rects: Dictionary[StringName, Rect2], screen: Rect2) -> void:
	visible = is_open()
	if not visible:
		_hero_id = &""
		return
	var hero: UnitState = _menu.hero()
	if hero != null and hero.unit_id != _hero_id:
		_hero_id = hero.unit_id
		card.show_hero(sim, hero)
	card.update()
	size = get_combined_minimum_size()
	var blockers: Array[Rect2] = []
	blockers.assign(rects.values())
	var around: Array[Rect2] = HudLayout.beside(rects.get(_hero_id, Rect2()), size, _view.turn_gap)
	position = HudLayout.pick(around, blockers, screen).position
