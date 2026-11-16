extends Control
## Demo: the main menu, pause menu and settings screen, with toggles for the
## menus' options and a log of every signal. Nothing quits, pauses or changes scene here.

@onready var _menu: MenuMainScreen = %MainMenu
@onready var _settings: MenuSettingsScreen = %SettingsScreen
@onready var _pause: MenuPauseScreen = %PauseMenu
@onready var _log: Label = %Log
@onready var _settings_opener: Control = %MainMenu

var _store := SettingsStore.new()


func _ready() -> void:
	_store.file_path = "user://menu_screens_demo.cfg"
	_store.definitions = [
		_def(SettingToggleDef.new(), &"show_hints", "Show hints", &"gameplay"),
		_def(SettingOptionsDef.new(), &"difficulty", "Difficulty", &"gameplay"),
		_def(SettingSliderDef.new(), &"text_speed", "Text speed", &"gameplay"),
		_def(SettingSliderDef.new(), &"master_volume", "Master volume", &"audio",
				SettingDef.ApplyAs.AUDIO_BUS_VOLUME, &"Master"),
		_def(SettingToggleDef.new(), &"fullscreen", "Fullscreen", &"video",
				SettingDef.ApplyAs.FULLSCREEN),
	]
	var difficulty := _store.definitions[1] as SettingOptionsDef
	difficulty.values = ["easy", "normal", "hard"]
	difficulty.labels = ["Easy", "Normal", "Hard"]
	difficulty.default_value = "normal"
	(_store.definitions[2] as SettingSliderDef).default_value = 0.5
	(_store.definitions[3] as SettingSliderDef).default_value = 1.0
	_store.setting_changed.connect(_on_setting_changed)
	add_child(_store)
	var applier := SettingsApplier.new()
	applier.store = _store
	add_child(applier)

	for signal_name: StringName in [&"start_pressed", &"continue_pressed",
			&"settings_pressed", &"quit_pressed"]:
		_menu.connect(signal_name, _log_line.bind("main menu: " + signal_name))
	for signal_name: StringName in [&"resume_pressed", &"settings_pressed",
			&"main_menu_pressed", &"quit_pressed", &"back_requested"]:
		_pause.connect(signal_name, _log_line.bind("pause menu: " + signal_name))
	_menu.settings_pressed.connect(_open_settings.bind(_menu))
	_pause.settings_pressed.connect(_open_settings.bind(_pause))
	_pause.back_requested.connect(_show_main_menu)
	_pause.main_menu_pressed.connect(_show_main_menu)
	_settings.back_requested.connect(_log_line.bind("settings: back_requested"))
	_settings.back_requested.connect(_close_settings)
	%ShowPause.pressed.connect(_show_pause_menu)
	%ShowContinue.toggled.connect(func(on: bool) -> void: _menu.show_continue = on)
	%ShowQuit.toggled.connect(func(on: bool) -> void:
		_menu.show_quit = on
		_pause.show_quit = on)
	_menu.get_initial_focus().grab_focus()


func _show_only(screen: Control) -> void:
	for other: Control in [_menu, _pause, _settings]:
		other.visible = other == screen


func _show_main_menu() -> void:
	_show_only(_menu)
	_menu.get_initial_focus().grab_focus()


func _show_pause_menu() -> void:
	_show_only(_pause)
	_pause.get_initial_focus().grab_focus()


## Opens settings from the main or pause menu; Back returns to that screen.
func _open_settings(from: Control) -> void:
	_settings_opener = from
	_settings.setup(_store)
	_show_only(_settings)
	_settings.get_initial_focus().grab_focus()


func _close_settings() -> void:
	_show_only(_settings_opener)
	_settings_opener.get_node("%SettingsButton").grab_focus()


func _on_setting_changed(key: StringName, value: Variant) -> void:
	_log_line("setting_changed: %s = %s" % [key, value])


func _log_line(text: String) -> void:
	_log.text += "\n" + text


func _def(def: SettingDef, key: StringName, label: String, category: StringName,
		apply_as := SettingDef.ApplyAs.NONE, target := &"") -> SettingDef:
	def.key = key
	def.label = label
	def.category = category
	def.apply_as = apply_as
	def.apply_target = target
	return def
