class_name MenuMainScreen
extends Control
## The main menu. Shows the buttons and emits a signal for each; the game
## decides what starting, continuing, settings and quitting mean.

signal start_pressed
signal continue_pressed
signal settings_pressed
signal quit_pressed

## Heading at the top. Empty hides the heading.
@export var title_text: String = "":
	set(value):
		title_text = value
		if is_node_ready():
			_refresh()

## Show a Continue button above Start, for a game with a save to resume.
@export var show_continue: bool = false:
	set(value):
		show_continue = value
		if is_node_ready():
			_refresh()

## Show the Quit button. A game hides this on web and mobile.
@export var show_quit: bool = true:
	set(value):
		show_quit = value
		if is_node_ready():
			_refresh()


func _ready() -> void:
	%StartButton.pressed.connect(start_pressed.emit)
	%ContinueButton.pressed.connect(continue_pressed.emit)
	%SettingsButton.pressed.connect(settings_pressed.emit)
	%QuitButton.pressed.connect(quit_pressed.emit)
	_refresh()


## The control to focus first: Continue when it is shown, otherwise Start.
func get_initial_focus() -> Control:
	return %ContinueButton if show_continue else %StartButton


func _refresh() -> void:
	# Read focus first: Godot drops focus as soon as the focused control is hidden.
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	%Title.text = title_text
	%Title.visible = not title_text.is_empty()
	%ContinueButton.visible = show_continue
	%QuitButton.visible = show_quit
	if focused != null and is_ancestor_of(focused) and not focused.is_visible_in_tree():
		get_initial_focus().grab_focus()
