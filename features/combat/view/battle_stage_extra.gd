class_name BattleStageExtra
extends RefCounted
## End-stage helpers extracted to keep battle_stage.gd under 200 lines.

static func finish(stage: BattleStage, result: StringName) -> void:
	if stage._finished:
		return
	stage._finished = true
	if stage.instant or stage.auto_play or not BattleEnding.washes(result):
		stage.ended.emit(result)
	else:
		BattleEnding.wash(stage, stage.ended.emit.bind(result))
