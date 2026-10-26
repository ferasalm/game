class_name TestNeonPlaytest
extends TestCase
## purpose: NeonGame.playtest_state reports the roof room and hero position, and a running fight's ticks and three
## fighters, and the capture's source points at the game.


func _game() -> NeonGame:
	var game := (load("res://features/neon/neon_game.tscn") as PackedScene).instantiate() as NeonGame
	tree.root.add_child(game)
	return game


func _child(game: NeonGame, kind: Variant) -> Node:
	for node: Node in game.get_children():
		if is_instance_of(node, kind) and not node.is_queued_for_deletion():
			return node
	return null


func _to_roof(game: NeonGame) -> RoofScene:
	GameState.start_new()
	game.show_roof()
	return _child(game, RoofScene) as RoofScene


func test_playtest_state_on_the_roof() -> void:
	var game: NeonGame = _game()
	_to_roof(game)
	var state: Dictionary = game.playtest_state()
	check_eq(state["stage"], "roof", "the stage is the roof")
	check_eq(state["room"], "prison_roof", "the room id is the prison roof")
	var hero: Array = state["hero"]
	check_eq(hero.size(), 2, "the hero position is [x, y]")
	var capture := _child(game, PlaytestCapture) as PlaytestCapture
	check_eq(capture.source, game, "the capture's source is the game")
	game.queue_free()


func test_playtest_state_in_a_fight() -> void:
	var game: NeonGame = _game()
	var roof := _to_roof(game)
	roof.battle_requested.emit(roof.guards(), roof.hero().position, false)
	var state: Dictionary = game.playtest_state()
	var fight: Dictionary = state["fight"]
	check(fight.has("ticks"), "the fight has a tick count")
	check_eq((fight["fighters"] as Array).size(), 3, "one hero and two guards")
	game.queue_free()
