class_name TestNeonGame
extends TestCase
## purpose: The first playable's flow wires up headless: start -> cold open -> roof -> fight on the map -> back on the
## roof after a win -> exit card -> start again; a lost fight (Quit) returns to the start.


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
	(_child(game, StartFlow) as StartFlow).done.emit(&"hard")
	(_child(game, ColdOpen) as ColdOpen).done.emit()
	return _child(game, RoofScene) as RoofScene


func test_launch_plays_through_to_the_exit_card() -> void:
	var game := _game()
	check_eq(game.stage, &"start", "the game opens on the start flow")
	check(_child(game, StartFlow) != null, "a StartFlow is shown")
	(_child(game, StartFlow) as StartFlow).done.emit(&"hard")
	check_eq(game.stage, &"cold_open", "the start flow leads to the cold open")
	check_eq(game.difficulty, &"hard", "the chosen difficulty is kept")
	(_child(game, ColdOpen) as ColdOpen).done.emit()
	check_eq(game.stage, &"roof", "the cold open leads to the prison roof")
	var roof := _child(game, RoofScene) as RoofScene
	roof.battle_requested.emit(roof.guards(), roof.hero().position, false)
	check_eq(game.stage, &"battle", "touching a guard starts the fight")
	var battle := _child(game, MapBattle) as MapBattle
	check(battle != null and battle.sim != null, "a MapBattle runs with a sim")
	battle.ended.emit(true)
	check_eq(game.stage, &"roof", "a win returns to the roof")
	roof.exited.emit()
	check_eq(game.stage, &"end", "the cable line leads to the exit card")
	game._process(game.end_card_seconds + 0.1)
	check_eq(game.stage, &"start", "the exit card returns to the start flow")
	game.queue_free()


func test_a_quit_fight_returns_to_the_start() -> void:
	var game := _game()
	var roof := _to_roof(game)
	roof.battle_requested.emit(roof.guards(), roof.hero().position, true)
	(_child(game, MapBattle) as MapBattle).ended.emit(false)
	check_eq(game.stage, &"start", "quitting a lost fight returns to the start flow")
	game.queue_free()


func test_the_project_launches_neon_game() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://features/neon/neon_game.tscn",
			"launching the project plays Neon Glitch")
