extends Control
## Sandbox wiring: the project opens on the main menu. What each button means
## belongs to the game, so only Quit does something real for now.


func _ready() -> void:
	var menu: MenuMainScreen = %MainMenu
	menu.title_text = ProjectSettings.get_setting("application/config/name")
	menu.show_quit = not (OS.has_feature("web") or OS.has_feature("mobile"))
	menu.quit_pressed.connect(get_tree().quit)
	menu.start_pressed.connect(_placeholder.bind("start"))
	menu.continue_pressed.connect(_placeholder.bind("continue"))
	menu.settings_pressed.connect(_placeholder.bind("settings"))
	menu.get_initial_focus().grab_focus()


func _placeholder(button: String) -> void:
	print("Main menu: %s pressed (not wired up yet)." % button)
