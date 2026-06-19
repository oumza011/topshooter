extends Control

const ART_DIR := "res://art/reference"

@onready var grid: GridContainer = %ArtGrid


func _ready() -> void:
	_load_art()


func _load_art() -> void:
	var dir := DirAccess.open(ART_DIR)
	if dir == null:
		push_error("Could not open art reference folder: %s" % ART_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			_add_art_card("%s/%s" % [ART_DIR, file_name], file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _add_art_card(texture_path: String, label_text: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(320, 280)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)

	var texture := load(texture_path) as Texture2D
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(300, 220)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(image)

	var caption := Label.new()
	caption.text = label_text.get_file().get_basename()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(caption)

	grid.add_child(card)

