extends Control




signal closed

var music_slider: HSlider
var sfx_slider: HSlider
var voice_min_slider: HSlider
var voice_max_slider: HSlider
var music_value_label: Label
var sfx_value_label: Label
var voice_min_value_label: Label
var voice_max_value_label: Label

var _syncing: bool = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	sync_from_settings()


func _build_ui() -> void :
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.09, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Settings         "
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	vbox.add_child(title)

	music_slider = _add_slider_row(vbox, "Background Music               ", 0.0, 1.0, 0.01)
	music_value_label = music_slider.get_meta("value_label")
	music_slider.value_changed.connect(_on_music_changed)

	sfx_slider = _add_slider_row(vbox, "SFX Volume               ", 0.0, 1.0, 0.01)
	sfx_value_label = sfx_slider.get_meta("value_label")
	sfx_slider.value_changed.connect(_on_sfx_changed)

	voice_min_slider = _add_slider_row(vbox, "Voice Floor dB               ", GameSettings.VOICE_DB_FLOOR, GameSettings.VOICE_DB_CEIL, 1.0)
	voice_min_value_label = voice_min_slider.get_meta("value_label")
	voice_min_slider.value_changed.connect(_on_voice_min_changed)

	voice_max_slider = _add_slider_row(vbox, "Voice Ceiling dB               ", GameSettings.VOICE_DB_FLOOR, GameSettings.VOICE_DB_CEIL, 1.0)
	voice_max_value_label = voice_max_slider.get_meta("value_label")
	voice_max_slider.value_changed.connect(_on_voice_max_changed)

	var hint: Label = Label.new()
	hint.text = "Lower ceiling = easier to reach full power                                    "
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.85))
	vbox.add_child(hint)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	vbox.add_child(buttons)

	var save_button: Button = _make_button("Save         ")
	save_button.pressed.connect(_on_save_pressed)
	buttons.add_child(save_button)

	var back_button: Button = _make_button("Back         ")
	back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(back_button)


func _add_slider_row(parent: VBoxContainer, label_text: String, min_value: float, max_value: float, step: float) -> HSlider:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var header: HBoxContainer = HBoxContainer.new()
	row.add_child(header)

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	var value_label: Label = Label.new()
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)

	var slider: HSlider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.custom_minimum_size = Vector2(0, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	slider.set_meta("value_label", value_label)
	return slider


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.16, 0.24, 0.82)
	style.set_corner_radius_all(22)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.6, 0.8, 1.0, 0.35)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	style.shadow_size = 18
	return style


func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 52)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	button.add_theme_stylebox_override("normal", _make_glass_style(0.12))
	button.add_theme_stylebox_override("hover", _make_glass_style(0.22))
	button.add_theme_stylebox_override("pressed", _make_glass_style(0.3))
	button.add_theme_stylebox_override("focus", _make_glass_style(0.16))
	return button


func _make_glass_style(fill_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, fill_alpha)
	style.set_corner_radius_all(16)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 1.0, 1.0, 0.4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style



func sync_from_settings() -> void :
	_syncing = true
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	voice_min_slider.value = GameSettings.voice_db_min
	voice_max_slider.value = GameSettings.voice_db_max
	_syncing = false
	_refresh_value_labels()


func _refresh_value_labels() -> void :
	music_value_label.text = "%d%%" % int(round(GameSettings.music_volume * 100.0))
	sfx_value_label.text = "%d%%" % int(round(GameSettings.sfx_volume * 100.0))
	voice_min_value_label.text = "%d dB" % int(round(GameSettings.voice_db_min))
	voice_max_value_label.text = "%d dB" % int(round(GameSettings.voice_db_max))


func _on_music_changed(value: float) -> void :
	if _syncing:
		return
	GameSettings.music_volume = value
	GameSettings.apply_audio()
	_refresh_value_labels()


func _on_sfx_changed(value: float) -> void :
	if _syncing:
		return
	GameSettings.sfx_volume = value
	GameSettings.apply_audio()
	_refresh_value_labels()


func _on_voice_min_changed(value: float) -> void :
	if _syncing:
		return
	GameSettings.set_voice_range(value, GameSettings.voice_db_max)
	sync_from_settings()


func _on_voice_max_changed(value: float) -> void :
	if _syncing:
		return
	GameSettings.set_voice_range(GameSettings.voice_db_min, value)
	sync_from_settings()


func _on_save_pressed() -> void :
	GameSettings.save_settings()


func _on_back_pressed() -> void :
	GameSettings.save_settings()
	closed.emit()
