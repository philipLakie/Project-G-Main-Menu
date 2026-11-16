extends GutTest

const SCENE := preload("res://addons/menu_screens/settings_screen.tscn")
const PATH := "user://test_menu_settings.cfg"


class _OddDef:
	extends SettingDef


var _store: SettingsStore
var _screen: MenuSettingsScreen


func before_each() -> void:
	_store = _make_store()
	_screen = SCENE.instantiate()
	add_child_autofree(_screen)
	_screen.setup(_store)


func after_each() -> void:
	get_tree().paused = false
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _make_store(extra: Array[SettingDef] = []) -> SettingsStore:
	var hints := SettingToggleDef.new()
	hints.key = &"hints"
	hints.label = "Hints"
	hints.category = &"gameplay"
	hints.default_value = true
	var volume := SettingSliderDef.new()
	volume.key = &"volume"
	volume.label = "Volume"
	volume.category = &"audio"
	volume.step = 0.1
	volume.default_value = 0.5
	var difficulty := SettingOptionsDef.new()
	difficulty.key = &"difficulty"
	difficulty.label = "Difficulty"
	difficulty.category = &"gameplay"
	difficulty.values = ["easy", "normal", "hard"]
	difficulty.labels = ["Easy", "Normal", "Hard"]
	difficulty.default_value = "normal"
	var store := SettingsStore.new()
	store.definitions = [hints, volume, difficulty]
	store.definitions.append_array(extra)
	store.file_path = PATH
	add_child_autofree(store)
	return store


func _value(screen: MenuSettingsScreen, key: String) -> Control:
	return screen.get_node("%Rows/" + key + "/Value")


func _row_names(screen: MenuSettingsScreen) -> Array[String]:
	var names: Array[String] = []
	for child in screen.get_node("%Rows").get_children():
		if not child.is_queued_for_deletion():
			names.append(String(child.name))
	return names


func test_one_row_per_definition_with_matching_control() -> void:
	var hints := _value(_screen, "hints") as CheckButton
	var volume := _value(_screen, "volume") as HSlider
	var difficulty := _value(_screen, "difficulty") as OptionButton
	assert_not_null(hints)
	assert_not_null(volume)
	assert_not_null(difficulty)
	assert_true(hints.button_pressed)
	assert_eq([volume.min_value, volume.max_value, volume.step], [0.0, 1.0, 0.1])
	assert_almost_eq(volume.value, 0.5, 0.0001)
	assert_eq(difficulty.item_count, 3)
	assert_eq(difficulty.get_item_text(2), "Hard")
	assert_eq(difficulty.selected, 1)
	assert_eq(_screen.get_node("%Rows/hints/Name").text, "Hints")


func test_rows_grouped_by_category_in_listed_order() -> void:
	assert_eq(_row_names(_screen),
			["Category_gameplay", "hints", "difficulty", "Category_audio", "volume"])


func test_changing_a_control_sets_the_store() -> void:
	(_value(_screen, "hints") as CheckButton).button_pressed = false
	(_value(_screen, "volume") as HSlider).value = 0.8
	var difficulty := _value(_screen, "difficulty") as OptionButton
	difficulty.select(2)
	difficulty.item_selected.emit(2)
	assert_eq(_store.get_value(&"hints"), false)
	assert_almost_eq(_store.get_value(&"volume"), 0.8, 0.0001)
	assert_eq(_store.get_value(&"difficulty"), "hard")


func test_store_change_updates_the_control() -> void:
	_store.set_value(&"hints", false)
	_store.set_value(&"volume", 0.2)
	_store.set_value(&"difficulty", "easy")
	assert_false((_value(_screen, "hints") as CheckButton).button_pressed)
	assert_almost_eq((_value(_screen, "volume") as HSlider).value, 0.2, 0.0001)
	assert_eq((_value(_screen, "difficulty") as OptionButton).selected, 0)


func test_reset_button_restores_defaults_in_store_and_controls() -> void:
	_store.set_value(&"hints", false)
	_store.set_value(&"difficulty", "hard")
	_screen.get_node("%ResetButton").pressed.emit()
	assert_eq(_store.get_value(&"hints"), true)
	assert_eq(_store.get_value(&"difficulty"), "normal")
	assert_true((_value(_screen, "hints") as CheckButton).button_pressed)
	assert_eq((_value(_screen, "difficulty") as OptionButton).selected, 1)


func test_back_button_emits_back_requested() -> void:
	watch_signals(_screen)
	_screen.get_node("%BackButton").pressed.emit()
	assert_signal_emit_count(_screen, "back_requested", 1)


func test_setup_twice_does_not_duplicate_rows() -> void:
	_screen.setup(_store)
	assert_eq(_row_names(_screen).size(), 5)


func test_setup_with_new_store_follows_only_new_store() -> void:
	var other := _make_store()
	_screen.setup(other)
	_store.set_value(&"hints", false)
	assert_true((_value(_screen, "hints") as CheckButton).button_pressed)
	other.set_value(&"hints", false)
	assert_false((_value(_screen, "hints") as CheckButton).button_pressed)


func test_unknown_definition_type_is_skipped_with_warning() -> void:
	var odd := _OddDef.new()
	odd.key = &"odd"
	var screen: MenuSettingsScreen = SCENE.instantiate()
	add_child_autofree(screen)
	screen.setup(_make_store([odd]))
	assert_false(_row_names(screen).has("odd"))
	assert_push_warning("odd")


func test_initial_focus_is_first_control_or_reset() -> void:
	assert_eq(_screen.get_initial_focus(), _value(_screen, "hints"))
	var empty := SettingsStore.new()
	empty.file_path = PATH
	add_child_autofree(empty)
	_screen.setup(empty)
	var target := _screen.get_initial_focus()
	assert_eq(target, _screen.get_node("%ResetButton"))
	assert_true(target.is_visible_in_tree())
	assert_eq(target.focus_mode, Control.FOCUS_ALL)


func test_freed_screen_ignores_store_changes() -> void:
	_screen.free()
	_store.set_value(&"hints", false)
	assert_eq(_store.get_value(&"hints"), false)
	assert_push_error_count(0)


func test_setup_before_entering_tree() -> void:
	var screen: MenuSettingsScreen = SCENE.instantiate()
	screen.setup(_store)
	add_child_autofree(screen)
	assert_eq(_row_names(screen).size(), 5)


func test_missing_option_labels_fall_back_to_values() -> void:
	var size := SettingOptionsDef.new()
	size.key = &"size"
	size.values = ["s", "m", "l"]
	size.labels = ["Small"]
	size.default_value = "m"
	var screen: MenuSettingsScreen = SCENE.instantiate()
	add_child_autofree(screen)
	screen.setup(_make_store([size]))
	var option := _value(screen, "size") as OptionButton
	assert_eq([option.get_item_text(0), option.get_item_text(1)], ["Small", "m"])


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)


func test_keyboard_reaches_rows_below_the_fold() -> void:
	var many: Array[SettingDef] = []
	for i in 40:
		var def := SettingToggleDef.new()
		def.key = StringName("t%d" % i)
		def.category = &"many"
		many.append(def)
	var screen: MenuSettingsScreen = SCENE.instantiate()
	add_child_autofree(screen)
	_screen.hide()
	screen.setup(_make_store(many))
	await wait_process_frames(2)
	screen.get_node("%Rows/t0/Value").grab_focus()
	for i in 39:
		_press(&"ui_down")
		await wait_process_frames(2)
	assert_eq(get_viewport().gui_get_focus_owner(), screen.get_node("%Rows/t39/Value"))


func test_free_slider_moves_with_keyboard() -> void:
	var free_slider := SettingSliderDef.new()
	free_slider.key = &"free"
	free_slider.step = 0.0
	free_slider.default_value = 0.5
	var store := _make_store([free_slider])
	var screen: MenuSettingsScreen = SCENE.instantiate()
	add_child_autofree(screen)
	_screen.hide()
	screen.setup(store)
	screen.get_node("%Rows/free/Value").grab_focus()
	_press(&"ui_right")
	assert_gt(store.get_value(&"free"), 0.5)


func test_definition_without_category_has_no_heading() -> void:
	var plain := SettingToggleDef.new()
	plain.key = &"plain"
	var screen: MenuSettingsScreen = SCENE.instantiate()
	add_child_autofree(screen)
	screen.setup(_make_store([plain]))
	assert_true(_row_names(screen).has("plain"))
	assert_false(_row_names(screen).has("Category_"))


func test_settings_screen_runs_while_tree_paused() -> void:
	get_tree().paused = true
	assert_true(_screen.can_process())
	assert_true(_value(_screen, "hints").can_process())
