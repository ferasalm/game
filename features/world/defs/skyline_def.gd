class_name SkylineDef
extends Def
## The city around the play area as data: the ground level (y of the street, far below the rooftops), the
## al-Saila street (a sunken street along z at saila_x), depth bands of buildings and the landmarks. chunk_m:
## blocks are batched per square of this size so the ones off screen are culled together.

var ground_y: float = -18.0
var saila_x: float = 18.0
var saila_half: float = 3.0
var far_texture_m: float = 32.0
var chunk_m: float = 80.0
var seed_value: int = 1
var bands: Array[SkylineBand] = []
var landmarks: Array[SkylineLandmark] = []


func read(r: DefReader) -> void:
	id = r.id()
	ground_y = r.number("ground_y", -100.0, -1.0)
	saila_x = r.number("saila_x", -100.0, 200.0)
	saila_half = r.number("saila_half", 1.0, 20.0)
	far_texture_m = r.number("far_texture_m", 4.0, 200.0, 32.0, false)
	chunk_m = r.number("chunk_m", 20.0, 1000.0, 80.0, false)
	seed_value = r.integer("seed", 0, 99999)
	for band_reader: DefReader in r.objects("bands"):
		var band := SkylineBand.new()
		band.read(band_reader)
		bands.append(band)
	for mark_reader: DefReader in r.objects("landmarks"):
		var mark := SkylineLandmark.new()
		mark.read(mark_reader)
		landmarks.append(mark)


func references() -> Array[Array]:
	var out: Array[Array] = []
	for band: SkylineBand in bands:
		for building: StringName in band.building_ids:
			out.append(["building", building])
	return out
