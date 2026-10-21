class_name EquipmentHost
extends UiScreen
## Puts the existing EquipmentScreen (the bench, a CanvasLayer with its own open()/closed API) on the Screens stack
## as the screen &"equipment". The bench itself is unchanged; PrototypeMain still opens it directly at the workshop.

var _bench: EquipmentScreen


func build(_args: Dictionary) -> void:
	_scrim.visible = false  # the bench draws its own backdrop
	_bench = EquipmentScreen.new()
	add_child(_bench)
	_bench.layer = layer_id
	_bench.closed.connect(close)
	_bench.open()


func on_back() -> bool:
	if _bench != null:
		_bench.cancel()
	else:
		close()
	return true


func bench() -> EquipmentScreen:
	return _bench
