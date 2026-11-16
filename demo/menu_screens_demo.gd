extends Control
## Demo: the main menu with toggles for its options and a log of every signal.
## Nothing quits or changes scene here; the demo only logs.

@onready var _menu: MenuMainScreen = %MainMenu
@onready var _log: Label = %Log


func _ready() -> void:
	for signal_name: StringName in [&"start_pressed", &"continue_pressed",
			&"settings_pressed", &"quit_pressed"]:
		_menu.connect(signal_name, _log_line.bind(signal_name))
	%ShowContinue.toggled.connect(func(on: bool) -> void: _menu.show_continue = on)
	%ShowQuit.toggled.connect(func(on: bool) -> void: _menu.show_quit = on)
	_menu.get_initial_focus().grab_focus()


func _log_line(signal_name: StringName) -> void:
	_log.text += "\n" + signal_name
