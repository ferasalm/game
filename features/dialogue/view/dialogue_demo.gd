extends Node
## Manual check: plays the workshop_first dialogue over a plain background (F6 in the editor). Press E / Enter / Space.

@export var box: DialogueBox
@export var dialogue_id: StringName = &"workshop_first"


func _ready() -> void:
	box.finished.connect(_on_finished)
	box.play(dialogue_id)


func _on_finished(finished_id: StringName) -> void:
	print("dialogue finished: ", finished_id)
	get_tree().quit()
