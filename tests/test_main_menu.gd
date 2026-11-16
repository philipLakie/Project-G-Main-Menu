extends GutTest

const SCENE := preload("res://addons/menu_screens/main_menu.tscn")

var _screen: MenuMainScreen


func before_each() -> void:
	_screen = SCENE.instantiate()
	add_child_autofree(_screen)


func _button(node_name: String) -> Button:
	return _screen.get_node("%" + node_name)


func test_each_button_emits_its_signal_once() -> void:
	_screen.show_continue = true
	watch_signals(_screen)
	var pairs := {
		"StartButton": "start_pressed",
		"ContinueButton": "continue_pressed",
		"SettingsButton": "settings_pressed",
		"QuitButton": "quit_pressed",
	}
	for node_name: String in pairs:
		_button(node_name).pressed.emit()
		assert_signal_emit_count(_screen, pairs[node_name], 1)


func test_show_continue_and_show_quit_toggle_buttons() -> void:
	assert_false(_button("ContinueButton").visible, "continue hidden by default")
	assert_true(_button("QuitButton").visible, "quit shown by default")
	_screen.show_continue = true
	_screen.show_quit = false
	assert_true(_button("ContinueButton").visible)
	assert_false(_button("QuitButton").visible)


func test_title_text_is_shown() -> void:
	_screen.title_text = "My Game"
	assert_eq(_screen.get_node("%Title").text, "My Game")
	assert_true(_screen.get_node("%Title").visible)


func test_empty_title_hides_title_label() -> void:
	_screen.title_text = ""
	assert_false(_screen.get_node("%Title").visible)


func test_initial_focus_prefers_continue_when_shown() -> void:
	assert_eq(_screen.get_initial_focus(), _button("StartButton"))
	_screen.show_continue = true
	assert_eq(_screen.get_initial_focus(), _button("ContinueButton"))


func test_initial_focus_is_visible_in_every_combination() -> void:
	for show_continue: bool in [false, true]:
		for show_quit: bool in [false, true]:
			_screen.show_continue = show_continue
			_screen.show_quit = show_quit
			var target := _screen.get_initial_focus()
			assert_true(target.is_visible_in_tree())
			assert_eq(target.focus_mode, Control.FOCUS_ALL)


func test_exports_set_before_entering_tree_apply() -> void:
	var screen: MenuMainScreen = SCENE.instantiate()
	screen.show_continue = true
	screen.show_quit = false
	screen.title_text = "Early"
	add_child_autofree(screen)
	assert_true(screen.get_node("%ContinueButton").visible)
	assert_false(screen.get_node("%QuitButton").visible)
	assert_eq(screen.get_node("%Title").text, "Early")


func test_hiding_focused_button_moves_focus() -> void:
	_screen.show_continue = true
	_button("ContinueButton").grab_focus()
	_screen.show_continue = false
	assert_eq(get_viewport().gui_get_focus_owner(), _button("StartButton"))
