extends Control
## Demo: one of each definition type plus master volume, fullscreen and vsync.
## Everything is built in code so the scene file stays trivial. A game would
## normally save definitions as .tres files and add the nodes in the editor.

var _store := SettingsStore.new()
var _log := Label.new()
var _controls: Dictionary[StringName, Control] = {}


func _ready() -> void:
	_store.file_path = "user://settings_demo.cfg"
	_store.definitions = [
		_toggle(&"show_hints", "Show hints", true),
		_slider(&"mouse_sensitivity", "Mouse sensitivity", 0.1, 2.0, 0.1, 1.0),
		_options(&"difficulty", "Difficulty", ["easy", "normal", "hard"], "normal"),
		_slider(&"master_volume", "Master volume", 0.0, 1.0, 0.05, 1.0,
				SettingDef.ApplyAs.AUDIO_BUS_VOLUME, &"Master"),
		_toggle(&"fullscreen", "Fullscreen", false, SettingDef.ApplyAs.FULLSCREEN),
		_toggle(&"vsync", "Vsync", true, SettingDef.ApplyAs.VSYNC),
	]
	_store.setting_changed.connect(_on_setting_changed)
	add_child(_store)

	var applier := SettingsApplier.new()
	applier.store = _store
	add_child(applier)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(box)
	for def in _store.get_definitions():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = def.label
		label.custom_minimum_size.x = 200
		row.add_child(label)
		_controls[def.key] = _make_control(def)
		row.add_child(_controls[def.key])
		box.add_child(row)

	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.pressed.connect(_store.reset_all)
	box.add_child(reset)
	_log.text = "Values were loaded from %s. Close and reopen to see them kept." % _store.file_path
	box.add_child(_log)
	_controls.values()[0].grab_focus()


func _make_control(def: SettingDef) -> Control:
	var value: Variant = _store.get_value(def.key)
	if def is SettingToggleDef:
		var check := CheckButton.new()
		check.button_pressed = value
		check.toggled.connect(func(on: bool) -> void: _store.set_value(def.key, on))
		return check
	if def is SettingSliderDef:
		var slider := HSlider.new()
		slider.min_value = def.min_value
		slider.max_value = def.max_value
		slider.step = def.step
		slider.value = value
		slider.custom_minimum_size.x = 200
		slider.value_changed.connect(func(number: float) -> void: _store.set_value(def.key, number))
		return slider
	var option := OptionButton.new()
	for text: String in def.values:
		option.add_item(text)
	option.selected = def.values.find(value)
	option.item_selected.connect(
			func(index: int) -> void: _store.set_value(def.key, def.values[index]))
	return option


func _on_setting_changed(key: StringName, value: Variant) -> void:
	_log.text += "\nsetting_changed: %s = %s" % [key, value]
	var control := _controls[key]
	if control is CheckButton:
		control.set_pressed_no_signal(value)
	elif control is HSlider:
		control.set_value_no_signal(value)
	else:
		control.selected = _store.get_definition(key).values.find(value)


func _toggle(key: StringName, text: String, default: bool,
		apply_as := SettingDef.ApplyAs.NONE) -> SettingToggleDef:
	var def := SettingToggleDef.new()
	def.key = key
	def.label = text
	def.default_value = default
	def.apply_as = apply_as
	return def


func _slider(key: StringName, text: String, minimum: float, maximum: float, step: float,
		default: float, apply_as := SettingDef.ApplyAs.NONE,
		target := &"") -> SettingSliderDef:
	var def := SettingSliderDef.new()
	def.key = key
	def.label = text
	def.min_value = minimum
	def.max_value = maximum
	def.step = step
	def.default_value = default
	def.apply_as = apply_as
	def.apply_target = target
	return def


func _options(key: StringName, text: String, values: PackedStringArray,
		default: String) -> SettingOptionsDef:
	var def := SettingOptionsDef.new()
	def.key = key
	def.label = text
	def.values = values
	def.labels = values
	def.default_value = default
	return def
