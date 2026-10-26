class_name StartFlowInput
extends RefCounted
## Maps a raw input event to the start-flow action it should trigger.


static func action_for(event: InputEvent, state: StringName) -> StringName:
	if state == StartSteps.STATE_TITLE:
		return &"press_any" if any_press(event) else &""
	if event.is_action_pressed("interact"):
		return &"confirm"
	if event.is_action_pressed("back"):
		return &"back"
	if event.is_action_pressed("move_up"):
		return &"move_up"
	if event.is_action_pressed("move_down"):
		return &"move_down"
	if event.is_action_pressed("move_left"):
		return &"move_left"
	if event.is_action_pressed("move_right"):
		return &"move_right"
	return &""


static func any_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return (event as InputEventKey).pressed and not (event as InputEventKey).echo
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	return false
