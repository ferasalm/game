class_name PauseStatBar
extends RefCounted
## purpose: Builds one HP/SP bar line for a pause hero row: tag, bar and numbers; returns the bar and the label.

const TAG_WIDTH: float = 36.0
const BAR_SIZE: Vector2 = Vector2(420.0, 14.0)
const NUMBERS_WIDTH: float = 90.0


## Returns [bar, numbers]; the caller keeps both.
static func build(parent: Control, tag_key: String, kind: StringName, maximum: int) -> Array[Node]:
	var line := HBoxContainer.new()
	var tag: Label = Ui.label(Ui.text(tag_key), &"CaptionLabel")
	tag.custom_minimum_size.x = TAG_WIDTH
	line.add_child(tag)
	var bar := ProgressBar.new()
	bar.theme_type_variation = kind
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size = BAR_SIZE
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(bar)
	var numbers: Label = Ui.label("", &"NumberLabel")
	numbers.custom_minimum_size.x = NUMBERS_WIDTH
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(numbers)
	parent.add_child(line)
	var pair: Array[Node] = [bar, numbers]
	return pair
