extends Node3D

const STONES_PER_TEAM: int = 5
const MAX_STONES: int = STONES_PER_TEAM * 2
const START_POS: Vector3 = Vector3(0.0, 0.18, 14.86)
const RESET_POS: Vector3 = Vector3(0.0, -2.0, 24.86)
const HOUSE_CENTER: Vector3 = Vector3(0.0, 0.06, -4.904)
const HOUSE_BLUE_RADIUS: float = 1.96
const HOUSE_WHITE_RADIUS: float = 1.46
const HOUSE_RED_RADIUS: float = 1.04
const OUT_Z: float = -10.45
const TRACK_HALF_WIDTH: float = 2.5
const STONE_RADIUS: float = 0.24
const MIN_SPEED: float = 0.035
const LINEAR_FRICTION: float = 0.42

const STONE_SPIN_RATE: float = 1.35
const STONE_TYPE_LIGHT: String = "light"
const STONE_TYPE_NORMAL: String = "normal"
const STONE_TYPE_HEAVY: String = "heavy"
const STONE_TYPES: Array[String] = [STONE_TYPE_LIGHT, STONE_TYPE_NORMAL, STONE_TYPE_HEAVY]
const STONE_FRICTIONS: Dictionary = {
	STONE_TYPE_LIGHT: 0.22, 
	STONE_TYPE_NORMAL: LINEAR_FRICTION, 
	STONE_TYPE_HEAVY: 0.72, 
}
const STONE_MASSES: Dictionary = {
	STONE_TYPE_LIGHT: 10.0, 
	STONE_TYPE_NORMAL: 19.0, 
	STONE_TYPE_HEAVY: 36.0, 
}

const STONE_THROW_SCALE: Dictionary = {
	STONE_TYPE_LIGHT: 1.18, 
	STONE_TYPE_NORMAL: 1.0, 
	STONE_TYPE_HEAVY: 0.78, 
}
const STONE_ICON_MODULATES: Dictionary = {
	STONE_TYPE_LIGHT: Color(1.35, 1.35, 1.35, 1.0), 
	STONE_TYPE_NORMAL: Color.WHITE, 
	STONE_TYPE_HEAVY: Color(0.68, 0.68, 0.68, 1.0), 
}
const STONE_TYPE_NAMES: Dictionary = {
	STONE_TYPE_LIGHT: "Light", 
	STONE_TYPE_NORMAL: "Normal", 
	STONE_TYPE_HEAVY: "Heavy", 
}
const POWER_BAND_IMPULSE: float = 90.0
const POWER_BAND_BOOST: float = 2.5
const POWER_BAND_COOLDOWN: float = 0.4
const POWER_BAND_MIN_X: float = -1.3
const POWER_BAND_MAX_X: float = 1.3
const POWER_BAND_MIN_Z: float = -1.5
const POWER_BAND_MAX_Z: float = 9.5
const POWER_BAND_MIN_DISTANCE: float = 2.4
const SETUP_SECONDS: float = 3.0
const WALL_BACK_Z: float = -10.49
const WALL_BOUNCE: float = 0.72
const DB_MIN: float = 30.0
const DB_MAX: float = 70.0
const VOICE_SENSITIVITY: float = 1.0

const MIN_THROW_SPEED: float = 1.2
const MAX_THROW_SPEED: float = 4.0
const MAX_ANGLE: float = PI / 6.0
const SLIDE_SOUND_PATH: String = "res://assets/music/curlRunSound.mp3"
const BACKGROUND_MUSIC_PATH: String = "res://assets/music/curlBgSound.mp3"

const NOISE_FLOOR_ATTACK: float = 0.06
const NOISE_FLOOR_RELEASE: float = 0.004
const VOICE_GATE_DB: float = 2.5
const VOICE_DB_SMOOTH: float = 0.28
const THROW_POWER_SMOOTH: float = 12.0
const CAMERA_SETUP_POS: Vector3 = Vector3(0.0, 0.0, 5.8)
const CAMERA_FOLLOW_OFFSET: Vector3 = Vector3(0.0, 0.0, -7.5)
const CAMERA_LOOK_AHEAD: Vector3 = Vector3(0.0, 0.12, -1.6)
const CAMERA_FOLLOW_SPEED: float = 4.2
const DIRECTION_LINE_LENGTH: float = 6.5
const TEAM_RED_COLOR: Color = Color(1.0, 0.12, 0.08, 1.0)
const TEAM_BLUE_COLOR: Color = Color(0.0, 0.36, 1.0, 1.0)
const STONE_SHADER_CODE: String = "\nshader_type spatial;\n// depth_prepass_alpha：玻璃半透明时减少排序闪烁，不透明壶仍正常。\nrender_mode blend_mix, depth_draw_opaque, depth_prepass_alpha, cull_back, specular_schlick_ggx;\n\nuniform vec4 accent_color : source_color = vec4(0.0, 0.32, 1.0, 1.0);\nuniform vec4 body_color : source_color = vec4(0.92, 0.95, 1.0, 1.0);\nuniform float roughness_value = 0.28;\nuniform float alpha_value = 1.0;\nuniform float wood_amount = 0.0;\nuniform float glass_amount = 0.0;\nuniform float stone_amount = 0.0;\n\nvarying vec3 model_pos;\n\nfloat hash21(vec2 p) {\n\treturn fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);\n}\n\nfloat value_noise(vec2 p) {\n\tvec2 i = floor(p);\n\tvec2 f = fract(p);\n\tfloat a = hash21(i);\n\tfloat b = hash21(i + vec2(1.0, 0.0));\n\tfloat c = hash21(i + vec2(0.0, 1.0));\n\tfloat d = hash21(i + vec2(1.0, 1.0));\n\tvec2 u = f * f * (3.0 - 2.0 * f);\n\treturn mix(mix(a, b, u.x), mix(c, d, u.x), u.y);\n}\n\nvoid vertex() {\n\tmodel_pos = VERTEX;\n}\n\nvoid fragment() {\n\tfloat height = model_pos.y;\n\tfloat radius = length(model_pos.xz);\n\tvec2 xz = model_pos.xz;\n\n\t// 顶盖：扁圆盘；握杆：更高更细的把手区域。重壶仅顶盖上队伍色。\n\tfloat top_cap = smoothstep(0.058, 0.078, height) * (1.0 - smoothstep(0.048, 0.112, radius));\n\tfloat handle_grip = smoothstep(0.078, 0.105, height) * (1.0 - smoothstep(0.018, 0.055, radius));\n\tfloat bottom_shadow = 1.0 - smoothstep(0.014, 0.048, height);\n\tfloat side_shadow = smoothstep(0.100, 0.145, radius) * (1.0 - smoothstep(0.070, 0.115, height));\n\n\t// 普通壶：顶盖+握杆队伍色；重壶/轻壶：仅顶盖队伍色（握杆分别为木/玻璃）。\n\tfloat accent_amount = mix(top_cap, max(top_cap, handle_grip), stone_amount);\n\n\tvec3 base_body = body_color.rgb;\n\tvec3 cool_shadow = base_body * 0.58;\n\tvec3 shaded_body = mix(base_body, cool_shadow, clamp(bottom_shadow * 0.5 + side_shadow * 0.32, 0.0, 1.0));\n\tfloat local_rough = roughness_value;\n\tfloat local_spec = 0.55;\n\n\t// 普通壶：更深灰石底（贴近 3.1/3.2）+ 斑驳裂纹。\n\tif (stone_amount > 0.01) {\n\t\tfloat n1 = value_noise(xz * 42.0 + height * 10.0);\n\t\tfloat n2 = value_noise(xz * 95.0 - height * 28.0);\n\t\tfloat n3 = value_noise(xz * 160.0 + height * 40.0);\n\t\tfloat speck = smoothstep(0.52, 0.88, n1) * 0.22 + smoothstep(0.70, 0.95, n2) * 0.16;\n\t\tfloat crack_a = abs(sin(xz.x * 48.0 + n1 * 7.0 + height * 18.0));\n\t\tfloat crack_b = abs(sin(xz.y * 62.0 - n2 * 6.0));\n\t\tfloat cracks = (1.0 - smoothstep(0.015, 0.07, min(crack_a, crack_b))) * 0.28;\n\t\tvec3 granite = mix(vec3(0.42, 0.44, 0.48), vec3(0.62, 0.64, 0.68), n1);\n\t\tgranite = mix(granite, vec3(0.28, 0.30, 0.34), speck);\n\t\tgranite = mix(granite, vec3(0.72, 0.74, 0.76), n3 * 0.12);\n\t\tgranite *= 1.0 - cracks;\n\t\tgranite = mix(granite, granite * 0.72, bottom_shadow * 0.35);\n\t\tshaded_body = mix(shaded_body, granite, stone_amount);\n\t\tlocal_rough = mix(local_rough, 0.58 + n2 * 0.1, stone_amount);\n\t\tlocal_spec = mix(local_spec, 0.35, stone_amount);\n\t}\n\n\t// 重壶：更深棕木质、更强层缝与年轮对比；壶身与握杆同为木头。\n\tif (wood_amount > 0.01) {\n\t\tfloat plank_band = sin(height * 240.0 + value_noise(xz * 10.0) * 3.0);\n\t\tfloat plank = 0.55 + 0.45 * smoothstep(-0.35, 0.9, plank_band);\n\t\tfloat seam = 1.0 - smoothstep(0.01, 0.06, abs(plank_band));\n\t\tfloat grain = 0.78 + 0.22 * sin(height * 920.0 + radius * 70.0 + value_noise(xz * 28.0) * 10.0);\n\t\tfloat wear = value_noise(xz * 18.0 + height * 5.0);\n\t\tfloat pit = smoothstep(0.78, 0.96, value_noise(xz * 55.0 - height * 8.0));\n\t\tvec3 wood_dark = vec3(0.14, 0.07, 0.03);\n\t\tvec3 wood_mid = vec3(0.30, 0.17, 0.07);\n\t\tvec3 wood_light = vec3(0.42, 0.26, 0.12);\n\t\tvec3 wood_col = mix(wood_dark, wood_mid, plank);\n\t\twood_col = mix(wood_col, wood_light, grain * 0.22 + wear * 0.08);\n\t\twood_col *= 1.0 - seam * 0.62;\n\t\twood_col = mix(wood_col, wood_dark, bottom_shadow * 0.4 + pit * 0.28);\n\t\tshaded_body = mix(shaded_body, wood_col, wood_amount);\n\t\tlocal_rough = mix(local_rough, 0.92 + wear * 0.05, wood_amount);\n\t\tlocal_spec = mix(local_spec, 0.18, wood_amount);\n\t}\n\n\t// 轻壶：冰蓝半透明冰质（非全透明），裂纹/气泡/菲涅耳，贴近 2.1/2.2。\n\tfloat fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.2);\n\tif (glass_amount > 0.01) {\n\t\tfloat groove = 0.9 + 0.1 * sin(height * 88.0);\n\t\tfloat bubble_cell = value_noise(xz * 100.0 + height * 45.0);\n\t\tfloat bubbles = smoothstep(0.80, 0.96, bubble_cell);\n\t\tfloat ice_crack = 1.0 - smoothstep(0.02, 0.09, abs(sin(xz.x * 70.0 + value_noise(xz * 20.0) * 4.0)));\n\t\tfloat frost = value_noise(xz * 55.0 - height * 15.0);\n\t\tvec3 ice_deep = vec3(0.45, 0.72, 0.92);\n\t\tvec3 ice_mid = vec3(0.70, 0.90, 1.0);\n\t\tvec3 ice_bright = vec3(0.88, 0.96, 1.0);\n\t\tvec3 ice_col = mix(ice_deep, ice_mid, groove);\n\t\tice_col = mix(ice_col, ice_bright, frost * 0.35 + bubbles * 0.2);\n\t\tice_col *= 1.0 - ice_crack * 0.18;\n\t\tice_col = mix(ice_col, ice_deep, bottom_shadow * 0.25);\n\t\tshaded_body = mix(shaded_body, ice_col, glass_amount);\n\t\tshaded_body += glass_amount * fresnel * vec3(0.55, 0.75, 0.95) * 0.45;\n\t\tlocal_rough = mix(local_rough, 0.12 + bubbles * 0.08, glass_amount);\n\t\tlocal_spec = mix(local_spec, 0.88, glass_amount);\n\t}\n\n\tvec3 cap_color = accent_color.rgb;\n\t// 重壶顶盖略旧，贴近参考图磨损漆面。\n\tif (wood_amount > 0.5) {\n\t\tfloat chip = value_noise(xz * 40.0);\n\t\tcap_color = mix(cap_color * 0.85, cap_color, smoothstep(0.2, 0.75, chip));\n\t}\n\n\tvec3 final_color = mix(shaded_body, cap_color, clamp(accent_amount, 0.0, 1.0));\n\n\tfloat body_alpha = mix(1.0, mix(alpha_value, min(1.0, alpha_value + fresnel * 0.55), glass_amount), glass_amount);\n\t// 顶盖始终不透明；普通壶握杆也不透明。\n\tbody_alpha = mix(body_alpha, 1.0, clamp(accent_amount, 0.0, 1.0));\n\n\tALBEDO = final_color;\n\tROUGHNESS = clamp(local_rough, 0.0, 1.0);\n\tMETALLIC = 0.0;\n\tSPECULAR = clamp(local_spec, 0.0, 1.0);\n\tALPHA = clamp(body_alpha, 0.0, 1.0);\n}\n"






































































































































var state: String = "power_adjust"
var phase_time_left: float = SETUP_SECONDS
var current_index: int = 0
var current_stone: RigidBody3D = null
var throw_power: float = 0.0
var throw_angle: float = 0.0
var last_db: float = DB_MIN
var noise_floor_db: float = DB_MIN
var _smoothed_voice_db: float = DB_MIN
var score_red: int = 0
var score_blue: int = 0
var launched_stones: Array[Dictionary] = []
var stone_infos: Array[Dictionary] = []

var _power_band_cooldown_until: Dictionary = {}

var _shared_stone_shader: Shader = null
var _hud_icons_dirty: bool = true
var _cached_display_score: Dictionary = {"red": 0, "blue": 0}
var _score_refresh_timer: float = 0.0
var _minimap_viewport: SubViewport = null
var _minimap_frame: int = 0
const MINIMAP_UPDATE_EVERY_N_FRAMES: int = 4
const SCORE_REFRESH_INTERVAL: float = 0.2

var is_starting = false:
	set(v):
		is_starting = v
		$HUD / StartPanel.visible = not is_starting

@onready var mic_monitor: Node = $MicrophoneVolumeMonitor
@onready var stones_root: Node3D = $Stones
@onready var accelerated_area: Area3D = $AcceleratedArea3D
@onready var deceleration_area: Area3D = $DecelerationArea3D
@onready var aim_line_root: Node3D = $AimLine
@onready var power_indicator: Node3D = $VoiceIndicators / PowerIndicator
@onready var direction_indicator: Node3D = $VoiceIndicators / DirectionIndicator
@onready var power_fill: MeshInstance3D = $VoiceIndicators / PowerIndicator / Fill
@onready var direction_bar: MeshInstance3D = $VoiceIndicators / DirectionIndicator / Bar
@onready var direction_line_root: Node3D = $DirectionLine
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot / Camera3D
@onready var status_label: Label = $HUD / Panel / MarginContainer / VBoxContainer / StatusLabel
@onready var score_label: Label = $HUD / Panel / MarginContainer / VBoxContainer / ScoreLabel
@onready var setup_label: Label = $HUD / Panel / MarginContainer / VBoxContainer / SetupLabel
@onready var power_volume_bar: TextureProgressBar = %PowerVolumeBar
@onready var power_volume_label: Label = $HUD / PowerVolumeBar / Power
@onready var power_volume_arrow: TextureRect = $HUD / PowerVolumeBar / Arrow
@onready var direction_volume_bar: TextureProgressBar = $HUD / DirecctionVolumeBar
@onready var direction_volume_label: Label = $HUD / DirecctionVolumeBar / Direction
@onready var direction_volume_arrow: Control = $HUD / DirecctionVolumeBar / Arrow
@onready var countdown_label: Label = $HUD / 倒计时标签
@onready var adjust_hint_label: Label = $"HUD/倒计时标签/调整指示"
@onready var current_stone_label: Label = $HUD / StartPanel / CurrentStoneLabel
@onready var red_score_value: Label = $HUD / 分数 / BoxContainer / 红方得分
@onready var blue_score_value: Label = $HUD / 分数 / HBoxContainer / 蓝方得分
@onready var red_stone_left_icons: VBoxContainer = $HUD / 分数 / 冰壶计数盒子 / Panel / 红方冰壶
@onready var blue_stone_left_icons: VBoxContainer = $HUD / 分数 / 冰壶计数盒子 / Panel3 / 蓝方冰壶
@onready var result_panel: PanelContainer = $HUD / ResultPanel
@onready var result_label: Label = $HUD / ResultPanel / MarginContainer / VBoxContainer / ResultLabel
@onready var restart_button: Button = $HUD / ResultPanel / MarginContainer / VBoxContainer / RestartButton
@onready var run_sound: AudioStreamPlayer = $Audio / RunSound
@onready var collider_sound: AudioStreamPlayer = $Audio / ColliderSound
@onready var bg_sound: AudioStreamPlayer = $Audio / BgSound
@onready var settings_panel: Control = $HUD / SettingsPanel



func _ready() -> void :
	GameSettings.apply_audio()
	collectStones()
	accelerated_area.body_entered.connect(onPowerBandBodyEntered.bind(1.0))
	deceleration_area.body_entered.connect(onPowerBandBodyEntered.bind(-1.0))
	hideAimLine()
	result_panel.hide()
	restart_button.pressed.connect(restartMatch)
	mic_monitor.connect("volume_changed", _on_volume_changed)
	if settings_panel != null:
		settings_panel.visible = false
		settings_panel.connect("closed", _on_settings_closed)
	_minimap_viewport = get_node_or_null("HUD/Panel2/SubViewportContainer/SubViewport") as SubViewport
	if _minimap_viewport != null:

		_minimap_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_start_background_music()
	restartMatch()



func _on_settings_button_pressed() -> void :
	if settings_panel == null:
		return
	if settings_panel.has_method("sync_from_settings"):
		settings_panel.call("sync_from_settings")
	settings_panel.visible = true
	get_tree().paused = true



func _on_settings_closed() -> void :
	if settings_panel != null:
		settings_panel.visible = false
	get_tree().paused = false
	noise_floor_db = GameSettings.voice_db_min



func _on_back_to_menu_pressed() -> void :
	get_tree().paused = false
	get_tree().change_scene_to_file("res://StartMenu.tscn")


func _start_background_music() -> void :
	if bg_sound.stream == null:
		bg_sound.stream = _load_background_music()
	if bg_sound.stream == null:
		return
	if bg_sound.stream is AudioStreamMP3:
		(bg_sound.stream as AudioStreamMP3).loop = true
	bg_sound.stream_paused = false
	if not bg_sound.playing:
		bg_sound.play()



func _set_music_muted(muted: bool) -> void :
	bg_sound.stream_paused = muted


func _load_background_music() -> AudioStream:
	if ResourceLoader.exists(BACKGROUND_MUSIC_PATH):
		return load(BACKGROUND_MUSIC_PATH) as AudioStream
	return null


func _load_slide_sound() -> AudioStream:
	if ResourceLoader.exists(SLIDE_SOUND_PATH):
		return load(SLIDE_SOUND_PATH) as AudioStream
	return null


func _play_slide_sound() -> void :
	if run_sound.stream == null:
		run_sound.stream = _load_slide_sound()
	if run_sound.stream == null:
		return
	if run_sound.stream is AudioStreamWAV:
		(run_sound.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif run_sound.stream is AudioStreamMP3:
		(run_sound.stream as AudioStreamMP3).loop = true
	run_sound.play()



func _unhandled_input(event: InputEvent) -> void :
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if get_tree().paused:
		return
	if settings_panel != null and settings_panel.visible:
		return

	if key_event.keycode == KEY_R:
		restartMatch()
		return


	if is_starting or state == "game_over":
		return
	if not $HUD / StartPanel.visible:
		return
	is_starting = true
	$HUD / StartPanel.hide()




func _process(delta: float) -> void :
	if not is_starting:
		return
	match state:
		"power_adjust":
			updatePowerSetup(delta)
		"direction_adjust":
			updateDirectionSetup(delta)
		"moving":
			followCurrentStone(delta)

	_score_refresh_timer -= delta
	if _score_refresh_timer <= 0.0 or state != "moving":
		_score_refresh_timer = SCORE_REFRESH_INTERVAL
		_cached_display_score = calculateScore()

	updateHud()
	_update_minimap_throttled()



func _update_minimap_throttled() -> void :
	if _minimap_viewport == null:
		return
	_minimap_frame += 1
	if _minimap_frame % MINIMAP_UPDATE_EVERY_N_FRAMES != 0:
		return
	_minimap_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE



func _physics_process(delta: float) -> void :
	if state != "moving":
		return

	var any_moving: bool = false
	var side_limit: float = TRACK_HALF_WIDTH - STONE_RADIUS
	for info: Dictionary in launched_stones:
		var body: RigidBody3D = info["body"] as RigidBody3D
		if body == null or bool(info["out"]):
			continue

		body.global_position.y = 0.18
		body.linear_velocity.y = 0.0

		var sim_speed: float = float(info.get("sim_speed", 0.0))
		var dir: Vector2 = info.get("dir", Vector2(0.0, -1.0))



		var planar: Vector2 = Vector2(body.linear_velocity.x, body.linear_velocity.z)
		if planar.length() > sim_speed:
			sim_speed = planar.length()
			dir = planar.normalized()


		if sim_speed <= 0.0:
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			info["sim_speed"] = 0.0
			continue

		sim_speed = max(sim_speed - float(STONE_FRICTIONS[str(info["type"])]) * delta, 0.0)

		var pos: Vector3 = body.global_position
		pos.x += dir.x * sim_speed * delta
		pos.z += dir.y * sim_speed * delta


		if absf(pos.x) > side_limit:
			pos.x = clampf(pos.x, - side_limit, side_limit)
			dir.x = - dir.x
			sim_speed *= WALL_BOUNCE
			playWallHitSound()

		info["dir"] = dir
		info["sim_speed"] = sim_speed
		body.linear_velocity = Vector3(dir.x, 0.0, dir.y) * sim_speed
		body.global_position = pos

		body.angular_velocity = Vector3.ZERO
		if sim_speed > MIN_SPEED:
			body.rotation.y += sim_speed * STONE_SPIN_RATE * delta


		if pos.z <= OUT_Z + STONE_RADIUS:
			markOut(info)
			continue

		if sim_speed > MIN_SPEED:
			any_moving = true
		else:
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			info["sim_speed"] = 0.0

		if isStoneOutOfBounds(body):
			markOut(info)

	if not any_moving:
		state = "settling"
		await get_tree().create_timer(0.4).timeout
		finishTurn()



func collectStones() -> void :
	stone_infos.clear()
	for child: Node in stones_root.get_children():
		var body: RigidBody3D = child as RigidBody3D
		if body == null:
			continue
		var team: String = "red" if body.name.begins_with("Red") else "blue"
		body.body_entered.connect(_on_stone_collision.bind(body))
		stone_infos.append({
			"body": body, 
			"team": team, 
			"type": STONE_TYPE_NORMAL, 
			"out": false, 
			"curl": 0.0, 
			"sim_speed": 0.0, 
			"dir": Vector2(0.0, -1.0), 
		})

	stone_infos.sort_custom( func(a: Dictionary, b: Dictionary) -> bool:
		return getTurnOrder(a) < getTurnOrder(b)
	)



func getTurnOrder(info: Dictionary) -> int:
	var body: RigidBody3D = info["body"] as RigidBody3D
	var name: String = body.name
	var number_text: String = name.substr(name.length() - 2, 2)
	var number: int = int(number_text)
	var team_offset: int = 0 if name.begins_with("Red") else 1
	return (number - 1) * 2 + team_offset



func assignStoneTypes() -> void :
	const MIN_NORMAL_PER_TEAM: int = 2
	for team: String in ["red", "blue"]:
		var team_stones: Array[Dictionary] = []
		for info: Dictionary in stone_infos:
			if str(info["team"]) != team:
				continue
			info["type"] = STONE_TYPES[randi_range(0, STONE_TYPES.size() - 1)]
			team_stones.append(info)

		var normal_count: int = 0
		for info: Dictionary in team_stones:
			if str(info["type"]) == STONE_TYPE_NORMAL:
				normal_count += 1


		while normal_count < MIN_NORMAL_PER_TEAM:
			var candidates: Array[Dictionary] = []
			for info: Dictionary in team_stones:
				if str(info["type"]) != STONE_TYPE_NORMAL:
					candidates.append(info)
			if candidates.is_empty():
				break
			var pick: Dictionary = candidates[randi_range(0, candidates.size() - 1)]
			pick["type"] = STONE_TYPE_NORMAL
			normal_count += 1

		var verified_normals: int = 0
		for info: Dictionary in team_stones:
			if str(info["type"]) == STONE_TYPE_NORMAL:
				verified_normals += 1
		assert (verified_normals >= MIN_NORMAL_PER_TEAM)



func applyStoneProperties() -> void :
	for info: Dictionary in stone_infos:
		var body: RigidBody3D = info["body"] as RigidBody3D
		var stone_type: String = str(info["type"])
		body.mass = float(STONE_MASSES[stone_type])
		var material: ShaderMaterial = createStoneMaterial(str(info["team"]), stone_type)
		applyMaterialToMeshes(body, material)



func randomizePowerBands() -> void :
	accelerated_area.position = Vector3(
		randf_range(POWER_BAND_MIN_X, POWER_BAND_MAX_X), 
		0.08, 
		randf_range(POWER_BAND_MIN_Z, POWER_BAND_MAX_Z)
	)
	var deceleration_position: Vector3 = accelerated_area.position
	while deceleration_position.distance_to(accelerated_area.position) < POWER_BAND_MIN_DISTANCE:
		deceleration_position = Vector3(
			randf_range(POWER_BAND_MIN_X, POWER_BAND_MAX_X), 
			0.08, 
			randf_range(POWER_BAND_MIN_Z, POWER_BAND_MAX_Z)
		)
	deceleration_area.position = deceleration_position



func setPowerBandsActive(active: bool) -> void :
	accelerated_area.visible = active
	accelerated_area.monitoring = active
	deceleration_area.visible = active
	deceleration_area.monitoring = active



func onPowerBandBodyEntered(body_node: Node3D, impulse_direction: float) -> void :
	if state != "moving":
		return
	var body: RigidBody3D = body_node as RigidBody3D
	if body == null or body.get_parent() != stones_root:
		return

	var info: Dictionary = {}
	for candidate: Dictionary in stone_infos:
		if candidate.get("body") == body:
			info = candidate
			break
	if info.is_empty():
		return

	var now_sec: float = Time.get_ticks_msec() * 0.001
	var cooldown_key: String = "%d_%.0f" % [body.get_instance_id(), impulse_direction]
	if float(_power_band_cooldown_until.get(cooldown_key, 0.0)) > now_sec:
		return
	_power_band_cooldown_until[cooldown_key] = now_sec + POWER_BAND_COOLDOWN

	var dir2: Vector2 = info.get("dir", Vector2(0.0, -1.0))
	var planar: Vector2 = Vector2(body.linear_velocity.x, body.linear_velocity.z)
	if planar.length() > 0.05:
		dir2 = planar.normalized()
		info["dir"] = dir2
	elif dir2.length() <= 0.001:
		dir2 = Vector2(0.0, -1.0)
		info["dir"] = dir2

	var sim_speed: float = float(info.get("sim_speed", 0.0))
	if planar.length() > sim_speed:
		sim_speed = planar.length()
	sim_speed = maxf(sim_speed + impulse_direction * POWER_BAND_BOOST, 0.0)
	info["sim_speed"] = sim_speed

	var move_direction: Vector3 = Vector3(dir2.x, 0.0, dir2.y)
	body.linear_velocity = move_direction * sim_speed
	body.apply_central_impulse(move_direction * POWER_BAND_IMPULSE * impulse_direction)



func createStoneMaterial(team: String, stone_type: String) -> ShaderMaterial:
	if _shared_stone_shader == null:
		_shared_stone_shader = Shader.new()
		_shared_stone_shader.code = STONE_SHADER_CODE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = _shared_stone_shader

	var accent_color: Color = Color(0.0, 0.32, 1.0, 1.0)
	if team == "red":
		accent_color = Color(0.95, 0.04, 0.03, 1.0)

	var body_color: Color = Color(0.88, 0.9, 0.93, 1.0)
	var roughness_value: float = 0.5
	var alpha_value: float = 1.0
	var wood_amount: float = 0.0
	var glass_amount: float = 0.0
	var stone_amount: float = 1.0

	if stone_type == STONE_TYPE_HEAVY:

		body_color = Color(0.28, 0.16, 0.07, 1.0)
		roughness_value = 0.93
		wood_amount = 1.0
		stone_amount = 0.0
		accent_color = accent_color.darkened(0.22)
	elif stone_type == STONE_TYPE_LIGHT:

		body_color = Color(0.62, 0.86, 0.98, 1.0)
		roughness_value = 0.12
		alpha_value = 0.62
		glass_amount = 1.0
		stone_amount = 0.0
		accent_color = accent_color.lightened(0.22)
	else:

		body_color = Color(0.48, 0.5, 0.54, 1.0)
		roughness_value = 0.58
		stone_amount = 1.0

	material.set_shader_parameter("accent_color", accent_color)
	material.set_shader_parameter("body_color", body_color)
	material.set_shader_parameter("roughness_value", roughness_value)
	material.set_shader_parameter("alpha_value", alpha_value)
	material.set_shader_parameter("wood_amount", wood_amount)
	material.set_shader_parameter("glass_amount", glass_amount)
	material.set_shader_parameter("stone_amount", stone_amount)
	return material



func restartMatch() -> void :
	is_starting = false
	$HUD / StartPanel.show()
	noise_floor_db = GameSettings.voice_db_min
	_start_background_music()
	current_index = 0
	score_red = 0
	score_blue = 0
	launched_stones.clear()
	_power_band_cooldown_until.clear()
	result_panel.hide()
	$HUD / ResultPanel / MarginContainer / VBoxContainer / RedWinChin.hide()
	$HUD / ResultPanel / MarginContainer / VBoxContainer / BlueWinChin.hide()
	assignStoneTypes()
	applyStoneProperties()

	for info: Dictionary in stone_infos:
		info["out"] = false
		info["curl"] = 0.0
		info["sim_speed"] = 0.0
		info["dir"] = Vector2(0.0, -1.0)
		var body: RigidBody3D = info["body"] as RigidBody3D
		body.freeze = true
		body.visible = false
		body.global_position = RESET_POS
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO

	startTurn()



func startTurn() -> void :
	if current_index >= MAX_STONES:
		setPowerBandsActive(false)
		finishMatch()
		return

	is_starting = false
	setPowerBandsActive(false)
	if current_index >= MAX_STONES - 6:
		randomizePowerBands()
		setPowerBandsActive(true)
	var info: Dictionary = stone_infos[current_index]
	current_stone_label.text = "Current stone: %s" % str(STONE_TYPE_NAMES[str(info["type"])])
	if current_index % 2 == 0:
		$WorldEnvironment.environment.background_color = Color("ffd5ceff")
	else:
		$WorldEnvironment.environment.background_color = Color(0.678, 0.859, 0.961, 1.0)


	current_stone = info["body"] as RigidBody3D
	current_stone.visible = true
	current_stone.freeze = true
	current_stone.global_position = START_POS
	current_stone.rotation = Vector3.ZERO
	current_stone.linear_velocity = Vector3.ZERO
	current_stone.angular_velocity = Vector3.ZERO
	info["out"] = false
	info["curl"] = 0.0

	throw_power = 0.0
	throw_angle = 0.0
	_smoothed_voice_db = GameSettings.voice_db_min
	last_db = _smoothed_voice_db
	noise_floor_db = GameSettings.voice_db_min
	phase_time_left = SETUP_SECONDS
	state = "power_adjust"
	_set_music_muted(true)
	_hud_icons_dirty = true
	_cached_display_score = calculateScore()
	updateCountdownLabel()
	updateTeamIndicatorMaterials()
	resetDirectionNeedle()
	power_indicator.visible = false
	direction_indicator.visible = false
	direction_line_root.visible = false
	setSetupBarsVisible(true, false)
	updatePowerVolumeBar()
	updateDirectionVolumeBar()
	showAimLine()
	camera_pivot.position = CAMERA_SETUP_POS
	lookAtCurrentStone()
	updateHud()



func updatePowerSetup(delta: float) -> void :
	adjust_hint_label.show()
	adjust_hint_label.text = "Adjusting power"
	setSetupBarsVisible(true, false)
	phase_time_left -= delta
	phase_time_left = max(phase_time_left, 0.0)
	var target_power: float = dbToUnit(last_db)
	throw_power = lerpf(throw_power, target_power, minf(1.0, THROW_POWER_SMOOTH * delta))
	updatePowerVolumeBar()
	updateAimLine()
	updateCountdownLabel()
	if phase_time_left <= 0.0:
		phase_time_left = SETUP_SECONDS
		state = "direction_adjust"
		throw_power = dbToUnit(last_db)
		throw_angle = lerp( - MAX_ANGLE, MAX_ANGLE, dbToUnit(last_db))
		power_indicator.visible = false
		direction_indicator.visible = false
		direction_line_root.visible = false
		setSetupBarsVisible(false, true)
		hideAimLine()
		updateDirectionIndicator()
		updateDirectionVolumeBar()
		direction_line_root.visible = true
		updateCountdownLabel()



func updateDirectionSetup(delta: float) -> void :
	adjust_hint_label.text = "Adjusting direction"
	setSetupBarsVisible(false, true)
	phase_time_left -= delta
	phase_time_left = max(phase_time_left, 0.0)
	var target_angle: float = lerp( - MAX_ANGLE, MAX_ANGLE, dbToUnit(last_db))
	throw_angle = lerpf(throw_angle, target_angle, minf(1.0, THROW_POWER_SMOOTH * delta))
	updateDirectionIndicator()
	updateDirectionVolumeBar()
	updateCountdownLabel()
	if phase_time_left <= 0.0:
		throw_angle = lerp( - MAX_ANGLE, MAX_ANGLE, dbToUnit(last_db))
		direction_indicator.visible = false
		direction_line_root.visible = false
		setSetupBarsVisible(false, false)
		throwCurrentStone()



func throwCurrentStone() -> void :
	adjust_hint_label.hide()
	setSetupBarsVisible(false, false)
	if current_stone == null:
		return

	var info: Dictionary = stone_infos[current_index]
	info["curl"] = 0.0
	launched_stones.append(info)

	var stone_type: String = str(info["type"])
	var throw_scale: float = float(STONE_THROW_SCALE.get(stone_type, 1.0))
	var speed: float = lerp(MIN_THROW_SPEED, MAX_THROW_SPEED, throw_power) * throw_scale
	var direction: Vector3 = getThrowDirection()
	info["sim_speed"] = speed
	info["dir"] = Vector2(direction.x, direction.z).normalized()
	current_stone.freeze = false
	current_stone.global_position = START_POS
	current_stone.linear_velocity = direction * speed
	current_stone.angular_velocity = Vector3.ZERO

	state = "moving"
	_set_music_muted(false)
	_hud_icons_dirty = true
	hideAimLine()
	_play_slide_sound()



func finishTurn() -> void :
	if run_sound.playing:
		run_sound.stop()
	current_index += 1
	startTurn()



func finishMatch() -> void :
	$HUD / StartPanel.hide()
	state = "game_over"

	if bg_sound.playing:
		bg_sound.stop()
	power_indicator.visible = false
	direction_indicator.visible = false
	direction_line_root.visible = false
	setSetupBarsVisible(false, false)
	hideAimLine()
	var result: Dictionary = calculateScore()
	score_red = int(result["red"])
	score_blue = int(result["blue"])
	var winner: String = "Draw"
	$HUD / ResultPanel / MarginContainer / VBoxContainer / RedWinChin.hide()
	$HUD / ResultPanel / MarginContainer / VBoxContainer / BlueWinChin.hide()
	if score_red > score_blue:
		winner = "Red wins!"
	elif score_blue > score_red:
		winner = "Blue wins!"
	result_label.text = "Game Over\nRed %d : Blue %d\n%s" % [score_red, score_blue, winner]
	result_panel.show()



func calculateScore() -> Dictionary:
	var red_total: int = 0
	var blue_total: int = 0

	for info: Dictionary in launched_stones:
		if bool(info["out"]):
			continue
		var body: RigidBody3D = info["body"] as RigidBody3D
		var distance: float = Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z))
		var points: int = getHousePoints(distance)
		if points <= 0:
			continue
		if info["team"] == "red":
			red_total += points
		else:
			blue_total += points

	return {"red": red_total, "blue": blue_total}



func getHousePoints(distance: float) -> int:
	if distance <= HOUSE_RED_RADIUS:
		return 3
	if distance <= HOUSE_WHITE_RADIUS:
		return 2
	if distance <= HOUSE_BLUE_RADIUS:
		return 1
	return 0



func markOut(info: Dictionary) -> void :
	info["out"] = true
	var body: RigidBody3D = info["body"] as RigidBody3D
	body.freeze = true
	body.visible = false
	body.global_position = RESET_POS
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO



func isStoneOutOfBounds(body: RigidBody3D) -> bool:
	if body.global_position.z < OUT_Z:
		return true
	if abs(body.global_position.x) > TRACK_HALF_WIDTH + STONE_RADIUS:
		return true
	return false



func dbToUnit(db: float) -> float:
	if is_inf(db):
		return 0.0
	var db_min: float = GameSettings.voice_db_min
	var db_max: float = GameSettings.voice_db_max
	var unit: float = (db - db_min) / maxf(db_max - db_min, 0.001)
	unit = clamp(unit * VOICE_SENSITIVITY, 0.0, 1.0)
	return pow(unit, 1.25)



func updatePowerIndicator() -> void :
	power_fill.scale.y = max(0.04, throw_power)
	power_fill.position.y = -0.5 + throw_power * 0.5



func setSetupBarsVisible(show_power_bar: bool, show_direction_bar: bool) -> void :
	power_volume_bar.visible = show_power_bar
	direction_volume_bar.visible = show_direction_bar



func updatePowerVolumeBar() -> void :
	var power_percent: float = throw_power * 100.0
	power_volume_bar.value = power_percent
	power_volume_label.text = "%d%%" % int(round(power_percent))
	updateVerticalProgressArrow(power_volume_bar, power_volume_arrow, throw_power)



func updateDirectionVolumeBar() -> void :
	var direction_unit: float = inverse_lerp( - MAX_ANGLE, MAX_ANGLE, throw_angle)
	direction_volume_bar.value = direction_unit * 100.0
	direction_volume_label.visible = true
	direction_volume_label.text = "%d°" % int(round(rad_to_deg(throw_angle)))
	updateArcProgressArrow(direction_volume_arrow, direction_unit)



func updateVerticalProgressArrow(bar: Control, arrow: Control, unit: float) -> void :
	var clamped_unit: float = clamp(unit, 0.0, 1.0)
	var arrow_size: Vector2 = arrow.size
	var bar_size: Vector2 = bar.size
	var arrow_top: float = (1.0 - clamped_unit) * bar_size.y - arrow_size.y * 0.5
	arrow.position.y = arrow_top



func updateArcProgressArrow(arrow: Control, unit: float) -> void :
	var clamped_unit: float = clamp(unit, 0.0, 1.0)
	arrow.rotation = lerp( - MAX_ANGLE + PI / 4, MAX_ANGLE + PI / 4, clamped_unit)



func updateDirectionIndicator() -> void :
	var effective_angle: float = getEffectiveThrowAngle()
	updateDirectionLineTransform(effective_angle)



func resetDirectionNeedle() -> void :
	updateDirectionLineTransform(0.0)



func updateDirectionLineTransform(effective_angle: float) -> void :
	var start_pos: Vector3 = START_POS
	if current_stone != null:
		start_pos = current_stone.global_position
	var direction: Vector3 = getThrowDirection()
	var side: Vector3 = Vector3(direction.z, 0.0, - direction.x).normalized()
	var line_basis: Basis = Basis(side, Vector3.UP, direction).orthonormalized()
	var segment_count: int = direction_line_root.get_child_count()
	for i: int in range(segment_count):
		var segment: MeshInstance3D = direction_line_root.get_child(i) as MeshInstance3D
		if segment == null:
			continue
		var start_t: float = float(i) / float(segment_count)
		var end_t: float = float(i + 1) / float(segment_count)
		var start_point: Vector3 = start_pos + direction * DIRECTION_LINE_LENGTH * start_t
		var end_point: Vector3 = start_pos + direction * DIRECTION_LINE_LENGTH * end_t
		start_point.y = 0.11
		end_point.y = 0.11
		var line_center: Vector3 = (start_point + end_point) * 0.5
		segment.global_transform = Transform3D(line_basis, line_center)
		segment.scale = Vector3(1.0, 1.0, DIRECTION_LINE_LENGTH / float(segment_count))
		setMeshMaterialColor(segment, getAimLineGradientColor(end_t))



func updateAimLine() -> void :
	if current_stone == null:
		return

	var stone_type: String = STONE_TYPE_NORMAL
	if current_index >= 0 and current_index < stone_infos.size():
		stone_type = str(stone_infos[current_index]["type"])
	var throw_scale: float = float(STONE_THROW_SCALE.get(stone_type, 1.0))
	var speed: float = lerp(MIN_THROW_SPEED, MAX_THROW_SPEED, throw_power) * throw_scale
	var effective_angle: float = getEffectiveThrowAngle()
	var direction: Vector3 = getThrowDirection()
	var side: Vector3 = Vector3( - direction.z, 0.0, direction.x)
	var root_pos: Vector3 = START_POS
	var segment_count: int = aim_line_root.get_child_count()

	for i: int in range(segment_count):
		var segment: MeshInstance3D = aim_line_root.get_child(i) as MeshInstance3D
		if segment == null:
			continue
		var start_t: float = float(i) / float(segment_count)
		var end_t: float = float(i + 1) / float(segment_count)
		var start_point: Vector3 = getAimLinePoint(root_pos, direction, side, speed, effective_angle, start_t)
		var end_point: Vector3 = getAimLinePoint(root_pos, direction, side, speed, effective_angle, end_t)
		var offset: Vector3 = end_point - start_point
		var length: float = offset.length()
		if length <= 0.001:
			segment.visible = false
			continue
		segment.visible = true
		segment.global_position = (start_point + end_point) * 0.5
		segment.look_at(end_point, Vector3.UP)
		segment.scale = Vector3(1.0, 1.0, length)
		setMeshMaterialColor(segment, getAimLineGradientColor(end_t))



func getAimLinePoint(root_pos: Vector3, direction: Vector3, _side: Vector3, speed: float, _effective_angle: float, t: float) -> Vector3:
	var distance: float = speed * speed * 0.62 * t
	var point: Vector3 = root_pos + direction * distance
	point.y = 0.08
	return point



func getAimLineGradientColor(t: float) -> Color:
	var unit: float = clamp(t, 0.0, 1.0)
	return Color(1.0, lerp(0.08, 1.0, unit), lerp(0.06, 1.0, unit), lerp(0.92, 0.62, unit))



func getEffectiveThrowAngle() -> float:
	return throw_angle



func getThrowDirection() -> Vector3:
	var a: float = getEffectiveThrowAngle()
	return Vector3(sin(a), 0.0, - cos(a))



func showAimLine() -> void :
	aim_line_root.visible = true



func hideAimLine() -> void :
	aim_line_root.visible = false



func updateTeamIndicatorMaterials() -> void :
	pass



func getCurrentTeamColor() -> Color:
	if current_index < stone_infos.size():
		var info: Dictionary = stone_infos[current_index]
		if str(info["team"]) == "blue":
			return TEAM_BLUE_COLOR
	return TEAM_RED_COLOR



func setMeshMaterialColor(mesh: MeshInstance3D, color: Color) -> void :
	if mesh == null:
		return
	var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
	if material == null:
		return
	if not mesh.has_meta("_owned_mat"):
		material = material.duplicate() as StandardMaterial3D
		mesh.material_override = material
		mesh.set_meta("_owned_mat", true)
	else:
		material = mesh.material_override as StandardMaterial3D
	if material.albedo_color.is_equal_approx(color):
		return
	material.albedo_color = color



func followCurrentStone(delta: float) -> void :
	if current_stone == null:
		return
	var stone_pos: Vector3 = current_stone.global_position
	var target: Vector3 = Vector3(stone_pos.x, 0.0, stone_pos.z) + CAMERA_FOLLOW_OFFSET
	camera_pivot.global_position = camera_pivot.global_position.lerp(target, min(delta * CAMERA_FOLLOW_SPEED, 1.0))
	lookAtCurrentStone()



func lookAtCurrentStone() -> void :
	if current_stone == null:
		return
	camera.look_at(current_stone.global_position + CAMERA_LOOK_AHEAD, Vector3.UP)



func updateHud() -> void :
	var team: String = "Red" if current_index % 2 == 0 else "Blue"
	var stone_no: int = int(current_index / 2) + 1
	var display_red_score: int = int(_cached_display_score["red"])
	var display_blue_score: int = int(_cached_display_score["blue"])
	status_label.text = "%s stone %d/%d" % [team, min(stone_no, STONES_PER_TEAM), STONES_PER_TEAM]
	score_label.text = "Red %d : Blue %d    Mic %.1f dB" % [display_red_score, display_blue_score, last_db]
	red_score_value.text = str(display_red_score)
	blue_score_value.text = str(display_blue_score)
	if _hud_icons_dirty:
		updateRemainingStoneIcons(red_stone_left_icons, "red")
		updateRemainingStoneIcons(blue_stone_left_icons, "blue")
		_hud_icons_dirty = false
	match state:
		"power_adjust":
			setup_label.text = "Power voice phase: %.1fs  power %.0f%%" % [phase_time_left, throw_power * 100.0]
		"direction_adjust":
			setup_label.text = "Direction voice phase: %.1fs  angle %.0f deg" % [phase_time_left, rad_to_deg(throw_angle)]
		"moving":
			setup_label.text = "Stone is moving"
		"game_over":
			setup_label.text = "Press R or Restart"
		_:
			setup_label.text = "Scoring"
	updateCountdownLabel()



func updateCountdownLabel() -> void :
	if state == "power_adjust" or state == "direction_adjust":
		countdown_label.text = "%.3f" % max(phase_time_left, 0.0)
	else:
		countdown_label.text = "0.000"



func updateRemainingStoneIcons(container: VBoxContainer, team: String) -> void :
	var remaining_stones: Array[Dictionary] = []
	for info: Dictionary in stone_infos:
		if str(info["team"]) == team and not launched_stones.has(info):
			remaining_stones.append(info)
	var current_info: Dictionary = {}
	if current_index >= 0 and current_index < stone_infos.size():
		current_info = stone_infos[current_index]
	for i: int in range(container.get_child_count()):
		var child: Node = container.get_child(i)
		if child == null:
			continue
		child.visible = i < remaining_stones.size()
		if child.visible:
			var info: Dictionary = remaining_stones[i]
			var stone_type: String = str(info["type"])
			if child.has_method("apply_type"):
				child.call("apply_type", stone_type)
			else:
				var icon_modulate: Color = STONE_ICON_MODULATES[stone_type]
				if child is CanvasItem:
					(child as CanvasItem).self_modulate = icon_modulate
			if child.has_method("set_selected"):
				var is_current: bool = (
					not current_info.is_empty()
					and is_same(info, current_info)
					and (state == "power_adjust" or state == "direction_adjust")
				)
				child.call("set_selected", is_current)
		elif child.has_method("set_selected"):
			child.call("set_selected", false)



func _on_volume_changed(db: float) -> void :
	var db_min: float = GameSettings.voice_db_min
	if is_inf(db):

		return


	if db < noise_floor_db:
		noise_floor_db = lerpf(noise_floor_db, db, NOISE_FLOOR_ATTACK)
	else:
		noise_floor_db = lerpf(noise_floor_db, db, NOISE_FLOOR_RELEASE)

	var voice_excess: float = maxf(db - noise_floor_db - VOICE_GATE_DB, 0.0)
	var target_db: float = db_min + voice_excess
	_smoothed_voice_db = lerpf(_smoothed_voice_db, target_db, VOICE_DB_SMOOTH)
	last_db = _smoothed_voice_db



func _on_stone_collision(other: Node, body: RigidBody3D) -> void :
	if isWallBody(other):
		playWallHitSound()
		return
	if body.linear_velocity.length() > 0.25 and collider_sound.stream != null:
		collider_sound.play()



func isWallBody(node: Node) -> bool:
	var parent: Node = node.get_parent()
	return parent != null and parent.name == "Walls"



func playWallHitSound() -> void :
	if collider_sound.stream != null:
		collider_sound.play()



func applyMaterialToMeshes(node: Node, material: Material) -> void :
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = node as MeshInstance3D
		mesh.material_override = material
	for child: Node in node.get_children():
		applyMaterialToMeshes(child, material)



func _on_restart_button_pressed() -> void :
	get_tree().reload_current_scene()
