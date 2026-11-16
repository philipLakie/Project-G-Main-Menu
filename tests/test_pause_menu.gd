extends GutTest

const SCENE := preload("res://addons/menu_screens/pause_menu.tscn")

var _screen: MenuPauseScreen


func before_each() -> void:
	_screen = SCENE.instantiate()
	add_child_autofree(_screen)


func after_each() -> void:
	get_tree().paused = false


func _button(node_name: String) -> Button:
	return _screen.get_node("%" + node_name)


func test_each_button_emits_its_signal_once() -> void:
	watch_signals(_screen)
	var pairs := {
		"ResumeButton": "resume_pressed",
		"SettingsButton": "settings_pressed",
		"MainMenuButton": "main_menu_pressed",
		"QuitButton": "quit_pressed",
	}
	for node_name: String in pairs:
		_button(node_name).pressed.emit()
		assert_signal_emit_count(_screen, pairs[node_name], 1)


func test_resume_also_emits_back_requested() -> void:
	watch_signals(_screen)
	_button("ResumeButton").pressed.emit()
	assert_signal_emit_count(_screen, "back_requested", 1)


func test_only_resume_emits_back_requested() -> void:
	watch_signals(_screen)
	for node_name: String in ["SettingsButton", "MainMenuButton", "QuitButton"]:
		_button(node_name).pressed.emit()
	assert_signal_emit_count(_screen, "back_requested", 0)


func test_show_quit_toggles_quit_button() -> void:
	assert_true(_button("QuitButton").visible, "quit shown by default")
	_screen.show_quit = false
	assert_false(_button("QuitButton").visible)


func test_show_quit_set_before_entering_tree_applies() -> void:
	var screen: MenuPauseScreen = SCENE.instantiate()
	screen.show_quit = false
	add_child_autofree(screen)
	assert_false(screen.get_node("%QuitButton").visible)


func test_initial_focus_is_resume_and_focusable() -> void:
	for show_quit: bool in [true, false]:
		_screen.show_quit = show_quit
		var target := _screen.get_initial_focus()
		assert_eq(target, _button("ResumeButton"))
		assert_true(target.is_visible_in_tree())
		assert_eq(target.focus_mode, Control.FOCUS_ALL)


func test_hiding_focused_quit_moves_focus() -> void:
	_button("QuitButton").grab_focus()
	_screen.show_quit = false
	assert_eq(get_viewport().gui_get_focus_owner(), _button("ResumeButton"))


func test_screen_runs_while_tree_paused() -> void:
	get_tree().paused = true
	assert_true(_screen.can_process())
	assert_true(_button("ResumeButton").can_process())
