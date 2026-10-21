class_name WorkshopSpot
extends InteractSpot
## The workshop bench: a plain box mesh (size and colour from explore.json; it is scenery, not a character) and the
## interact prompt. Pressing interact next to it emits `opened`.

## The player pressed interact next to the bench.
signal opened


func _init(rules: ExploreRulesDef, player: Player) -> void:
	super(rules, player, "WORLD_PROMPT_WORKSHOP", rules.bench_size.y + rules.prompt_height)
	var box := BoxMesh.new()
	box.size = rules.bench_size
	var material := StandardMaterial3D.new()
	material.albedo_color = rules.bench_color
	box.material = material
	var bench := MeshInstance3D.new()
	bench.name = "Bench"
	bench.mesh = box
	bench.position.y = rules.bench_size.y / 2.0
	add_child(bench)


func _interact() -> void:
	opened.emit()
