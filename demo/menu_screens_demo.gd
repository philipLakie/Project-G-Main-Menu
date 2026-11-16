extends Control
## Demo: the main menu and the settings screen, with toggles for the menu's
## options and a log of every signal. Nothing quits or changes scene here.

@onready var _menu: MenuMainScreen = %MainMenu
@onready var _settings: MenuSettingsScreen = %SettingsScreen
@onready var _log: Label = %Log

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
		_menu.connect(signal_name, _log_line.bind(signal_name))
	_menu.settings_pressed.connect(_open_settings)
	_settings.back_requested.connect(_log_line.bind(&"back_requested"))
	_settings.back_requested.connect(_close_settings)
	%ShowContinue.toggled.connect(func(on: bool) -> void: _menu.show_continue = on)
	%ShowQuit.toggled.connect(func(on: bool) -> void: _menu.show_quit = on)
	_menu.get_initial_focus().grab_focus()


func _open_settings() -> void:
	_settings.setup(_store)
	_menu.hide()
	_settings.show()
	_settings.get_initial_focus().grab_focus()


func _close_settings() -> void:
	_settings.hide()
	_menu.show()
	_menu.get_node("%SettingsButton").grab_focus()


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
