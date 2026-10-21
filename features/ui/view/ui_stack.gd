extends CanvasLayer
## Screen stack (autoload Screens): push/pop UiScreens, pause the tree while one is open, restore focus, route
## back/menu input, open the pause menu when nothing is open. Contract stub: the foundation builder (P1b) fills in
## the bodies; other features call only these methods.


func is_open() -> bool:
	return false


func push(_screen: Control) -> void:
	pass


func pop() -> void:
	pass


func register(_id: StringName, _factory: Callable) -> void:
	pass


func open(_id: StringName, _args: Dictionary = {}) -> void:
	pass
