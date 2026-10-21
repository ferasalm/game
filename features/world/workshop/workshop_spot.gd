class_name WorkshopSpot
extends InteractSpot
## The workshop bench: its sprite, and the interact prompt. Pressing interact next to it emits `opened`.

## The player pressed interact next to the bench.
signal opened


func _init(rules: ExploreRulesDef, player: Player) -> void:
	var bench := CharacterVisual.new()
	bench.set_sprite(&"workshop_bench")
	bench.set_prop(true)
	super(rules, player, "WORLD_PROMPT_WORKSHOP", bench.height() + rules.prompt_height)
	add_child(bench)


func _interact() -> void:
	opened.emit()
