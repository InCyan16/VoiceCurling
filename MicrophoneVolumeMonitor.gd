extends Node

signal volume_exceeded(db: float)
signal volume_changed(db: float)

@export var threshold_db: float = 40.0
@export var calibration_offset_db: float = 80.0
@export var print_interval: float = 0.2
@export var sample_interval: float = 0.033
@export var input_device_name: String = ""
@export var max_frames_per_read: int = 4096

var microphone_player: AudioStreamPlayer = null
var capture_effect: AudioEffectCapture = null
var capture_bus_name: String = "MicrophoneCapture"
var time_since_print: float = 0.0
var time_since_sample: float = 0.0
var is_monitoring: bool = false
var last_valid_db: float = - INF



func _ready() -> void :
	setupCaptureBus()
	await get_tree().process_frame
	startMicrophone()



func _process(delta: float) -> void :
	if not is_monitoring:
		return

	time_since_sample += delta
	time_since_print += delta
	if time_since_sample < sample_interval:
		return
	time_since_sample = 0.0

	var db: float = readVolumeDb()
	if is_inf(db):
		return

	last_valid_db = db
	volume_changed.emit(db)

	if db <= threshold_db or time_since_print < print_interval:
		return

	time_since_print = 0.0
	volume_exceeded.emit(db)



func setupCaptureBus() -> void :
	var bus_index: int = AudioServer.get_bus_index(capture_bus_name)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, capture_bus_name)
		AudioServer.set_bus_send(bus_index, "Master")

	AudioServer.set_bus_volume_db(bus_index, -80.0)
	capture_effect = AudioEffectCapture.new()

	var has_capture: bool = false
	for effect_index: int in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect: AudioEffect = AudioServer.get_bus_effect(bus_index, effect_index)
		if effect is AudioEffectCapture:
			capture_effect = effect as AudioEffectCapture
			has_capture = true
			break

	if not has_capture:
		AudioServer.add_bus_effect(bus_index, capture_effect)



func startMicrophone() -> void :
	var input_devices: PackedStringArray = AudioServer.get_input_device_list()
	print("Available microphone devices: %s" % [input_devices])

	if input_devices.is_empty():
		push_warning("No microphone input device was found. Check system permission and recording device.")
		return

	var selected_device: String = input_device_name if input_device_name != "" else input_devices[0]
	if not input_devices.has(selected_device):
		push_warning("Microphone '%s' was not found. Using '%s' instead." % [selected_device, input_devices[0]])
		selected_device = input_devices[0]

	AudioServer.input_device = selected_device
	print("Using microphone device: %s" % AudioServer.input_device)

	microphone_player = get_node_or_null("../MicrophoneInput") as AudioStreamPlayer
	if microphone_player == null:
		microphone_player = AudioStreamPlayer.new()
		microphone_player.name = "MicrophoneInput"
		get_parent().call_deferred("add_child", microphone_player)
		await get_tree().process_frame

	microphone_player.stream = AudioStreamMicrophone.new()
	microphone_player.bus = capture_bus_name
	microphone_player.play()
	is_monitoring = microphone_player.playing

	if not is_monitoring:
		push_warning("Could not start microphone input. Check privacy settings or close other apps using the microphone.")



func readVolumeDb() -> float:
	var available_frames: int = capture_effect.get_frames_available()
	if available_frames == 0:
		return - INF


	if available_frames > max_frames_per_read:
		capture_effect.get_buffer(available_frames - max_frames_per_read)
		available_frames = max_frames_per_read

	var frames: PackedVector2Array = capture_effect.get_buffer(available_frames)
	var squared_sum: float = 0.0
	var sample_count: int = frames.size() * 2

	for frame: Vector2 in frames:
		squared_sum += frame.x * frame.x
		squared_sum += frame.y * frame.y

	if sample_count == 0:
		return - INF

	var rms: float = sqrt(squared_sum / sample_count)
	if rms <= 0.0:
		return - INF

	return 20.0 * log(rms) / log(10.0) + calibration_offset_db
