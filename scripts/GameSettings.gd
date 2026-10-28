extends Node



const CONFIG_PATH: String = "user://settings.cfg"
const MUSIC_BUS_NAME: String = "Music"
const SFX_BUS_NAME: String = "SFX"

const DEFAULT_MUSIC_VOLUME: float = 0.6
const DEFAULT_SFX_VOLUME: float = 0.5
const DEFAULT_VOICE_DB_MIN: float = 30.0
const DEFAULT_VOICE_DB_MAX: float = 70.0


const VOICE_DB_FLOOR: float = 5.0
const VOICE_DB_CEIL: float = 95.0
const VOICE_DB_GAP: float = 5.0

var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var voice_db_min: float = DEFAULT_VOICE_DB_MIN
var voice_db_max: float = DEFAULT_VOICE_DB_MAX


func _ready() -> void :
	_ensure_bus(MUSIC_BUS_NAME)
	_ensure_bus(SFX_BUS_NAME)
	load_settings()
	apply_audio()



func _ensure_bus(bus_name: String) -> void :
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")



func apply_audio() -> void :
	_apply_bus_volume(MUSIC_BUS_NAME, music_volume)
	_apply_bus_volume(SFX_BUS_NAME, sfx_volume)


func _apply_bus_volume(bus_name: String, linear: float) -> void :
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var clamped: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clamped, 0.0001)))



func set_voice_range(new_min: float, new_max: float) -> void :
	voice_db_min = clampf(new_min, VOICE_DB_FLOOR, VOICE_DB_CEIL - VOICE_DB_GAP)
	voice_db_max = clampf(new_max, voice_db_min + VOICE_DB_GAP, VOICE_DB_CEIL)


func load_settings() -> void :
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	if err != OK:
		return
	music_volume = float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME))
	sfx_volume = float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME))
	var loaded_min: float = float(config.get_value("voice", "db_min", DEFAULT_VOICE_DB_MIN))
	var loaded_max: float = float(config.get_value("voice", "db_max", DEFAULT_VOICE_DB_MAX))
	set_voice_range(loaded_min, loaded_max)


func save_settings() -> void :
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("voice", "db_min", voice_db_min)
	config.set_value("voice", "db_max", voice_db_max)
	config.save(CONFIG_PATH)
