extends Control
## Sandbox wiring: the project opens on the main menu. Start shows a placeholder
## game; Esc pauses it and opens the pause menu. Settings opens from either menu
## and Back returns to the menu that opened it. Continue is not wired up yet.

@export var settings_scene: PackedScene
@export var pause_scene: PackedScene

var _settings_screen: MenuSettingsScreen
var _settings_opener: Control
var _pause_screen: MenuPauseScreen
var _can_quit := not (OS.has_feature("web") or OS.has_feature("mobile"))

@onready var _menu: MenuMainScreen = %MainMenu
@onready var _playing: Label = %Playing


func _ready() -> void:
	_menu.title_text = ProjectSettings.get_setting("application/config/name")
	_menu.show_quit = _can_quit
	_menu.quit_pressed.connect(get_tree().quit)
	_menu.settings_pressed.connect(_open_settings.bind(_menu))
	_menu.start_pressed.connect(_start)
	_menu.continue_pressed.connect(_placeholder.bind("continue"))
	_menu.get_initial_focus().grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Esc toggles the pause menu while playing, but not while settings is open over it.
	if not event.is_action_pressed(&"ui_cancel") or not _playing.visible or _settings_screen != null:
		return
	get_viewport().set_input_as_handled()
	if _pause_screen == null:
		_open_pause()
	else:
		_resume()


func _start() -> void:
	_menu.hide()
	_playing.show()


func _open_pause() -> void:
	if _pause_screen != null:
		return
	get_tree().paused = true
	_pause_screen = pause_scene.instantiate()
	_pause_screen.show_quit = _can_quit
	add_child(_pause_screen)
	_pause_screen.back_requested.connect(_resume)
	_pause_screen.settings_pressed.connect(_open_settings.bind(_pause_screen))
	_pause_screen.main_menu_pressed.connect(_to_main_menu)
	_pause_screen.quit_pressed.connect(get_tree().quit)
	_pause_screen.get_initial_focus().grab_focus()


func _resume() -> void:
	if _pause_screen == null:
		return
	_pause_screen.queue_free()
	_pause_screen = null
	get_tree().paused = false


func _to_main_menu() -> void:
	_resume()
	_playing.hide()
	_menu.show()
	_menu.get_initial_focus().grab_focus()


func _open_settings(from: Control) -> void:
	if _settings_screen != null:
		return
	_settings_opener = from
	_settings_screen = settings_scene.instantiate()
	add_child(_settings_screen)
	_settings_screen.setup(%Settings)
	_settings_screen.back_requested.connect(_close_settings)
	from.hide()
	_settings_screen.get_initial_focus().grab_focus()


func _close_settings() -> void:
	_settings_screen.queue_free()
	_settings_screen = null
	_settings_opener.show()
	_settings_opener.get_node("%SettingsButton").grab_focus()


func _placeholder(button: String) -> void:
	print("Main menu: %s pressed (not wired up yet)." % button)
