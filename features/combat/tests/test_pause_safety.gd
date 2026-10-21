extends TestCase
## Pausing the game stops battle waits and cancels a hitstop (a SceneTreeTimer would keep running during a pause).


func _wait_of(host: Node) -> PauseWait:
	for child: Node in host.get_children():
		if child is PauseWait:
			return child
	return null


func test_wait_counts_game_time_and_finishes_once() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var wait: PauseWait = _wait_of(host)
	check(wait == null, "no wait yet")
	var fired: Array[int] = []
	PauseWait.seconds(host, 1.0).connect(func() -> void: fired.append(1))
	wait = _wait_of(host)
	wait._process(0.6)
	check(fired.is_empty(), "still waiting at 0.6 s")
	wait._process(0.5)
	check_eq(fired.size(), 1, "done at 1.1 s")
	host.free()


func test_wait_does_not_run_while_paused() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	PauseWait.seconds(host, 1.0)
	var wait: PauseWait = _wait_of(host)
	tree.paused = true
	check(not wait.can_process(), "a wait stops while the tree is paused")
	tree.paused = false
	check(wait.can_process(), "and runs again after the pause")
	host.free()


func test_event_player_wait_is_pause_safe() -> void:
	var player := BattleEventPlayer.new()
	tree.root.add_child(player)
	player._wait(1.0)
	var wait: PauseWait = _wait_of(player)
	check(wait != null, "the event wait is a PauseWait")
	tree.paused = true
	check(wait == null or not wait.can_process(), "the event wait holds during a pause")
	tree.paused = false
	player.free()


func test_real_time_wait_ignores_a_low_time_scale() -> void:
	var host := Node.new()
	tree.root.add_child(host)
	var fired: Array[int] = []
	PauseWait.seconds(host, 0.5, true).connect(func() -> void: fired.append(1))
	var wait: PauseWait = _wait_of(host)
	Engine.time_scale = 0.1
	wait._process(0.04)  # the engine hands 0.04 s of scaled time: 0.4 s of wall clock
	check(fired.is_empty(), "0.4 s of real time is not enough")
	wait._process(0.02)
	check_eq(fired.size(), 1, "0.6 s of real time is")
	Engine.time_scale = 1.0
	host.free()


func test_pause_cancels_a_hitstop() -> void:
	var juice := BattleJuice.new()
	tree.root.add_child(juice)
	juice.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, null)
	juice.hitstop(0.5)
	check(juice.is_frozen() and Engine.time_scale < 1.0, "frozen during the hitstop")
	EventBus.game_paused.emit(true)
	check(not juice.is_frozen(), "pausing cancels the freeze")
	check_eq(Engine.time_scale, 1.0, "and restores the time scale")
	var stale: PauseWait = _wait_of(juice)
	stale._process(1.0)  # the old wait finishing later must not touch the state
	check_eq(Engine.time_scale, 1.0, "a stale hitstop changes nothing")
	juice.hitstop(0.5)
	EventBus.game_paused.emit(false)
	check(juice.is_frozen(), "a new hitstop after the pause freezes again")
	juice.free()
	check_eq(Engine.time_scale, 1.0, "leaving the tree restores time")


func test_hitstop_wait_is_pause_safe() -> void:
	var juice := BattleJuice.new()
	tree.root.add_child(juice)
	juice.setup(ContentDB.get_def("battle_juice", &"default") as JuiceDef, null)
	juice.hitstop(0.5)
	var wait: PauseWait = _wait_of(juice)
	tree.paused = true
	check(not wait.can_process(), "the hitstop wait stops during a pause")
	tree.paused = false
	juice.free()
	Engine.time_scale = 1.0
