class_name UiType
extends RefCounted
## Typed text: a label reveals one character per t_text_char with the typing blip; confirm finishes the line.
## Use: var t := Ui.type_text(label, text); ...; UiType.finish(label, t) when the player confirms.


## Sets the text and starts the reveal. The label must be in the tree; otherwise the line shows at once and
## null is returned.
static func start(label: Label, content: String) -> Tween:
	label.text = content
	label.visible_characters = -1
	var total: int = label.get_total_character_count()
	if not label.is_inside_tree() or total == 0:
		return null
	label.visible_characters = 0
	var out: Tween = UiMotion.tween(label)
	out.tween_method(_reveal.bind(label), 0.0, float(total), float(total) * Ui.style().time(&"t_text_char"))
	return out


## Shows the whole line now and stops the tween (may be null).
static func finish(label: Label, tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	label.visible_characters = -1


## True while characters are still being revealed.
static func is_typing(label: Label, tween: Tween) -> bool:
	return tween != null and tween.is_valid() and tween.is_running() and label.visible_characters >= 0


static func _reveal(progress: float, label: Label) -> void:
	var shown: int = int(progress)
	if shown != label.visible_characters:
		label.visible_characters = shown
		AudioDirector.text_blip(shown)
