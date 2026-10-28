extends Control



const MAIN_SCENE_PATH: String = "res://Main.tscn"
const SETTINGS_PANEL_PATH: String = "res://SettingsPanel.tscn"
const MUSIC_PATH: String = "res://assets/music/curlBgSound.mp3"
const RED_STONE_PATH: String = "res://assets/UIimg/redStoneIcon.png"
const BLUE_STONE_PATH: String = "res://assets/UIimg/blueStoneIcon.png"

var settings_panel: Control


func _ready() -> void :
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_decorations()
	_build_center_menu()
	_build_settings_panel()
	_start_music()


func _build_background() -> void :
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.85, 0.93, 0.99))
	gradient.set_color(1, Color(0.52, 0.72, 0.9))
	var gradient_texture: GradientTexture2D = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	gradient_texture.width = 8
	gradient_texture.height = 256

	var background: TextureRect = TextureRect.new()
	background.texture = gradient_texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _build_decorations() -> void :
	var red_tex: Texture2D = load(RED_STONE_PATH) as Texture2D
	var blue_tex: Texture2D = load(BLUE_STONE_PATH) as Texture2D
	var deco_size: Vector2 = Vector2(200, 200)

	_add_corner_decoration(red_tex, Control.PRESET_TOP_LEFT, Vector2(24, 24), deco_size, false)
	_add_corner_decoration(blue_tex, Control.PRESET_TOP_RIGHT, Vector2(-24, 24), deco_size, true)
	_add_corner_decoration(blue_tex, Control.PRESET_BOTTOM_LEFT, Vector2(24, -24), deco_size, false)
	_add_corner_decoration(red_tex, Control.PRESET_BOTTOM_RIGHT, Vector2(-24, -24), deco_size, true)


func _add_corner_decoration(texture: Texture2D, preset: int, offset: Vector2, deco_size: Vector2, flip_h: bool) -> void :
	if texture == null:
		return
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = deco_size
	rect.size = deco_size
	rect.flip_h = flip_h
	rect.modulate = Color(1.0, 1.0, 1.0, 0.85)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(preset, false)
	rect.position += offset
	add_child(rect)


func _build_center_menu() -> void :
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 26)
	center.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Voice Curling               "
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.12, 0.24, 0.42))
	title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.6))
	title.add_theme_constant_override("outline_size", 6)
	vbox.add_child(title)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var start_button: Button = _make_glass_button("Start Game               ")
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

	var settings_button: Button = _make_glass_button("Settings         ")
	settings_button.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_button)


func _build_settings_panel() -> void :
	var panel_scene: PackedScene = load(SETTINGS_PANEL_PATH) as PackedScene
	if panel_scene == null:
		return
	settings_panel = panel_scene.instantiate() as Control
	settings_panel.visible = false
	add_child(settings_panel)
	settings_panel.connect("closed", _on_settings_closed)


func _start_music() -> void :
	if AudioServer.get_bus_index("Music") == -1:
		return
	var stream: AudioStream = load(MUSIC_PATH) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music"
	player.autoplay = true
	add_child(player)
	player.play()


func _make_glass_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 76)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color(0.1, 0.2, 0.36))
	button.add_theme_color_override("font_hover_color", Color(0.05, 0.14, 0.3))
	button.add_theme_stylebox_override("normal", _make_glass_style(0.28))
	button.add_theme_stylebox_override("hover", _make_glass_style(0.42))
	button.add_theme_stylebox_override("pressed", _make_glass_style(0.52))
	button.add_theme_stylebox_override("focus", _make_glass_style(0.32))
	button.mouse_entered.connect(_on_button_hover.bind(button, true))
	button.mouse_exited.connect(_on_button_hover.bind(button, false))
	button.resized.connect( func() -> void : button.pivot_offset = button.size * 0.5)
	return button


func _make_glass_style(fill_alpha: float) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, fill_alpha)
	style.set_corner_radius_all(20)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 1.0, 1.0, 0.6)
	style.shadow_color = Color(0.2, 0.35, 0.55, 0.35)
	style.shadow_size = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_button_hover(button: Button, hovering: bool) -> void :
	button.pivot_offset = button.size * 0.5
	var target: Vector2 = Vector2(1.05, 1.05) if hovering else Vector2.ONE
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", target, 0.15)


func _on_start_pressed() -> void :
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _on_settings_pressed() -> void :
	if settings_panel == null:
		return
	if settings_panel.has_method("sync_from_settings"):
		settings_panel.call("sync_from_settings")
	settings_panel.visible = true


func _on_settings_closed() -> void :
	if settings_panel != null:
		settings_panel.visible = false
