extends Control
## Sandbox wiring: the project opens on the main menu, and Settings opens the
## settings screen for the game's store. Start and Continue are not wired up yet.

@export var settings_scene: PackedScene

var _settings_screen: MenuSettingsScreen

@onready var _menu: MenuMainScreen = %MainMenu


func _ready() -> void:
	_menu.title_text = ProjectSettings.get_setting("application/config/name")
	_menu.show_quit = not (OS.has_feature("web") or OS.has_feature("mobile"))
	_menu.quit_pressed.connect(get_tree().quit)
	_menu.settings_pressed.connect(_open_settings)
	_menu.start_pressed.connect(_placeholder.bind("start"))
	_menu.continue_pressed.connect(_placeholder.bind("continue"))
	_menu.get_initial_focus().grab_focus()


func _open_settings() -> void:
	_settings_screen = settings_scene.instantiate()
	add_child(_settings_screen)
	_settings_screen.setup(%Settings)
	_settings_screen.back_requested.connect(_close_settings)
	_menu.hide()
	_settings_screen.get_initial_focus().grab_focus()


func _close_settings() -> void:
	_settings_screen.queue_free()
	_settings_screen = null
	_menu.show()
	_menu.get_node("%SettingsButton").grab_focus()


func _placeholder(button: String) -> void:
	print("Main menu: %s pressed (not wired up yet)." % button)
