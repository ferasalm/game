class_name MapBattleIntro
extends RefCounted
## purpose: The map fight's start (docs/design/first-playable.md section 3): glitch flash and letterbox in, the
## fighters run from where they stood to their MapFormation spots, then face each other and idle.


static func play(battle: MapBattle) -> void:
	await battle.hud.play_intro()
	await _run_fighters(battle)
	battle._busy = false
	battle._check_end()


static func _run_fighters(battle: MapBattle) -> void:
	var tween: Tween = battle.create_tween()
	tween.set_parallel(true)
	battle._hero.play(&"run", true)
	tween.tween_property(battle._hero, "position", battle._hero_spot, battle.view.run_seconds)
	for i: int in battle._foes.size():
		battle._foes[i].play(&"run", true)
		tween.tween_property(battle._foes[i], "position", battle._foe_spots[i], battle.view.run_seconds)
	await tween.finished
	battle._hero.play(&"idle", true)
	battle._hero.face(battle._contact - battle._hero.position)
	for foe: IsoActor in battle._foes:
		foe.play(&"idle", true)
		foe.face(battle._hero.position - foe.position)
