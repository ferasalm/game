extends Node
## Manual check: opens the workshop menu over a plain background (F6 in the editor). Confirm or Esc closes it and
## prints the saved pair.

@export var menu: WorkshopMenu


func _ready() -> void:
	menu.closed.connect(_on_closed)
	menu.open()


func _on_closed() -> void:
	print("workshop closed, equipment: ", GameState.equipment)
	get_tree().quit()
