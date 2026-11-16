class_name MenuPauseScreen
extends Control
## The pause menu. Shows the buttons and emits a signal for each; the game
## decides what pausing, resuming and leaving mean. Runs while the tree is
## paused, but never pauses or unpauses it itself.

signal resume_pressed
signal settings_pressed
signal main_menu_pressed
signal quit_pressed
## Emitted with resume_pressed, so a screen stack closes this screen.
signal back_requested

## Show the Quit button. A game hides this on web and mobile.
@export var show_quit: bool = true:
	set(value):
		show_quit = value
		if is_node_ready():
			_refresh()


func _ready() -> void:
	%ResumeButton.pressed.connect(resume_pressed.emit)
	%ResumeButton.pressed.connect(back_requested.emit)
	%SettingsButton.pressed.connect(settings_pressed.emit)
	%MainMenuButton.pressed.connect(main_menu_pressed.emit)
	%QuitButton.pressed.connect(quit_pressed.emit)
	_refresh()


## The control to focus first: Resume.
func get_initial_focus() -> Control:
	return %ResumeButton


func _refresh() -> void:
	# Read focus first: Godot drops focus as soon as the focused control is hidden.
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	%QuitButton.visible = show_quit
	if focused != null and is_ancestor_of(focused) and not focused.is_visible_in_tree():
		get_initial_focus().grab_focus()
