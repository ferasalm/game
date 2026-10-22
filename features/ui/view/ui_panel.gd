class_name UiPanel
extends PanelContainer
## A framed night-glass panel: gypsum tracery frame (the theme's panel box), an optional title pair (English left in
## Reem Kufi, Musnad right in dim brass) with a frieze under it, and a `body` column for the content.
## Use: Ui.panel("Items", Ui.text("ITEMS_TITLE_MUSNAD")).body.add_child(...).

var body: VBoxContainer


## title_en empty = no title bar.
func setup(title_en: String, title_musnad: String = "") -> UiPanel:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", Ui.style().size(&"s_gap"))
	add_child(column)
	if not title_en.is_empty():
		column.add_child(Ui.title_pair(title_en, title_musnad))
		column.add_child(Ui.divider())
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Ui.style().size(&"s_gap"))
	column.add_child(body)
	return self
