class_name WaterNetState
extends RefCounted
## purpose: Runtime state of a water routing network (gate open/freed states and spout directions).

var open: Dictionary[StringName, bool] = {}
var freed: Dictionary[StringName, bool] = {}
var spout: Dictionary[StringName, int] = {}


static func start(def: WaterNetDef) -> WaterNetState:
	var state := WaterNetState.new()
	for node: WaterNodeDef in def.nodes:
		if node.kind == &"gate":
			state.open[node.id] = node.open
			state.freed[node.id] = not node.jammed
		elif node.kind == &"spout":
			state.spout[node.id] = node.start
	return state
