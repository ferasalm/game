class_name LevelUp
extends RefCounted
## Holds the details of a hero's level advancement: from/to levels and stat gains.

var hero: StringName = &""
var from_level: int = 1
var to_level: int = 1
var gains: Dictionary[StringName, int] = {}
