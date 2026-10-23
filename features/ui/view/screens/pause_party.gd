class_name PauseParty
extends VBoxContainer
## Party panel for the pause screen: one row per hero (h 200).

var _equipment: EquipmentData = EquipmentData.new()
var _rows: Array[PauseHeroRow] = []


func fill() -> void:
	var style: UiStyleDef = Ui.style()
	add_theme_constant_override("separation", style.size(&"s_pad"))
	for hero: StringName in heroes():
		var row := PauseHeroRow.new().setup(hero)
		add_child(row)
		_rows.append(row)


## The party: GameState.party, or the heroes of the start loadouts when none is set yet.
func heroes() -> Array[StringName]:
	return GameState.party if not GameState.party.is_empty() else _equipment.heroes


func rows() -> Array[PauseHeroRow]:
	return _rows
