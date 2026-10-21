class_name FacadeSpec
extends RefCounted
## What one painted facade needs: width in metres, floors (the lowest stone_floors are basalt, the rest brick),
## window columns, frieze style, qamariya glass letters, lit and shutter ratios, a door, floor height in pixels
## and the seed. Pure data; BuildingDef.facade_spec() fills it.

var width_m: int = 4
var floors: int = 4
var stone_floors: int = 1
var columns: int = 2
var frieze: StringName = &"zigzag"
var qamariya: Array[String] = ["R", "Y", "G", "B", "V"]
var lit_ratio: float = 0.4
var shutter_ratio: float = 0.2
var door: bool = false
var floor_px: int = 96
var seed_value: int = 1
