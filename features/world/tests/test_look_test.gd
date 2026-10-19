extends TestCase
## The look-test scene builds without errors (headless: no pixels are drawn, but every node and resource is made).


func test_scene_builds() -> void:
	var scene: Node = (load("res://features/world/look_test/look_test.tscn") as PackedScene).instantiate()
	tree.root.add_child(scene)
	check(scene.get_child_count() > 100, "diorama, light, sprite and camera were added")
	scene.free()
