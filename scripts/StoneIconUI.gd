extends Control

# Sidebar stone icon. Every slot renders its stone at the same size, centred on
# the same baseline, straight from the artwork's own alpha (no colour keying).

const ICON_SIZE := Vector2(88, 78)
const STONE_BOX := Vector2(80, 68)
const SLOT_RADIUS := 10
const SLOT_BG := Color(0.78, 0.84, 0.90, 0.55)
const SLOT_BORDER := Color(0.78, 0.8, 0.84, 0.75)
const SELECTED_BORDER := Color(0.878, 0.69, 0.251, 1.0)
const SELECTED_WIDTH := 3
const SHADOW_OFFSET := Vector2(2, 3)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.22)
const TYPE_TEXTURE_PATHS := {
	"heavy": {"red": "res://assets/UIimg/1.1.png", "blue": "res://assets/UIimg/1.2.png"},
	"light": {"red": "res://assets/UIimg/2.1.png", "blue": "res://assets/UIimg/2.2.png"},
	"normal": {"red": "res://assets/UIimg/3.1.png", "blue": "res://assets/UIimg/3.2.png"},
}

@export var team: String = "red"

var _type: String = "normal"
var _selected: bool = false

@onready var type_frame: Panel = $TypeFrame
@onready var stone_slot: CenterContainer = $StoneSlot
@onready var stone_visual: Control = $StoneSlot/StoneVisual
@onready var shadow: TextureRect = $StoneSlot/StoneVisual/Shadow
@onready var stone: TextureRect = $StoneSlot/StoneVisual/Stone
@onready var type_badge: Label = $TypeBadge
@onready var mass_dots: HBoxContainer = $MassDots


func _ready() -> void:
	custom_minimum_size = ICON_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()
	apply_type(_type)
	set_selected(_selected)


func apply_type(stone_type: String) -> void:
	_type = stone_type
	if stone == null:
		return
	var by_team: Dictionary = TYPE_TEXTURE_PATHS.get(stone_type, TYPE_TEXTURE_PATHS["normal"])
	var path: String = str(by_team.get(_team(), by_team["red"]))
	var tex: Texture2D = load(path)
	stone.texture = tex
	shadow.texture = tex
	stone_visual.show()


func set_selected(selected: bool) -> void:
	_selected = selected
	if type_frame == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.set_corner_radius_all(SLOT_RADIUS)
	style.set_border_width_all(SELECTED_WIDTH if selected else 1)
	style.border_color = SELECTED_BORDER if selected else SLOT_BORDER
	type_frame.add_theme_stylebox_override("panel", style)


func _build_layout() -> void:
	if type_frame != null:
		type_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		type_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if type_badge != null:
		type_badge.hide()
	if mass_dots != null:
		mass_dots.hide()
	if stone_slot != null:
		stone_slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stone_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stone_visual != null:
		stone_visual.custom_minimum_size = STONE_BOX
		stone_visual.size = STONE_BOX
		stone_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare(shadow, SHADOW_OFFSET)
	_prepare(stone, Vector2.ZERO)
	if shadow != null:
		shadow.modulate = SHADOW_COLOR
	if stone != null:
		stone.modulate = Color.WHITE
		stone.self_modulate = Color.WHITE


func _prepare(rect: TextureRect, offset: Vector2) -> void:
	if rect == null:
		return
	rect.material = null
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = offset.x
	rect.offset_top = offset.y
	rect.offset_right = offset.x
	rect.offset_bottom = offset.y
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.show()


func _team() -> String:
	var t := String(team).to_lower()
	if t == "red" or t == "blue":
		return t
	if String(name).find("Blue") >= 0 or String(scene_file_path).find("蓝") >= 0:
		return "blue"
	return "red"
