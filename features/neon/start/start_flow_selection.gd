class_name StartFlowSelection
extends RefCounted
## Connects start-flow mouse targets to selection and confirm callbacks.


static func connect_ui(ui: StartUI, steps: StartSteps, handle: Callable, busy: Callable) -> void:
	if ui == null:
		return
	ui.any_pressed.connect(func() -> void: handle.call(&"press_any"))
	ui.menu_hovered.connect(func(index: int) -> void: hover(steps, ui, &"menu", index, busy))
	ui.menu_chosen.connect(func(index: int) -> void: click(steps, ui, &"menu", index, busy, handle))
	ui.hero_hovered.connect(func(hero: StringName) -> void: hover(steps, ui, &"hero", hero, busy))
	ui.hero_chosen.connect(func(hero: StringName) -> void: click(steps, ui, &"hero", hero, busy, handle))
	ui.difficulty_hovered.connect(func(diff: StringName) -> void: hover(steps, ui, &"difficulty", diff, busy))
	ui.difficulty_chosen.connect(func(diff: StringName) -> void: click(steps, ui, &"difficulty", diff, busy, handle))


static func hover(steps: StartSteps, ui: StartUI, kind: StringName, value: Variant, busy: Callable) -> void:
	if busy.call():
		return
	match kind:
		&"menu":
			if steps.state == StartSteps.STATE_MENU and steps.select_menu_index(int(value)):
				ui.update_menu_cursor(steps.menu_cursor)
		&"hero":
			if steps.state == StartSteps.STATE_PICK:
				steps.select_hero(StringName(value))
				ui.update_hero_selection(steps.hero)
		&"difficulty":
			if steps.state == StartSteps.STATE_PANEL:
				steps.set_difficulty(StringName(value))
				ui.update_difficulty(steps.difficulty)


static func click(steps: StartSteps, ui: StartUI, kind: StringName, value: Variant, busy: Callable, handle: Callable) -> void:
	if busy.call():
		return
	match kind:
		&"menu":
			if steps.state == StartSteps.STATE_MENU and steps.select_menu_index(int(value)):
				handle.call(&"confirm")
		&"hero":
			if steps.state == StartSteps.STATE_PICK:
				steps.select_hero(StringName(value))
				ui.update_hero_selection(steps.hero)
				handle.call(&"confirm")
		&"difficulty":
			if steps.state == StartSteps.STATE_PANEL:
				steps.set_difficulty(StringName(value))
				ui.update_difficulty(steps.difficulty)
				handle.call(&"confirm")
