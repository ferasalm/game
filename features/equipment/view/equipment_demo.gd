extends Node
## Manual check: opens the equipment screen over a plain background (F6 in the editor) with a few owned items.
## Confirm or Esc closes it and prints the saved equipment.

@export var screen: EquipmentScreen


func _ready() -> void:
	for item_id: StringName in [&"swift_hilt", &"keen_blade", &"anvil_hilt", &"arc_arm", &"lens_array", &"cradle_spine", &"dawn_lens"]:
		Inventory.add(GameState.inventory, item_id)
	screen.closed.connect(_on_closed)
	screen.open()


func _on_closed() -> void:
	print("equipment closed, equipment: ", GameState.equipment)
	get_tree().quit()
