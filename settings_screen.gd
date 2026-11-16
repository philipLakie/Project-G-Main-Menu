class_name MenuSettingsScreen
extends Control
## The settings screen. Builds one row per definition in a SettingsStore,
## grouped by category. Changes go straight to the store; there is no Apply.

signal back_requested

## How many key or gamepad presses cross a slider whose definition has
## step 0 (no snapping); such a slider has no step of its own to move by.
@export var free_slider_presses: int = 20

var _store: SettingsStore


func _ready() -> void:
	%ResetButton.pressed.connect(_on_reset_pressed)
	%BackButton.pressed.connect(back_requested.emit)
	if _store != null:
		_build_rows()


## Builds the screen from the store. Call again to rebuild or switch stores.
func setup(store: SettingsStore) -> void:
	if _store != null and _store.setting_changed.is_connected(_on_setting_changed):
		_store.setting_changed.disconnect(_on_setting_changed)
	_store = store
	_store.setting_changed.connect(_on_setting_changed)
	if is_node_ready():
		_build_rows()


## The control to focus first: the first setting's control, or Reset if there are none.
func get_initial_focus() -> Control:
	for row in %Rows.get_children():
		if row.has_node("Value"):
			return row.get_node("Value")
	return %ResetButton


func _build_rows() -> void:
	for child in %Rows.get_children():
		child.free()
	var categories: Array[StringName] = []
	for def in _store.get_definitions():
		if not categories.has(def.category):
			categories.append(def.category)
	for category in categories:
		var heading_added := false
		for def in _store.get_definitions():
			if def.category != category:
				continue
			var control := _make_control(def)
			if control == null:
				continue
			if not heading_added and category != &"":
				var heading := Label.new()
				heading.name = "Category_" + String(category)
				heading.theme_type_variation = &"MenuCategoryLabel"
				heading.text = category
				%Rows.add_child(heading)
			heading_added = true
			var row := HBoxContainer.new()
			row.name = String(def.key).validate_node_name()
			var label := Label.new()
			label.name = "Name"
			label.theme_type_variation = &"MenuSettingLabel"
			label.text = def.label
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			control.name = "Value"
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(control)
			%Rows.add_child(row)


func _make_control(def: SettingDef) -> Control:
	var value: Variant = _store.get_value(def.key)
	if def is SettingToggleDef:
		var check := CheckButton.new()
		check.button_pressed = value
		check.toggled.connect(_on_value_chosen.bind(def.key))
		return check
	if def is SettingSliderDef:
		var slider := HSlider.new()
		slider.min_value = def.min_value
		slider.max_value = def.max_value
		slider.step = def.step
		if def.step <= 0.0:
			slider.gui_input.connect(_on_free_slider_input.bind(slider, def))
		slider.value = value
		slider.value_changed.connect(_on_value_chosen.bind(def.key))
		return slider
	if def is SettingOptionsDef:
		var option := OptionButton.new()
		for i in def.values.size():
			option.add_item(def.labels[i] if i < def.labels.size() else def.values[i])
		option.select(def.values.find(value))
		option.item_selected.connect(_on_option_selected.bind(def))
		return option
	push_warning("MenuSettingsScreen: skipping setting '%s': unknown definition type." % def.key)
	return null


func _on_value_chosen(value: Variant, key: StringName) -> void:
	_store.set_value(key, value)


## A slider with step 0 ignores left/right, so move it by a fixed share of its range.
func _on_free_slider_input(event: InputEvent, slider: HSlider, def: SettingSliderDef) -> void:
	if free_slider_presses <= 0:
		return
	var amount := (def.max_value - def.min_value) / free_slider_presses
	if event.is_action_pressed(&"ui_right", true):
		slider.value += amount
		slider.accept_event()
	elif event.is_action_pressed(&"ui_left", true):
		slider.value -= amount
		slider.accept_event()


func _on_option_selected(index: int, def: SettingOptionsDef) -> void:
	_store.set_value(def.key, def.values[index])


func _on_reset_pressed() -> void:
	if _store != null:
		_store.reset_all()


func _on_setting_changed(key: StringName, value: Variant) -> void:
	var path := String(key).validate_node_name() + "/Value"
	if not is_node_ready() or not %Rows.has_node(path):
		return
	var control: Control = %Rows.get_node(path)
	if control is CheckButton:
		control.set_pressed_no_signal(value)
	elif control is HSlider:
		control.set_value_no_signal(value)
	elif control is OptionButton:
		control.select((_store.get_definition(key) as SettingOptionsDef).values.find(value))
